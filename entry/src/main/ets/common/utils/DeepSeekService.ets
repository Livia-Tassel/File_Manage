/*
 * DeepSeek API 服务封装
 */

import http from '@ohos.net.http';

export interface ClassificationResult {
  category: string;
  confidence: number;
}

export interface SummaryResult {
  summary: string;
}

export interface KeywordsResult {
  keywords: string[];
}

export interface RelationResult {
  relatedDocs: string[];
  reason: string;
}

interface ChatMessage {
  role: string;
  content: string;
}

interface ChatRequest {
  model: string;
  messages: ChatMessage[];
  temperature: number;
}

interface ChatChoice {
  message: ChatMessage;
}

interface ChatResponse {
  choices: ChatChoice[];
}

export class DeepSeekService {
  private apiKey: string = '';
  private baseUrl: string = 'https://api.deepseek.com/chat/completions';
  private model: string = 'deepseek-chat';

  setApiKey(key: string): void {
    this.apiKey = key;
  }

  getApiKey(): string {
    return this.apiKey;
  }

  isConfigured(): boolean {
    return this.apiKey.length > 0;
  }

  private async callApi(prompt: string): Promise<string> {
    if (!this.isConfigured()) {
      throw new Error('API Key 未配置');
    }

    const httpRequest = http.createHttp();
    const messages: ChatMessage[] = [{ role: 'user', content: prompt }];
    const requestData: ChatRequest = {
      model: this.model,
      messages: messages,
      temperature: 0.3
    };

    try {
      const response = await httpRequest.request(this.baseUrl, {
        method: http.RequestMethod.POST,
        header: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ' + this.apiKey
        },
        extraData: JSON.stringify(requestData),
        connectTimeout: 30000,
        readTimeout: 60000
      });

      if (response.responseCode === 200) {
        const result: ChatResponse = JSON.parse(response.result as string);
        if (result.choices && result.choices.length > 0) {
          return result.choices[0].message.content;
        }
        throw new Error('API 返回数据格式错误');
      } else {
        throw new Error('API 请求失败: ' + response.responseCode);
      }
    } finally {
      httpRequest.destroy();
    }
  }

  async classifyDocument(content: string): Promise<ClassificationResult> {
    const prompt = `请分析以下文档内容，判断其属于哪个类别：会议纪要、学习笔记、项目报告、其他。
只返回JSON格式，不要其他内容：{"category": "类别名", "confidence": 0.95}

文档内容：
${content.substring(0, 2000)}`;

    try {
      const response = await this.callApi(prompt);
      const jsonMatch = response.match(/\{[\s\S]*\}/);
      if (jsonMatch) {
        return JSON.parse(jsonMatch[0]) as ClassificationResult;
      }
      return { category: '其他', confidence: 0.5 };
    } catch (error) {
      console.error('分类失败:', error);
      return { category: '其他', confidence: 0 };
    }
  }

  async generateSummary(content: string): Promise<SummaryResult> {
    const prompt = `请为以下文档生成100字以内的中文摘要，突出核心要点：

${content.substring(0, 3000)}`;

    try {
      const response = await this.callApi(prompt);
      return { summary: response.trim() };
    } catch (error) {
      console.error('摘要生成失败:', error);
      return { summary: '摘要生成失败' };
    }
  }

  async extractKeywords(content: string): Promise<KeywordsResult> {
    const prompt = `提取以下文档的5个核心关键词，只返回JSON数组格式，不要其他内容：["关键词1", "关键词2", ...]

文档内容：
${content.substring(0, 2000)}`;

    try {
      const response = await this.callApi(prompt);
      const jsonMatch = response.match(/\[[\s\S]*\]/);
      if (jsonMatch) {
        return { keywords: JSON.parse(jsonMatch[0]) as string[] };
      }
      return { keywords: [] };
    } catch (error) {
      console.error('关键词提取失败:', error);
      return { keywords: [] };
    }
  }

  async analyzeRelations(docName: string, docKeywords: string[], allDocsKeywords: Map<string, string[]>): Promise<RelationResult> {
    let otherDocs = '';
    allDocsKeywords.forEach((keywords, name) => {
      if (name !== docName) {
        otherDocs += `${name}: ${keywords.join(', ')}\n`;
      }
    });

    if (otherDocs === '') {
      return { relatedDocs: [], reason: '没有其他文档可供比较' };
    }

    const prompt = `当前文档"${docName}"的关键词：${docKeywords.join(', ')}

其他文档及其关键词：
${otherDocs}

请找出与当前文档最相关的文档（最多3个），返回JSON格式：
{"relatedDocs": ["文档名1", "文档名2"], "reason": "关联原因简述"}`;

    try {
      const response = await this.callApi(prompt);
      const jsonMatch = response.match(/\{[\s\S]*\}/);
      if (jsonMatch) {
        return JSON.parse(jsonMatch[0]) as RelationResult;
      }
      return { relatedDocs: [], reason: '分析失败' };
    } catch (error) {
      console.error('关联分析失败:', error);
      return { relatedDocs: [], reason: '分析失败' };
    }
  }
}

const deepSeekService = new DeepSeekService();
export default deepSeekService;

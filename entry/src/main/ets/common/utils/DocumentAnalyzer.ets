/*
 * 文档分析器 - 整合分类、摘要、关键词、关联分析
 */

import { DocumentParser, ParsedDocument } from './DocumentParser';
import { AnalysisCache, DocumentAnalysis } from './AnalysisCache';
import deepSeekService from './DeepSeekService';

export interface AnalysisProgress {
  total: number;
  current: number;
  currentFile: string;
  stage: string;
}

interface WordCount {
  word: string;
  count: number;
}

export type ProgressCallback = (progress: AnalysisProgress) => void;

export class DocumentAnalyzer {
  private parser: DocumentParser;
  private cache: AnalysisCache;
  private filesDir: string;

  constructor(filesDir: string) {
    this.filesDir = filesDir;
    this.parser = new DocumentParser(filesDir);
    this.cache = new AnalysisCache(filesDir);
  }

  async init(): Promise<void> {
    await this.cache.load();
  }

  async analyzeDocument(filename: string, forceRefresh: boolean = false): Promise<DocumentAnalysis | null> {
    // 解析文档
    const parsed = await this.parser.parseDocument(filename);
    if (!parsed.parseSuccess) {
      console.error('文档解析失败:', parsed.errorMsg);
      return null;
    }

    const contentHash = this.cache.simpleHash(parsed.content);

    // 检查缓存
    if (!forceRefresh && !this.cache.needsUpdate(filename, contentHash)) {
      return this.cache.get(filename);
    }

    // 检查 API 是否配置
    if (!deepSeekService.isConfigured()) {
      // 返回基础分析结果（无 API）
      const basicAnalysis: DocumentAnalysis = {
        filename: filename,
        category: '未分类',
        confidence: 0,
        summary: parsed.content.substring(0, 100) + '...',
        keywords: this.extractBasicKeywords(parsed.content),
        relatedDocs: [],
        relatedReason: '',
        analyzedAt: Date.now(),
        contentHash: contentHash
      };
      this.cache.set(basicAnalysis);
      await this.cache.save();
      return basicAnalysis;
    }

    // 调用 API 分析
    const classification = await deepSeekService.classifyDocument(parsed.content);
    const summaryResult = await deepSeekService.generateSummary(parsed.content);
    const keywordsResult = await deepSeekService.extractKeywords(parsed.content);

    const analysis: DocumentAnalysis = {
      filename: filename,
      category: classification.category,
      confidence: classification.confidence,
      summary: summaryResult.summary,
      keywords: keywordsResult.keywords,
      relatedDocs: [],
      relatedReason: '',
      analyzedAt: Date.now(),
      contentHash: contentHash
    };

    this.cache.set(analysis);
    await this.cache.save();

    return analysis;
  }

  async analyzeAllDocuments(filenames: string[], onProgress?: ProgressCallback): Promise<DocumentAnalysis[]> {
    await this.init();
    const results: DocumentAnalysis[] = [];

    for (let i = 0; i < filenames.length; i++) {
      const filename = filenames[i];

      if (onProgress) {
        onProgress({
          total: filenames.length,
          current: i + 1,
          currentFile: filename,
          stage: '分析中'
        });
      }

      const analysis = await this.analyzeDocument(filename);
      if (analysis) {
        results.push(analysis);
      }
    }

    // 分析关联关系
    if (deepSeekService.isConfigured() && results.length > 1) {
      if (onProgress) {
        onProgress({
          total: filenames.length,
          current: filenames.length,
          currentFile: '',
          stage: '分析关联'
        });
      }
      await this.analyzeRelations(results);
    }

    return results;
  }

  private async analyzeRelations(analyses: DocumentAnalysis[]): Promise<void> {
    const allKeywords = this.cache.getAllKeywords();

    for (let i = 0; i < analyses.length; i++) {
      const analysis = analyses[i];
      if (analysis.keywords.length > 0) {
        const relation = await deepSeekService.analyzeRelations(
          analysis.filename,
          analysis.keywords,
          allKeywords
        );
        analysis.relatedDocs = relation.relatedDocs;
        analysis.relatedReason = relation.reason;
        this.cache.set(analysis);
      }
    }

    await this.cache.save();
  }

  private extractBasicKeywords(content: string): string[] {
    // 简单的关键词提取（无 API 时使用）
    const words = content.split(/[\s，。！？、；：""''（）\[\]【】\n\r]+/);
    const wordCount = new Map<string, number>();

    for (let i = 0; i < words.length; i++) {
      const word = words[i].trim();
      if (word.length >= 2 && word.length <= 10) {
        const count = wordCount.get(word) || 0;
        wordCount.set(word, count + 1);
      }
    }

    // 按频率排序取前5个
    const sorted: WordCount[] = [];
    wordCount.forEach((count, word) => {
      const item: WordCount = { word: word, count: count };
      sorted.push(item);
    });
    sorted.sort((a, b) => b.count - a.count);

    const result: string[] = [];
    for (let i = 0; i < Math.min(5, sorted.length); i++) {
      result.push(sorted[i].word);
    }
    return result;
  }

  getCache(): AnalysisCache {
    return this.cache;
  }

  getCachedAnalysis(filename: string): DocumentAnalysis | null {
    return this.cache.get(filename);
  }

  getAllCachedAnalyses(): DocumentAnalysis[] {
    return this.cache.getAll();
  }

  getByCategory(category: string): DocumentAnalysis[] {
    return this.cache.getByCategory(category);
  }

  getAllCategories(): string[] {
    return this.cache.getAllCategories();
  }

  cleanupCache(existingFiles: string[]): void {
    this.cache.cleanupStaleEntries(existingFiles);
    this.cache.save();
  }
}

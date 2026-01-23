/*
 * 搜索索引 - 支持关键词全文检索
 */

import fs from '@ohos.file.fs';
import { DocumentParser } from './DocumentParser';
import { AnalysisCache } from './AnalysisCache';

export interface SearchResult {
  filename: string;
  score: number;
  matchedKeywords: string[];
  snippet: string;
  category: string;
}

interface IndexEntry {
  filename: string;
  keywords: string[];
  content: string;
}

interface InvertedIndexItem {
  keyword: string;
  files: string[];
}

interface IndexData {
  version: number;
  entries: IndexEntry[];
  invertedIndexArray: InvertedIndexItem[];
  buildTime: number;
}

export class SearchIndex {
  private filesDir: string;
  private indexFile: string;
  private parser: DocumentParser;
  private cache: AnalysisCache;
  private invertedIndex: Map<string, string[]> = new Map();
  private contentMap: Map<string, string> = new Map();
  private loaded: boolean = false;

  constructor(filesDir: string) {
    this.filesDir = filesDir;
    this.indexFile = filesDir + '/.search_index.json';
    this.parser = new DocumentParser(filesDir);
    this.cache = new AnalysisCache(filesDir);
  }

  async load(): Promise<void> {
    if (this.loaded) {
      return;
    }

    try {
      await this.cache.load();

      const exists = await this.fileExists(this.indexFile);
      if (!exists) {
        this.loaded = true;
        return;
      }

      const file = await fs.open(this.indexFile, fs.OpenMode.READ_ONLY);
      const stat = await fs.stat(this.indexFile);
      const buffer = new ArrayBuffer(stat.size);
      await fs.read(file.fd, buffer);
      await fs.close(file);

      const content = this.arrayBufferToString(buffer);
      const data: IndexData = JSON.parse(content);

      // 重建内存索引
      this.invertedIndex.clear();
      this.contentMap.clear();

      for (let i = 0; i < data.entries.length; i++) {
        const entry = data.entries[i];
        this.contentMap.set(entry.filename, entry.content);
      }

      // 从数组格式恢复倒排索引
      if (data.invertedIndexArray) {
        for (let i = 0; i < data.invertedIndexArray.length; i++) {
          const item = data.invertedIndexArray[i];
          this.invertedIndex.set(item.keyword, item.files);
        }
      }

      this.loaded = true;
    } catch (error) {
      console.error('加载索引失败:', error);
      this.loaded = true;
    }
  }

  async save(): Promise<void> {
    try {
      const entries: IndexEntry[] = [];
      this.contentMap.forEach((content, filename) => {
        const analysis = this.cache.get(filename);
        const entry: IndexEntry = {
          filename: filename,
          keywords: analysis ? analysis.keywords : [],
          content: content
        };
        entries.push(entry);
      });

      // 将Map转换为数组格式以便JSON序列化
      const invertedIndexArray: InvertedIndexItem[] = [];
      this.invertedIndex.forEach((files, keyword) => {
        const item: InvertedIndexItem = {
          keyword: keyword,
          files: files
        };
        invertedIndexArray.push(item);
      });

      const data: IndexData = {
        version: 1,
        entries: entries,
        invertedIndexArray: invertedIndexArray,
        buildTime: Date.now()
      };

      const content = JSON.stringify(data);
      const file = await fs.open(this.indexFile, fs.OpenMode.CREATE | fs.OpenMode.WRITE_ONLY | fs.OpenMode.TRUNC);
      await fs.write(file.fd, content);
      await fs.close(file);
    } catch (error) {
      console.error('保存索引失败:', error);
    }
  }

  async buildIndex(filenames: string[]): Promise<void> {
    await this.load();

    console.log('SearchIndex: 开始构建索引, 文件数:', filenames.length);

    // 清空旧索引，重新构建
    this.invertedIndex.clear();
    this.contentMap.clear();

    for (let i = 0; i < filenames.length; i++) {
      const filename = filenames[i];
      await this.indexDocument(filename);
    }

    console.log('SearchIndex: 索引构建完成, 索引词数:', this.invertedIndex.size, '文档数:', this.contentMap.size);

    await this.save();
  }

  async indexDocument(filename: string): Promise<void> {
    const parsed = await this.parser.parseDocument(filename);
    if (!parsed.parseSuccess) {
      console.log('SearchIndex: 解析失败:', filename, parsed.errorMsg);
      return;
    }

    // 存储内容
    this.contentMap.set(filename, parsed.content);
    console.log('SearchIndex: 索引文档:', filename, '内容长度:', parsed.content.length);

    // 提取词汇并建立倒排索引
    const words = this.tokenize(parsed.content);
    for (let i = 0; i < words.length; i++) {
      const word = words[i];
      if (!this.invertedIndex.has(word)) {
        this.invertedIndex.set(word, []);
      }
      const files = this.invertedIndex.get(word)!;
      if (!files.includes(filename)) {
        files.push(filename);
      }
    }

    // 添加关键词到索引
    const analysis = this.cache.get(filename);
    if (analysis && analysis.keywords) {
      for (let i = 0; i < analysis.keywords.length; i++) {
        const keyword = analysis.keywords[i];
        if (!this.invertedIndex.has(keyword)) {
          this.invertedIndex.set(keyword, []);
        }
        const files = this.invertedIndex.get(keyword)!;
        if (!files.includes(filename)) {
          files.push(filename);
        }
      }
    }
  }

  search(query: string): SearchResult[] {
    const queryWords = this.tokenize(query);
    console.log('SearchIndex: 搜索查询:', query, '分词结果:', queryWords.length, '索引大小:', this.invertedIndex.size);

    if (queryWords.length === 0) {
      return [];
    }

    const scoreMap = new Map<string, number>();
    const matchedKeywordsMap = new Map<string, string[]>();

    // 计算每个文档的匹配分数
    for (let i = 0; i < queryWords.length; i++) {
      const word = queryWords[i];
      const matchingFiles = this.invertedIndex.get(word);
      if (matchingFiles) {
        for (let j = 0; j < matchingFiles.length; j++) {
          const filename = matchingFiles[j];
          const currentScore = scoreMap.get(filename) || 0;
          scoreMap.set(filename, currentScore + 1);

          if (!matchedKeywordsMap.has(filename)) {
            matchedKeywordsMap.set(filename, []);
          }
          const keywords = matchedKeywordsMap.get(filename)!;
          if (!keywords.includes(word)) {
            keywords.push(word);
          }
        }
      }
    }

    // 构建结果
    const results: SearchResult[] = [];
    scoreMap.forEach((score, filename) => {
      const content = this.contentMap.get(filename) || '';
      const analysis = this.cache.get(filename);
      const matchedKeywords = matchedKeywordsMap.get(filename) || [];

      results.push({
        filename: filename,
        score: score / queryWords.length,
        matchedKeywords: matchedKeywords,
        snippet: this.generateSnippet(content, queryWords),
        category: analysis ? analysis.category : '未分类'
      });
    });

    // 按分数排序
    results.sort((a, b) => b.score - a.score);

    return results;
  }

  private tokenize(text: string): string[] {
    // 简单分词：按标点和空格分割，过滤短词
    const words = text.toLowerCase().split(/[\s，。！？、；：""''（）\[\]【】\n\r\t,.!?;:'"()\[\]]+/);
    const result: string[] = [];

    for (let i = 0; i < words.length; i++) {
      const word = words[i].trim();
      if (word.length >= 2) {
        result.push(word);
      }
    }

    return result;
  }

  private generateSnippet(content: string, queryWords: string[]): string {
    const maxLength = 100;
    const lowerContent = content.toLowerCase();

    // 找到第一个匹配词的位置
    let firstMatchPos = -1;
    for (let i = 0; i < queryWords.length; i++) {
      const pos = lowerContent.indexOf(queryWords[i]);
      if (pos !== -1 && (firstMatchPos === -1 || pos < firstMatchPos)) {
        firstMatchPos = pos;
      }
    }

    if (firstMatchPos === -1) {
      return content.substring(0, maxLength) + (content.length > maxLength ? '...' : '');
    }

    // 从匹配位置前后截取
    const start = Math.max(0, firstMatchPos - 20);
    const end = Math.min(content.length, start + maxLength);
    let snippet = content.substring(start, end);

    if (start > 0) {
      snippet = '...' + snippet;
    }
    if (end < content.length) {
      snippet = snippet + '...';
    }

    return snippet;
  }

  removeDocument(filename: string): void {
    this.contentMap.delete(filename);

    // 从倒排索引中移除
    this.invertedIndex.forEach((files, keyword) => {
      const index = files.indexOf(filename);
      if (index !== -1) {
        files.splice(index, 1);
      }
    });
  }

  clear(): void {
    this.invertedIndex.clear();
    this.contentMap.clear();
  }

  private async fileExists(path: string): Promise<boolean> {
    try {
      await fs.access(path);
      return true;
    } catch {
      return false;
    }
  }

  private arrayBufferToString(buffer: ArrayBuffer): string {
    const uint8Array = new Uint8Array(buffer);
    let result = '';
    for (let i = 0; i < uint8Array.length; i++) {
      result += String.fromCharCode(uint8Array[i]);
    }
    return decodeURIComponent(escape(result));
  }
}

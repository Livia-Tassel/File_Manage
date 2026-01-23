/*
 * 分析结果缓存管理 - 避免重复调用 API
 */

import fs from '@ohos.file.fs';

export interface DocumentAnalysis {
  filename: string;
  category: string;
  confidence: number;
  summary: string;
  keywords: string[];
  relatedDocs: string[];
  relatedReason: string;
  analyzedAt: number;
  contentHash: string;
}

interface CacheData {
  version: number;
  documents: DocumentAnalysis[];
}

export class AnalysisCache {
  private filesDir: string;
  private cacheFile: string;
  private cache: Map<string, DocumentAnalysis> = new Map();
  private loaded: boolean = false;

  constructor(filesDir: string) {
    this.filesDir = filesDir;
    this.cacheFile = filesDir + '/.analysis_cache.json';
  }

  async load(): Promise<void> {
    if (this.loaded) {
      return;
    }

    try {
      const exists = await this.fileExists(this.cacheFile);
      if (!exists) {
        this.loaded = true;
        return;
      }

      const file = await fs.open(this.cacheFile, fs.OpenMode.READ_ONLY);
      const stat = await fs.stat(this.cacheFile);
      const buffer = new ArrayBuffer(stat.size);
      await fs.read(file.fd, buffer);
      await fs.close(file);

      const content = this.arrayBufferToString(buffer);
      const data: CacheData = JSON.parse(content);

      this.cache.clear();
      for (let i = 0; i < data.documents.length; i++) {
        const doc = data.documents[i];
        this.cache.set(doc.filename, doc);
      }

      this.loaded = true;
    } catch (error) {
      console.error('加载缓存失败:', error);
      this.loaded = true;
    }
  }

  async save(): Promise<void> {
    try {
      const documents: DocumentAnalysis[] = [];
      this.cache.forEach((value) => {
        documents.push(value);
      });

      const data: CacheData = {
        version: 1,
        documents: documents
      };

      const content = JSON.stringify(data, null, 2);
      const file = await fs.open(this.cacheFile, fs.OpenMode.CREATE | fs.OpenMode.WRITE_ONLY | fs.OpenMode.TRUNC);
      await fs.write(file.fd, content);
      await fs.close(file);
    } catch (error) {
      console.error('保存缓存失败:', error);
    }
  }

  get(filename: string): DocumentAnalysis | null {
    const result = this.cache.get(filename);
    if (result) {
      return result;
    }
    return null;
  }

  set(analysis: DocumentAnalysis): void {
    this.cache.set(analysis.filename, analysis);
  }

  has(filename: string): boolean {
    return this.cache.has(filename);
  }

  needsUpdate(filename: string, contentHash: string): boolean {
    const cached = this.get(filename);
    if (!cached) {
      return true;
    }
    return cached.contentHash !== contentHash;
  }

  remove(filename: string): void {
    this.cache.delete(filename);
  }

  clear(): void {
    this.cache.clear();
  }

  getAll(): DocumentAnalysis[] {
    const result: DocumentAnalysis[] = [];
    this.cache.forEach((value) => {
      result.push(value);
    });
    return result;
  }

  // 清理不存在的文件缓存
  cleanupStaleEntries(existingFiles: string[]): void {
    const toRemove: string[] = [];
    this.cache.forEach((value, key) => {
      if (!existingFiles.includes(key)) {
        toRemove.push(key);
      }
    });
    for (let i = 0; i < toRemove.length; i++) {
      this.cache.delete(toRemove[i]);
    }
  }

  getByCategory(category: string): DocumentAnalysis[] {
    const result: DocumentAnalysis[] = [];
    this.cache.forEach((value) => {
      if (value.category === category) {
        result.push(value);
      }
    });
    return result;
  }

  getAllCategories(): string[] {
    const categories: string[] = [];
    this.cache.forEach((value) => {
      if (!categories.includes(value.category)) {
        categories.push(value.category);
      }
    });
    return categories;
  }

  getAllKeywords(): Map<string, string[]> {
    const result = new Map<string, string[]>();
    this.cache.forEach((value, key) => {
      result.set(key, value.keywords);
    });
    return result;
  }

  simpleHash(content: string): string {
    let hash = 0;
    for (let i = 0; i < content.length; i++) {
      const char = content.charCodeAt(i);
      hash = ((hash << 5) - hash) + char;
      hash = hash & hash;
    }
    return hash.toString(16);
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

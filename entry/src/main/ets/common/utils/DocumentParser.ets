/*
 * 文档解析器 - 支持 txt/docx 文件解析
 */

import fs from '@ohos.file.fs';
import zlib from '@ohos.zlib';

export interface ParsedDocument {
  filename: string;
  content: string;
  fileType: string;
  size: number;
  parseSuccess: boolean;
  errorMsg: string;
}

export class DocumentParser {
  private filesDir: string;

  constructor(filesDir: string) {
    this.filesDir = filesDir;
  }

  async parseDocument(filename: string): Promise<ParsedDocument> {
    const filePath = this.filesDir + '/' + filename;
    const ext = this.getFileExtension(filename).toLowerCase();

    const result: ParsedDocument = {
      filename: filename,
      content: '',
      fileType: ext,
      size: 0,
      parseSuccess: false,
      errorMsg: ''
    };

    try {
      const stat = await fs.stat(filePath);
      result.size = stat.size;

      if (ext === 'txt') {
        result.content = await this.parseTxt(filePath);
        result.parseSuccess = true;
      } else if (ext === 'docx') {
        result.content = await this.parseDocx(filePath);
        result.parseSuccess = true;
      } else {
        result.errorMsg = '不支持的文件格式: ' + ext;
      }
    } catch (error) {
      result.errorMsg = '解析失败: ' + (error as Error).message;
    }

    return result;
  }

  private async parseTxt(filePath: string): Promise<string> {
    const file = await fs.open(filePath, fs.OpenMode.READ_ONLY);
    const stat = await fs.stat(filePath);
    const buffer = new ArrayBuffer(stat.size);
    await fs.read(file.fd, buffer);
    await fs.close(file);

    return this.arrayBufferToString(buffer);
  }

  private async parseDocx(filePath: string): Promise<string> {
    // docx 是 ZIP 格式，核心内容在 word/document.xml
    try {
      const tempDir = this.filesDir + '/.docx_temp_' + Date.now();

      // 解压 docx 文件
      await zlib.decompressFile(filePath, tempDir);

      // 读取 document.xml
      const xmlPath = tempDir + '/word/document.xml';
      const xmlContent = await this.parseTxt(xmlPath);

      // 提取纯文本
      const text = this.extractTextFromDocxXml(xmlContent);

      // 清理临时目录
      await this.cleanupDir(tempDir);

      return text;
    } catch (error) {
      console.error('docx 解析失败:', error);
      throw new Error('docx 解析失败: ' + (error as Error).message);
    }
  }

  private extractTextFromDocxXml(xml: string): string {
    // 提取 <w:t> 标签中的文本内容
    const textParts: string[] = [];
    const regex = /<w:t[^>]*>([^<]*)<\/w:t>/g;
    let match = regex.exec(xml);

    while (match !== null) {
      if (match[1]) {
        textParts.push(match[1]);
      }
      match = regex.exec(xml);
    }

    // 处理段落分隔
    let result = textParts.join('');
    result = result.replace(/<w:p[^>]*>/g, '\n');

    return result.trim();
  }

  private async cleanupDir(dirPath: string): Promise<void> {
    try {
      await fs.rmdir(dirPath);
    } catch (error) {
      console.warn('清理临时目录失败:', error);
    }
  }

  private arrayBufferToString(buffer: ArrayBuffer): string {
    const uint8Array = new Uint8Array(buffer);
    let result = '';

    // 检测 UTF-8 BOM
    let start = 0;
    if (uint8Array.length >= 3 &&
        uint8Array[0] === 0xEF &&
        uint8Array[1] === 0xBB &&
        uint8Array[2] === 0xBF) {
      start = 3;
    }

    // UTF-8 解码
    for (let i = start; i < uint8Array.length; i++) {
      const byte = uint8Array[i];
      if (byte < 0x80) {
        result += String.fromCharCode(byte);
      } else if (byte < 0xE0) {
        const byte2 = uint8Array[++i];
        result += String.fromCharCode(((byte & 0x1F) << 6) | (byte2 & 0x3F));
      } else if (byte < 0xF0) {
        const byte2 = uint8Array[++i];
        const byte3 = uint8Array[++i];
        result += String.fromCharCode(((byte & 0x0F) << 12) | ((byte2 & 0x3F) << 6) | (byte3 & 0x3F));
      }
    }

    return result;
  }

  private getFileExtension(filename: string): string {
    const lastDot = filename.lastIndexOf('.');
    if (lastDot === -1) {
      return '';
    }
    return filename.substring(lastDot + 1);
  }

  getSupportedExtensions(): string[] {
    return ['txt', 'docx'];
  }

  isSupported(filename: string): boolean {
    const ext = this.getFileExtension(filename).toLowerCase();
    return this.getSupportedExtensions().includes(ext);
  }
}

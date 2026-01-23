/*
 * 智能分析页面 - 文档分类、摘要、关联分析
 */

import { common } from '@kit.AbilityKit';
import { DocumentAnalyzer, AnalysisProgress } from '../common/utils/DocumentAnalyzer';
import { DocumentAnalysis } from '../common/utils/AnalysisCache';
import { FileManager, FileInfo } from '../common/utils/FileManager';
import deepSeekService from '../common/utils/DeepSeekService';
import fs from '@ohos.file.fs';

interface ApiConfig {
  apiKey: string;
}

@Component
export struct AnalysisTab {
  @State private documents: DocumentAnalysis[] = [];
  @State private allFiles: FileInfo[] = [];
  @State private isAnalyzing: boolean = false;
  @State private progress: AnalysisProgress = { total: 0, current: 0, currentFile: '', stage: '' };
  @State private selectedDoc: DocumentAnalysis | null = null;
  @State private apiConfigured: boolean = false;
  @StorageLink('fileChangeFlag') @Watch('onFileChange') fileChangeFlag: number = 0;
  private context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
  private analyzer: DocumentAnalyzer = new DocumentAnalyzer(this.context.filesDir);
  private fileManager: FileManager = new FileManager(this.context);

  onFileChange(): void {
    this.loadData();
  }

  aboutToAppear(): void {
    this.initPage();
  }

  async initPage(): Promise<void> {
    await this.loadApiConfig();
    await this.loadData();
  }

  async loadApiConfig(): Promise<void> {
    try {
      const configFile = this.context.filesDir + '/.api_config.json';
      try {
        await fs.access(configFile);
      } catch {
        console.log('API配置文件不存在');
        return;
      }

      const file = await fs.open(configFile, fs.OpenMode.READ_ONLY);
      const stat = await fs.stat(configFile);
      const buffer = new ArrayBuffer(stat.size);
      await fs.read(file.fd, buffer);
      await fs.close(file);

      const uint8Array = new Uint8Array(buffer);
      let content = '';
      for (let i = 0; i < uint8Array.length; i++) {
        content += String.fromCharCode(uint8Array[i]);
      }

      console.log('读取到API配置:', content);

      const config: ApiConfig = JSON.parse(content) as ApiConfig;
      if (config.apiKey && config.apiKey.length > 0) {
        deepSeekService.setApiKey(config.apiKey);
        this.apiConfigured = true;
        console.log('API配置成功');
      }
    } catch (error) {
      console.error('加载API配置失败:', error);
    }
  }

  private async fileExists(path: string): Promise<boolean> {
    try {
      await fs.access(path);
      return true;
    } catch {
      return false;
    }
  }

  async loadData(): Promise<void> {
    try {
      await this.analyzer.init();
      this.allFiles = await this.fileManager.getAllFilesWithInfo();

      // 清理不存在的文件缓存
      const existingFiles: string[] = [];
      for (let i = 0; i < this.allFiles.length; i++) {
        existingFiles.push(this.allFiles[i].filename);
      }
      this.analyzer.cleanupCache(existingFiles);

      this.documents = this.analyzer.getAllCachedAnalyses();
    } catch (error) {
      console.error('加载数据失败:', error);
    }
  }

  async startAnalysis(): Promise<void> {
    if (this.isAnalyzing) return;

    console.log('开始分析, API配置状态:', this.apiConfigured);
    console.log('DeepSeek服务配置状态:', deepSeekService.isConfigured());

    this.isAnalyzing = true;
    this.selectedDoc = null;

    try {
      const filenames: string[] = [];
      for (let i = 0; i < this.allFiles.length; i++) {
        filenames.push(this.allFiles[i].filename);
      }

      console.log('待分析文件数:', filenames.length);

      this.documents = await this.analyzer.analyzeAllDocuments(filenames, (progress: AnalysisProgress) => {
        this.progress = progress;
      });

      console.log('分析完成, 结果数:', this.documents.length);
    } catch (error) {
      console.error('分析失败:', error);
    }

    this.isAnalyzing = false;
  }

  build() {
    Column() {
      // API 状态提示
      if (!this.apiConfigured) {
        Row() {
          Text('⚠️ API 未配置，请在设置页面配置 DeepSeek API Key')
            .fontSize(12)
            .fontColor('#FF6B00')
        }
        .width('100%')
        .padding(12)
        .backgroundColor('#FFF3E0')
      }

      // 操作栏
      Row() {
        Button(this.isAnalyzing ? '分析中...' : '开始分析')
          .fontSize(14)
          .fontColor(Color.White)
          .backgroundColor(this.isAnalyzing ? '#CCCCCC' : '#007AFF')
          .borderRadius(8)
          .height(36)
          .padding({ left: 16, right: 16 })
          .enabled(!this.isAnalyzing)
          .onClick(() => {
            this.startAnalysis();
          })

        Text('已分析 ' + this.documents.length + '/' + this.allFiles.length + ' 个文档')
          .fontSize(14)
          .fontColor('#666666')
          .margin({ left: 12 })
      }
      .width('100%')
      .padding(16)
      .justifyContent(FlexAlign.Start)

      // 进度条
      if (this.isAnalyzing) {
        Column() {
          Progress({ value: this.progress.current, total: this.progress.total, type: ProgressType.Linear })
            .width('100%')
            .height(4)
          Text(this.progress.stage + ': ' + this.progress.currentFile)
            .fontSize(12)
            .fontColor('#999999')
            .margin({ top: 4 })
        }
        .width('100%')
        .padding({ left: 16, right: 16 })
      }

      // 主内容区
      Row() {
        // 左侧文档列表
        Column() {
          Text('文档列表')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .fontColor('#333333')
            .margin({ bottom: 8 })

          List() {
            ForEach(this.documents, (doc: DocumentAnalysis) => {
              ListItem() {
                this.DocListItem(doc)
              }
              .onClick(() => {
                this.selectedDoc = doc;
              })
            })
          }
          .width('100%')
          .layoutWeight(1)
          .divider({ strokeWidth: 1, color: '#F0F0F0' })
        }
        .width('40%')
        .height('100%')
        .padding(12)
        .backgroundColor('#FAFAFA')

        // 右侧详情
        Column() {
          if (this.selectedDoc) {
            this.DocDetail(this.selectedDoc)
          } else {
            Column() {
              Text('选择文档查看分析结果')
                .fontSize(14)
                .fontColor('#999999')
            }
            .width('100%')
            .height('100%')
            .justifyContent(FlexAlign.Center)
          }
        }
        .width('60%')
        .height('100%')
        .padding(12)
      }
      .width('100%')
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  DocListItem(doc: DocumentAnalysis) {
    Column() {
      Text(doc.filename)
        .fontSize(14)
        .fontColor(this.selectedDoc && this.selectedDoc.filename === doc.filename ? '#007AFF' : '#333333')
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      Row() {
        Text(doc.category)
          .fontSize(10)
          .fontColor('#007AFF')
          .backgroundColor('#E8F4FD')
          .borderRadius(4)
          .padding({ left: 4, right: 4, top: 2, bottom: 2 })

        if (doc.confidence > 0) {
          Text((doc.confidence * 100).toFixed(0) + '%')
            .fontSize(10)
            .fontColor('#999999')
            .margin({ left: 4 })
        }
      }
      .margin({ top: 4 })
    }
    .width('100%')
    .padding({ top: 8, bottom: 8 })
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  DocDetail(doc: DocumentAnalysis) {
    Scroll() {
      Column() {
        // 文件名
        Text(doc.filename)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')

        // 分类
        Row() {
          Text('分类: ')
            .fontSize(14)
            .fontColor('#666666')
          Text(doc.category)
            .fontSize(14)
            .fontColor('#007AFF')
            .fontWeight(FontWeight.Bold)
          if (doc.confidence > 0) {
            Text(' (' + (doc.confidence * 100).toFixed(0) + '%)')
              .fontSize(12)
              .fontColor('#999999')
          }
        }
        .margin({ top: 12 })

        // 摘要
        Column() {
          Text('摘要')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .fontColor('#333333')
          Text(doc.summary)
            .fontSize(14)
            .fontColor('#666666')
            .margin({ top: 4 })
        }
        .width('100%')
        .margin({ top: 16 })
        .padding(12)
        .backgroundColor('#F5F5F5')
        .borderRadius(8)
        .alignItems(HorizontalAlign.Start)

        // 关键词
        Column() {
          Text('关键词')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .fontColor('#333333')
          Flex({ wrap: FlexWrap.Wrap }) {
            ForEach(doc.keywords, (keyword: string) => {
              Text(keyword)
                .fontSize(12)
                .fontColor('#007AFF')
                .backgroundColor('#E8F4FD')
                .borderRadius(12)
                .padding({ left: 8, right: 8, top: 4, bottom: 4 })
                .margin({ right: 8, top: 4 })
            })
          }
          .margin({ top: 4 })
        }
        .width('100%')
        .margin({ top: 16 })
        .alignItems(HorizontalAlign.Start)

        // 相关文档
        if (doc.relatedDocs && doc.relatedDocs.length > 0) {
          Column() {
            Text('相关文档')
              .fontSize(14)
              .fontWeight(FontWeight.Bold)
              .fontColor('#333333')

            ForEach(doc.relatedDocs, (relatedDoc: string) => {
              Text('• ' + relatedDoc)
                .fontSize(14)
                .fontColor('#666666')
                .margin({ top: 4 })
            })

            if (doc.relatedReason) {
              Text('关联原因: ' + doc.relatedReason)
                .fontSize(12)
                .fontColor('#999999')
                .margin({ top: 8 })
            }
          }
          .width('100%')
          .margin({ top: 16 })
          .padding(12)
          .backgroundColor('#F0FFF0')
          .borderRadius(8)
          .alignItems(HorizontalAlign.Start)
        }
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height('100%')
  }
}

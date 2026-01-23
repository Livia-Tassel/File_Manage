/*
 * 文档库页面 - 按分类展示文档
 */

import { common } from '@kit.AbilityKit';
import { DocumentAnalyzer } from '../common/utils/DocumentAnalyzer';
import { DocumentAnalysis } from '../common/utils/AnalysisCache';
import { FileManager, FileInfo } from '../common/utils/FileManager';

@Component
export struct DocumentLibraryTab {
  @State private categories: string[] = ['全部', '会议纪要', '学习笔记', '项目报告', '其他', '未分类'];
  @State private selectedCategory: string = '全部';
  @State private documents: DocumentAnalysis[] = [];
  @State private allFiles: FileInfo[] = [];
  @State private isLoading: boolean = false;
  @StorageLink('fileChangeFlag') @Watch('onFileChange') fileChangeFlag: number = 0;
  private context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
  private analyzer: DocumentAnalyzer = new DocumentAnalyzer(this.context.filesDir);
  private fileManager: FileManager = new FileManager(this.context);

  onFileChange(): void {
    this.loadDocuments();
  }

  aboutToAppear(): void {
    this.loadDocuments();
  }

  async loadDocuments(): Promise<void> {
    this.isLoading = true;
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
      console.error('加载文档失败:', error);
    }
    this.isLoading = false;
  }

  getFilteredDocuments(): FileInfo[] {
    if (this.selectedCategory === '全部') {
      return this.allFiles;
    }

    const analyzedFiles: string[] = [];
    for (let i = 0; i < this.documents.length; i++) {
      if (this.documents[i].category === this.selectedCategory) {
        analyzedFiles.push(this.documents[i].filename);
      }
    }

    if (this.selectedCategory === '未分类') {
      const analyzedSet: string[] = [];
      for (let i = 0; i < this.documents.length; i++) {
        analyzedSet.push(this.documents[i].filename);
      }
      return this.allFiles.filter(f => !analyzedSet.includes(f.filename));
    }

    return this.allFiles.filter(f => analyzedFiles.includes(f.filename));
  }

  getDocumentAnalysis(filename: string): DocumentAnalysis | null {
    for (let i = 0; i < this.documents.length; i++) {
      if (this.documents[i].filename === filename) {
        return this.documents[i];
      }
    }
    return null;
  }

  getCategoryCount(category: string): number {
    if (category === '全部') {
      return this.allFiles.length;
    }
    if (category === '未分类') {
      const analyzedSet: string[] = [];
      for (let i = 0; i < this.documents.length; i++) {
        analyzedSet.push(this.documents[i].filename);
      }
      return this.allFiles.filter(f => !analyzedSet.includes(f.filename)).length;
    }
    let count = 0;
    for (let i = 0; i < this.documents.length; i++) {
      if (this.documents[i].category === category) {
        count++;
      }
    }
    return count;
  }

  build() {
    Column() {
      // 分类选择器
      Scroll() {
        Row() {
          ForEach(this.categories, (category: string) => {
            Button(category + ' (' + this.getCategoryCount(category) + ')')
              .fontSize(14)
              .fontColor(this.selectedCategory === category ? Color.White : '#333333')
              .backgroundColor(this.selectedCategory === category ? '#007AFF' : '#F0F0F0')
              .borderRadius(16)
              .height(32)
              .padding({ left: 12, right: 12 })
              .margin({ right: 8 })
              .onClick(() => {
                this.selectedCategory = category;
              })
          })
        }
        .padding({ left: 16, right: 16 })
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .width('100%')
      .height(48)

      // 文档列表
      if (this.isLoading) {
        Column() {
          LoadingProgress()
            .width(40)
            .height(40)
          Text('加载中...')
            .fontSize(14)
            .fontColor('#999999')
            .margin({ top: 8 })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        List() {
          ForEach(this.getFilteredDocuments(), (file: FileInfo) => {
            ListItem() {
              this.DocumentItem(file)
            }
          })
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ left: 16, right: 16 })
        .divider({ strokeWidth: 1, color: '#F0F0F0' })
      }

      if (!this.isLoading && this.getFilteredDocuments().length === 0) {
        Column() {
          Text('暂无文档')
            .fontSize(16)
            .fontColor('#999999')
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  DocumentItem(file: FileInfo) {
    Column() {
      Row() {
        Column() {
          Text(file.filename)
            .fontSize(16)
            .fontColor('#333333')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          Row() {
            Text(file.sizeReadable)
              .fontSize(12)
              .fontColor('#999999')
            Text(' | ')
              .fontSize(12)
              .fontColor('#CCCCCC')
            Text(file.mtimeFormatted)
              .fontSize(12)
              .fontColor('#999999')
          }
          .margin({ top: 4 })

          // 显示分类标签
          Row() {
            if (this.getDocumentAnalysis(file.filename)) {
              Text(this.getDocumentAnalysis(file.filename)!.category)
                .fontSize(10)
                .fontColor('#007AFF')
                .backgroundColor('#E8F4FD')
                .borderRadius(4)
                .padding({ left: 6, right: 6, top: 2, bottom: 2 })
            }
          }
          .margin({ top: 4 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Image($r('sys.media.ohos_ic_public_arrow_right'))
          .width(20)
          .height(20)
          .fillColor('#CCCCCC')
      }
      .width('100%')
      .padding({ top: 12, bottom: 12 })
    }
  }
}

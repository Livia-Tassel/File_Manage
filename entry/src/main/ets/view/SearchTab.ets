/*
 * 搜索页面 - 关键词全文检索
 */

import { common } from '@kit.AbilityKit';
import { SearchIndex, SearchResult } from '../common/utils/SearchIndex';
import { FileManager, FileInfo } from '../common/utils/FileManager';

@Component
export struct SearchTab {
  @State private searchQuery: string = '';
  @State private searchResults: SearchResult[] = [];
  @State private isSearching: boolean = false;
  @State private isIndexBuilding: boolean = false;
  @State private hasSearched: boolean = false;
  @State private indexedCount: number = 0;
  @StorageLink('fileChangeFlag') @Watch('onFileChange') fileChangeFlag: number = 0;
  private context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
  private searchIndex: SearchIndex = new SearchIndex(this.context.filesDir);
  private fileManager: FileManager = new FileManager(this.context);

  onFileChange(): void {
    this.initIndex();
  }

  aboutToAppear(): void {
    this.initIndex();
  }

  async initIndex(): Promise<void> {
    this.isIndexBuilding = true;
    try {
      await this.searchIndex.load();
      const files = await this.fileManager.getAllFilesWithInfo();
      const filenames: string[] = [];
      for (let i = 0; i < files.length; i++) {
        filenames.push(files[i].filename);
      }
      console.log('SearchTab: 准备索引文件数:', filenames.length);
      await this.searchIndex.buildIndex(filenames);
      this.indexedCount = filenames.length;
    } catch (error) {
      console.error('初始化索引失败:', error);
    }
    this.isIndexBuilding = false;
  }

  doSearch(): void {
    if (!this.searchQuery.trim()) {
      this.searchResults = [];
      this.hasSearched = false;
      return;
    }

    this.isSearching = true;
    this.hasSearched = true;

    try {
      this.searchResults = this.searchIndex.search(this.searchQuery);
    } catch (error) {
      console.error('搜索失败:', error);
      this.searchResults = [];
    }

    this.isSearching = false;
  }

  build() {
    Column() {
      // 搜索框
      Row() {
        TextInput({ placeholder: '输入关键词搜索文档...', text: this.searchQuery })
          .fontSize(14)
          .height(40)
          .layoutWeight(1)
          .backgroundColor('#F5F5F5')
          .borderRadius(8)
          .padding({ left: 12, right: 12 })
          .onChange((value: string) => {
            this.searchQuery = value;
          })
          .onSubmit(() => {
            this.doSearch();
          })

        Button('搜索')
          .fontSize(14)
          .fontColor(Color.White)
          .backgroundColor('#007AFF')
          .borderRadius(8)
          .height(40)
          .padding({ left: 16, right: 16 })
          .margin({ left: 8 })
          .onClick(() => {
            this.doSearch();
          })
      }
      .width('100%')
      .padding(16)

      // 索引状态
      Row() {
        if (this.isIndexBuilding) {
          LoadingProgress()
            .width(16)
            .height(16)
          Text('正在构建索引...')
            .fontSize(12)
            .fontColor('#999999')
            .margin({ left: 8 })
        } else {
          Text('已索引 ' + this.indexedCount + ' 个文档')
            .fontSize(12)
            .fontColor(this.indexedCount > 0 ? '#4CAF50' : '#999999')

          Button('刷新')
            .fontSize(12)
            .fontColor('#007AFF')
            .backgroundColor(Color.Transparent)
            .height(28)
            .margin({ left: 8 })
            .onClick(() => {
              this.initIndex();
            })
        }
      }
      .width('100%')
      .padding({ left: 16, right: 16 })

      // 搜索结果
      if (this.isSearching) {
        Column() {
          LoadingProgress()
            .width(40)
            .height(40)
          Text('搜索中...')
            .fontSize(14)
            .fontColor('#999999')
            .margin({ top: 8 })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else if (this.hasSearched && this.searchResults.length === 0) {
        Column() {
          Text('未找到匹配结果')
            .fontSize(16)
            .fontColor('#999999')
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else if (this.searchResults.length > 0) {
        Column() {
          Text('找到 ' + this.searchResults.length + ' 个结果')
            .fontSize(12)
            .fontColor('#999999')
            .padding({ left: 16, bottom: 8 })
            .width('100%')

          List() {
            ForEach(this.searchResults, (result: SearchResult, index: number) => {
              ListItem() {
                this.SearchResultItem(result)
              }
            }, (result: SearchResult) => result.filename)
          }
          .width('100%')
          .layoutWeight(1)
          .padding({ left: 16, right: 16 })
          .divider({ strokeWidth: 1, color: '#F0F0F0' })
        }
        .width('100%')
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
      } else {
        Column() {
          Text('输入关键词开始搜索')
            .fontSize(14)
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
  SearchResultItem(result: SearchResult) {
    Column() {
      Row() {
        Text(result.filename)
          .fontSize(16)
          .fontColor('#333333')
          .fontWeight(FontWeight.Medium)
          .layoutWeight(1)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text((result.score * 100).toFixed(0) + '%')
          .fontSize(12)
          .fontColor('#007AFF')
          .backgroundColor('#E8F4FD')
          .borderRadius(4)
          .padding({ left: 6, right: 6, top: 2, bottom: 2 })
      }
      .width('100%')

      // 分类标签
      Row() {
        Text(result.category)
          .fontSize(10)
          .fontColor('#666666')
          .backgroundColor('#F0F0F0')
          .borderRadius(4)
          .padding({ left: 4, right: 4, top: 2, bottom: 2 })
      }
      .margin({ top: 4 })

      // 匹配关键词
      if (result.matchedKeywords.length > 0) {
        Flex({ wrap: FlexWrap.Wrap }) {
          Text('匹配: ')
            .fontSize(12)
            .fontColor('#999999')
          ForEach(result.matchedKeywords, (keyword: string) => {
            Text(keyword)
              .fontSize(12)
              .fontColor('#FF6B00')
              .margin({ right: 8 })
          })
        }
        .margin({ top: 4 })
      }

      // 摘要片段
      Text(result.snippet)
        .fontSize(13)
        .fontColor('#666666')
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .margin({ top: 4 })
    }
    .width('100%')
    .padding({ top: 12, bottom: 12 })
    .alignItems(HorizontalAlign.Start)
  }
}

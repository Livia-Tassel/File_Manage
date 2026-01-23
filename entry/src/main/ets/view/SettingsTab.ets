/*
 * 设置页面 - API Key 配置
 */

import { common } from '@kit.AbilityKit';
import deepSeekService from '../common/utils/DeepSeekService';
import fs from '@ohos.file.fs';

interface ApiConfig {
  apiKey: string;
}

@Component
export struct SettingsTab {
  @State private apiKey: string = '';
  @State private isConfigured: boolean = false;
  @State private showKey: boolean = false;
  @State private saveMessage: string = '';
  private context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
  private configFile: string = '';

  aboutToAppear(): void {
    this.configFile = this.context.filesDir + '/.api_config.json';
    this.loadConfig();
  }

  async loadConfig(): Promise<void> {
    try {
      const exists = await this.fileExists(this.configFile);
      if (exists) {
        const file = await fs.open(this.configFile, fs.OpenMode.READ_ONLY);
        const stat = await fs.stat(this.configFile);
        const buffer = new ArrayBuffer(stat.size);
        await fs.read(file.fd, buffer);
        await fs.close(file);

        const content = this.arrayBufferToString(buffer);
        const config: ApiConfig = JSON.parse(content) as ApiConfig;
        if (config.apiKey) {
          this.apiKey = config.apiKey;
          deepSeekService.setApiKey(config.apiKey);
          this.isConfigured = true;
        }
      }
    } catch (error) {
      console.error('加载配置失败:', error);
    }
  }

  async saveConfig(): Promise<void> {
    try {
      const config: ApiConfig = { apiKey: this.apiKey };
      const content = JSON.stringify(config);
      const file = await fs.open(this.configFile, fs.OpenMode.CREATE | fs.OpenMode.WRITE_ONLY | fs.OpenMode.TRUNC);
      await fs.write(file.fd, content);
      await fs.close(file);

      deepSeekService.setApiKey(this.apiKey);
      this.isConfigured = this.apiKey.length > 0;
      this.saveMessage = '保存成功';

      setTimeout(() => {
        this.saveMessage = '';
      }, 2000);
    } catch (error) {
      console.error('保存配置失败:', error);
      this.saveMessage = '保存失败';
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

  private arrayBufferToString(buffer: ArrayBuffer): string {
    const uint8Array = new Uint8Array(buffer);
    let result = '';
    for (let i = 0; i < uint8Array.length; i++) {
      result += String.fromCharCode(uint8Array[i]);
    }
    return result;
  }

  getMaskedKey(): string {
    if (!this.apiKey) return '';
    if (this.apiKey.length <= 8) return '****';
    return this.apiKey.substring(0, 4) + '****' + this.apiKey.substring(this.apiKey.length - 4);
  }

  build() {
    Scroll() {
      Column() {
        // 标题
        Text('设置')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .width('100%')
          .padding({ left: 16, top: 16, bottom: 16 })

        // API 配置卡片
        Column() {
          Text('DeepSeek API 配置')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#333333')
            .width('100%')

          // 状态指示
          Row() {
            Circle()
              .width(8)
              .height(8)
              .fill(this.isConfigured ? '#4CAF50' : '#FF5722')
            Text(this.isConfigured ? 'API 已配置' : 'API 未配置')
              .fontSize(14)
              .fontColor(this.isConfigured ? '#4CAF50' : '#FF5722')
              .margin({ left: 8 })
          }
          .margin({ top: 12 })

          // API Key 输入
          Column() {
            Text('API Key')
              .fontSize(14)
              .fontColor('#666666')
              .width('100%')

            Row() {
              TextInput({
                placeholder: '请输入 DeepSeek API Key',
                text: this.apiKey
              })
                .fontSize(14)
                .height(44)
                .layoutWeight(1)
                .backgroundColor('#F5F5F5')
                .borderRadius(8)
                .padding({ left: 12, right: 12 })
                .type(this.showKey ? InputType.Normal : InputType.Password)
                .onChange((value: string) => {
                  this.apiKey = value;
                })

              Button(this.showKey ? '隐藏' : '显示')
                .fontSize(12)
                .fontColor('#007AFF')
                .backgroundColor(Color.Transparent)
                .height(44)
                .onClick(() => {
                  this.showKey = !this.showKey;
                })
            }
            .margin({ top: 8 })
          }
          .margin({ top: 16 })
          .width('100%')

          // 保存按钮
          Button('保存 API Key')
            .fontSize(14)
            .fontColor(Color.White)
            .backgroundColor('#007AFF')
            .borderRadius(8)
            .height(44)
            .width('100%')
            .margin({ top: 16 })
            .onClick(() => {
              this.saveConfig();
            })

          // 保存提示
          if (this.saveMessage) {
            Text(this.saveMessage)
              .fontSize(14)
              .fontColor(this.saveMessage === '保存成功' ? '#4CAF50' : '#FF5722')
              .margin({ top: 8 })
          }
        }
        .width('100%')
        .padding(16)
        .margin({ left: 16, right: 16, top: 8 })
        .backgroundColor(Color.White)
        .borderRadius(12)

        // 说明卡片
        Column() {
          Text('使用说明')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#333333')
            .width('100%')

          Text('1. 访问 DeepSeek 官网获取 API Key')
            .fontSize(14)
            .fontColor('#666666')
            .margin({ top: 12 })
            .width('100%')

          Text('2. 将 API Key 粘贴到上方输入框')
            .fontSize(14)
            .fontColor('#666666')
            .margin({ top: 8 })
            .width('100%')

          Text('3. 点击保存后即可使用智能分析功能')
            .fontSize(14)
            .fontColor('#666666')
            .margin({ top: 8 })
            .width('100%')

          Text('4. API Key 仅存储在本地，不会上传')
            .fontSize(14)
            .fontColor('#666666')
            .margin({ top: 8 })
            .width('100%')
        }
        .width('100%')
        .padding(16)
        .margin({ left: 16, right: 16, top: 16 })
        .backgroundColor(Color.White)
        .borderRadius(12)
        .alignItems(HorizontalAlign.Start)

        // 功能说明
        Column() {
          Text('功能介绍')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#333333')
            .width('100%')

          this.FeatureItem('智能分类', '自动识别文档类型：会议纪要、学习笔记、项目报告等')
          this.FeatureItem('摘要生成', '为长篇文档生成简洁的核心摘要')
          this.FeatureItem('关键词提取', '提取文档核心关键词，便于检索')
          this.FeatureItem('关联分析', '发现不同文档间的概念联系')
          this.FeatureItem('全文检索', '基于关键词的高性能文档搜索')
        }
        .width('100%')
        .padding(16)
        .margin({ left: 16, right: 16, top: 16, bottom: 16 })
        .backgroundColor(Color.White)
        .borderRadius(12)
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  @Builder
  FeatureItem(title: string, desc: string) {
    Row() {
      Text('•')
        .fontSize(14)
        .fontColor('#007AFF')
      Column() {
        Text(title)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333333')
        Text(desc)
          .fontSize(12)
          .fontColor('#999999')
          .margin({ top: 2 })
      }
      .alignItems(HorizontalAlign.Start)
      .margin({ left: 8 })
    }
    .width('100%')
    .margin({ top: 12 })
    .alignItems(VerticalAlign.Top)
  }
}

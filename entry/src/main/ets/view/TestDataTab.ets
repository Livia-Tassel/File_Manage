/*
 * 测试数据生成Tab页面 - 批量生成测试文件的UI界面
 */

import { TestDataGenerator, GeneratorConfig, GeneratorResult } from '../common/utils/TestDataGenerator';

@Component
export struct TestDataTab {
  // 配置参数
  @State fileCount: string = '200';           // 文件总数
  @State minSize: string = '100';             // 最小文件大小(bytes)
  @State maxSize: string = '1000';            // 最大文件大小(bytes)
  @State minDuplicateRate: string = '30';     // 最小重复率(%)
  @State maxDuplicateRate: string = '50';     // 最大重复率(%)

  // 状态
  @State isGenerating: boolean = false;
  @State showMessage: boolean = false;
  @State messageText: string = '';
  @State messageType: string = 'success';
  @State lastResult: GeneratorResult | null = null;
  @State currentTestFileCount: number = 0;

  private generator: TestDataGenerator | null = null;

  aboutToAppear() {
    const context = this.getUIContext().getHostContext() as Context;
    this.generator = TestDataGenerator.getInstance(context);
    this.refreshTestFileCount();
  }

  // 刷新测试文件数量
  private refreshTestFileCount() {
    if (this.generator) {
      this.currentTestFileCount = this.generator.getTestFileCount();
    }
  }

  // 显示消息
  private showToast(message: string, type: string = 'success') {
    this.messageText = message;
    this.messageType = type;
    this.showMessage = true;
    setTimeout(() => {
      this.showMessage = false;
    }, 3000);
  }

  // 验证输入参数
  private validateConfig(): GeneratorConfig | null {
    const fileCount = parseInt(this.fileCount);
    const minSize = parseInt(this.minSize);
    const maxSize = parseInt(this.maxSize);
    const minDupRate = parseInt(this.minDuplicateRate);
    const maxDupRate = parseInt(this.maxDuplicateRate);

    if (isNaN(fileCount) || fileCount < 1 || fileCount > 1000) {
      this.showToast('文件数量需在1-1000之间', 'error');
      return null;
    }

    if (isNaN(minSize) || isNaN(maxSize) || minSize < 10 || maxSize > 100000) {
      this.showToast('文件大小需在10-100000字节之间', 'error');
      return null;
    }

    if (minSize > maxSize) {
      this.showToast('最小文件大小不能大于最大值', 'error');
      return null;
    }

    if (isNaN(minDupRate) || isNaN(maxDupRate) || minDupRate < 0 || maxDupRate > 100) {
      this.showToast('重复率需在0-100%之间', 'error');
      return null;
    }

    if (minDupRate > maxDupRate) {
      this.showToast('最小重复率不能大于最大值', 'error');
      return null;
    }

    return {
      fileCount: fileCount,
      minSize: minSize,
      maxSize: maxSize,
      minDuplicateRate: minDupRate,
      maxDuplicateRate: maxDupRate
    };
  }

  // 执行生成
  private performGenerate() {
    if (!this.generator || this.isGenerating) return;

    const config = this.validateConfig();
    if (!config) return;

    this.isGenerating = true;
    this.showToast('正在生成测试文件...', 'info');

    // 使用setTimeout让UI有时间更新
    setTimeout(() => {
      if (this.generator) {
        const result = this.generator.generateTestFiles(config);
        this.lastResult = result;
        this.isGenerating = false;
        this.refreshTestFileCount();

        if (result.success) {
          this.showToast(result.message, 'success');
        } else {
          this.showToast(result.message, 'error');
        }
      }
    }, 100);
  }

  // 清空测试文件
  private performClear() {
    if (!this.generator || this.isGenerating) return;

    this.isGenerating = true;
    const deletedCount = this.generator.clearTestFiles();
    this.isGenerating = false;
    this.lastResult = null;
    this.refreshTestFileCount();

    this.showToast(`已清空 ${deletedCount} 个txt文件`, 'success');
  }

  // 格式化文件大小
  private formatSize(bytes: number): string {
    if (bytes < 1024) return `${bytes} B`;
    if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`;
    return `${(bytes / 1024 / 1024).toFixed(2)} MB`;
  }

  build() {
    Column() {
      // === 标题 ===
      Column() {
        Text('测试数据生成器')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_color'))
          .margin({ bottom: 4 })

        Text(`当前txt文件: ${this.currentTestFileCount} 个`)
          .fontSize(12)
          .fontColor($r('app.color.text_muted'))
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 8 })
      .alignItems(HorizontalAlign.Start)

      // === 消息提示 ===
      if (this.showMessage) {
        Text(this.messageText)
          .fontSize(14)
          .fontColor('#FFFFFF')
          .backgroundColor(
            this.messageType === 'success' ? $r('app.color.success') :
              (this.messageType === 'error' ? $r('app.color.danger') : $r('app.color.primary'))
          )
          .padding({ left: 16, right: 16, top: 8, bottom: 8 })
          .borderRadius(10)
          .margin({ left: 16, right: 16, bottom: 12 })
          .animation({ duration: 200, curve: Curve.EaseInOut })
      }

      // === 配置表单 ===
      Column({ space: 16 }) {
        // 文件数量
        Column({ space: 6 }) {
          Text('文件总数量')
            .fontSize(14)
            .fontColor($r('app.color.text_secondary'))
          TextInput({ text: this.fileCount, placeholder: '1-1000' })
            .type(InputType.Number)
            .onChange((value: string) => { this.fileCount = value; })
            .height(44)
            .backgroundColor($r('app.color.input_background'))
            .border({ width: 1, color: $r('app.color.border_light'), radius: 12 })
            .padding({ left: 12, right: 12 })
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)

        // 文件大小范围
        Column({ space: 6 }) {
          Text('文件大小范围 (字节)')
            .fontSize(14)
            .fontColor($r('app.color.text_secondary'))
          Row({ space: 12 }) {
            TextInput({ text: this.minSize, placeholder: '最小' })
              .type(InputType.Number)
              .onChange((value: string) => { this.minSize = value; })
              .height(44)
              .backgroundColor($r('app.color.input_background'))
              .border({ width: 1, color: $r('app.color.border_light'), radius: 12 })
              .padding({ left: 12, right: 12 })
              .layoutWeight(1)

            Text('~')
              .fontSize(16)
              .fontColor($r('app.color.text_secondary'))

            TextInput({ text: this.maxSize, placeholder: '最大' })
              .type(InputType.Number)
              .onChange((value: string) => { this.maxSize = value; })
              .height(44)
              .backgroundColor($r('app.color.input_background'))
              .border({ width: 1, color: $r('app.color.border_light'), radius: 12 })
              .padding({ left: 12, right: 12 })
              .layoutWeight(1)
          }
          .width('100%')
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)

        // 重复率范围
        Column({ space: 6 }) {
          Text('重复率范围 (%)')
            .fontSize(14)
            .fontColor($r('app.color.text_secondary'))
          Row({ space: 12 }) {
            TextInput({ text: this.minDuplicateRate, placeholder: '最小' })
              .type(InputType.Number)
              .onChange((value: string) => { this.minDuplicateRate = value; })
              .height(44)
              .backgroundColor($r('app.color.input_background'))
              .border({ width: 1, color: $r('app.color.border_light'), radius: 12 })
              .padding({ left: 12, right: 12 })
              .layoutWeight(1)

            Text('~')
              .fontSize(16)
              .fontColor($r('app.color.text_secondary'))

            TextInput({ text: this.maxDuplicateRate, placeholder: '最大' })
              .type(InputType.Number)
              .onChange((value: string) => { this.maxDuplicateRate = value; })
              .height(44)
              .backgroundColor($r('app.color.input_background'))
              .border({ width: 1, color: $r('app.color.border_light'), radius: 12 })
              .padding({ left: 12, right: 12 })
              .layoutWeight(1)
          }
          .width('100%')
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .padding({ left: 16, right: 16 })

      // === 操作按钮 ===
      Row({ space: 12 }) {
        Button(this.isGenerating ? '生成中...' : '生成测试文件')
          .onClick(() => this.performGenerate())
          .enabled(!this.isGenerating)
          .height(48)
          .fontSize(16)
          .backgroundColor(this.isGenerating ? $r('app.color.border_light') : $r('app.color.primary'))
          .fontColor(Color.White)
          .borderRadius(12)
          .shadow({ radius: 12, color: '#143B6EF5', offsetX: 0, offsetY: 6 })
          .layoutWeight(1)

        Button('清空所有txt文件')
          .onClick(() => this.performClear())
          .enabled(!this.isGenerating && this.currentTestFileCount > 0)
          .height(48)
          .fontSize(16)
          .backgroundColor((!this.isGenerating && this.currentTestFileCount > 0) ? $r('app.color.danger') : $r('app.color.border_light'))
          .fontColor(Color.White)
          .borderRadius(12)
          .shadow({ radius: 12, color: '#14F04B4B', offsetX: 0, offsetY: 6 })
          .layoutWeight(1)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 24 })

      // === 生成结果 ===
      if (this.lastResult && this.lastResult.success) {
        Column({ space: 8 }) {
          Text('上次生成结果')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.text_color'))

          Row() {
            Column() {
              Text(`${this.lastResult.totalFiles}`)
                .fontSize(24)
                .fontWeight(FontWeight.Bold)
                .fontColor($r('app.color.primary'))
              Text('总文件数')
                .fontSize(11)
                .fontColor($r('app.color.text_muted'))
            }
            .layoutWeight(1)

            Column() {
              Text(`${this.lastResult.uniqueFiles}`)
                .fontSize(24)
                .fontWeight(FontWeight.Bold)
                .fontColor($r('app.color.success'))
              Text('唯一文件')
                .fontSize(11)
                .fontColor($r('app.color.text_muted'))
            }
            .layoutWeight(1)

            Column() {
              Text(`${this.lastResult.duplicateFiles}`)
                .fontSize(24)
                .fontWeight(FontWeight.Bold)
                .fontColor($r('app.color.warning'))
              Text('重复文件')
                .fontSize(11)
                .fontColor($r('app.color.text_muted'))
            }
            .layoutWeight(1)

            Column() {
              Text(`${this.lastResult.duplicateGroups}`)
                .fontSize(24)
                .fontWeight(FontWeight.Bold)
                .fontColor($r('app.color.danger'))
              Text('重复组')
                .fontSize(11)
                .fontColor($r('app.color.text_muted'))
            }
            .layoutWeight(1)
          }
          .width('100%')

          Text(`总大小: ${this.formatSize(this.lastResult.totalSize)}`)
            .fontSize(12)
            .fontColor($r('app.color.text_muted'))
        }
        .width('100%')
        .padding(16)
        .margin({ left: 16, right: 16, top: 24 })
        .backgroundColor($r('app.color.surface_alt'))
        .borderRadius(14)
        .border({ width: 1, color: $r('app.color.border_light') })
      }

      // === 使用说明 ===
      Column({ space: 8 }) {
        Text('使用说明')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_color'))

        Text('1. 设置要生成的文件数量（1-1000）')
          .fontSize(12)
          .fontColor($r('app.color.text_muted'))
        Text('2. 设置单个文件的大小范围（字节）')
          .fontSize(12)
          .fontColor($r('app.color.text_muted'))
        Text('3. 设置文件重复率范围（实际重复率会在此范围内随机）')
          .fontSize(12)
          .fontColor($r('app.color.text_muted'))
        Text('4. 点击"生成测试文件"开始生成')
          .fontSize(12)
          .fontColor($r('app.color.text_muted'))
        Text('5. 生成的文件为随机文件名，可在"管理文件"页面查看')
          .fontSize(12)
          .fontColor($r('app.color.text_muted'))
      }
      .width('100%')
      .padding(16)
      .margin({ left: 16, right: 16, top: 16 })
      .backgroundColor($r('app.color.primary_soft'))
      .borderRadius(14)
      .border({ width: 1, color: $r('app.color.border_light') })
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.page_background'))
  }
}

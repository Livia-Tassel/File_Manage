/*
 * 文件去重Tab页面 - 实现重复文件扫描、展示和去重功能
 */

import { DuplicateScanner, DuplicateGroup, DuplicateFileInfo, ScanResult } from '../common/utils/DuplicateScanner';
import { fileIo } from '@kit.CoreFileKit';
import { common } from '@kit.AbilityKit';

@Component
export struct DeduplicationTab {
  @State scanResult: ScanResult | null = null;
  @State isScanning: boolean = false;
  @State expandedGroups: string[] = [];
  @State showMessage: boolean = false;
  @State messageText: string = '';
  @State messageType: string = 'success'; // 'success' | 'error' | 'info'
  @State lastScanTime: string = '';
  @State showConfirmDialog: boolean = false;
  @State confirmAction: string = ''; // 'dedup_all' | 'dedup_group'
  @State selectedGroupHash: string = '';
  @State selectedKeepFile: string = '';

  // 查看文件内容相关状态
  @State showFileContentDialog: boolean = false;
  @State viewingFileName: string = '';
  @State viewingFileContent: string = '';

  private scanner: DuplicateScanner | null = null;
  private filesDir: string = '';

  aboutToAppear() {
    const context = this.getUIContext().getHostContext() as Context;
    this.scanner = DuplicateScanner.getInstance(context);
    this.lastScanTime = this.scanner.getLastScanTimeFormatted();

    // 获取文件目录路径
    const uiAbilityContext = context as common.UIAbilityContext;
    this.filesDir = uiAbilityContext.filesDir;
  }

  // 查看文件内容
  private viewFileContent(filename: string) {
    try {
      const filePath = `${this.filesDir}/${filename}`;
      const file = fileIo.openSync(filePath, fileIo.OpenMode.READ_ONLY);
      const stat = fileIo.statSync(filePath);

      // 限制读取大小，避免内存问题
      const maxReadSize = 10 * 1024; // 最多读取10KB
      const readSize = Math.min(stat.size, maxReadSize);
      const buffer = new ArrayBuffer(readSize);
      fileIo.readSync(file.fd, buffer);
      fileIo.closeSync(file);

      // 转换为字符串
      const uint8Array = new Uint8Array(buffer);
      let content = '';
      for (let i = 0; i < uint8Array.length; i++) {
        content += String.fromCharCode(uint8Array[i]);
      }

      // 如果文件被截断，添加提示
      if (stat.size > maxReadSize) {
        content += `\n\n... (文件过大，仅显示前 ${maxReadSize} 字节)`;
      }

      this.viewingFileName = filename;
      this.viewingFileContent = content;
      this.showFileContentDialog = true;
    } catch (error) {
      this.showToast(`读取文件失败: ${error}`, 'error');
    }
  }

  // 显示消息提示
  private showToast(message: string, type: string = 'success') {
    this.messageText = message;
    this.messageType = type;
    this.showMessage = true;
    setTimeout(() => {
      this.showMessage = false;
    }, 3000);
  }

  // 执行全量扫描
  private async performFullScan() {
    if (!this.scanner || this.isScanning) return;

    this.isScanning = true;
    this.showToast('正在扫描文件...', 'info');

    try {
      // 使用 setTimeout 让 UI 有时间更新
      setTimeout(() => {
        if (this.scanner) {
          this.scanResult = this.scanner.fullScan();
          this.lastScanTime = this.scanner.getLastScanTimeFormatted();
          this.isScanning = false;

          if (this.scanResult.duplicateGroups.length === 0) {
            this.showToast('扫描完成，未发现重复文件', 'info');
          } else {
            this.showToast(
              `扫描完成！发现 ${this.scanResult.duplicateGroups.length} 组重复文件，` +
              `可节省 ${this.scanResult.totalWasteSizeReadable} 空间`,
              'success'
            );
          }
        }
      }, 100);
    } catch (error) {
      this.isScanning = false;
      this.showToast(`扫描失败: ${error}`, 'error');
    }
  }

  // 执行增量扫描
  private async performIncrementalScan() {
    if (!this.scanner || this.isScanning) return;

    this.isScanning = true;
    this.showToast('正在执行增量扫描...', 'info');

    try {
      setTimeout(() => {
        if (this.scanner) {
          this.scanResult = this.scanner.incrementalScan();
          this.lastScanTime = this.scanner.getLastScanTimeFormatted();
          this.isScanning = false;

          if (this.scanResult.changedFiles === 0) {
            this.showToast('增量扫描完成，文件无变化', 'info');
          } else {
            this.showToast(
              `增量扫描完成！检测到 ${this.scanResult.changedFiles} 个文件变更`,
              'success'
            );
          }
        }
      }, 100);
    } catch (error) {
      this.isScanning = false;
      this.showToast(`扫描失败: ${error}`, 'error');
    }
  }

  // 一键去重
  private performDeduplicateAll() {
    if (!this.scanner) return;

    const deletedCount = this.scanner.deduplicateAll();
    this.scanResult = this.scanner.fullScan();

    this.showToast(`一键去重完成！已删除 ${deletedCount} 个重复文件`, 'success');
    this.showConfirmDialog = false;
  }

  // 处理单个重复组
  private performDeduplicateGroup() {
    if (!this.scanner || !this.selectedGroupHash || !this.selectedKeepFile) return;

    const deletedCount = this.scanner.deduplicateGroup(this.selectedGroupHash, this.selectedKeepFile);
    this.scanResult = this.scanner.fullScan();

    this.showToast(`已删除 ${deletedCount} 个重复文件，保留 "${this.selectedKeepFile}"`, 'success');
    this.showConfirmDialog = false;
    this.expandedGroups = this.expandedGroups.filter(h => h !== this.selectedGroupHash);
  }

  // 切换组展开状态
  private toggleGroup(hash: string) {
    const index = this.expandedGroups.indexOf(hash);
    if (index >= 0) {
      this.expandedGroups = this.expandedGroups.filter(h => h !== hash);
    } else {
      this.expandedGroups = this.expandedGroups.concat([hash]);
    }
  }

  // 检查组是否展开
  private isGroupExpanded(hash: string): boolean {
    return this.expandedGroups.indexOf(hash) >= 0;
  }

  // 获取变更状态文字
  private getChangeStatusText(group: DuplicateGroup): string {
    if (!group.changeStatus) return '';

    switch (group.changeStatus) {
      case 'new':
        return `新增重复组 (+${group.changeCount})`;
      case 'increased':
        return `重复数增加 (+${group.changeCount})`;
      case 'decreased':
        return `重复数减少 (-${group.changeCount})`;
      default:
        return '';
    }
  }

  // 获取变更状态颜色
  private getChangeStatusColor(group: DuplicateGroup): string {
    switch (group.changeStatus) {
      case 'new':
        return '#F6A609';
      case 'increased':
        return '#F04B4B';
      case 'decreased':
        return '#1DBE6B';
      default:
        return '#8B97A7';
    }
  }

  build() {
    Column() {
      // === 顶部标题和扫描信息 ===
      Column() {
        Text('文件去重')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_color'))
          .margin({ bottom: 8 })

        Row() {
          Text(`上次扫描: ${this.lastScanTime}`)
            .fontSize(12)
            .fontColor($r('app.color.text_muted'))
        }
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 8 })
      .alignItems(HorizontalAlign.Start)

      // === 操作按钮区 ===
      Row({ space: 10 }) {
        Button(this.isScanning ? '扫描中...' : '全量扫描')
          .onClick(() => this.performFullScan())
          .enabled(!this.isScanning)
          .height(40)
          .fontSize(14)
          .backgroundColor(this.isScanning ? $r('app.color.border_light') : $r('app.color.primary'))
          .fontColor(Color.White)
          .borderRadius(12)
          .shadow({ radius: 10, color: '#143B6EF5', offsetX: 0, offsetY: 4 })
          .layoutWeight(1)

        Button('增量扫描')
          .onClick(() => this.performIncrementalScan())
          .enabled(!this.isScanning && this.lastScanTime !== '从未扫描')
          .height(40)
          .fontSize(14)
          .backgroundColor((!this.isScanning && this.lastScanTime !== '从未扫描') ? $r('app.color.success') : $r('app.color.border_light'))
          .fontColor(Color.White)
          .borderRadius(12)
          .shadow({ radius: 10, color: '#141DBE6B', offsetX: 0, offsetY: 4 })
          .layoutWeight(1)

        Button('一键去重')
          .onClick(() => {
            if (this.scanResult && this.scanResult.duplicateGroups.length > 0) {
              this.confirmAction = 'dedup_all';
              this.showConfirmDialog = true;
            } else {
              this.showToast('请先执行扫描', 'info');
            }
          })
          .enabled(!this.isScanning && this.scanResult !== null && this.scanResult.duplicateGroups.length > 0)
          .height(40)
          .fontSize(14)
          .backgroundColor(
            (!this.isScanning && this.scanResult !== null && this.scanResult.duplicateGroups.length > 0)
              ? $r('app.color.danger') : $r('app.color.border_light')
          )
          .fontColor(Color.White)
          .borderRadius(12)
          .shadow({ radius: 10, color: '#14F04B4B', offsetX: 0, offsetY: 4 })
          .layoutWeight(1)
      }
      .width('100%')
      .padding({ left: 16, right: 16, bottom: 12 })

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
          .margin({ left: 16, right: 16, bottom: 8 })
          .animation({ duration: 200, curve: Curve.EaseInOut })
      }

      // === 扫描结果统计 ===
      if (this.scanResult) {
        Row() {
          Column() {
            Text(`${this.scanResult.scannedFiles}`)
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.primary'))
            Text('扫描文件')
              .fontSize(11)
              .fontColor($r('app.color.text_muted'))
          }
          .layoutWeight(1)

          Column() {
            Text(`${this.scanResult.duplicateGroups.length}`)
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.warning'))
            Text('重复组')
              .fontSize(11)
              .fontColor($r('app.color.text_muted'))
          }
          .layoutWeight(1)

          Column() {
            Text(`${this.scanResult.totalDuplicates}`)
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.danger'))
            Text('重复文件')
              .fontSize(11)
              .fontColor($r('app.color.text_muted'))
          }
          .layoutWeight(1)

          Column() {
            Text(this.scanResult.totalWasteSizeReadable)
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.success'))
            Text('可节省')
              .fontSize(11)
              .fontColor($r('app.color.text_muted'))
          }
          .layoutWeight(1)
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 8, bottom: 12 })
        .backgroundColor($r('app.color.surface_alt'))
        .borderRadius(14)
        .border({ width: 1, color: $r('app.color.border_light') })
        .margin({ left: 16, right: 16, bottom: 12 })
      }

      // === 重复文件列表 ===
      if (!this.scanResult) {
        Column() {
          Text('🔍')
            .fontSize(48)
            .margin({ bottom: 16 })
          Text('点击"全量扫描"开始检测重复文件')
            .fontSize(14)
            .fontColor($r('app.color.text_muted'))
        }
        .width('100%')
        .height(200)
        .justifyContent(FlexAlign.Center)
      } else if (this.scanResult.duplicateGroups.length === 0) {
        Column() {
          Text('✅')
            .fontSize(48)
            .margin({ bottom: 16 })
          Text('太棒了！没有发现重复文件')
            .fontSize(14)
            .fontColor($r('app.color.text_muted'))
        }
        .width('100%')
        .height(200)
        .justifyContent(FlexAlign.Center)
      } else {
        // 增量扫描提示
        if (this.scanResult.isIncremental && this.scanResult.changedFiles > 0) {
          Row() {
            Text(`📊 本次仅扫描变更文件，共 ${this.scanResult.changedFiles} 个文件有变化`)
              .fontSize(12)
              .fontColor($r('app.color.warning'))
          }
          .width('100%')
          .padding({ left: 16, right: 16, bottom: 8 })
        }

        List({ space: 8 }) {
          ForEach(this.scanResult.duplicateGroups, (group: DuplicateGroup, index: number) => {
            ListItem() {
              Column() {
                // 组标题行
                Row() {
                  Column() {
                    Row() {
                      Text(`重复组 ${index + 1}`)
                        .fontSize(16)
                        .fontWeight(FontWeight.Bold)
                        .fontColor($r('app.color.text_color'))

                      if (group.changeStatus) {
                        Text(this.getChangeStatusText(group))
                          .fontSize(11)
                          .fontColor(Color.White)
                          .backgroundColor(this.getChangeStatusColor(group))
                          .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                          .borderRadius(4)
                          .margin({ left: 8 })
                      }
                    }

                    Text(`${group.files.length} 个重复文件 · 可节省 ${this.formatFileSize(group.wasteSize)}`)
                      .fontSize(12)
                      .fontColor($r('app.color.text_muted'))
                      .margin({ top: 4 })
                  }
                  .alignItems(HorizontalAlign.Start)
                  .layoutWeight(1)

                  Text(this.isGroupExpanded(group.hash) ? '▼' : '▶')
                    .fontSize(14)
                    .fontColor($r('app.color.text_muted'))
                }
                .width('100%')
                .padding(12)
                .onClick(() => this.toggleGroup(group.hash))

                // 展开的文件列表
                if (this.isGroupExpanded(group.hash)) {
                  Column({ space: 6 }) {
                    ForEach(group.files, (file: DuplicateFileInfo, fileIndex: number) => {
                      Row() {
                        Column() {
                          Row() {
                            if (fileIndex === 0) {
                              Text('保留')
                                .fontSize(10)
                                .fontColor(Color.White)
                                .backgroundColor($r('app.color.success'))
                                .padding({ left: 4, right: 4, top: 1, bottom: 1 })
                                .borderRadius(4)
                                .margin({ right: 6 })
                            }

                            if (file.isNew) {
                              Text('新增')
                                .fontSize(10)
                                .fontColor(Color.White)
                                .backgroundColor($r('app.color.warning'))
                                .padding({ left: 4, right: 4, top: 1, bottom: 1 })
                                .borderRadius(4)
                                .margin({ right: 6 })
                            }

                            Text(file.filename)
                              .fontSize(14)
                              .fontColor($r('app.color.text_color'))
                              .maxLines(1)
                              .textOverflow({ overflow: TextOverflow.Ellipsis })
                          }

                          Text(`${file.sizeReadable} · ${file.mtimeFormatted}`)
                            .fontSize(11)
                            .fontColor($r('app.color.text_muted'))
                            .margin({ top: 2 })
                        }
                        .alignItems(HorizontalAlign.Start)
                        .layoutWeight(1)

                        Row({ space: 4 }) {
                          Button('查看')
                            .onClick(() => {
                              this.viewFileContent(file.filename);
                            })
                            .height(28)
                            .fontSize(11)
                            .backgroundColor($r('app.color.text_muted'))
                            .fontColor(Color.White)
                            .borderRadius(14)

                          if (fileIndex !== 0) {
                            Button('保留此文件')
                              .onClick(() => {
                                this.selectedGroupHash = group.hash;
                                this.selectedKeepFile = file.filename;
                                this.confirmAction = 'dedup_group';
                                this.showConfirmDialog = true;
                              })
                              .height(28)
                              .fontSize(11)
                              .backgroundColor($r('app.color.primary'))
                              .fontColor(Color.White)
                              .borderRadius(14)
                          }
                        }
                      }
                      .width('100%')
                      .padding({ left: 12, right: 12, top: 8, bottom: 8 })
                      .backgroundColor(fileIndex === 0 ? '#E9F7F0' : '#FFF4E3')
                      .borderRadius(10)
                    })

                    // 快速操作按钮
                    Row({ space: 10 }) {
                      Button('保留第一个，删除其他')
                        .onClick(() => {
                          this.selectedGroupHash = group.hash;
                          this.selectedKeepFile = group.files[0].filename;
                          this.confirmAction = 'dedup_group';
                          this.showConfirmDialog = true;
                        })
                        .height(36)
                        .fontSize(13)
                        .backgroundColor($r('app.color.danger'))
                        .fontColor(Color.White)
                        .borderRadius(10)
                        .shadow({ radius: 10, color: '#14F04B4B', offsetX: 0, offsetY: 4 })
                        .layoutWeight(1)
                    }
                    .width('100%')
                    .padding({ top: 8 })
                  }
                  .width('100%')
                  .padding({ left: 12, right: 12, bottom: 12 })
                }
              }
              .backgroundColor($r('app.color.surface'))
              .borderRadius(14)
              .border({ width: 1, color: $r('app.color.border_light') })
              .shadow({ radius: 12, color: '#0F000000', offsetX: 0, offsetY: 4 })
            }
          })
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ left: 16, right: 16 })
      }

      // === 确认对话框 ===
      if (this.showConfirmDialog) {
        Stack()
          .width('100%')
          .height('100%')
          .backgroundColor('rgba(0, 0, 0, 0.5)')
          .onClick(() => {
            this.showConfirmDialog = false;
          })
          .position({ x: 0, y: 0 })

        Column() {
          Text(this.confirmAction === 'dedup_all' ? '确认一键去重' : '确认删除重复文件')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.text_color'))
            .margin({ bottom: 16 })

          Text(
            this.confirmAction === 'dedup_all'
              ? `即将删除所有重复组中的多余文件，每组保留最早创建的文件。\n\n共 ${this.scanResult ? this.scanResult.duplicateGroups.length : 0} 组重复文件将被处理。\n\n删除的文件将移入回收站，可以恢复。`
              : `即将删除该组中除 "${this.selectedKeepFile}" 以外的所有文件。\n\n删除的文件将移入回收站，可以恢复。`
          )
            .fontSize(14)
            .fontColor($r('app.color.text_secondary'))
            .textAlign(TextAlign.Center)
            .margin({ bottom: 24 })

          Row({ space: 16 }) {
            Button('取消')
              .onClick(() => {
                this.showConfirmDialog = false;
              })
              .height(44)
              .fontSize(16)
              .backgroundColor($r('app.color.surface_alt'))
              .fontColor($r('app.color.text_secondary'))
              .borderRadius(10)
              .border({ width: 1, color: $r('app.color.border_light') })
              .layoutWeight(1)

            Button('确认删除')
              .onClick(() => {
                if (this.confirmAction === 'dedup_all') {
                  this.performDeduplicateAll();
                } else {
                  this.performDeduplicateGroup();
                }
              })
              .height(44)
              .fontSize(16)
              .backgroundColor($r('app.color.danger'))
              .fontColor(Color.White)
              .borderRadius(10)
              .shadow({ radius: 10, color: '#14F04B4B', offsetX: 0, offsetY: 4 })
              .layoutWeight(1)
          }
          .width('100%')
        }
        .width('85%')
        .padding(24)
        .backgroundColor($r('app.color.surface'))
        .borderRadius(18)
        .shadow({ radius: 22, color: '#24000000', offsetX: 0, offsetY: 12 })
        .position({ x: '7.5%', y: '30%' })
      }

      // === 文件内容查看对话框 ===
      if (this.showFileContentDialog) {
        Stack()
          .width('100%')
          .height('100%')
          .backgroundColor('rgba(0, 0, 0, 0.5)')
          .onClick(() => {
            this.showFileContentDialog = false;
          })
          .position({ x: 0, y: 0 })

        Column() {
          // 标题栏
          Row() {
            Text('文件内容')
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.text_color'))
              .layoutWeight(1)

            Button('×')
              .fontSize(24)
              .fontColor($r('app.color.text_secondary'))
              .backgroundColor(Color.Transparent)
              .onClick(() => {
                this.showFileContentDialog = false;
              })
          }
          .width('100%')
          .padding({ left: 20, right: 20, top: 15, bottom: 15 })
          .border({ width: { bottom: 1 }, color: $r('app.color.border_light') })

          // 文件名
          Row() {
            Text('文件名:')
              .fontSize(14)
              .fontColor($r('app.color.text_secondary'))
              .width('20%')
            Text(this.viewingFileName)
              .fontSize(14)
              .fontColor($r('app.color.primary'))
              .fontWeight(FontWeight.Medium)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .width('80%')
          }
          .width('100%')
          .padding({ left: 20, right: 20, top: 12 })

          // 文件内容
          Scroll() {
            Text(this.viewingFileContent)
              .fontSize(13)
              .fontColor($r('app.color.text_color'))
              .fontFamily('monospace')
              .width('100%')
          }
          .width('100%')
          .height(300)
          .padding(16)
          .margin({ left: 20, right: 20, top: 12, bottom: 12 })
          .backgroundColor($r('app.color.surface_alt'))
          .borderRadius(10)
          .border({ width: 1, color: $r('app.color.border_light') })

          // 关闭按钮
          Button('关闭')
            .onClick(() => {
              this.showFileContentDialog = false;
            })
            .width('90%')
            .height(44)
            .fontSize(16)
            .backgroundColor($r('app.color.primary'))
            .fontColor(Color.White)
            .borderRadius(12)
            .shadow({ radius: 10, color: '#143B6EF5', offsetX: 0, offsetY: 4 })
            .margin({ bottom: 20 })
        }
        .width('90%')
        .backgroundColor($r('app.color.surface'))
        .borderRadius(18)
        .shadow({ radius: 22, color: '#24000000', offsetX: 0, offsetY: 12 })
        .position({ x: '5%', y: '10%' })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.page_background'))
  }

  // 格式化文件大小
  private formatFileSize(bytes: number): string {
    if (bytes === 0) return '0 B';
    const k = 1024;
    const sizes = ['B', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return `${parseFloat((bytes / Math.pow(k, i)).toFixed(1))} ${sizes[i]}`;
  }
}

/*
 * 回收站Tab页面 - 实现已删除文件的查看和恢复功能
 */

import { TrashManager, TrashFileInfo } from '../common/utils/TrashManager';

@Component
export struct TrashTab {
  @State trashFiles: TrashFileInfo[] = [];
  @State showMessage: boolean = false;
  @State messageText: string = '';
  @State messageType: string = 'success';
  @State showConfirmDialog: boolean = false;
  @State confirmAction: string = ''; // 'empty' | 'delete' | 'restore_all'
  @State selectedTrashName: string = '';
  @State isLoading: boolean = false;

  private trashManager: TrashManager | null = null;

  aboutToAppear() {
    const context = this.getUIContext().getHostContext() as Context;
    this.trashManager = TrashManager.getInstance(context);
    this.loadTrashFiles();
  }

  // 加载回收站文件
  private loadTrashFiles() {
    if (this.trashManager) {
      this.trashFiles = this.trashManager.getTrashFiles();
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

  // 恢复单个文件
  private restoreFile(trashName: string) {
    if (!this.trashManager) return;

    const success = this.trashManager.restoreFile(trashName);
    if (success) {
      this.showToast('文件已恢复', 'success');
      this.loadTrashFiles();
    } else {
      this.showToast('恢复失败', 'error');
    }
  }

  // 永久删除单个文件
  private permanentDelete(trashName: string) {
    if (!this.trashManager) return;

    const success = this.trashManager.permanentDelete(trashName);
    if (success) {
      this.showToast('文件已永久删除', 'success');
      this.loadTrashFiles();
    } else {
      this.showToast('删除失败', 'error');
    }
    this.showConfirmDialog = false;
  }

  // 恢复所有文件
  private restoreAll() {
    if (!this.trashManager) return;

    const restoredCount = this.trashManager.restoreAll();
    this.showToast(`已恢复 ${restoredCount} 个文件`, 'success');
    this.loadTrashFiles();
    this.showConfirmDialog = false;
  }

  // 清空回收站
  private emptyTrash() {
    if (!this.trashManager) return;

    const success = this.trashManager.emptyTrash();
    if (success) {
      this.showToast('回收站已清空', 'success');
      this.loadTrashFiles();
    } else {
      this.showToast('清空失败', 'error');
    }
    this.showConfirmDialog = false;
  }

  // 获取删除来源文字
  private getSourceText(source: string): string {
    switch (source) {
      case 'manual':
        return '手动删除';
      case 'dedup':
        return '去重删除';
      default:
        return '删除';
    }
  }

  // 获取删除来源颜色
  private getSourceColor(source: string): string {
    switch (source) {
      case 'manual':
        return '#3B6EF5';
      case 'dedup':
        return '#F6A609';
      default:
        return '#8B97A7';
    }
  }

  build() {
    Column() {
      // === 顶部标题 ===
      Column() {
        Text('回收站')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_color'))
          .margin({ bottom: 4 })

        Text(`共 ${this.trashFiles.length} 个文件`)
          .fontSize(12)
          .fontColor($r('app.color.text_muted'))
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 8 })
      .alignItems(HorizontalAlign.Start)

      // === 操作按钮区 ===
      Row({ space: 10 }) {
        Button('刷新')
          .onClick(() => this.loadTrashFiles())
          .height(40)
          .fontSize(14)
          .backgroundColor($r('app.color.primary'))
          .fontColor(Color.White)
          .borderRadius(12)
          .shadow({ radius: 10, color: '#143B6EF5', offsetX: 0, offsetY: 4 })
          .layoutWeight(1)

        Button('全部恢复')
          .onClick(() => {
            if (this.trashFiles.length > 0) {
              this.confirmAction = 'restore_all';
              this.showConfirmDialog = true;
            } else {
              this.showToast('回收站为空', 'info');
            }
          })
          .enabled(this.trashFiles.length > 0)
          .height(40)
          .fontSize(14)
          .backgroundColor(this.trashFiles.length > 0 ? $r('app.color.success') : $r('app.color.border_light'))
          .fontColor(Color.White)
          .borderRadius(12)
          .shadow({ radius: 10, color: '#141DBE6B', offsetX: 0, offsetY: 4 })
          .layoutWeight(1)

        Button('清空回收站')
          .onClick(() => {
            if (this.trashFiles.length > 0) {
              this.confirmAction = 'empty';
              this.showConfirmDialog = true;
            } else {
              this.showToast('回收站为空', 'info');
            }
          })
          .enabled(this.trashFiles.length > 0)
          .height(40)
          .fontSize(14)
          .backgroundColor(this.trashFiles.length > 0 ? $r('app.color.danger') : $r('app.color.border_light'))
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

      // === 文件列表 ===
      if (this.trashFiles.length === 0) {
        Column() {
          Text('🗑️')
            .fontSize(48)
            .margin({ bottom: 16 })
          Text('回收站为空')
            .fontSize(16)
            .fontColor($r('app.color.text_muted'))
            .margin({ bottom: 8 })
          Text('删除的文件会暂存在这里，可以随时恢复')
            .fontSize(12)
            .fontColor($r('app.color.text_muted'))
        }
        .width('100%')
        .height(300)
        .justifyContent(FlexAlign.Center)
      } else {
        List({ space: 8 }) {
          ForEach(this.trashFiles, (file: TrashFileInfo) => {
            ListItem() {
              Row() {
                Column() {
                  Row() {
                    Text(file.originalName)
                      .fontSize(15)
                      .fontWeight(FontWeight.Medium)
                      .fontColor($r('app.color.text_color'))
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                      .layoutWeight(1)

                    Text(this.getSourceText(file.source))
                      .fontSize(10)
                      .fontColor(Color.White)
                      .backgroundColor(this.getSourceColor(file.source))
                      .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                      .borderRadius(4)
                      .margin({ left: 8 })
                  }
                  .width('100%')

                  Row() {
                    Text(file.sizeReadable)
                      .fontSize(11)
                      .fontColor($r('app.color.text_muted'))
                      .margin({ right: 12 })

                    Text(`删除于 ${file.deleteTimeFormatted}`)
                      .fontSize(11)
                      .fontColor($r('app.color.text_muted'))
                  }
                  .margin({ top: 4 })
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Start)

                Row({ space: 8 }) {
                  Button('恢复')
                    .onClick(() => this.restoreFile(file.trashName))
                    .height(32)
                    .fontSize(12)
                    .backgroundColor($r('app.color.success'))
                    .fontColor(Color.White)
                    .borderRadius(16)
                    .shadow({ radius: 8, color: '#141DBE6B', offsetX: 0, offsetY: 3 })

                  Button('删除')
                    .onClick(() => {
                      this.selectedTrashName = file.trashName;
                      this.confirmAction = 'delete';
                      this.showConfirmDialog = true;
                    })
                    .height(32)
                    .fontSize(12)
                    .backgroundColor($r('app.color.danger'))
                    .fontColor(Color.White)
                    .borderRadius(16)
                    .shadow({ radius: 8, color: '#14F04B4B', offsetX: 0, offsetY: 3 })
                }
              }
              .width('100%')
              .padding(12)
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

      // === 提示信息 ===
      if (this.trashFiles.length > 0) {
        Row() {
          Text('💡 提示：回收站中的文件不会永久删除，直到您手动清空回收站')
            .fontSize(11)
            .fontColor($r('app.color.text_muted'))
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 8, bottom: 16 })
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
          Text(
            this.confirmAction === 'empty' ? '确认清空回收站' :
              (this.confirmAction === 'restore_all' ? '确认恢复所有文件' : '确认永久删除')
          )
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.text_color'))
            .margin({ bottom: 16 })

          Text(
            this.confirmAction === 'empty'
              ? `即将永久删除回收站中的所有 ${this.trashFiles.length} 个文件。\n\n此操作不可撤销！`
              : (this.confirmAction === 'restore_all'
                ? `即将恢复回收站中的所有 ${this.trashFiles.length} 个文件到原位置。`
                : '此文件将被永久删除，无法恢复。')
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

            Button(this.confirmAction === 'restore_all' ? '确认恢复' : '确认删除')
              .onClick(() => {
                switch (this.confirmAction) {
                  case 'empty':
                    this.emptyTrash();
                    break;
                  case 'restore_all':
                    this.restoreAll();
                    break;
                  case 'delete':
                    this.permanentDelete(this.selectedTrashName);
                    break;
                }
              })
              .height(44)
              .fontSize(16)
              .backgroundColor(this.confirmAction === 'restore_all' ? $r('app.color.success') : $r('app.color.danger'))
              .fontColor(Color.White)
              .borderRadius(10)
              .shadow({ radius: 10, color: this.confirmAction === 'restore_all' ? '#141DBE6B' : '#14F04B4B', offsetX: 0, offsetY: 4 })
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
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.page_background'))
  }
}

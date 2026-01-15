/*
 * Copyright (c) 2025 Huawei Device Co., Ltd.
 * Licensed under the Apache License,Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */


// import { photoAccessHelper } from '@kit.MediaLibraryKit';
// import { fileIo } from '@kit.CoreFileKit';
// import Logger from '../common/utils/Logger';
// import { readUserFile, saveToUser } from '../common/utils/SavingAndSelectUserFile';
// import { photoPickerGetUri } from '../common/utils/PictureSaving';
//
// @Component
// export struct publicFilesTab {
//   @State picture: string = '';
//   @State flag: Boolean = false;
//   @State message: string = '';
//   @State content: string = '';
//   @State isInput: Boolean = false;
//   // Setting the button properties of a security control
//   @State saveButtonOptions: SaveButtonOptions = {
//     icon: SaveIconStyle.FULL_FILLED,
//     text: SaveDescription.SAVE_IMAGE,
//     buttonType: ButtonType.Capsule
//   }
//
//   build() {
//     Column() {
//       Column() {
//         Image($r('app.media.img'))
//           .borderRadius($r('app.float.default_24'))
//           .width($r('app.float.default_312'))
//           .height($r('app.float.default_147'))
//         // Create Security Control Button
//         SaveButton(this.saveButtonOptions)
//           .onClick(async (event, result: SaveButtonOnClickResult) => {
//             if (result == SaveButtonOnClickResult.SUCCESS) {
//               try {
//                 Logger.info('createAsset successfully, event: ' + event);
//                 let context = this.getUIContext().getHostContext();
//                 let phAccessHelper = photoAccessHelper.getPhotoAccessHelper(context);
//                 // Creating a Media File
//                 let uri = await phAccessHelper.createAsset(photoAccessHelper.PhotoType.IMAGE, 'jpg')
//                   .catch((error: BusinessError<Error>) => {
//                     Logger.error(`createAsset catch error, code: ${error.code}, message: ${error.message}`);
//                     return '';
//                   })
//                 Logger.info('createAsset successfully, uri: ' + uri);
//                 // Open the created media file and read the local file and convert it to ArrayBuffer for easy filling.
//                 let file = await fileIo.open(uri, fileIo.OpenMode.READ_WRITE);
//                 let buffer = context!.resourceManager.getMediaContentSync($r('app.media.img').id);
//                 // Write the read ArrayBuffer to the new media file.
//                 let writeLen = await fileIo.write(file.fd, buffer.buffer);
//                 Logger.info('write success,len=' + writeLen);
//                 await fileIo.close(file);
//               } catch (err) {
//                 Logger.error('createAsset failed, message = ', err);
//               }
//             } else {
//               Logger.error('SaveButtonOnClickResult createAsset failed');
//             }
//           })
//       }
//       .margin({ bottom: $r('app.float.default_10') })
//       .width($r('app.float.default_336'))
//       .height($r('app.float.default_223'))
//       .borderRadius($r('app.float.default_24'))
//       .justifyContent(FlexAlign.SpaceAround)
//       .backgroundColor($r('app.color.start_window_background'))
//
//       Column() {
//         Text($r('app.string.select_photo'))
//           .width($r('app.float.default_302'))
//           .height($r('app.float.default_48'))
//           .lineHeight($r('app.float.default_22'))
//           .fontFamily('HarmonyHeiTi-Medium')
//           .fontSize($r('app.float.default_16'))
//           .fontWeight(500)
//           .textAlign(TextAlign.Start)
//           .fontColor($r('app.color.text_color'))
//         Column() {
//           if (!this.flag) {
//             Image($r('app.media.ic_folder_add2'))
//               .width($r('app.float.default_24'))
//               .height($r('app.float.default_24'))
//               .objectFit(ImageFit.Contain)
//           } else {
//             Image(this.picture)
//               .width('100%')
//               .height('100%')
//               .borderRadius($r('app.float.default_24'))
//           }
//         }
//         .width($r('app.float.default_312'))
//         .height($r('app.float.default_147'))
//         .borderRadius($r('app.float.default_16'))
//         .backgroundColor($r('app.color.picture_background'))
//         .onClick(async () => {
//           await photoPickerGetUri().then(value => {
//             this.flag = true;
//             this.picture = value;
//           });
//         })
//         .justifyContent(FlexAlign.Center)
//         .alignItems(HorizontalAlign.Center)
//       }
//       .margin({ bottom: $r('app.float.default_10') })
//       .backgroundColor($r('app.color.start_window_background'))
//       .width($r('app.float.default_336'))
//       .height($r('app.float.default_213'))
//       .borderRadius($r('app.float.default_24'))
//
//       Column() {
//         TextArea({ placeholder: $r('app.string.textarea_default2'), text: this.isInput ? this.content : this.message })
//           .onChange((value: string) => {
//             this.content = value;
//           })
//           .width($r('app.float.default_312'))
//           .height($r('app.float.default_120'))
//           .margin({ top: $r('app.float.default_10'), bottom: $r('app.float.default_10') })
//           .enableKeyboardOnFocus(false)
//         Button($r('app.string.button3'))
//           .width($r('app.float.default_312'))
//           .height($r('app.float.default_40'))
//           .onClick(() => {
//             saveToUser(this.content)
//             this.content = '';
//             this.isInput = true;
//           })
//           .margin({ bottom: $r('app.float.default_10') })
//         Button($r('app.string.button4'))
//           .width($r('app.float.default_312'))
//           .height($r('app.float.default_40'))
//           .onClick(async () => {
//             await readUserFile().then((value: string) => {
//               this.message = value;
//               this.isInput = false;
//             })
//           })
//       }
//       .backgroundColor($r('app.color.start_window_background'))
//       .width($r('app.float.default_336'))
//       .height('251')
//       .borderRadius($r('app.float.default_24'))
//       .margin({ bottom: $r('app.float.default_100') })
//     }
//     .width('100%')
//   }
// }

import { FileManager } from '../common/utils/FileManager';
import { fileIo } from '@kit.CoreFileKit';
import { photoPickerGetUri } from '../common/utils/PictureSaving';
import { FileInfo } from '../common/utils/FileManager';
import { readFile } from '../common/utils/ReadFile';
import { deleteFile, initDeleteUtils } from '../common/utils/DeleteFile';
import fs from '@ohos.file.fs';

@Component
export struct publicFilesTab {
  // 新增状态变量
  @State fileList: Array<FileInfo> = []; // 文件列表
  @State searchKeyword: string = ''; // 搜索关键字
  @State selectedFile: string = ''; // 当前选中的文件
  @State fileContent: string = ''; // 文件内容
  @State showFileContent: boolean = false; // 是否显示文件内容
  @State newFileName: string = ''; // 新文件名
  @State fileManager: FileManager | null = null; // 文件管理器实例

  // 删除的状态变量
  @State showSaveSuccess: boolean = false;
  @State saveMessage: string = '';

  // 文件操作菜单相关状态
  @State showFileActionMenu: boolean = false;
  @State selectedFileForMenu: string = '';

  // 重命名状态
  @State renamingFile: string = '';
  @State newFilename: string = '';
  @State showRenameDialog: boolean = false;

  // 文件操作面板状态
  @State showFileActionPanel: boolean = false;
  @State selectedFileForPanel: string = '';

  aboutToAppear() {
    let context = this.getUIContext().getHostContext() as Context;
    this.fileManager = new FileManager(context);
    initDeleteUtils(context);
    // this.searchFilesWithInfo();
    this.loadFileListWithInfo();
  }

  onPageShow() {
    console.log('页面显示，刷新文件列表');
    this.searchFilesWithInfo();
  }

  // 加载文件列表（包含详细信息）
  async loadFileListWithInfo() {
    console.log('加载文件列表（带详细信息）...');

    if (this.fileManager) {
      try {
        const files = await this.fileManager.getAllFilesWithInfo();
        console.log('获取到的文件数量:', files.length);
        this.fileList = files;

        if (files.length > 0) {
          console.log('示例文件信息:', {
            filename: files[0].filename,
            size: files[0].sizeReadable,
            ctime: files[0].ctimeFormatted
          });
        }
      } catch (error) {
        console.error('加载文件列表失败:', error);
        this.fileList = [];
      }
    }
  }

  // 搜索文件（带详细信息）
  async searchFilesWithInfo() {
    console.log('搜索文件:', this.searchKeyword);

    if (this.fileManager) {
      if (this.searchKeyword.trim() === '') {
        await this.loadFileListWithInfo();
      } else {
        const files = await this.fileManager.searchFilesWithInfo(this.searchKeyword);
        this.fileList = files;
        console.log('搜索结果:', files.length, '个文件');
      }
    }
  }

  // 执行删除文件的方法
  private async executeDeleteFile(filename: string) {
    console.log(`执行删除文件: ${filename}`);
    const success = deleteFile(filename);
    if (success) {
      console.log(`文件 ${filename} 删除成功`);
      await this.loadFileListWithInfo();

      if (this.selectedFile === filename) {
        this.selectedFile = '';
        this.fileContent = '';
        this.showFileContent = false;
      }

      this.saveMessage = `文件 "${filename}" 已删除`;
      this.showSaveSuccess = true;
      setTimeout(() => {
        this.showSaveSuccess = false;
      }, 3000);
    } else {
      console.log(`文件 ${filename} 删除失败`);
      this.saveMessage = `删除文件失败`;
      this.showSaveSuccess = true;
      setTimeout(() => {
        this.showSaveSuccess = false;
      }, 3000);
    }
  }

  // 打开文件操作面板
  private openFileActionPanel(filename: string) {
    this.selectedFileForPanel = filename;
    this.showFileActionPanel = true;
  }

  // 关闭文件操作面板
  private closeFileActionPanel() {
    this.showFileActionPanel = false;
    this.selectedFileForPanel = '';
  }

  // 查看文件内容
  private async viewFileContent(filename: string) {
    if (this.fileManager) {
      try {
        const content = readFile(filename);
        console.log(`文件内容:${content}`);


        this.selectedFile = filename;
        this.fileContent = content;
        this.showFileContent = true;
      } catch (error) {
        console.error(`读取文件失败: ${error}`);
        this.saveMessage = `读取文件失败: ${error}`;
        this.showSaveSuccess = true;
        setTimeout(() => {
          this.showSaveSuccess = false;
        }, 3000);
      }
    }
  }

  // private async updateFileContent() {
  //   if (!this.fileManager || !this.selectedFile) {
  //     console.error('更新文件内容参数不完整');
  //     return;
  //   }
  //
  //   try {
  //     // 直接调用 FileManager 的 updateFile 方法
  //     const success = await this.fileManager.updateFile(this.selectedFile, this.fileContent);
  //
  //     if (success) {
  //       console.log(`文件内容更新成功: ${this.selectedFile}`);
  //
  //       // 显示成功提示
  //       this.saveMessage = '文件内容已保存';
  //       this.showSaveSuccess = true;
  //       setTimeout(() => {
  //         this.showSaveSuccess = false;
  //       }, 2000);
  //
  //       // 关闭文件内容界面
  //       setTimeout(() => {
  //         this.showFileContent = false;
  //       }, 1000);
  //
  //       // 刷新文件列表（因为文件大小可能已改变）
  //       await this.loadFileListWithInfo();
  //     } else {
  //       console.error('更新文件内容失败');
  //       this.saveMessage = '保存失败，请重试';
  //       this.showSaveSuccess = true;
  //       setTimeout(() => {
  //         this.showSaveSuccess = false;
  //       }, 3000);
  //     }
  //   } catch (error) {
  //     console.error(`更新文件内容过程中发生错误: ${error}`);
  //     this.saveMessage = `保存失败: ${error}`;
  //     this.showSaveSuccess = true;
  //     setTimeout(() => {
  //       this.showSaveSuccess = false;
  //     }, 3000);
  //   }
  // }
  private async updateFileContent() {
    if (!this.selectedFile || !this.fileContent) {
      console.error('更新文件内容参数不完整');
      return;
    }

    try {
      console.log(`开始更新文件内容: ${this.selectedFile}`);

      // 获取文件路径
      const context = this.getUIContext().getHostContext() as Context;
      const filesDir = context.filesDir;
      const filePath = filesDir + '/' + this.selectedFile;

      console.log(`更新文件路径: ${filePath}`);

      // 创建文件流并写入内容
      let fileStream = fileIo.createStreamSync(filePath, "w+");

      fileStream.writeSync(this.fileContent);
      fileStream.close();

      console.log(`文件内容更新成功: ${this.selectedFile}`);
      console.log(`写入的内容长度: ${this.fileContent.length}`);

      // 显示成功提示
      this.saveMessage = '文件内容已保存';
      this.showSaveSuccess = true;

      // 关闭文件内容界面
      setTimeout(() => {
        this.showFileContent = false;
      }, 1000);

      // 刷新文件列表（因为文件大小可能已改变）
      await this.loadFileListWithInfo();

      // 3秒后隐藏成功提示
      setTimeout(() => {
        this.showSaveSuccess = false;
      }, 3000);

    } catch (error) {
      console.error(`更新文件内容失败: ${error}`);
      this.saveMessage = `保存失败: ${error.message || error}`;
      this.showSaveSuccess = true;
      setTimeout(() => {
        this.showSaveSuccess = false;
      }, 3000);
    }
  }


  // 打开重命名对话框
  private openRenameDialog(filename: string) {
    this.renamingFile = filename;
    this.newFilename = filename;
    this.showRenameDialog = true;
  }

  // 关闭重命名对话框
  private closeRenameDialog() {
    this.showRenameDialog = false;
    this.renamingFile = '';
    this.newFilename = '';
  }

  // 执行重命名
  private async executeRename() {
    if (!this.fileManager || !this.renamingFile || !this.newFilename) {
      console.error('重命名参数不完整');
      return;
    }

    if (this.renamingFile === this.newFilename.trim()) {
      this.saveMessage = '文件名未改变';
      this.showSaveSuccess = true;
      setTimeout(() => {
        this.showSaveSuccess = false;
      }, 2000);
      this.closeRenameDialog();
      return;
    }

    if (this.newFilename.trim() === '') {
      this.saveMessage = '新文件名不能为空';
      this.showSaveSuccess = true;
      setTimeout(() => {
        this.showSaveSuccess = false;
      }, 2000);
      return;
    }

    try {
      console.log(`old name${this.renamingFile} new name${this.newFilename.trim()}`);
      const success = await this.fileManager.renameFile(this.renamingFile, this.newFilename.trim());

      if (success) {
        console.log(`重命名成功: ${this.renamingFile} -> ${this.newFilename}`);
        await this.loadFileListWithInfo();

        if (this.selectedFile === this.renamingFile) {
          this.selectedFile = this.newFilename.trim();
        }

        this.saveMessage = `文件已重命名为 "${this.newFilename.trim()}"`;
        this.showSaveSuccess = true;
        setTimeout(() => {
          this.showSaveSuccess = false;
        }, 3000);

        this.closeRenameDialog();
      } else {
        console.error('重命名失败');
        this.saveMessage = '重命名失败，请检查文件名是否合法或已存在';
        this.showSaveSuccess = true;
        setTimeout(() => {
          this.showSaveSuccess = false;
        }, 3000);
      }
    } catch (error) {
      console.error(`重命名过程中发生错误: ${error}`);
      this.saveMessage = `重命名失败: ${error}`;
      this.showSaveSuccess = true;
      setTimeout(() => {
        this.showSaveSuccess = false;
      }, 3000);
    }
  }



  // 根据文件扩展名返回对应的图标
  private getFileIcon(filename: string): string {
    if (filename.endsWith('.txt')) return '📝';
    if (filename.endsWith('.pdf')) return '📕';
    if (filename.endsWith('.jpg') || filename.endsWith('.png') || filename.endsWith('.gif')) return '🖼️';
    if (filename.endsWith('.mp4') || filename.endsWith('.avi')) return '🎬';
    if (filename.endsWith('.mp3') || filename.endsWith('.wav')) return '🎵';
    if (filename.endsWith('.zip') || filename.endsWith('.rar')) return '🗜️';
    return '📄';
  }

  build() {
    Column() {
      // === 顶部搜索栏 ===
      Row() {
        TextInput({ placeholder: '搜索文件...', text: this.searchKeyword })
          .onChange((value: string) => {
            this.searchKeyword = value;
            this.searchFilesWithInfo();
          })
          .layoutWeight(1)
          .height(40)
          .margin({ right: 10 })
          .padding({ left: 12, right: 12 })
          .backgroundColor($r('app.color.input_background'))
          .border({ width: 1, color: $r('app.color.border_light'), radius: 12 })

        Button('刷新')
          .onClick(() => {
            this.searchFilesWithInfo();
          })
          .height(40)
          .backgroundColor($r('app.color.primary'))
          .fontColor(Color.White)
          .borderRadius(12)
          .shadow({ radius: 10, color: '#143B6EF5', offsetX: 0, offsetY: 4 })
      }
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })
      .backgroundColor($r('app.color.surface'))
      .borderRadius(16)
      .shadow({ radius: 18, color: '#12000000', offsetX: 0, offsetY: 8 })
      .margin({ left: 16, right: 16, top: 8, bottom: 12 })

      // === 成功提示消息 ===
      if (this.showSaveSuccess) {
        Text(this.saveMessage)
          .fontSize(14)
          .fontColor('#FFFFFF')
          .backgroundColor($r('app.color.success'))
          .padding({ left: 16, right: 16, top: 8, bottom: 8 })
          .borderRadius(10)
          .margin({ left: 16, right: 16, bottom: 12 })
          .animation({ duration: 200, curve: Curve.EaseInOut })
      }

      // === 文件列表 ===
      if (this.fileList.length === 0) {
        Column() {
          Text("📁")
            .fontSize(48)
            .margin({ bottom: 10 })
          Text(this.searchKeyword ? '未找到相关文件' : '暂无文件')
            .fontColor($r('app.color.text_muted'))
        }
        .height(200)
        .justifyContent(FlexAlign.Center)
        .width('100%')
      } else {
        List({ space: 8 }) {
          ForEach(this.fileList, (fileInfo: FileInfo) => {
            ListItem() {
              Row() {
                Text(this.getFileIcon(fileInfo.filename))
                  .fontSize(18)
                  .margin({ right: 10 })

                Column() {
                  Text(fileInfo.filename)
                    .fontSize(15)
                    .fontWeight(FontWeight.Medium)
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .width('100%')

                  Row() {
                    Text(fileInfo.sizeReadable)
                      .fontSize(11)
                      .fontColor($r('app.color.text_muted'))
                      .margin({ right: 12 })

                    // Text(fileInfo.ctimeFormatted)
                    //   .fontSize(11)
                    //   .fontColor(Color.Gray)
                  }
                }
                .layoutWeight(1)

                Row() {
                  Button('查看')
                    .onClick(() => {
                      this.openFileActionPanel(fileInfo.filename);
                    })
                    .height(28)
                    .fontSize(11)
                    .margin({ right: 4 })
                    .borderRadius(14)
                    .backgroundColor($r('app.color.primary'))
                    .fontColor(Color.White)

                  Button('删除')
                    .onClick(() => {
                      this.executeDeleteFile(fileInfo.filename);
                    })
                    .height(28)
                    .fontSize(11)
                    .borderRadius(14)
                    .backgroundColor($r('app.color.danger'))
                    .fontColor(Color.White)
                }
              }
              .padding({ left: 12, right: 12, top: 10, bottom: 10 })
              .backgroundColor($r('app.color.surface'))
              .borderRadius(12)
              .border({ width: 1, color: $r('app.color.border_light') })
              .shadow({ radius: 12, color: '#0F000000', offsetX: 0, offsetY: 4 })
              .animation({ duration: 180, curve: Curve.EaseInOut })
            }
          })
        }
        .layoutWeight(1)
        .padding({ left: 16, right: 16 })
      }

      // === 文件操作面板（居中弹出）===
      if (this.showFileActionPanel) {
        Stack()
          .width('100%')
          .height('100%')
          .backgroundColor('rgba(0, 0, 0, 0.5)')
          .onClick(() => {
            this.closeFileActionPanel();
          })
          .position({ x: 0, y: 0 })

        Column() {
          Row() {
            Text('文件操作')
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.text_color'))
              .layoutWeight(1)

            Button('×')
              .fontSize(24)
              .fontColor($r('app.color.text_secondary'))
              .backgroundColor(Color.Transparent)
              .onClick(() => {
                this.closeFileActionPanel();
              })
          }
          .width('100%')
          .padding({ left: 20, right: 20, top: 15, bottom: 15 })
          .border({ width: { bottom: 1 }, color: $r('app.color.border_light') })

          Column({ space: 12 }) {
            Row() {
              Text('文件名:')
                .fontSize(16)
                .fontColor($r('app.color.text_secondary'))
                .width('30%')
              Text(this.selectedFileForPanel)
                .fontSize(16)
                .fontColor($r('app.color.primary'))
                .fontWeight(FontWeight.Bold)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .width('70%')
            }
            .width('100%')
          }
          .width('100%')
          .padding(20)

          Column({ space: 15 }) {
            Button('重命名')
              .fontSize(18)
              .width('90%')
              .height(50)
              .backgroundColor($r('app.color.primary'))
              .fontColor('#FFFFFF')
              .borderRadius(12)
              .shadow({ radius: 10, color: '#143B6EF5', offsetX: 0, offsetY: 4 })
              .onClick(() => {
                this.openRenameDialog(this.selectedFileForPanel);
                this.closeFileActionPanel();
              })

            Button('查看并修改内容')
              .fontSize(18)
              .width('90%')
              .height(50)
              .backgroundColor($r('app.color.success'))
              .fontColor('#FFFFFF')
              .borderRadius(12)
              .shadow({ radius: 10, color: '#141DBE6B', offsetX: 0, offsetY: 4 })
              .onClick(() => {
                this.viewFileContent(this.selectedFileForPanel);
                this.closeFileActionPanel();
              })

            Button('取消')
              .fontSize(18)
              .width('90%')
              .height(50)
              .backgroundColor($r('app.color.surface_alt'))
              .fontColor($r('app.color.text_secondary'))
              .borderRadius(12)
              .border({ width: 1, color: $r('app.color.border_light') })
              .onClick(() => {
                this.closeFileActionPanel();
              })
          }
          .width('100%')
          .padding({ left: 20, right: 20, bottom: 20 })
          .alignItems(HorizontalAlign.Center)
        }
        .width('85%')
        .backgroundColor($r('app.color.surface'))
        .borderRadius(20)
        .shadow({ radius: 24, color: '#24000000', offsetX: 0, offsetY: 12 })
        .position({ x: '7.5%', y: '25%' })
        .hitTestBehavior(HitTestMode.None)
      }

      // === 重命名对话框 ===
      if (this.showRenameDialog) {
        Stack()
          .width('100%')
          .height('100%')
          .backgroundColor('rgba(0, 0, 0, 0.5)')
          .onClick(() => {
            this.closeRenameDialog();
          })

        Column() {
          Row() {
            Text('重命名文件')
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.text_color'))
              .layoutWeight(1)

            Button('×')
              .fontSize(24)
              .fontColor($r('app.color.text_secondary'))
              .backgroundColor(Color.Transparent)
              .onClick(() => {
                this.closeRenameDialog();
              })
          }
          .width('100%')
          .padding({ left: 20, right: 20, top: 15, bottom: 15 })
          .border({ width: { bottom: 1 }, color: $r('app.color.border_light') })

          Column({ space: 15 }) {
            Row() {
              Text('原文件名:')
                .fontSize(16)
                .fontColor($r('app.color.text_secondary'))
                .width('30%')
              Text(this.renamingFile)
                .fontSize(16)
                .fontColor($r('app.color.text_color'))
                .fontWeight(FontWeight.Medium)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .width('70%')
            }
            .width('100%')

            Row() {
              Text('新文件名:')
                .fontSize(16)
                .fontColor($r('app.color.text_secondary'))
                .width('30%')
              TextInput({
                placeholder: '输入新文件名',
                text: this.newFilename
              })
                .onChange((value: string) => {
                  this.newFilename = value;
                })
                .width('70%')
                .height(40)
                .padding(10)
                .backgroundColor($r('app.color.input_background'))
                .border({ width: 1, color: $r('app.color.border_light'), radius: 10 })
            }
            .width('100%')
          }
          .width('100%')
          .padding(20)

          Row({ space: 15 }) {
            Button('取消')
              .fontSize(16)
              .width('45%')
              .height(45)
              .backgroundColor($r('app.color.surface_alt'))
              .fontColor($r('app.color.text_secondary'))
              .borderRadius(12)
              .border({ width: 1, color: $r('app.color.border_light') })
              .onClick(() => {
                this.closeRenameDialog();
              })

            Button('确定')
              .fontSize(16)
              .width('45%')
              .height(45)
              .backgroundColor($r('app.color.primary'))
              .fontColor('#FFFFFF')
              .borderRadius(12)
              .shadow({ radius: 10, color: '#143B6EF5', offsetX: 0, offsetY: 4 })
              .onClick(() => {
                this.executeRename();
              })
          }
          .width('100%')
          .padding({ left: 20, right: 20, bottom: 20 })
        }
        .width('85%')
        .backgroundColor($r('app.color.surface'))
        .borderRadius(20)
        .shadow({ radius: 24, color: '#24000000', offsetX: 0, offsetY: 12 })
        .position({ x: '7.5%', y: '30%' })
        .hitTestBehavior(HitTestMode.None)
      }

      // === 文件内容查看/编辑界面 ===
      if (this.showFileContent && this.selectedFile) {
        Stack()
          .width('100%')
          .height('100%')
          .backgroundColor('rgba(0, 0, 0, 0.5)')
          .onClick(() => {
            this.showFileContent = false;
          })

        Column() {
          Row() {
            Text('编辑文件内容')
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.text_color'))
              .layoutWeight(1)

            Button('×')
              .fontSize(24)
              .fontColor($r('app.color.text_secondary'))
              .backgroundColor(Color.Transparent)
              .onClick(() => {
                this.showFileContent = false;
              })
          }
          .width('100%')
          .padding({ left: 20, right: 20, top: 15, bottom: 15 })
          .border({ width: { bottom: 1 }, color: $r('app.color.border_light') })

          Column({ space: 15 }) {
            Row() {
              Text('文件名:')
                .fontSize(16)
                .fontColor($r('app.color.text_secondary'))
                .width('20%')
              Text(this.selectedFile)
                .fontSize(16)
                .fontColor($r('app.color.primary'))
                .fontWeight(FontWeight.Medium)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .width('80%')
            }
            .width('100%')

            Text('文件内容:')
              .fontSize(16)
              .fontColor($r('app.color.text_secondary'))
              .width('100%')
              .textAlign(TextAlign.Start)

            TextArea({ text: this.fileContent })
              .onChange((value: string) => {
                this.fileContent = value;
              })
              .width('100%')
              .height(300)
              .backgroundColor($r('app.color.surface_alt'))
              .padding(10)
              .border({ width: 1, color: $r('app.color.border_light'), radius: 10 })
          }
          .width('100%')
          .padding(20)

          Row({ space: 15 }) {
            Button('取消')
              .fontSize(16)
              .width('45%')
              .height(45)
              .backgroundColor($r('app.color.surface_alt'))
              .fontColor($r('app.color.text_secondary'))
              .borderRadius(12)
              .border({ width: 1, color: $r('app.color.border_light') })
              .onClick(() => {
                this.showFileContent = false;
              })

            Button('保存修改')
              .fontSize(16)
              .width('45%')
              .height(45)
              .backgroundColor($r('app.color.success'))
              .fontColor('#FFFFFF')
              .borderRadius(12)
              .shadow({ radius: 10, color: '#141DBE6B', offsetX: 0, offsetY: 4 })
              .onClick(() => {
                this.updateFileContent();
              })
          }
          .width('100%')
          .padding({ left: 20, right: 20, bottom: 20 })
        }
        .width('85%')
        .backgroundColor($r('app.color.surface'))
        .borderRadius(20)
        .shadow({ radius: 24, color: '#24000000', offsetX: 0, offsetY: 12 })
        .position({ x: '7.5%', y: '15%' })
        .hitTestBehavior(HitTestMode.None)
      }
    }
    .width('100%')
    .layoutWeight(1)
    .backgroundColor($r('app.color.page_background'))
  }
}

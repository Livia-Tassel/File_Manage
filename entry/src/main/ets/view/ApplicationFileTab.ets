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

import { readFile } from '../common/utils/ReadFile';
import { writeFile } from '../common/utils/WriteFile';

@Component
export struct ApplicationFileTab {
  // Used to record the read content.
  @State message: string = '';
  // Used to record the contents of a text box.
  @State content: string = '';

  // 新增：记录文件名
  @State fileName: string = '';

  build() {
    Column() {
      // === 文件名输入区域 ===
      Column({ space: 10 }) {
        Text('文件名称')
          .fontColor($r('app.color.text_secondary'))
          .fontWeight(500)
          .fontSize($r('app.float.default_16'))
          .fontFamily('HarmonyHeiTi-Medium')
          .textAlign(TextAlign.Start)

        TextInput({ placeholder: '输入文件名（如：myfile.txt）', text: this.fileName })
          .height($r('app.float.default_40'))
          .borderRadius(12)
          .backgroundColor($r('app.color.input_background'))
          .border({ width: 1, color: $r('app.color.border_light'), radius: 12 })
          .padding({ left: 12, right: 12 })
          .onChange((value: string) => {
            this.fileName = value;
          })
      }
      .width('100%')
      .padding(16)
      .backgroundColor($r('app.color.surface'))
      .borderRadius(16)
      .shadow({ radius: 18, color: '#12000000', offsetX: 0, offsetY: 8 })
      .margin({ bottom: 16 })

      Column({ space: 10 }) {
        Text($r('app.string.textarea_default'))
          .fontColor($r('app.color.text_secondary'))
          .fontWeight(500)
          .fontSize($r('app.float.default_16'))
          .fontFamily('HarmonyHeiTi-Medium')
          .textAlign(TextAlign.Start)

        TextArea({ placeholder: '输入文件内容', text: this.content })
          .height($r('app.float.default_139'))
          .borderRadius(16)
          .backgroundColor($r('app.color.input_background'))
          .border({ width: 1, color: $r('app.color.border_light'), radius: 16 })
          .enableKeyboardOnFocus(false)
          .onChange((value: string) => {
            this.content = value
          })
      }
      .width('100%')
      .padding(16)
      .backgroundColor($r('app.color.surface'))
      .borderRadius(16)
      .shadow({ radius: 18, color: '#12000000', offsetX: 0, offsetY: 8 })

      // Text($r('app.string.file_content'))
      //   .width($r('app.float.default_294'))
      //   .height($r('app.float.default_22'))
      //   .fontSize($r('app.float.default_16'))
      //   .lineHeight($r('app.float.default_22'))
      //   .fontWeight(500)
      //   .margin({
      //     top: $r('app.float.default_13'),
      //     bottom: $r('app.float.default_13'),
      //     right: $r('app.float.default_8')
      //   })
      // TextArea({ text: this.message })
      //   .enableKeyboardOnFocus(false)
      //   .width($r('app.float.default_336'))
      //   .height($r('app.float.default_139'))
      //   .backgroundColor($r('app.color.start_window_background'))
      //   .borderRadius($r('app.float.default_24'))

      Column() {
        Button($r('app.string.button1'))
          .width('100%')
          .height($r('app.float.default_40'))
          .fontSize($r('app.float.default_16'))
          .fontWeight(FontWeight.Medium)
          .backgroundColor($r('app.color.primary'))
          .fontColor(Color.White)
          .borderRadius(14)
          .shadow({ radius: 12, color: '#1A3B6EF5', offsetX: 0, offsetY: 6 })
          .animation({ duration: 200, curve: Curve.EaseInOut })
          // Write the information and clear the content so that the text box is cleared after you click Save.
          .onClick(() => {
            writeFile(this.content,this.fileName);
            this.content = '';
            this.fileName='';
          })
        // Button($r('app.string.button2'))
        //   .width($r('app.float.default_312'))
        //   .height($r('app.float.default_40'))
        //   .margin({ top: $r('app.float.default_12'), bottom: $r('app.float.default_100') })
        //   .onClick(() => {
        //     this.message = readFile();
        //   })
      }
      .width('100%')
      .padding({ left: 16, right: 16 })
      .margin({ top: 24 })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 24 })
    .backgroundColor($r('app.color.page_background'))
  }
}

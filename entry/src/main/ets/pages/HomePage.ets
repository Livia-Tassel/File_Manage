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

import { ApplicationFileTab } from '../view/ApplicationFileTab';
import { publicFilesTab } from '../view/PublicFilesTab';
import { DeduplicationTab } from '../view/DeduplicationTab';
import { TrashTab } from '../view/TrashTab';
import { TestDataTab } from '../view/TestDataTab';

@Entry
@Component
struct HomePage {
  build() {
    Column() {
      Column() {
        Text($r('app.string.title'))
          .width('100%')
          .textAlign(TextAlign.Start)
          .fontSize($r('app.float.default_30'))
          .fontFamily('HarmonyHeiTi-Bold')
          .fontColor($r('app.color.text_color'))
          .lineHeight($r('app.float.default_41'))
          .fontWeight(700)
        Text('文件管理与去重')
          .fontSize($r('app.float.default_13'))
          .fontColor($r('app.color.text_muted'))
          .margin({ top: 2 })
      }
      .width('100%')
      .padding({ top: 12, bottom: 12, left: 24, right: 24 })
      .backgroundColor($r('app.color.surface'))
      .borderRadius(16)
      .shadow({ radius: 16, color: '#14000000', offsetX: 0, offsetY: 6 })
      .margin({ left: 16, right: 16, bottom: 12 })

      Tabs() {
        TabContent() {
          ApplicationFileTab()
        }
        .height('100%')
        .tabBar(new SubTabBarStyle($r('app.string.bar1'))
          .indicator({ marginTop: $r('app.float.default_8') })
          .labelStyle({ font: { size: $r('app.float.default_16') } })
        )

        TabContent() {
          Scroll() {
            publicFilesTab()
          }
          .height($r('app.float.default_680'))
        }
        .height('100%')
        .tabBar(new SubTabBarStyle($r('app.string.bar2'))
          .indicator({marginTop : $r('app.float.default_8')})
          .labelStyle({font : {size : $r('app.float.default_16')}})
        )

        TabContent() {
          Scroll() {
            DeduplicationTab()
          }
          .height($r('app.float.default_680'))
        }
        .height('100%')
        .tabBar(new SubTabBarStyle($r('app.string.bar3'))
          .indicator({marginTop : $r('app.float.default_8')})
          .labelStyle({font : {size : $r('app.float.default_16')}})
        )

        TabContent() {
          Scroll() {
            TrashTab()
          }
          .height($r('app.float.default_680'))
        }
        .height('100%')
        .tabBar(new SubTabBarStyle($r('app.string.bar4'))
          .indicator({marginTop : $r('app.float.default_8')})
          .labelStyle({font : {size : $r('app.float.default_16')}})
        )

        TabContent() {
          Scroll() {
            TestDataTab()
          }
          .height($r('app.float.default_680'))
        }
        .height('100%')
        .tabBar(new SubTabBarStyle($r('app.string.bar5'))
          .indicator({marginTop : $r('app.float.default_8')})
          .labelStyle({font : {size : $r('app.float.default_16')}})
        )
      }
      .barWidth($r('app.float.default_360'))
      .barHeight($r('app.float.default_56'))
      .width('100%')
      .barBackgroundColor($r('app.color.surface'))
    }
    .backgroundColor($r('app.color.page_background'))
    .justifyContent(FlexAlign.Start)
    .width('100%')
    .padding({ top: $r('app.float.default_24') })
  }
}

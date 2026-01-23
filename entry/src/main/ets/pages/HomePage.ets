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

import { DocumentLibraryTab } from '../view/DocumentLibraryTab';
import { AnalysisTab } from '../view/AnalysisTab';
import { SearchTab } from '../view/SearchTab';
import { SettingsTab } from '../view/SettingsTab';
import { TestDataTab } from '../view/TestDataTab';

// 初始化文件变更标志
AppStorage.setOrCreate('fileChangeFlag', 0);

@Entry
@Component
struct HomePage {
  @State currentIndex: number = 0;

  build() {
    Column() {
      // 标题栏
      Column() {
        Text('智能文档助手')
          .width('100%')
          .height(41)
          .textAlign(TextAlign.Start)
          .fontSize(24)
          .fontFamily('HarmonyHeiTi-Bold')
          .fontColor('#333333')
          .fontWeight(700)
          .padding({ left: 24 })
      }
      .width('100%')
      .height(56)

      // 主内容区
      Tabs({ barPosition: BarPosition.End, index: this.currentIndex }) {
        TabContent() {
          DocumentLibraryTab()
        }
        .tabBar(this.TabBuilder(0, '文档库', $r('sys.media.ohos_ic_public_copy')))

        TabContent() {
          AnalysisTab()
        }
        .tabBar(this.TabBuilder(1, '分析', $r('sys.media.ohos_ic_public_scan')))

        TabContent() {
          SearchTab()
        }
        .tabBar(this.TabBuilder(2, '搜索', $r('sys.media.ohos_ic_public_search_filled')))

        TabContent() {
          TestDataTab()
        }
        .tabBar(this.TabBuilder(3, '测试', $r('sys.media.ohos_ic_public_add')))

        TabContent() {
          SettingsTab()
        }
        .tabBar(this.TabBuilder(4, '设置', $r('sys.media.ohos_ic_public_more')))
      }
      .barWidth('100%')
      .barHeight(56)
      .width('100%')
      .layoutWeight(1)
      .onChange((index: number) => {
        this.currentIndex = index;
      })
    }
    .backgroundColor('#F5F5F5')
    .width('100%')
    .height('100%')
    .padding({ top: 48 })
  }

  @Builder
  TabBuilder(index: number, title: string, icon: Resource) {
    Column() {
      Image(icon)
        .width(24)
        .height(24)
        .fillColor(this.currentIndex === index ? '#007AFF' : '#999999')
      Text(title)
        .fontSize(10)
        .fontColor(this.currentIndex === index ? '#007AFF' : '#999999')
        .margin({ top: 4 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}
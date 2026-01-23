/*
 * 测试数据生成器 - 批量生成测试用txt文件
 */

import { fileIo } from '@kit.CoreFileKit';
import { common } from '@kit.AbilityKit';

// 生成配置
export interface GeneratorConfig {
  fileCount: number;        // 文件总数
  minSize: number;          // 最小文件大小(bytes)
  maxSize: number;          // 最大文件大小(bytes)
  minDuplicateRate: number; // 最小重复率(0-100)
  maxDuplicateRate: number; // 最大重复率(0-100)
}

// 生成结果
export interface GeneratorResult {
  totalFiles: number;       // 生成的文件总数
  uniqueFiles: number;      // 唯一文件数
  duplicateFiles: number;   // 重复文件数
  duplicateGroups: number;  // 重复组数
  totalSize: number;        // 总大小
  success: boolean;
  message: string;
}

// 文档模板
interface DocTemplate {
  title: string;
  content: string;
}

// 相似文档
interface SimilarDoc {
  filename: string;
  content: string;
}

export class TestDataGenerator {
  private context: Context;
  private filesDir: string;
  private static instance: TestDataGenerator | null = null;

  constructor(context: Context) {
    this.context = context;
    const uiAbilityContext = context as common.UIAbilityContext;
    this.filesDir = uiAbilityContext.filesDir;
  }

  static getInstance(context: Context): TestDataGenerator {
    if (!TestDataGenerator.instance) {
      TestDataGenerator.instance = new TestDataGenerator(context);
    }
    return TestDataGenerator.instance;
  }

  /**
   * 生成随机字符串内容
   */
  private generateRandomContent(size: number): string {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789 \n';
    let content = '';
    for (let i = 0; i < size; i++) {
      content += chars.charAt(Math.floor(Math.random() * chars.length));
    }
    return content;
  }

  /**
   * 生成指定范围内的随机数
   */
  private randomInRange(min: number, max: number): number {
    return Math.floor(Math.random() * (max - min + 1)) + min;
  }

  /**
   * 生成随机文件名
   */
  private generateRandomFilename(length: number = 8): string {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    let name = '';
    for (let i = 0; i < length; i++) {
      name += chars.charAt(Math.floor(Math.random() * chars.length));
    }
    return name;
  }

  /**
   * 生成测试文件
   */
  generateTestFiles(config: GeneratorConfig): GeneratorResult {
    try {
      console.log(`开始生成测试文件，配置: ${JSON.stringify(config)}`);

      // 计算实际重复率（在范围内随机）
      const actualDuplicateRate = this.randomInRange(config.minDuplicateRate, config.maxDuplicateRate) / 100;

      // 计算重复文件数和唯一文件数
      const duplicateFileCount = Math.floor(config.fileCount * actualDuplicateRate);
      const uniqueFileCount = config.fileCount - duplicateFileCount;

      // 计算重复组数（每组至少2个文件）
      // 重复文件分成若干组，每组2-5个文件
      let remainingDuplicates = duplicateFileCount;
      const duplicateGroups: string[] = []; // 存储每组的内容模板

      while (remainingDuplicates > 0) {
        // 每组2-5个文件
        const groupSize = Math.min(this.randomInRange(2, 5), remainingDuplicates);
        if (groupSize < 2 && remainingDuplicates >= 2) {
          continue;
        }
        if (groupSize < 2) {
          break;
        }

        // 为这组生成一个内容模板
        const contentSize = this.randomInRange(config.minSize, config.maxSize);
        const content = this.generateRandomContent(contentSize);

        // 添加groupSize次相同内容
        for (let i = 0; i < groupSize; i++) {
          duplicateGroups.push(content);
        }

        remainingDuplicates -= groupSize;
      }

      // 生成唯一文件的内容
      const uniqueContents: string[] = [];
      for (let i = 0; i < uniqueFileCount; i++) {
        const contentSize = this.randomInRange(config.minSize, config.maxSize);
        uniqueContents.push(this.generateRandomContent(contentSize));
      }

      // 合并所有内容并打乱顺序
      const allContents: string[] = [];
      for (const content of duplicateGroups) {
        allContents.push(content);
      }
      for (const content of uniqueContents) {
        allContents.push(content);
      }

      // Fisher-Yates 洗牌算法
      for (let i = allContents.length - 1; i > 0; i--) {
        const j = Math.floor(Math.random() * (i + 1));
        const temp = allContents[i];
        allContents[i] = allContents[j];
        allContents[j] = temp;
      }

      // 写入文件
      let totalSize = 0;
      const usedFilenames: string[] = []; // 记录已使用的文件名，避免重复

      for (let i = 0; i < allContents.length; i++) {
        // 生成唯一的随机文件名
        let filename = '';
        do {
          filename = `${this.generateRandomFilename(10)}.txt`;
        } while (usedFilenames.indexOf(filename) >= 0);
        usedFilenames.push(filename);

        const filePath = `${this.filesDir}/${filename}`;
        const content = allContents[i];

        try {
          const stream = fileIo.createStreamSync(filePath, 'w+');
          stream.writeSync(content);
          stream.closeSync();
          totalSize += content.length;
        } catch (writeError) {
          console.error(`写入文件失败 ${filename}: ${writeError}`);
        }
      }

      // 计算实际生成的重复组数
      const contentSet = new Set<string>();
      let actualDuplicateGroups = 0;
      const contentCount: Map<string, number> = new Map();

      for (const content of allContents) {
        const count = contentCount.get(content) || 0;
        contentCount.set(content, count + 1);
      }

      contentCount.forEach((count: number) => {
        if (count > 1) {
          actualDuplicateGroups++;
        }
      });

      const result: GeneratorResult = {
        totalFiles: allContents.length,
        uniqueFiles: uniqueFileCount,
        duplicateFiles: duplicateGroups.length,
        duplicateGroups: actualDuplicateGroups,
        totalSize: totalSize,
        success: true,
        message: `成功生成 ${allContents.length} 个测试文件`
      };

      console.log(`生成完成: ${JSON.stringify(result)}`);
      return result;

    } catch (error) {
      console.error(`生成测试文件失败: ${error}`);
      return {
        totalFiles: 0,
        uniqueFiles: 0,
        duplicateFiles: 0,
        duplicateGroups: 0,
        totalSize: 0,
        success: false,
        message: `生成失败: ${error}`
      };
    }
  }

  /**
   * 清空所有txt文件
   */
  clearTestFiles(): number {
    try {
      const files = fileIo.listFileSync(this.filesDir);
      let deletedCount = 0;

      for (const file of files) {
        // 清空所有txt文件（排除隐藏文件）
        if (!file.startsWith('.') && file.endsWith('.txt')) {
          try {
            const filePath = `${this.filesDir}/${file}`;
            fileIo.unlinkSync(filePath);
            deletedCount++;
          } catch (e) {
            console.warn(`删除文件失败: ${file}`);
          }
        }
      }

      console.log(`已清空 ${deletedCount} 个txt文件`);
      return deletedCount;
    } catch (error) {
      console.error(`清空文件失败: ${error}`);
      return 0;
    }
  }

  /**
   * 获取当前txt文件数量
   */
  getTestFileCount(): number {
    try {
      const files = fileIo.listFileSync(this.filesDir);
      let count = 0;
      for (const file of files) {
        if (!file.startsWith('.') && file.endsWith('.txt')) {
          count++;
        }
      }
      return count;
    } catch (error) {
      return 0;
    }
  }

  /**
   * 生成智能文档测试数据集
   * 包含三类文档：会议纪要、学习笔记、项目报告
   */
  generateSmartDocuments(): GeneratorResult {
    try {
      console.log('开始生成智能文档测试数据集');

      const meetingDocs = this.getMeetingTemplates();
      const notesDocs = this.getNotesTemplates();
      const reportDocs = this.getReportTemplates();

      let totalFiles = 0;
      let totalSize = 0;

      // 生成会议纪要
      for (let i = 0; i < meetingDocs.length; i++) {
        const doc = meetingDocs[i];
        const filename = `会议纪要_${i + 1}_${doc.title}.txt`;
        const filePath = `${this.filesDir}/${filename}`;
        try {
          const stream = fileIo.createStreamSync(filePath, 'w+');
          stream.writeSync(doc.content);
          stream.closeSync();
          totalFiles++;
          totalSize += doc.content.length;
        } catch (e) {
          console.warn(`写入文件失败: ${filename}`);
        }
      }

      // 生成学习笔记
      for (let i = 0; i < notesDocs.length; i++) {
        const doc = notesDocs[i];
        const filename = `学习笔记_${i + 1}_${doc.title}.txt`;
        const filePath = `${this.filesDir}/${filename}`;
        try {
          const stream = fileIo.createStreamSync(filePath, 'w+');
          stream.writeSync(doc.content);
          stream.closeSync();
          totalFiles++;
          totalSize += doc.content.length;
        } catch (e) {
          console.warn(`写入文件失败: ${filename}`);
        }
      }

      // 生成项目报告
      for (let i = 0; i < reportDocs.length; i++) {
        const doc = reportDocs[i];
        const filename = `项目报告_${i + 1}_${doc.title}.txt`;
        const filePath = `${this.filesDir}/${filename}`;
        try {
          const stream = fileIo.createStreamSync(filePath, 'w+');
          stream.writeSync(doc.content);
          stream.closeSync();
          totalFiles++;
          totalSize += doc.content.length;
        } catch (e) {
          console.warn(`写入文件失败: ${filename}`);
        }
      }

      // 生成一些相似文档用于测试重复检测
      const similarDocs = this.getSimilarDocuments();
      for (let i = 0; i < similarDocs.length; i++) {
        const doc = similarDocs[i];
        const filename = doc.filename;
        const filePath = `${this.filesDir}/${filename}`;
        try {
          const stream = fileIo.createStreamSync(filePath, 'w+');
          stream.writeSync(doc.content);
          stream.closeSync();
          totalFiles++;
          totalSize += doc.content.length;
        } catch (e) {
          console.warn(`写入文件失败: ${filename}`);
        }
      }

      return {
        totalFiles: totalFiles,
        uniqueFiles: totalFiles - 4,
        duplicateFiles: 4,
        duplicateGroups: 2,
        totalSize: totalSize,
        success: true,
        message: `成功生成 ${totalFiles} 个智能文档测试文件`
      };
    } catch (error) {
      console.error(`生成智能文档失败: ${error}`);
      return {
        totalFiles: 0,
        uniqueFiles: 0,
        duplicateFiles: 0,
        duplicateGroups: 0,
        totalSize: 0,
        success: false,
        message: `生成失败: ${error}`
      };
    }
  }

  private getMeetingTemplates(): DocTemplate[] {
    const templates: DocTemplate[] = [];
    const t1: DocTemplate = {
      title: '产品需求评审',
      content: `会议纪要：产品需求评审会议

会议时间：2025年1月15日 14:00-16:00
会议地点：3楼会议室A
参会人员：张经理、李工程师、王设计师、陈产品经理

会议议题：
1. 新版本功能需求讨论
2. 用户反馈问题分析
3. 下一阶段开发计划

会议内容：
一、新版本功能需求
陈产品经理介绍了用户调研结果，主要需求包括：
- 文档智能分类功能
- 全文搜索优化
- 批量操作支持

二、用户反馈问题
李工程师汇报了近期用户反馈的主要问题：
- 大文件处理速度慢
- 界面响应不够流畅
- 部分功能入口不明显

三、开发计划
经讨论决定：
1. 优先解决性能问题
2. 下周完成智能分类原型
3. 两周后进行内部测试

决议事项：
1. 李工程师负责性能优化，预计3天完成
2. 王设计师重新设计功能入口，本周五提交设计稿
3. 下周三召开进度同步会议

会议记录人：张助理`
    };
    templates.push(t1);

    const t2: DocTemplate = {
      title: '周例会',
      content: `会议纪要：研发部周例会

会议时间：2025年1月20日 10:00-11:30
会议地点：线上会议
参会人员：研发部全体成员

本周工作总结：
1. 完成文档解析模块开发
2. 修复了5个线上bug
3. 代码review完成率95%

下周工作计划：
1. 开始智能分析功能开发
2. 进行性能压力测试
3. 准备版本发布

风险提示：
- 第三方API接口可能有变更
- 需要协调测试资源

会议决议：
1. 加强与第三方的沟通
2. 提前预约测试环境`
    };
    templates.push(t2);

    const t3: DocTemplate = {
      title: '技术方案评审',
      content: `会议纪要：智能分析技术方案评审

会议时间：2025年1月18日 15:00-17:00
参会人员：技术委员会成员

评审内容：
一、方案概述
本次评审的是文档智能分析功能的技术方案，主要包括：
- 文档分类算法选型
- API调用架构设计
- 缓存策略设计

二、技术讨论
1. 分类算法：决定采用DeepSeek API进行语义分析
2. 架构设计：采用异步处理+本地缓存的方式
3. 性能优化：使用Worker多线程处理

三、评审结论
方案整体可行，建议：
1. 增加降级策略
2. 完善错误处理
3. 添加使用量监控

评审结果：通过`
    };
    templates.push(t3);

    return templates;
  }

  private getNotesTemplates(): DocTemplate[] {
    const templates: DocTemplate[] = [];

    const n1: DocTemplate = {
      title: 'TypeScript基础',
      content: `学习笔记：TypeScript基础知识

学习日期：2025年1月12日
学习时长：3小时

一、TypeScript简介
TypeScript是JavaScript的超集，添加了类型系统和其他特性。
主要优势：
- 静态类型检查
- 更好的IDE支持
- 面向对象编程支持

二、基本类型
1. 原始类型：string, number, boolean
2. 数组类型：number[]
3. 元组类型
4. 枚举类型

学习心得：
TypeScript的类型系统非常强大，能够在编译时发现很多潜在问题。`
    };
    templates.push(n1);

    const n2: DocTemplate = {
      title: 'HarmonyOS开发入门',
      content: `学习笔记：HarmonyOS应用开发入门

学习日期：2025年1月14日
参考资料：HarmonyOS官方文档

一、开发环境搭建
1. 安装DevEco Studio
2. 配置SDK
3. 创建第一个项目

二、ArkTS语言特点
ArkTS是HarmonyOS的开发语言，基于TypeScript扩展。
主要特点：
- 声明式UI
- 状态管理
- 组件化开发

知识点总结：
1. ArkTS与TypeScript语法相似但有限制
2. 声明式UI简化了界面开发
3. 状态驱动视图更新`
    };
    templates.push(n2);

    const n3: DocTemplate = {
      title: '算法学习笔记',
      content: `学习笔记：常用算法复习

学习日期：2025年1月16日

一、排序算法
1. 冒泡排序
2. 快速排序
3. 归并排序

二、查找算法
1. 二分查找
2. 哈希查找

复习心得：
算法的核心是理解思想，而不是死记代码。
多做练习题有助于加深理解。`
    };
    templates.push(n3);

    return templates;
  }

  private getReportTemplates(): DocTemplate[] {
    const templates: DocTemplate[] = [];

    const r1: DocTemplate = {
      title: '月度进度报告',
      content: `项目报告：智能文档助手1月进度报告

报告日期：2025年1月25日
报告人：项目组

一、项目概况
项目名称：智能文档助手
当前阶段：开发阶段
整体进度：60%

二、本月完成工作
1. 基础架构搭建 - 100%
2. 核心功能开发 - 80%
3. UI界面开发 - 40%

三、存在问题
1. 大文件处理性能需优化
2. API调用成本需要控制

四、下月计划
1. 完成剩余UI开发
2. 进行全面测试
3. 性能优化

项目风险：低`
    };
    templates.push(r1);

    const r2: DocTemplate = {
      title: '技术调研报告',
      content: `项目报告：文档智能分析技术调研

报告日期：2025年1月8日
调研人：技术组

一、调研背景
为实现文档智能分析功能，需要选择合适的技术方案。

二、调研范围
1. 大语言模型API
2. 本地NLP方案
3. 混合方案

三、调研结论
推荐采用DeepSeek API为主、本地规则为辅的混合方案。

四、实施建议
1. 优先接入DeepSeek API
2. 实现本地降级方案
3. 添加结果缓存机制`
    };
    templates.push(r2);

    const r3: DocTemplate = {
      title: '测试报告',
      content: `项目报告：智能文档助手测试报告

报告日期：2025年1月24日
测试人员：测试组

一、测试概述
测试版本：v0.1.0
测试环境：HarmonyOS 5.0模拟器

二、测试范围
1. 功能测试
2. 性能测试
3. 兼容性测试

三、测试结果
功能测试：通过
性能测试：通过
兼容性测试：通过

四、测试结论
整体功能正常，建议修复发现的问题后发布。`
    };
    templates.push(r3);

    return templates;
  }

  private getSimilarDocuments(): SimilarDoc[] {
    const docs: SimilarDoc[] = [];
    const baseContent = `这是一份测试文档，用于验证重复检测功能。
文档包含一些通用的文本内容，可以用来测试系统的去重能力。
智能文档助手能够识别内容相似的文档，帮助用户清理冗余文件。`;

    const d1: SimilarDoc = {
      filename: '测试文档_副本1.txt',
      content: baseContent
    };
    docs.push(d1);

    const d2: SimilarDoc = {
      filename: '测试文档_副本2.txt',
      content: baseContent
    };
    docs.push(d2);

    const weeklyContent = `项目周报 - 第一周
本周完成了基础功能开发，下周计划进行测试。
团队成员工作积极，项目进展顺利。`;

    const d3: SimilarDoc = {
      filename: '相似文档_版本A.txt',
      content: weeklyContent
    };
    docs.push(d3);

    const d4: SimilarDoc = {
      filename: '相似文档_版本B.txt',
      content: weeklyContent
    };
    docs.push(d4);

    return docs;
  }
}

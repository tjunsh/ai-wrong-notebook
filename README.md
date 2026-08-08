# AI错题本 (AI Wrong Notebook)

一款面向学生的智能错题管理应用，把拍题、解析、保存、追问和练习串成完整学习闭环。

## 功能特性

### 核心功能
- **拍照录题** - 使用相机或相册快速录入错题，支持框选裁剪
- **AI 视觉分析** - AI 直接分析错题图片，识别科目、题干、答案、关键步骤、错因和知识点
- **连续扫题与排队解析** - 当前题解析中仍可继续拍题；任务在后台按顺序处理，避免并发请求和重复消耗
- **多题逐题解析** - 一张图片中的独立题目分别解析、分别保存，避免不同题目的答案和知识点混在一起
- **失败题单独重试** - 多题中某一题失败时，已成功题保持不变；可在原结果页只重试失败题
- **保存或放弃** - 解析后可选择保存到错题本或直接放弃；部分成功时只允许保存已经解析成功的题目
- **AI 自动打标** - 自动生成短标签（如"压强"、"力学"）和详细知识点
- **AI 追问** - 在已保存错题详情中继续提问，追问记录随题目保存
- **举一反三** - 根据错题生成针对性练习，完成一轮后可继续生成新题
- **间隔复习** - 基于记忆曲线安排复习计划
- **学习统计** - 掌握进度可视化（柱状图 + 统计卡片）

### v1.0.5 更新
- **严格任务队列** - 连续扫描多张图片时，AI 请求按顺序执行；用户可以离开解析页继续录题，不会并发消耗多个请求。
- **多题结果可补全** - 部分成功的扫描结果保留在同一张任务卡中，失败题可逐题重试，不会产生重复任务或重复解析成功题。
- **结果更可控** - 未保存的扫描结果可直接放弃；保存时会过滤失败题，并在部分成功时要求确认。
- **配置向导优化** - 可选择服务商预设自动填写 Base URL，获取可用模型后选择模型，并在保存前测试连接；仍支持自定义 OpenAI 兼容接口。
- **本地任务维护** - 支持导出失败日志、清理历史任务和一键清空本地题库及排队任务。

### 用户界面
- Material Design 3 设计语言
- 支持浅色模式 / 深色模式 / 跟随系统
- 流畅的页面切换动画

## 技术栈

| 分类 | 技术 |
|------|------|
| 框架 | Flutter 3.4+ |
| 状态管理 | Riverpod |
| 路由 | GoRouter |
| 本地数据库 | Drift (SQLite) |
| 轻量存储 | SharedPreferences |
| 网络请求 | Dio |
| 主题方案 | flex_color_scheme |
| 图表 | fl_chart |
| AI 服务 | 兼容 OpenAI 格式 API 的多模态模型 |
| 图片选择 | image_picker |
| 图片裁剪 | image_cropper |
| 数据导入导出 | share_plus + file_picker |
| 本地通知 | flutter_local_notifications |
| 安全存储 | flutter_secure_storage |
| 序列化 | json_annotation + json_serializable |
| ID 生成 | uuid |
| 国际化 | intl |

## 项目结构

```
lib/
├── app/                  # 应用入口、路由、主题
├── common/widgets/       # 通用组件
├── data/                 # 数据层
│   ├── files/           # 文件存储
│   ├── remote/ai/       # AI 分析服务
│   ├── repositories/    # 数据仓库（Drift + SharedPreferences）
│   └── services/        # 服务（拍照、存储、通知等）
├── domain/models/       # 领域模型
└── features/           # 功能模块
    ├── analysis/        # AI 分析（加载 + 结果展示）
    ├── capture/         # 拍照录题（裁剪、预览）
    ├── exercise/        # 举一反三练习
    ├── home/            # 首页
    ├── notebook/        # 错题本（列表 + 详情）
    ├── onboarding/      # 引导页
    ├── review/          # 间隔复习
    └── settings/        # 设置（AI配置、数据管理）
```

## 开发

### 环境要求
- Flutter SDK >= 3.4.0
- Android SDK

### 安装依赖
```bash
flutter pub get
```

### 运行
```bash
flutter run
```

### 构建 APK
```bash
flutter build apk --release
```

发布构建需要在本地创建并妥善保管 `android/key.properties` 和签名 keystore；两者均已被 Git 忽略，不应提交到仓库。

### 测试
```bash
flutter test
```

## AI 服务配置

应用支持配置任意 OpenAI 兼容格式的 AI 服务。用于拍照识题的模型必须支持 Vision/图片输入：

1. 进入「设置」→「AI 服务商配置」，选择服务商预设或「自定义」。
2. 预设会自动填写 Base URL；填写 API Key 后可获取模型列表并选择模型。自定义服务可手动填写 Base URL 和模型名称。
3. 点击「保存并测试」，连接通过后即可使用。

不同服务商的模型能力和稳定性不同，请以实际的图片识题测试结果为准。

## 鸣谢

感谢 [Dohoya.com](https://www.dohoya.com/sign-up?aff=hiUV)  
感谢 [Vbcode.io](https://vbcode.io/sign-up?aff=lEmu)

对 AI错题本项目的大模型 API 支持。 
本项目的 AI 视觉分析能力基于兼容 OpenAI API 格式的多模态模型，用户可在应用内自行配置 API 地址、API Key 和模型名称。

> 本项目不内置 API Key，也不绑定特定服务商；<br>
> [dohoya.com]和[vbcode.io] 为推荐的大模型 API 服务提供方之一。


## APP 截图
<table>
  <tr>
    <td width="50%"><img width="100%" alt="首页截图" src="https://github.com/user-attachments/assets/e2e6fdd6-4ed8-42c9-b69c-57eaa30d2faa" /></td>
    <td width="50%"><img width="100%" alt="AI 服务配置截图" src="https://github.com/user-attachments/assets/6c4b6d0d-5d11-4d08-86eb-969013aa18c2" /></td>
  </tr>
  <tr>
    <td width="50%"><img width="100%" alt="错题分析截图" src="https://github.com/user-attachments/assets/68a6c5ce-32dc-428d-af4f-b48f98d5eafc" /></td>
    <td width="50%"><img width="100%" alt="练习复习截图" src="https://github.com/user-attachments/assets/3f31dd6d-cd96-4bcf-934a-e183b937b0f5" /></td>
  </tr>
</table>

## Star History

<a href="https://www.star-history.com/?repos=tjunsh%2Fai-wrong-notebook&type=date&legend=bottom-right">
 <picture>
   <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/chart?repos=tjunsh/ai-wrong-notebook&type=date&theme=dark&legend=bottom-right&sealed_token=KDfa2h6bUXcCadImEO8vHVPGcCJ_pYYRhg9RyoYvNz1OBuKyl2n53kGB3jWQVU7xd52vpbefDpATCgJkYjEEjkjdEnj7nxX4UnHtYIs5-pYfsumMWIq3K_zg3IgPfZ41IQlTEdETGSgAko3SrO2akGkBalQTyWhwOxsWpAy10shTEbF0AxUOXW389KWh" />
   <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/chart?repos=tjunsh/ai-wrong-notebook&type=date&legend=bottom-right&sealed_token=KDfa2h6bUXcCadImEO8vHVPGcCJ_pYYRhg9RyoYvNz1OBuKyl2n53kGB3jWQVU7xd52vpbefDpATCgJkYjEEjkjdEnj7nxX4UnHtYIs5-pYfsumMWIq3K_zg3IgPfZ41IQlTEdETGSgAko3SrO2akGkBalQTyWhwOxsWpAy10shTEbF0AxUOXW389KWh" />
   <img alt="Star History Chart" src="https://api.star-history.com/chart?repos=tjunsh/ai-wrong-notebook&type=date&legend=bottom-right&sealed_token=KDfa2h6bUXcCadImEO8vHVPGcCJ_pYYRhg9RyoYvNz1OBuKyl2n53kGB3jWQVU7xd52vpbefDpATCgJkYjEEjkjdEnj7nxX4UnHtYIs5-pYfsumMWIq3K_zg3IgPfZ41IQlTEdETGSgAko3SrO2akGkBalQTyWhwOxsWpAy10shTEbF0AxUOXW389KWh" />
 </picture>
</a>

## License

MIT

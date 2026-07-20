# AI错题本 (AI Wrong Notebook)

一款面向学生的智能错题管理应用，支持拍照录题、AI 视觉分析、举一反三练习和间隔复习。

## 功能特性

### 核心功能
- **拍照录题** - 使用相机或相册快速录入错题，支持框选裁剪
- **AI 视觉分析** - AI 直接分析错题图片，自动识别科目、生成解题步骤、分析错因
- **AI 自动打标** - 自动生成短标签（如"压强"、"力学"）和详细知识点
- **举一反三** - 根据错题生成针对性的选择题练习
- **间隔复习** - 基于记忆曲线安排复习计划
- **学习统计** - 掌握进度可视化（柱状图 + 统计卡片）

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
| AI 服务 | 兼容 OpenAI 格式 API（支持 Vision 模型，如 GPT5.4，GPT-4o 等）|
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

### 测试
```bash
flutter test
```

## AI 服务配置

应用支持配置任意 OpenAI 兼容格式的 AI 服务（需支持 Vision/图片输入）：

1. 进入「设置」→「AI 服务商配置」
2. 填写 API 地址、API Key、模型名称
3. 保存后即可使用

支持 DeepSeek、OpenAI、OpenRouter 等服务商。

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

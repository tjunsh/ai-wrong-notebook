# 智能错题本 (Smart Wrong Notebook)

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
- 浅色模式
- 流畅的页面切换动画

## 技术栈

- **框架**: Flutter 3.4+
- **状态管理**: Riverpod
- **路由**: GoRouter
- **本地存储**: Drift (SQLite)
- **AI 服务**: 兼容 OpenAI 格式 API（支持 Vision 模型，如 DeepSeek、GPT-4o 等）
- **图片裁剪**: image_cropper
- **图片选择**: image_picker

## 项目结构

```
lib/
├── app/                  # 应用入口、路由、主题
├── common/widgets/       # 通用组件
├── data/                 # 数据层
│   ├── files/           # 文件存储
│   ├── remote/ai/       # AI 分析服务
│   ├── repositories/    # 数据仓库（Drift）
│   └── services/        # 服务（拍照、存储等）
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

## License

MIT

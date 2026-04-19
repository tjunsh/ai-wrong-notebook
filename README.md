# 智能错题本 (Smart Wrong Notebook)

一款面向学生的智能错题管理应用，支持拍照录题、AI 分析、举一反三练习和间隔复习。

## 功能特性

### 核心功能
- **拍照录题** - 使用相机或相册快速录入错题
- **文字识别 (OCR)** - 自动识别图片中的文字
- **AI 智能分析** - DeepSeek 分析错因，生成解题步骤和学习建议
- **举一反三** - 根据错题生成针对性的练习题
- **间隔复习** - 基于记忆曲线安排复习计划

### 用户界面
- Material Design 3 设计语言
- 支持浅色/深色模式
- 流畅的页面切换动画

## 技术栈

- **框架**: Flutter 3.4+
- **状态管理**: Riverpod
- **路由**: GoRouter
- **本地存储**: Drift (SQLite)
- **AI 服务**: 兼容 OpenAI 格式 API (DeepSeek 等)

## 项目结构

```
lib/
├── app/                  # 应用入口、路由、主题
├── common/widgets/       # 通用组件
├── data/                 # 数据层
│   ├── files/           # 文件存储
│   ├── remote/          # 远程 API
│   ├── repositories/    # 数据仓库
│   └── services/        # 服务
├── domain/models/       # 领域模型
└── features/           # 功能模块
    ├── analysis/        # AI 分析
    ├── capture/         # 拍照录题
    ├── home/            # 首页
    ├── notebook/        # 错题本
    ├── onboarding/      # 引导页
    ├── ocr/             # 文字识别
    ├── review/          # 复习
    └── settings/        # 设置
```

## 开发

### 环境要求
- Flutter SDK >= 3.4.0
- Android SDK
- iOS (可选)

### 安装依赖
```bash
flutter pub get
```

### 运行
```bash
# 开发模式
flutter run

# 构建 APK
flutter build apk --debug

# 构建发布版
flutter build apk --release
```

### 测试
```bash
flutter test
```

### 生成代码
```bash
# Drift 数据库代码
dart run build_runner build --delete-conflicting-outputs
```

## AI 服务配置

应用支持配置自定义 AI 服务商（如 DeepSeek）：

1. 进入「设置」→「AI 服务商配置」
2. 填写 API 地址和密钥
3. 保存后即可使用

支持 OpenAI 兼容格式的 API。

## 版本

当前版本: 1.0.0

## License

MIT

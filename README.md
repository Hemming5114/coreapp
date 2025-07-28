# 音乐搭子 - 演唱会社交应用

一个专为音乐爱好者设计的社交应用，可以寻找演唱会搭子、分享音乐瞬间、聊天交流。

## 功能特性

### 🎵 主要功能
- **寻找搭子**: 发布演唱会信息，寻找志同道合的伙伴
- **分享动态**: 分享参加演唱会的精彩瞬间
- **即时聊天**: 与搭子进行实时聊天交流
- **AI助手**: 集成智谱AI，提供智能服务

### 🚀 技术特性
- **Flutter跨平台**: 支持iOS和Android
- **智谱AI集成**: 使用GLM-4-Flash模型
- **安全存储**: API密钥安全存储
- **权限管理**: 完善的网络权限处理
- **优雅UI**: 现代化的用户界面设计

## 项目结构

```
lib/
├── main.dart              # 应用入口
├── services/
│   └── api_service.dart   # API服务类
└── screens/
    ├── splash_screen.dart # 启动页
    └── home_screen.dart   # 主页面
```

## 安装和运行

### 环境要求
- Flutter SDK >= 3.7.0
- Dart >= 3.7.0
- iOS 12.0+ / Android 5.0+

### 安装步骤

1. **克隆项目**
```bash
git clone <repository-url>
cd coreapp
```

2. **安装依赖**
```bash
flutter pub get
```

3. **运行应用**
```bash
# iOS
flutter run -d ios

# Android
flutter run -d android
```

## 配置说明

### API配置
应用使用智谱AI的GLM-4-Flash模型，API密钥已配置在`lib/services/api_service.dart`中：

```dart
static const String _apiKey = '842370724dfa455487f16b1898f77ff8.XiwJjovFzYO0GKPO';
```

### 权限配置
iOS权限已在`ios/Runner/Info.plist`中配置：
- 位置权限
- 网络访问权限

## 启动页功能

启动页(`SplashScreen`)包含以下功能：

1. **启动图片显示**: 使用`assets/images/appicon/bg_login.webp`
2. **网络权限请求**: 自动请求必要的网络权限
3. **API连接测试**: 测试智谱AI服务连接
4. **API密钥存储**: 安全存储API密钥
5. **优雅动画**: 淡入动画效果

## 主页面结构

主页面采用底部导航栏设计，包含四个主要模块：

1. **动态页面**: 显示音乐相关动态
2. **找搭子页面**: 寻找演唱会伙伴
3. **聊天页面**: 即时通讯功能
4. **我的页面**: 个人资料管理

## 开发说明

### 依赖包
- `http`: 网络请求
- `permission_handler`: 权限管理
- `cached_network_image`: 图片缓存
- `flutter_secure_storage`: 安全存储
- `shared_preferences`: 本地存储

### 代码规范
- 遵循Flutter官方代码规范
- 使用Material Design 3
- 支持中文界面
- 完善的错误处理

## 注意事项

1. **网络权限**: 首次启动会请求网络权限
2. **API限制**: 注意智谱AI的API调用限制
3. **图片资源**: 确保启动图片路径正确
4. **iOS配置**: 需要配置相应的权限描述

## 更新日志

### v1.0.0
- 初始版本发布
- 实现启动页功能
- 集成智谱AI服务
- 基础页面框架搭建

## 许可证

本项目采用MIT许可证，详见LICENSE文件。

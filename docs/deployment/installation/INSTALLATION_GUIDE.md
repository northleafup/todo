# 🛠️ 开发环境安装指南

## 🍎 Xcode 安装

### 方法一：通过 App Store（推荐）

1. **打开 App Store**
2. **搜索 "Xcode"**
3. **选择版本**：
   - ✅ **推荐**: 最新稳定版（当前 Xcode 15.x 或 16.x）
   - ⚠️ **最低要求**: Xcode 14.0
   - 📦 **大小**: 约 10-15GB

4. **点击"获取"开始安装**
5. **等待下载完成**（可能需要 30-60 分钟，取决于网络速度）

### 方法二：通过 Apple Developer 网站

1. 访问 https://developer.apple.com/xcode/
2. 登录 Apple Developer 账号
3. 下载 Xcode
4. 双击 `.xip` 文件解压
5. 将 Xcode 移动到 `/Applications/` 目录

### 安装后配置

```bash
# 设置 Xcode 路径
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer

# 接受许可协议
sudo xcodebuild -license

# 验证安装
xcodebuild -version
```

## 🤖 Android Studio 安装

### 当前状态：正在自动安装中 📥

我正在通过 Homebrew 为你安装 Android Studio，这将包含：
- Android Studio IDE
- Android SDK
- Android SDK Platform-Tools
- Android SDK Build-Tools

### 手动安装（如果自动安装失败）

1. **访问官方网站**：https://developer.android.com/studio
2. **下载 Mac 版本**
3. **安装步骤**：
   ```bash
   # 下载后挂载 DMG 文件
   # 将 Android Studio 拖拽到 Applications 文件夹
   # 启动 Android Studio
   ```

### Android Studio 初始配置

首次启动 Android Studio 时：

1. **选择 "Standard" 安装类型**
2. **选择 UI 主题**（推荐 Darla）
3. **等待 SDK 下载完成**
4. **创建或导入项目**

### 环境变量配置

Android Studio 安装完成后，需要配置环境变量：

```bash
# 添加到 ~/.zshrc 或 ~/.bash_profile
export ANDROID_HOME=$HOME/Library/Android/sdk
export ANDROID_SDK_ROOT=$ANDROID_HOME
export PATH=$PATH:$ANDROID_HOME/emulator
export PATH=$PATH:$ANDROID_HOME/tools
export PATH=$PATH:$ANDROID_HOME/tools/bin
export PATH=$PATH:$ANDROID_HOME/platform-tools
```

## 🔄 验证安装

安装完成后，运行以下命令验证：

```bash
# 检查 Flutter 环境
flutter doctor -v

# 预期输出：
# ✓ Flutter (Channel stable)
# ✓ Android toolchain (develop for Android devices)
# ✓ Xcode (develop for iOS and macOS)
```

## ⚡ 快速构建测试

环境配置完成后，测试构建：

```bash
# 启动交互式构建脚本
./build_interactive.sh

# 选择选项 6 检查环境
# 然后选择 1、2 或 3 构建对应平台
```

## 🆘 常见问题

### Xcode 相关

**问题**: "xcodebuild requires Xcode"
**解决**:
```bash
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
```

**问题**: "Command Line Tools not working"
**解决**:
```bash
sudo xcode-select --install
```

### Android SDK 相关

**问题**: "ANDROID_HOME not found"
**解决**:
```bash
export ANDROID_HOME=$HOME/Library/Android/sdk
echo 'export ANDROID_HOME=$HOME/Library/Android/sdk' >> ~/.zshrc
```

**问题**: "Android licenses not accepted"
**解决**:
```bash
flutter doctor --android-licenses
```

## 📞 安装进度

当前状态：
- ✅ Xcode Command Line Tools: 已安装
- 📥 Android Studio: 正在下载中...
- ⏳ Xcode 完整版: 需要通过 App Store 安装

## 🎯 下一步

1. **完成 Xcode 安装**（通过 App Store）
2. **等待 Android Studio 安装完成**
3. **运行环境检查**：`./build_interactive.sh` 选项 6
4. **测试构建**：选择要构建的平台

---

**💡 提示**: 这些工具体积较大，安装可能需要一些时间。安装完成后，你就可以构建所有平台的安装包了！
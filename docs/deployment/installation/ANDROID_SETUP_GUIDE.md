# 🤖 Android Studio 配置详细指南

## 📋 概述
本指南将详细说明如何配置Android Studio，以便在macOS上构建和测试Android应用。

## 🚀 开始配置

### 第一步：启动 Android Studio

```bash
# 方法1：通过命令行启动
open "/Applications/Android Studio.app"

# 方法2：通过 Finder 启动
# 1. 打开 Finder
# 2. 进入 "应用程序" 文件夹
# 3. 双击 "Android Studio.app"
```

---

## 🎯 首次启动配置向导

### 1. 欢迎界面
- **出现**: "Welcome to Android Studio" 欢迎界面
- **操作**: 点击 "Next" 继续

### 2. 安装类型选择
- **界面**: "Install Type" 选择界面
- **选项**:
  - 📦 **Standard** - 标准安装（推荐）
  - 🎛️ **Custom** - 自定义安装（高级用户）
- **选择**: ✅ **选择 "Standard"**
- **原因**:
  - 自动安装所需的 Android SDK
  - 自动设置 Android Virtual Device
  - 自动下载最新的系统镜像
- **操作**: 点击 "Next"

### 3. 主题选择
- **界面**: UI Theme 选择界面
- **选项**:
  - 🌙 **Light** - 浅色主题
  - 🌚 **Darla** - 深色主题（推荐）
- **选择**: 根据个人喜好选择
- **操作**: 点击 "Next"

### 4. 验证设置
- **界面**: "Verify Settings" 确认界面
- **信息**: 显示即将安装的组件列表
- **组件包括**:
  - Android SDK
  - Android SDK Platform-Tools
  - Android SDK Command-line Tools
  - Android Virtual Device
  - Performance (Intel® HAXM)
- **操作**: 点击 "Finish" 开始下载和安装

---

## ⏳ 下载和安装过程

### 下载阶段
- **时间**: 15-60分钟（取决于网络速度）
- **大小**: 约 2-3GB
- **进度条**: 会在底部显示下载进度
- **提示**: 确保网络连接稳定

### 安装阶段
- **时间**: 5-10分钟
- **状态**: 显示 "Installing components..."
- **组件**: 自动安装所有必要的开发工具

### 完成提示
- **出现**: "Installation complete" 消息
- **操作**: 点击 "Finish"

---

## 🎯 创建 Android 虚拟设备 (AVD)

### 方法一：通过欢迎界面创建

1. **打开设备管理器**
   - 在 Android Studio 欢迎界面
   - 点击 **"More Actions"** → **"Virtual Device Manager"**
   - 或者点击 **"Device Manager"** 按钮

2. **创建新设备**
   - 点击 **"Create Device"** 按钮
   - 进入设备配置向导

### 方法二：通过菜单创建

1. **打开设备管理器**
   - 菜单栏: **Tools** → **Device Manager**
   - 或者快捷键: **Shift + Cmd + A**，然后搜索 "Device Manager"

2. **创建新设备**
   - 点击 **"Create Virtual Device"** 按钮

---

## 📱 设备配置步骤

### 1. 选择硬件设备

#### 推荐设备选项：
- 📱 **Pixel 6** - 现代Android设备，性能良好
- 📱 **Pixel 7** - 最新版本，功能完整
- 📱 **Pixel 5** - 较旧但稳定
- 📱 **Nexus 6** - 经典设备，兼容性好

#### 操作步骤：
1. 在左侧选择 **"Phone"** 类别
2. 选择推荐设备之一（如 Pixel 6）
3. 点击 **"Next"**

#### 设备规格（以Pixel 6为例）：
- **屏幕尺寸**: 6.4英寸
- **分辨率**: 1080 x 2400
- **内存**: 8GB
- **存储**: 128GB
- **处理器**: Google Tensor

### 2. 选择系统镜像

#### 推荐系统版本：
- 🤖 **Android 13.0 (Tiramisu)** - 最新稳定版（推荐）
- 🤖 **Android 12.0 (S)** - 广泛支持
- 🤖 **Android 11.0 (R)** - 兼容性好

#### 操作步骤：
1. 在右侧选择 **"Recommended"** 标签
2. 选择 **"Android 13.0"** 或其他推荐版本
3. 点击 **"Next"**

#### 如果没有下载镜像：
- 点击 **"Download"** 链接
- 等待下载完成（约1GB）
- 选择下载完成的镜像

### 3. 配置 AVD 设置

#### 基本设置：
- **AVD Name**: `Pixel_6_API_33`（自动生成）
- **Advanced Settings**: 可选配置

#### 高级设置（可选）：
1. **启动方向**: Portrait（竖屏）或 Landscape（横屏）
2. **内存**: 保持默认（推荐）
3. **内部存储**: 6000MB（推荐）
4. **SD 卡**: 可选
5. **图形渲染**: Auto（推荐）

#### 操作：
1. **选择 "Portrait"（竖屏）**
2. **确保内存设置为 4096MB 或以上**
3. **点击 "Finish"**

---

## 🚀 启动和测试模拟器

### 1. 启动模拟器

#### 方法一：通过设备管理器
- 在 Device Manager 中找到刚创建的设备
- 点击设备右侧的 **"▶️"** 播放按钮

#### 方法二：通过命令行
```bash
# 查看可用模拟器
flutter emulators

# 启动特定模拟器
flutter emulators --launch Pixel_6_API_33
```

### 2. 模拟器启动过程

- **启动时间**: 30秒 - 2分钟
- **首次启动**: 可能需要更长时间（系统初始化）
- **出现界面**: Android 桌面界面

### 3. 验证模拟器工作

#### 检查设备连接：
```bash
flutter devices
```

#### 预期输出：
```
Found 2 connected devices:
  macOS (desktop) • macos • darwin-x64 • macOS 13.7.8 22H730 darwin-x64
  Android (mobile) • emulator-5554 • android-x86    • Android 13.0 (API 33) (emulator)
```

---

## 🛠️ 在 Android Studio 中测试

### 1. 打开项目
```bash
# 在项目根目录运行
open -a "Android Studio" .
```

### 2. 同步项目
- Android Studio 会自动检测 Flutter 项目
- 等待 Gradle 同步完成
- 出现 "Sync Completed" 提示

### 3. 选择目标设备
- 在工具栏的设备选择器中
- 选择你创建的模拟器（如 "emulator-5554"）

### 4. 运行应用
- 点击绿色的 **"▶️ Run"** 按钮
- 或者使用快捷键 **Ctrl + R**

---

## 🔧 故障排除

### 常见问题和解决方案

#### 1. 模拟器启动失败
**问题**: "Unable to locate ADB"
**解决**:
```bash
# 检查环境变量
echo $ANDROID_HOME

# 手动设置（如果需要）
export ANDROID_HOME=$HOME/Library/Android/sdk
export PATH=$PATH:$ANDROID_HOME/platform-tools
```

#### 2. 模拟器运行缓慢
**原因**: 默认配置可能不够优化
**解决**:
- 在 AVD 设置中增加内存（推荐 4096MB+）
- 启用硬件加速（HAXM）
- 选择 x86_64 镜像而不是 ARM 镜像

#### 3. 下载速度慢
**解决**:
- 检查网络连接
- 使用 VPN（如果需要）
- 在深夜等网络较好的时间段下载

#### 4. Gradle 同步失败
**解决**:
```bash
# 清理 Gradle 缓存
./gradlew clean

# 重新同步项目
# 在 Android Studio 中点击 "Sync Project with Gradle Files"
```

---

## ✅ 完成验证

### 验证步骤清单

完成配置后，运行以下命令验证：

```bash
# 1. 检查 Flutter 环境
flutter doctor

# 2. 查看可用设备
flutter devices

# 3. 检查模拟器列表
flutter emulators

# 4. 运行我们的构建脚本
./build_interactive.sh
# 选择选项 3: 🤖 Android 应用
```

### 成功标志
- ✅ `flutter devices` 显示 Android 设备
- ✅ 模拟器可以正常启动
- ✅ Flutter 应用可以在模拟器中运行
- ✅ APK 构建成功

---

## 📞 技术支持

如果遇到问题：

1. **查看详细日志**:
   ```bash
   flutter doctor -v
   ```

2. **检查 Android Studio 日志**:
   - 菜单: Help → Show Log in Explorer

3. **重新配置**:
   ```bash
   # 删除配置重新开始
   rm -rf ~/.android
   # 重新启动 Android Studio 配置
   ```

4. **使用我们的工具**:
   ```bash
   ./check_environment.sh  # 环境检查
   ./setup_android_env.sh   # 自动配置
   ```

---

## ⏱️ 预计时间总结

- **Android Studio 首次配置**: 30-60分钟
- **创建虚拟设备**: 5-15分钟
- **下载系统镜像**: 10-20分钟
- **模拟器首次启动**: 1-2分钟
- **总计**: 约 1-2小时

**耐心等待，一次配置，永久使用！** 🎯

---

## 🎉 配置完成后的使用

配置完成后，你就可以：

1. **在macOS上测试Android应用**
2. **使用 `./build_interactive.sh` 构建APK**
3. **在模拟器中运行和调试**
4. **创建包含卸载功能的完整安装包**

**恭喜！你将在macOS上拥有完整的Android开发和测试环境！** 🚀
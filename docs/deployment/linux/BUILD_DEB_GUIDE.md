# Linux DEB 包构建指南

## 📋 前置要求

### 1. 安装构建依赖

```bash
# 安装必要的开发包
sudo apt update
sudo apt install -y \
    pkg-config \
    libgtk-3-dev \
    libsecret-1-dev \
    libjsoncpp-dev \
    cmake \
    clang \
    ninja-build \
    libx11-dev \
    libglib2.0-dev \
    libpango1.0-dev \
    libatk1.0-dev \
    libcairo-gobject2 \
    libgdk-pixbuf2.0-dev \
    libgraphene-1.0-dev
```

### 2. 或者使用提供的脚本

```bash
# 运行依赖安装脚本
./scripts/setup/install_linux_deps.sh
```

## 🔨 构建步骤

### 方法1: 使用自动化脚本

```bash
# 运行构建脚本
./scripts/build/build_linux_deb.sh
```

### 方法2: 手动构建

```bash
# 1. 进入源代码目录
cd src

# 2. 获取 Flutter 依赖
flutter pub get

# 3. 构建 Linux 应用
flutter build linux --release

# 4. 手动创建 DEB 包
# 参考下面的手动打包步骤
```

## 📦 手动打包步骤

如果自动化脚本失败，可以按以下步骤手动创建 DEB 包：

```bash
# 1. 设置变量
APP_NAME="todo_app"
APP_VERSION="1.0.0"
PACKAGE_NAME="todo-app"
BUILD_DIR="outputs/linux"
DEB_BUILD_DIR="$BUILD_DIR/deb"

# 2. 进入源代码目录
cd src

# 3. 构建 Flutter 应用
flutter build linux --release

# 4. 创建 DEB 包结构
mkdir -p "$DEB_BUILD_DIR/DEBIAN"
mkdir -p "$DEB_BUILD_DIR/usr/bin"
mkdir -p "$DEB_BUILD_DIR/usr/share/applications"
mkdir -p "$DEB_BUILD_DIR/opt/$APP_NAME"

# 5. 复制应用文件
cp -r build/linux/x64/release/bundle/* "$DEB_BUILD_DIR/opt/$APP_NAME/"

# 6. 创建启动脚本
cat > "$DEB_BUILD_DIR/usr/bin/$APP_NAME" << 'EOF'
#!/bin/bash
cd /opt/todo_app
./todo_app
EOF
chmod +x "$DEB_BUILD_DIR/usr/bin/$APP_NAME"

# 7. 创建桌面文件
cat > "$DEB_BUILD_DIR/usr/share/applications/$APP_NAME.desktop" << 'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Todo App
Comment=一个简洁的跨平台Todo应用
Exec=todo_app
Icon=todo_app
Categories=Office;Productivity;
Terminal=false
EOF

# 8. 创建控制文件
cat > "$DEB_BUILD_DIR/DEBIAN/control" << 'EOF'
Package: todo-app
Version: 1.0.0
Section: office
Priority: optional
Architecture: amd64
Depends: libgtk-3-0, libjsoncpp25, libsecret-1-0
Maintainer: Todo App Developer
Description: 一个简洁的跨平台Todo应用
 一个功能丰富的Todo应用，支持任务管理、提醒和同步。
 适用于Linux桌面环境。
EOF

# 9. 构建 DEB 包
cd "$BUILD_DIR"
dpkg-deb --build deb "todo-app-1.0.0-amd64.deb"
```

## 🚀 安装和卸载

### 安装

```bash
# 使用 dpkg 安装
sudo dpkg -i outputs/linux/todo-app-1.0.0-amd64.deb

# 如果有依赖问题，运行:
sudo apt-get install -f
```

### 卸载

```bash
# 卸载应用
sudo dpkg -r todo-app

# 完全删除（包括配置文件）
sudo dpkg -P todo-app
```

## 🐛 故障排除

### 1. Flutter 构建失败

**错误**: `A required package was not found`
**解决**: 确保安装了 `libsecret-1-dev`

```bash
sudo apt install libsecret-1-dev
```

### 2. 应用无法启动

**可能原因**: 权限问题或依赖缺失
**解决**: 检查应用权限和安装状态

```bash
# 检查权限
ls -la /opt/todo_app/
ls -la /usr/bin/todo_app

# 检查依赖
ldd /opt/todo_app/todo_app
```

### 3. 桌面图标不显示

**解决**: 更新桌面数据库

```bash
update-desktop-database ~/.local/share/applications/
```

## 📊 构建输出

成功构建后，DEB 包将位于：

```
outputs/linux/
├── todo-app-1.0.0-amd64.deb    # 主安装包
└── deb/                        # 临时构建目录
```

## 🔍 验证安装

```bash
# 检查是否已安装
dpkg -l | grep todo-app

# 检查应用位置
which todo_app

# 检查应用版本
todo_app --version
```

## 📝 更多信息

- Flutter Linux 部署: https://flutter.dev/docs/deployment/linux
- Debian 打包指南: https://www.debian.org/doc/manuals/debian-faq/ch-pkg-basics.html
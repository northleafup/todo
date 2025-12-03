#!/bin/bash

# Beautiful Todo 跨平台安装包构建脚本
# 支持: macOS, Linux, Windows, Android (不包括Web)

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 配置
APP_NAME="Beautiful Todo"
VERSION="1.0.0"
BUILD_DIR="builds"
PACKAGE_DIR="packages"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# 创建目录
setup_directories() {
    log_info "创建构建目录..."
    mkdir -p "$PROJECT_ROOT/$BUILD_DIR"
    mkdir -p "$PROJECT_ROOT/$PACKAGE_DIR"
    mkdir -p "$PROJECT_ROOT/$BUILD_DIR/macos"
    mkdir -p "$PROJECT_ROOT/$BUILD_DIR/linux"
    mkdir -p "$PROJECT_ROOT/$BUILD_DIR/windows"
    mkdir -p "$PROJECT_ROOT/$BUILD_DIR/apk"
}

# 检查依赖
check_dependencies() {
    log_info "检查构建依赖..."

    # 检查Flutter
    if ! command -v flutter &> /dev/null; then
        log_error "Flutter 未安装或不在 PATH 中"
        exit 1
    fi

    log_info "Flutter 版本: $(flutter --version | head -1)"

    # 检查项目依赖
    log_info "检查项目依赖..."
    cd "$PROJECT_ROOT"

    # 运行 pub get
    flutter pub get

    # 检查Flutter配置 (不包含Web)
    flutter config --enable-linux-desktop --enable-macos-desktop --enable-windows-desktop 2>/dev/null || true
}


# 构建 macOS 版本
build_macos() {
    log_info "构建 macOS 版本..."
    cd "$PROJECT_ROOT"

    # 检查 macOS 工具链
    if ! command -v xcodebuild &> /dev/null; then
        log_warning "Xcode 未安装，跳过 macOS 构建"
        return
    fi

    # 构建
    flutter build macos \
        --release

    # 复制构建文件
    cp -r build/macos/Build/Products/Release/beautiful_todo.app "$PROJECT_ROOT/$BUILD_DIR/macos/" 2>/dev/null || {
        # 尝试其他可能的路径
        find build -name "*.app" -type d -exec cp -r {} "$PROJECT_ROOT/$BUILD_DIR/macos/" \; 2>/dev/null || true
    }

    # 创建 macOS 安装包目录
    MACOS_PACKAGE_DIR="$PROJECT_ROOT/$PACKAGE_DIR/macos"
    mkdir -p "$MACOS_PACKAGE_DIR"

    # 创建 DMG（如果有 create-dmg）
    if command -v create-dmg &> /dev/null; then
        cd "$PROJECT_ROOT/$BUILD_DIR/macos"
        if [ -d "beautiful_todo.app" ]; then
            create-dmg \
                --volname "$APP_NAME" \
                --window-pos 200 120 \
                --window-size 800 600 \
                --icon-size 100 \
                --icon "beautiful_todo.app" 200 190 \
                --hide-extension "beautiful_todo.app" \
                --app-drop-link 600 185 \
                "../../$PACKAGE_DIR/macos/beautiful-todo-macos-$VERSION.dmg"
        fi
    else
        log_warning "create-dmg 未安装，跳过 DMG 创建"
    fi

    log_success "macOS 版本构建完成"
}

# 构建 Linux 版本
build_linux() {
    log_info "构建 Linux 版本..."
    cd "$PROJECT_ROOT"

    # 构建
    flutter build linux \
        --release

    # 复制构建文件
    cp -r build/linux/*/release/bundle/* "$PROJECT_ROOT/$BUILD_DIR/linux/" 2>/dev/null || {
        # 尝试其他可能的路径
        find build/linux -name "bundle" -type d -exec cp -r {}/* "$PROJECT_ROOT/$BUILD_DIR/linux/" \; 2>/dev/null || true
    }

    # 创建 Linux 安装包目录
    LINUX_PACKAGE_DIR="$PROJECT_ROOT/$PACKAGE_DIR/linux"
    mkdir -p "$LINUX_PACKAGE_DIR"

    # 创建 AppImage（如果有 appimagetool）
    if command -v appimagetool &> /dev/null && [ -f "$PROJECT_ROOT/$BUILD_DIR/linux/beautiful_todo" ]; then
        mkdir -p "$PROJECT_ROOT/$BUILD_DIR/linux/beautiful_todo.AppDir/usr/bin"
        mkdir -p "$PROJECT_ROOT/$BUILD_DIR/linux/beautiful_todo.AppDir/usr/share/applications"

        # 复制可执行文件
        cp "$PROJECT_ROOT/$BUILD_DIR/linux/beautiful_todo" "$PROJECT_ROOT/$BUILD_DIR/linux/beautiful_todo.AppDir/usr/bin/"

        # 创建 desktop 文件
        cat > "$PROJECT_ROOT/$BUILD_DIR/linux/beautiful_todo.AppDir/beautiful_todo.desktop" << EOF
[Desktop Entry]
Type=Application
Name=Beautiful Todo
Exec=/usr/bin/beautiful_todo
Icon=beautiful_todo
Categories=Office;Productivity;
EOF

        cp "$PROJECT_ROOT/$BUILD_DIR/linux/beautiful_todo.AppDir/beautiful_todo.desktop" \
           "$PROJECT_ROOT/$BUILD_DIR/linux/beautiful_todo.AppDir/usr/share/applications/"

        # 创建 AppRun
        cat > "$PROJECT_ROOT/$BUILD_DIR/linux/beautiful_todo.AppDir/AppRun" << 'EOF'
#!/bin/sh
HERE="$(dirname "$(readlink -f "${0}")")"
export PATH="${HERE}/usr/bin/:${HERE}/usr/sbin/:${HERE}/usr/games/:${HERE}/bin/:${HERE}/sbin/${PATH:+:$PATH}"
exec "${HERE}/usr/bin/beautiful_todo" "$@"
EOF
        chmod +x "$PROJECT_ROOT/$BUILD_DIR/linux/beautiful_todo.AppDir/AppRun"

        # 创建 AppImage
        cd "$PROJECT_ROOT/$BUILD_DIR/linux"
        appimagetool "beautiful_todo.AppDir" "../../$PACKAGE_DIR/linux/beautiful-todo-linux-$VERSION.AppImage"
    else
        log_warning "appimagetool 未安装或找不到可执行文件，跳过 AppImage 创建"
    fi

    # 创建 tar.gz 包
    cd "$PROJECT_ROOT/$BUILD_DIR/linux"
    if [ "$(ls -A .)" ]; then
        tar -czf "../../$PACKAGE_DIR/linux/beautiful-todo-linux-$VERSION.tar.gz" *
    fi

    log_success "Linux 版本构建完成"
}

# 构建 Windows 版本
build_windows() {
    log_info "构建 Windows 版本..."
    cd "$PROJECT_ROOT"

    # 构建
    flutter build windows \
        --release

    # 复制构建文件
    cp -r build/windows/runner/Release/* "$PROJECT_ROOT/$BUILD_DIR/windows/" 2>/dev/null || {
        # 尝试其他可能的路径
        find build/windows -name "Release" -type d -exec cp -r {}/* "$PROJECT_ROOT/$BUILD_DIR/windows/" \; 2>/dev/null || true
    }

    # 创建 Windows 安装包目录
    WINDOWS_PACKAGE_DIR="$PROJECT_ROOT/$PACKAGE_DIR/windows"
    mkdir -p "$WINDOWS_PACKAGE_DIR"

    # 创建 ZIP 包
    cd "$PROJECT_ROOT/$BUILD_DIR/windows"
    if [ "$(ls -A .)" ]; then
        zip -r "../../$PACKAGE_DIR/windows/beautiful-todo-windows-$VERSION.zip" *
    fi

    log_success "Windows 版本构建完成"
}

# 构建 Android APK
build_android() {
    log_info "构建 Android APK..."
    cd "$PROJECT_ROOT"

    # 检查 Android 工具链
    if ! flutter doctor --android-licenses &> /dev/null; then
        log_warning "Android SDK 未配置，跳过 Android 构建"
        return
    fi

    # 构建 APK
    flutter build apk \
        --release \
        --target-platform android-arm64

    # 复制构建文件
    cp build/app/outputs/flutter-apk/app-release.apk "$PROJECT_ROOT/$BUILD_DIR/apk/beautiful-todo-android.apk" 2>/dev/null || {
        find build -name "*release.apk" -exec cp {} "$PROJECT_ROOT/$BUILD_DIR/apk/beautiful-todo-android.apk" \;
    }

    # 创建 Android 安装包目录
    ANDROID_PACKAGE_DIR="$PROJECT_ROOT/$PACKAGE_DIR/android"
    mkdir -p "$ANDROID_PACKAGE_DIR"

    # 复制 APK
    cp "$PROJECT_ROOT/$BUILD_DIR/apk/beautiful-todo-android.apk" "$ANDROID_PACKAGE_DIR/"

    log_success "Android APK 构建完成"
}

# 复制安装脚本
copy_installer_scripts() {
    log_info "复制安装脚本..."

    # 创建脚本目录
    mkdir -p "$PROJECT_ROOT/$PACKAGE_DIR/scripts"

    # 复制卸载脚本
    cp "$SCRIPT_DIR/uninstaller.sh" "$PROJECT_ROOT/$PACKAGE_DIR/scripts/"
    chmod +x "$PROJECT_ROOT/$PACKAGE_DIR/scripts/uninstaller.sh"

    # 创建安装说明
    cat > "$PROJECT_ROOT/$PACKAGE_DIR/README.md" << 'EOF'
# Beautiful Todo 安装包

## 平台支持

- **macOS**: 支持 Intel 芯片 macOS 13.6+ 系统
- **Linux**: 支持 Ubuntu 22.04 及其他主流发行版
- **Windows**: 支持 Windows 10/11
- **Android**: 支持小米 14 HyperOS 3 及其他 Android 设备

## 安装说明

### macOS 版本
1. 下载 `beautiful-todo-macos-*.dmg` 文件
2. 双击 DMG 文件打开安装器
3. 将应用拖拽到 Applications 文件夹

### Linux 版本
1. 下载 `beautiful-todo-linux-*.AppImage` 文件
2. 添加执行权限: `chmod +x beautiful-todo-linux-*.AppImage`
3. 双击运行或在终端执行: `./beautiful-todo-linux-*.AppImage`

### Windows 版本
1. 下载 `beautiful-todo-windows-*.zip` 文件
2. 解压到目标目录
3. 双击 `beautiful_todo.exe` 运行

### Android 版本
1. 下载 `beautiful-todo-android.apk` 文件
2. 在 Android 设备上安装 APK
3. 授予必要的权限

## 卸载

使用 `scripts/uninstaller.sh` 脚本进行卸载：

```bash
chmod +x scripts/uninstaller.sh
./scripts/uninstaller.sh
```

## 功能特性

- ✅ 任务管理和分类
- ✅ 高级筛选和排序
- ✅ 任务模板和快捷操作
- ✅ 跨平台云同步（坚果云）
- ✅ 任务提醒和通知
- ✅ Material Design 3 主题
- ✅ 数据导入导出
- ✅ 跨平台支持

## 技术栈

- Flutter 3.38.3
- Riverpod 状态管理
- SQLite 本地存储
- Material Design 3

## 系统要求

- **macOS**: Intel 芯片，macOS 13.6+
- **Linux**: Ubuntu 22.04+, 或其他支持 GTK3 的发行版
- **Windows**: Windows 10 1903+ (x64)
- **Android**: Android 5.0+ (API 21+)

## 支持

如有问题，请查看项目文档或提交 Issue。
EOF

    log_success "安装脚本和说明文档复制完成"
}

# 生成构建报告
generate_build_report() {
    log_info "生成构建报告..."

    REPORT_FILE="$PROJECT_ROOT/$PACKAGE_DIR/build-report-$VERSION.md"

    cat > "$REPORT_FILE" << EOF
# Beautiful Todo 构建报告

**版本**: $VERSION
**构建时间**: $(date)
**构建平台**: $(uname -s) $(uname -r)

## 构建结果

| 平台 | 状态 | 文件 |
|------|------|------|
EOF

    
    if [ -f "$PROJECT_ROOT/$PACKAGE_DIR/macos/beautiful-todo-macos-$VERSION.dmg" ]; then
        echo "| macOS | ✅ 成功 | beautiful-todo-macos-$VERSION.dmg |" >> "$REPORT_FILE"
    elif [ -d "$PROJECT_ROOT/$BUILD_DIR/macos" ] && [ "$(ls -A "$PROJECT_ROOT/$BUILD_DIR/macos")" ]; then
        echo "| macOS | ⚠️ 部分成功 | 可执行文件已生成 |" >> "$REPORT_FILE"
    else
        echo "| macOS | ❌ 失败 | - |" >> "$REPORT_FILE"
    fi

    if [ -f "$PROJECT_ROOT/$PACKAGE_DIR/linux/beautiful-todo-linux-$VERSION.AppImage" ]; then
        echo "| Linux | ✅ 成功 | beautiful-todo-linux-$VERSION.AppImage |" >> "$REPORT_FILE"
    elif [ -f "$PROJECT_ROOT/$PACKAGE_DIR/linux/beautiful-todo-linux-$VERSION.tar.gz" ]; then
        echo "| Linux | ⚠️ 部分成功 | beautiful-todo-linux-$VERSION.tar.gz |" >> "$REPORT_FILE"
    else
        echo "| Linux | ❌ 失败 | - |" >> "$REPORT_FILE"
    fi

    if [ -f "$PROJECT_ROOT/$PACKAGE_DIR/windows/beautiful-todo-windows-$VERSION.zip" ]; then
        echo "| Windows | ✅ 成功 | beautiful-todo-windows-$VERSION.zip |" >> "$REPORT_FILE"
    else
        echo "| Windows | ❌ 失败 | - |" >> "$REPORT_FILE"
    fi

    if [ -f "$PROJECT_ROOT/$PACKAGE_DIR/android/beautiful-todo-android.apk" ]; then
        echo "| Android | ✅ 成功 | beautiful-todo-android.apk |" >> "$REPORT_FILE"
    else
        echo "| Android | ❌ 失败 | - |" >> "$REPORT_FILE"
    fi

    cat >> "$REPORT_FILE" << EOF

## 文件大小

EOF

    # 显示文件大小
    for platform in macos linux windows android; do
        platform_dir="$PROJECT_ROOT/$PACKAGE_DIR/$platform"
        if [ -d "$platform_dir" ]; then
            echo "### $platform" >> "$REPORT_FILE"
            du -sh "$platform_dir"/* >> "$REPORT_FILE" 2>/dev/null || echo "- 无文件" >> "$REPORT_FILE"
            echo "" >> "$REPORT_FILE"
        fi
    done

    log_success "构建报告生成完成: $REPORT_FILE"
}

# 主函数
main() {
    clear
    echo "=============================================="
    echo "    Beautiful Todo 跨平台构建脚本"
    echo "=============================================="
    echo ""

    log_info "开始构建 $APP_NAME v$VERSION"
    echo ""

    # 设置目录
    setup_directories

    # 检查依赖
    check_dependencies

    echo ""
    log_info "开始构建各平台版本..."
    echo ""

    # 构建各平台（按优先级）
    build_macos
    build_linux
    build_android
    build_windows

    # 复制安装脚本
    copy_installer_scripts

    # 生成构建报告
    generate_build_report

    echo ""
    echo "=============================================="
    log_success "构建完成！"
    echo ""
    echo "📦 构建文件位置: $PROJECT_ROOT/$PACKAGE_DIR"
    echo "📊 构建报告: $PROJECT_ROOT/$PACKAGE_DIR/build-report-$VERSION.md"
    echo "🧹 卸载脚本: $PROJECT_ROOT/$PACKAGE_DIR/scripts/uninstaller.sh"
    echo ""
    echo "安装包已生成，请查看 $PACKAGE_DIR 目录"
    echo "=============================================="
}

# 检查是否以root权限运行
if [[ $EUID -eq 0 ]]; then
    log_warning "检测到以root权限运行，请谨慎操作"
fi

# 执行主函数
main "$@"
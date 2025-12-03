#!/bin/bash

# 🏗️ 美丽的待办事项 - 完整环境检查工具
# 检查所有开发环境的配置状态和可用性

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
NC='\033[0m'

# 应用信息
APP_NAME="美丽的待办事项"
VERSION="1.0.0"

# 状态标志
OVERALL_STATUS=true

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[⚠]${NC} $1"
    OVERALL_STATUS=false
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
    OVERALL_STATUS=false
}

log_section() {
    echo -e "${MAGENTA}[$1]${NC} $2"
}

# 显示标题
show_header() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}                  ${WHITE}🔍 环境检查工具${NC}                    ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}              ${APP_NAME} v${VERSION} 构建环境检查              ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# 检查系统信息
check_system_info() {
    log_section "系统" "检查系统信息"
    echo "操作系统: $(uname -s)"
    echo "系统版本: $(sw_vers -productVersion 2>/dev/null || uname -r)"
    echo "系统架构: $(uname -m)"
    echo "用户名: $(whoami)"
    echo "当前目录: $(pwd)"
    echo ""
}

# 检查 Flutter 环境
check_flutter() {
    log_section "Flutter" "检查 Flutter 环境"

    if command -v flutter &> /dev/null; then
        local flutter_version=$(flutter --version 2>/dev/null)
        log_success "Flutter 已安装"
        echo "$flutter_version" | head -n 3

        # 检查 Flutter 支持的平台
        echo ""
        echo "支持的平台:"
        flutter devices 2>/dev/null | grep -E "(macos|linux|android)" | while read line; do
            echo "  $line"
        done || echo "  无法获取设备列表"

    else
        log_error "Flutter 未安装或不在 PATH 中"
        echo "  请访问 https://flutter.dev/docs/get-started/install"
    fi
    echo ""
}

# 检查 Xcode 环境
check_xcode() {
    log_section "Xcode" "检查 Xcode 环境"

    # 检查 Command Line Tools
    if xcode-select -p &> /dev/null; then
        local xcode_path=$(xcode-select -p 2>/dev/null)
        log_success "Xcode Command Line Tools 已安装"
        echo "  路径: $xcode_path"
    else
        log_error "Xcode Command Line Tools 未安装"
        echo "  安装命令: xcode-select --install"
    fi

    # 检查完整 Xcode
    if command -v xcodebuild &> /dev/null; then
        local xcode_version=$(xcodebuild -version 2>/dev/null)
        log_success "完整 Xcode 已安装"
        echo "$xcode_version" | head -n 2
        echo "  ✅ 可以构建 macOS 应用"
    else
        log_warning "完整 Xcode 未安装"
        echo "  ⚠️  无法构建 macOS 应用"
        echo "  请通过 App Store 安装最新版 Xcode"
        echo "  安装后运行: sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer"
    fi
    echo ""
}

# 检查 Android 环境
check_android() {
    log_section "Android" "检查 Android 开发环境"

    # 检查 Android Studio
    if [ -d "/Applications/Android Studio.app" ] || [ -d "$HOME/Applications/Android Studio.app" ]; then
        log_success "Android Studio 已安装"
        echo "  路径: $(find /Applications "$HOME/Applications" -name "Android Studio.app" -type d 2>/dev/null | head -n 1)"
    else
        log_error "Android Studio 未安装"
        echo "  安装命令: brew install --cask android-studio"
    fi

    # 检查 Android SDK
    local android_sdk_path=""
    if [ -n "$ANDROID_HOME" ] && [ -d "$ANDROID_HOME" ]; then
        android_sdk_path="$ANDROID_HOME"
    elif [ -d "$HOME/Library/Android/sdk" ]; then
        android_sdk_path="$HOME/Library/Android/sdk"
    fi

    if [ -n "$android_sdk_path" ]; then
        log_success "Android SDK 已配置"
        echo "  SDK 路径: $android_sdk_path"

        # 检查关键组件
        if [ -f "$android_sdk_path/platform-tools/adb" ]; then
            log_success "ADB 工具可用"
            local adb_version=$("$android_sdk_path/platform-tools/adb" version 2>/dev/null | head -n 1)
            echo "  $adb_version"
        else
            log_warning "ADB 工具不可用"
        fi

        # 检查平台版本
        echo "  已安装的 Android 平台:"
        ls "$android_sdk_path/platforms" 2>/dev/null | sed 's/^/    /' || echo "    无平台信息"

        echo "  ✅ 可以构建 Android 应用"

    else
        log_error "Android SDK 未配置"
        echo "  环境变量 ANDROID_HOME: ${ANDROID_HOME:-未设置}"
        echo "  请启动 Android Studio 并完成初始配置"
        echo "  然后运行: ./setup_android_env.sh"
    fi
    echo ""
}

# 检查 Homebrew
check_homebrew() {
    log_section "Homebrew" "检查包管理器"

    if command -v brew &> /dev/null; then
        log_success "Homebrew 已安装"
        local brew_version=$(brew --version 2>/dev/null | head -n 1)
        echo "  $brew_version"

        echo ""
        echo "已安装的相关包:"
        brew list --cask 2>/dev/null | grep -E "(android-studio|xcode)" | sed 's/^/  /' || echo "  无相关包"

    else
        log_error "Homebrew 未安装"
        echo "  安装命令: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
    fi
    echo ""
}

# 检查构建脚本
check_build_scripts() {
    log_section "构建脚本" "检查构建工具"

    local scripts=(
        "build_interactive.sh:交互式构建脚本"
        "check_env.sh:环境检查脚本"
        "setup_android_env.sh:Android环境配置脚本"
        "tools/scripts/build.sh:命令行构建脚本"
        "tools/scripts/quick_build.sh:快速构建脚本"
    )

    local all_available=true

    for script_info in "${scripts[@]}"; do
        local script_file="${script_info%%:*}"
        local script_desc="${script_info##*:}"

        if [ -f "$script_file" ]; then
            if [ -x "$script_file" ]; then
                log_success "$script_desc"
                echo "  ✅ 文件存在且有执行权限: $script_file"
            else
                log_warning "$script_desc"
                echo "  ⚠️  文件存在但无执行权限: $script_file"
                echo "     运行: chmod +x $script_file"
            fi
        else
            log_error "$script_desc"
            echo "  ✗ 文件不存在: $script_file"
            all_available=false
        fi
    done

    if [ "$all_available" = true ]; then
        echo ""
        echo "✅ 所有构建脚本已就绪，可以开始构建"
    else
        echo ""
        echo "⚠️  部分构建脚本缺失，请检查项目完整性"
    fi
    echo ""
}

# 检查项目结构
check_project_structure() {
    log_section "项目" "检查项目结构"

    local required_files=(
        "pubspec.yaml:Flutter项目配置"
        "lib/main.dart:应用入口文件"
        "README.md:项目说明文档"
    )

    local required_dirs=(
        "lib:源代码目录"
        "android:Android平台配置"
        "macOS:macOS平台配置"
        "linux:Linux平台配置"
        "tools:构建工具目录"
    )

    echo "必需文件检查:"
    for file_info in "${required_files[@]}"; do
        local file="${file_info%%:*}"
        local desc="${file_info##*:}"

        if [ -f "$file" ]; then
            log_success "$desc: $file"
        else
            log_warning "$desc: $file (缺失)"
        fi
    done

    echo ""
    echo "必需目录检查:"
    for dir_info in "${required_dirs[@]}"; do
        local dir="${dir_info%%:*}"
        local desc="${dir_info##*:}"

        if [ -d "$dir" ]; then
            log_success "$desc: $dir"
        else
            log_warning "$desc: $dir (缺失)"
        fi
    done
    echo ""
}

# 检查网络连接
check_network() {
    log_section "网络" "检查网络连接"

    # 检查到 GitHub 的连接
    if curl -s --connect-timeout 5 https://github.com > /dev/null; then
        log_success "GitHub 连接正常"
    else
        log_warning "GitHub 连接异常，可能影响依赖下载"
    fi

    # 检查到 Flutter 官网连接
    if curl -s --connect-timeout 5 https://flutter.dev > /dev/null; then
        log_success "Flutter 官网连接正常"
    else
        log_warning "Flutter 官网连接异常"
    fi

    # 检查磁盘空间
    local available_space=$(df -h . | awk 'NR==2 {print $4}')
    echo "可用磁盘空间: $available_space"
    echo ""
}

# 运行 Flutter Doctor
run_flutter_doctor() {
    log_section "Flutter Doctor" "运行官方诊断"

    if command -v flutter &> /dev/null; then
        echo "运行 Flutter 官方环境诊断..."
        echo "=========================================="
        flutter doctor -v
        echo "=========================================="
    else
        log_warning "Flutter 未安装，无法运行 doctor"
    fi
    echo ""
}

# 显示构建能力
show_build_capabilities() {
    log_section "构建能力" "当前可用的构建选项"

    echo "🍎 macOS 应用构建:"
    if command -v xcodebuild &> /dev/null; then
        log_success "可用 - 可以构建 DMG 安装包"
        echo "   格式: DMG，包含完整卸载功能"
    else
        log_warning "不可用 - 需要安装 Xcode"
    fi

    echo ""
    echo "🐧 Linux 应用构建:"
    echo "⚠️  跨平台构建 - 需要在 Linux 环境中运行"
    echo "   格式: DEB，包含完整卸载脚本"

    echo ""
    echo "🤖 Android 应用构建:"
    if [ -n "$ANDROID_HOME" ] && [ -d "$ANDROID_HOME" ]; then
        log_success "可用 - 可以构建 APK 安装包"
        echo "   格式: APK，包含系统卸载功能"
    else
        log_warning "不可用 - 需要配置 Android SDK"
    fi

    echo ""
}

# 提供下一步建议
show_next_steps() {
    log_section "建议" "下一步操作"

    echo "根据当前环境状态，建议按以下顺序操作："
    echo ""

    if ! command -v flutter &> /dev/null; then
        echo "1. 📦 安装 Flutter SDK"
        echo "   访问: https://flutter.dev/docs/get-started/install"
        echo ""
    fi

    if ! command -v xcodebuild &> /dev/null; then
        echo "2. 🍎 安装 Xcode"
        echo "   通过 App Store 搜索 'Xcode' 并安装最新版"
        echo "   安装后运行: sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer"
        echo ""
    fi

    if [ ! -d "/Applications/Android Studio.app" ]; then
        echo "3. 🤖 安装 Android Studio"
        echo "   运行: brew install --cask android-studio"
        echo ""
    fi

    if [ -d "/Applications/Android Studio.app" ] && ([ -z "$ANDROID_HOME" ] || [ ! -d "$ANDROID_HOME" ]); then
        echo "4. ⚙️  配置 Android SDK"
        echo "   启动 Android Studio 并完成初始配置"
        echo "   然后运行: ./setup_android_env.sh"
        echo ""
    fi

    echo "5. 🏗️  开始构建"
    echo "   运行: ./build_interactive.sh"
    echo ""

    echo "6. 🔍 随时检查"
    echo "   运行: ./check_environment.sh"
    echo ""
}

# 显示帮助信息
show_help() {
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  --help, -h     显示此帮助信息"
    echo "  --quick        快速检查（仅显示状态）"
    echo "  --full         完整检查（包含 Flutter Doctor）"
    echo "  --doctor       仅运行 Flutter Doctor"
    echo ""
    echo "示例:"
    echo "  $0              # 运行完整环境检查"
    echo "  $0 --quick      # 快速检查"
    echo "  $0 --doctor     # 仅运行 Flutter Doctor"
    echo ""
}

# 主函数
main() {
    local quick_mode=false
    local full_mode=true
    local doctor_only=false

    # 解析命令行参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            --help|-h)
                show_help
                exit 0
                ;;
            --quick)
                quick_mode=true
                full_mode=false
                shift
                ;;
            --full)
                quick_mode=false
                full_mode=true
                shift
                ;;
            --doctor)
                doctor_only=true
                shift
                ;;
            *)
                echo "未知选项: $1"
                echo "使用 --help 查看帮助信息"
                exit 1
                ;;
        esac
    done

    # 仅运行 Flutter Doctor
    if [ "$doctor_only" = true ]; then
        run_flutter_doctor
        exit 0
    fi

    # 显示标题
    show_header

    # 运行各项检查
    check_system_info
    check_flutter
    check_xcode
    check_android
    check_homebrew

    if [ "$quick_mode" = false ]; then
        check_build_scripts
        check_project_structure
        check_network
        show_build_capabilities
        show_next_steps
    fi

    # 运行完整 Flutter Doctor
    if [ "$full_mode" = true ]; then
        run_flutter_doctor
    fi

    # 显示最终状态
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}                    ${WHITE}📊 检查完成${NC}                        ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    if [ "$OVERALL_STATUS" = true ]; then
        echo -e "${GREEN}🎉 环境检查通过！可以开始构建应用。${NC}"
    else
        echo -e "${YELLOW}⚠️  环境检查发现问题，请根据上述建议进行配置。${NC}"
    fi

    echo ""
    echo -e "${BLUE}💡 提示：${NC}"
    echo "• 重新运行检查: $0"
    echo "• 开始构建应用: ./build_interactive.sh"
    echo "• 查看 Flutter 状态: flutter doctor -v"
    echo ""
}

# 运行主函数
main "$@"
#!/bin/bash

# Beautiful Todo 应用卸载脚本
# 支持跨平台卸载：macOS, Linux, Windows(WSL)

set -e

APP_NAME="Beautiful Todo"
PACKAGE_NAME="beautiful_todo"
CONFIG_DIR="$HOME/.beautiful_todo"
UNINSTALLER_DIR="$(dirname "$0")"

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

# 检测操作系统
detect_os() {
    case "$(uname -s)" in
        Darwin*)
            echo "macos"
            ;;
        Linux*)
            if [ -f /etc/debian_version ]; then
                echo "debian"
            elif [ -f /etc/redhat-release ]; then
                echo "redhat"
            elif [ -f /etc/arch-release ]; then
                echo "arch"
            else
                echo "linux"
            fi
            ;;
        CYGWIN*|MINGW*|MSYS*)
            echo "windows"
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

# macOS卸载
uninstall_macos() {
    log_info "开始卸载 macOS 版本的应用..."

    # 停止可能运行的应用
    if pgrep -f "$PACKAGE_NAME" > /dev/null; then
        log_info "停止正在运行的应用..."
        pkill -f "$PACKAGE_NAME" || true
    fi

    # 删除应用文件
    local APP_DIRS=(
        "/Applications/$APP_NAME.app"
        "$HOME/Applications/$APP_NAME.app"
    )

    for app_dir in "${APP_DIRS[@]}"; do
        if [ -d "$app_dir" ]; then
            log_info "删除应用文件: $app_dir"
            rm -rf "$app_dir"
        fi
    done

    # 删除用户配置和数据
    if [ -d "$CONFIG_DIR" ]; then
        log_info "删除用户配置和数据..."
        rm -rf "$CONFIG_DIR"
    fi

    # 删除 Dock 中的图标（如果存在）
    defaults write com.apple.dock persistent-apps -array-add "$(defaults read com.apple.dock persistent-apps 2>/dev/null | grep -v "$APP_NAME" 2>/dev/null || echo '')" 2>/dev/null || true

    log_success "macOS 应用卸载完成！"
}

# Linux卸载 (基于包管理器)
uninstall_linux() {
    log_info "开始卸载 Linux 版本的应用..."

    local os_type=$(detect_os)
    local package_names=("beautiful-todo" "beautiful_todo" "$PACKAGE_NAME")

    # 尝试不同的包管理器
    if command -v apt-get >/dev/null 2>&1; then
        # Debian/Ubuntu
        log_info "使用 apt-get 卸载..."
        for pkg in "${package_names[@]}"; do
            if dpkg -l | grep -q "^ii  $pkg "; then
                log_info "卸载包: $pkg"
                sudo apt-get remove --purge -y "$pkg" || log_warning "无法卸载包: $pkg"
            fi
        done

    elif command -v yum >/dev/null 2>&1; then
        # RHEL/CentOS
        log_info "使用 yum 卸载..."
        for pkg in "${package_names[@]}"; do
            if rpm -q "$pkg" >/dev/null 2>&1; then
                log_info "卸载包: $pkg"
                sudo yum remove -y "$pkg" || log_warning "无法卸载包: $pkg"
            fi
        done

    elif command -v dnf >/dev/null 2>&1; then
        # Fedora
        log_info "使用 dnf 卸载..."
        for pkg in "${package_names[@]}"; do
            if rpm -q "$pkg" >/dev/null 2>&1; then
                log_info "卸载包: $pkg"
                sudo dnf remove -y "$pkg" || log_warning "无法卸载包: $pkg"
            fi
        done

    elif command -v pacman >/dev/null 2>&1; then
        # Arch Linux
        log_info "使用 pacman 卸载..."
        for pkg in "${package_names[@]}"; do
            if pacman -Qi "$pkg" >/dev/null 2>&1; then
                log_info "卸载包: $pkg"
                sudo pacman -Rns "$pkg" || log_warning "无法卸载包: $pkg"
            fi
        done
    fi

    # 停止可能运行的应用
    if pgrep -f "$PACKAGE_NAME" > /dev/null; then
        log_info "停止正在运行的应用..."
        pkill -f "$PACKAGE_NAME" || true
    fi

    # 删除桌面快捷方式
    local desktop_dirs=(
        "$HOME/Desktop"
        "$HOME/.local/share/applications"
        "/usr/share/applications"
        "/usr/local/share/applications"
    )

    for desktop_dir in "${desktop_dirs[@]}"; do
        if [ -d "$desktop_dir" ]; then
            local desktop_files=(
                "$desktop_dir/$APP_NAME.desktop"
                "$desktop_dir/$PACKAGE_NAME.desktop"
                "$desktop_dir/beautiful_todo.desktop"
            )
            for desktop_file in "${desktop_files[@]}"; do
                if [ -f "$desktop_file" ]; then
                    log_info "删除桌面文件: $desktop_file"
                    rm -f "$desktop_file"
                fi
            done
        fi
    done

    # 删除用户配置和数据
    if [ -d "$CONFIG_DIR" ]; then
        log_info "删除用户配置和数据..."
        rm -rf "$CONFIG_DIR"
    fi

    # 删除可能的手动安装位置
    local manual_install_dirs=(
        "/opt/$PACKAGE_NAME"
        "/usr/local/bin/$PACKAGE_NAME"
        "$HOME/.local/bin/$PACKAGE_NAME"
    )

    for install_dir in "${manual_install_dirs[@]}"; do
        if [ -d "$install_dir" ] || [ -f "$install_dir" ]; then
            log_info "删除手动安装文件: $install_dir"
            sudo rm -rf "$install_dir" || rm -rf "$install_dir" 2>/dev/null || true
        fi
    done

    log_success "Linux 应用卸载完成！"
}

# Windows卸载 (WSL)
uninstall_windows() {
    log_info "开始卸载 Windows 版本的应用..."

    # 在WSL中，我们只能删除配置文件
    # 实际的Windows应用需要用户手动通过控制面板卸载

    if [ -d "$CONFIG_DIR" ]; then
        log_info "删除用户配置和数据..."
        rm -rf "$CONFIG_DIR"
    fi

    log_warning "请手动通过Windows控制面板卸载应用"
    log_info "Windows控制面板 -> 程序和功能 -> 卸载程序"
    log_success "WSL 环境下的数据清理完成！"
}

# 创建备份
create_backup() {
    local backup_dir="$HOME/beautiful_todo_backup_$(date +%Y%m%d_%H%M%S)"

    if [ -d "$CONFIG_DIR" ]; then
        log_info "创建配置备份到: $backup_dir"
        cp -r "$CONFIG_DIR" "$backup_dir"
        log_success "备份创建成功！"
    else
        log_warning "没有找到需要备份的配置文件"
    fi
}

# 清理残留文件
cleanup_residual_files() {
    log_info "清理残留文件..."

    # 清理临时文件
    local temp_dirs=(
        "/tmp/$PACKAGE_NAME"
        "$HOME/.cache/$PACKAGE_NAME"
        "$HOME/.local/share/$PACKAGE_NAME"
    )

    for temp_dir in "${temp_dirs[@]}"; do
        if [ -d "$temp_dir" ]; then
            log_info "删除临时目录: $temp_dir"
            rm -rf "$temp_dir"
        fi
    done

    # 清理日志文件
    local log_files=(
        "$HOME/.local/share/$PACKAGE_NAME.log"
        "/var/log/$PACKAGE_NAME.log"
    )

    for log_file in "${log_files[@]}"; do
        if [ -f "$log_file" ]; then
            log_info "删除日志文件: $log_file"
            rm -f "$log_file"
        fi
    done
}

# 主函数
main() {
    clear
    echo "=============================================="
    echo "    Beautiful Todo 应用卸载程序"
    echo "=============================================="
    echo ""

    # 确认卸载
    echo -e "${YELLOW}警告：此操作将永久删除应用和所有相关数据！${NC}"
    echo -e "${YELLOW}如果您想保留数据，请选择备份选项。${NC}"
    echo ""
    echo "请选择操作："
    echo "1) 卸载应用并删除所有数据"
    echo "2) 卸载应用但保留数据备份"
    echo "3) 仅删除应用数据（保留安装）"
    echo "4) 退出"
    echo ""
    read -p "请输入选择 (1-4): " choice

    case $choice in
        1)
            ;;
        2)
            create_backup
            ;;
        3)
            if [ -d "$CONFIG_DIR" ]; then
                log_info "删除用户数据..."
                rm -rf "$CONFIG_DIR"
            fi
            cleanup_residual_files
            log_success "数据删除完成！"
            exit 0
            ;;
        4)
            echo "取消卸载操作"
            exit 0
            ;;
        *)
            log_error "无效选择！"
            exit 1
            ;;
    esac

    # 再次确认
    echo ""
    read -p "确定要继续卸载吗？(y/N): " confirm
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        echo "取消卸载操作"
        exit 0
    fi

    echo ""
    log_info "开始卸载 $APP_NAME..."

    # 检测操作系统并执行对应的卸载逻辑
    local os=$(detect_os)

    case $os in
        "macos")
            uninstall_macos
            ;;
        "debian"|"redhat"|"arch"|"linux")
            uninstall_linux
            ;;
        "windows")
            uninstall_windows
            ;;
        *)
            log_error "不支持的操作系统: $os"
            exit 1
            ;;
    esac

    # 清理残留文件
    cleanup_residual_files

    echo ""
    log_success "$APP_NAME 卸载完成！"
    echo ""
    echo "感谢您使用 Beautiful Todo！"
}

# 检查是否以root权限运行（某些操作可能需要）
if [[ $EUID -eq 0 ]]; then
    log_warning "检测到以root权限运行，请谨慎操作"
fi

# 执行主函数
main "$@"
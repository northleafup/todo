#!/bin/bash

# Android 环境自动配置脚本

echo "🤖 配置 Android 开发环境..."
echo ""

# Android SDK 路径
ANDROID_SDK_PATH="$HOME/Library/Android/sdk"

# 检查 Android Studio 是否已安装
check_android_studio() {
    if [ -d "/Applications/Android Studio.app" ]; then
        echo "✅ Android Studio 已安装"
        return 0
    elif [ -d "$HOME/Applications/Android Studio.app" ]; then
        echo "✅ Android Studio 已安装（用户应用）"
        return 0
    else
        echo "❌ Android Studio 未找到"
        return 1
    fi
}

# 配置环境变量
setup_environment() {
    echo "📝 配置环境变量..."

    # 检测 shell 类型
    if [ -n "$ZSH_VERSION" ]; then
        SHELL_RC="$HOME/.zshrc"
    elif [ -n "$BASH_VERSION" ]; then
        SHELL_RC="$HOME/.bash_profile"
    else
        SHELL_RC="$HOME/.profile"
    fi

    echo "使用配置文件: $SHELL_RC"

    # 检查是否已经配置过
    if grep -q "ANDROID_HOME" "$SHELL_RC" 2>/dev/null; then
        echo "ℹ️  Android 环境变量已经配置过"
    else
        echo "正在添加 Android 环境变量..."
        cat >> "$SHELL_RC" << 'EOF'

# Android SDK 环境变量
export ANDROID_HOME=$HOME/Library/Android/sdk
export ANDROID_SDK_ROOT=$ANDROID_HOME
export PATH=$PATH:$ANDROID_HOME/emulator
export PATH=$PATH:$ANDROID_HOME/tools
export PATH=$PATH:$ANDROID_HOME/tools/bin
export PATH=$PATH:$ANDROID_HOME/platform-tools
EOF
        echo "✅ 环境变量已添加到 $SHELL_RC"
    fi

    # 立即生效
    export ANDROID_HOME="$ANDROID_SDK_PATH"
    export ANDROID_SDK_ROOT="$ANDROID_SDK_PATH"
    export PATH="$PATH:$ANDROID_SDK_PATH/emulator"
    export PATH="$PATH:$ANDROID_SDK_PATH/tools"
    export PATH="$PATH:$ANDROID_SDK_PATH/tools/bin"
    export PATH="$PATH:$ANDROID_SDK_PATH/platform-tools"
}

# 检查 Android SDK
check_android_sdk() {
    if [ -d "$ANDROID_SDK_PATH" ]; then
        echo "✅ Android SDK 已找到: $ANDROID_SDK_PATH"
        return 0
    else
        echo "❌ Android SDK 未找到"
        echo "请先启动 Android Studio 并完成初始配置"
        return 1
    fi
}

# 接受 Android 许可证
accept_licenses() {
    if check_android_sdk; then
        echo "📋 接受 Android 许可证..."
        if flutter doctor --android-licenses > /dev/null 2>&1; then
            echo "✅ Android 许可证已接受"
        else
            echo "⚠️  需要手动接受许可证，请运行:"
            echo "   flutter doctor --android-licenses"
        fi
    fi
}

# 验证配置
verify_setup() {
    echo "🔍 验证配置..."
    echo ""

    echo "环境变量:"
    echo "  ANDROID_HOME: ${ANDROID_HOME:-未设置}"
    echo "  ANDROID_SDK_ROOT: ${ANDROID_SDK_ROOT:-未设置}"
    echo ""

    if command -v adb &> /dev/null; then
        echo "✅ ADB 已可用"
        adb version | head -n 1
    else
        echo "❌ ADB 不可用"
    fi

    echo ""
    echo "Flutter 状态:"
    flutter doctor --android
}

# 主函数
main() {
    echo "开始配置 Android 开发环境..."
    echo ""

    # 检查 Android Studio
    if ! check_android_studio; then
        echo "请先安装 Android Studio"
        echo "可以通过以下命令安装:"
        echo "  brew install --cask android-studio"
        echo ""
        echo "或者访问: https://developer.android.com/studio"
        exit 1
    fi

    echo ""

    # 配置环境变量
    setup_environment

    echo ""

    # 检查 Android SDK
    if check_android_sdk; then
        # 接受许可证
        accept_licenses

        # 验证配置
        verify_setup

        echo ""
        echo "🎉 Android 环境配置完成！"
        echo ""
        echo "📋 下一步:"
        echo "1. 重新启动终端或运行: source ~/.zshrc"
        echo "2. 运行 'flutter doctor -v' 验证配置"
        echo "3. 使用 './build_interactive.sh' 开始构建"
    else
        echo "ℹ️  请启动 Android Studio 并完成初始配置:"
        echo "   1. 打开 Android Studio"
        echo "   2. 选择 'Standard' 安装"
        echo "   3. 等待 SDK 下载完成"
        echo "   4. 重新运行此脚本"
    fi
}

# 运行主函数
main "$@"
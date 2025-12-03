#!/bin/bash

# 环境检查和配置脚本

echo "🔍 检查开发环境..."
echo ""

# 检查 Xcode
echo "🍎 Xcode 状态："
if command -v xcodebuild &> /dev/null; then
    echo "✅ Xcode 已安装"
    xcodebuild -version | head -n 2
else
    echo "❌ Xcode 未安装或未正确配置"
    echo "   请通过 App Store 安装完整版 Xcode"
    echo "   安装后运行: sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer"
fi
echo ""

# 检查 Android SDK
echo "🤖 Android SDK 状态："
if [ -n "$ANDROID_HOME" ] && [ -d "$ANDROID_HOME" ]; then
    echo "✅ Android SDK 已配置: $ANDROID_HOME"
else
    echo "❌ Android SDK 未配置"

    # 检查常见路径
    if [ -d "$HOME/Library/Android/sdk" ]; then
        echo "ℹ️  发现 Android SDK 在: $HOME/Library/Android/sdk"
        echo "   请运行以下命令配置环境变量："
        echo "   export ANDROID_HOME=\$HOME/Library/Android/sdk"
        echo "   export PATH=\$PATH:\$ANDROID_HOME/platform-tools"
    else
        echo "ℹ️  正在通过 Homebrew 安装 Android Studio..."
    fi
fi
echo ""

# 检查 Flutter
echo "🐣 Flutter 状态："
if command -v flutter &> /dev/null; then
    echo "✅ Flutter 已安装"
    flutter --version | head -n 3
else
    echo "❌ Flutter 未安装"
fi
echo ""

# 检查 Homebrew
echo "🍺 Homebrew 状态："
if command -v brew &> /dev/null; then
    echo "✅ Homebrew 已安装"
    brew --version | head -n 1
else
    echo "❌ Homebrew 未安装"
fi
echo ""

# 检查构建脚本
echo "📜 构建脚本状态："
if [ -f "build_interactive.sh" ]; then
    echo "✅ 交互式构建脚本已就绪"
    if [ -x "build_interactive.sh" ]; then
        echo "✅ 脚本具有执行权限"
    else
        echo "⚠️  脚本需要执行权限，运行: chmod +x build_interactive.sh"
    fi
else
    echo "❌ 构建脚本不存在"
fi
echo ""

# 提供下一步建议
echo "📋 下一步建议："
echo "1. 如果 Xcode 未安装，请通过 App Store 安装最新版 Xcode"
echo "2. 等待 Android Studio 安装完成"
echo "3. 运行 'flutter doctor -v' 查看详细状态"
echo "4. 运行 './build_interactive.sh' 开始构建"
echo ""

echo "💡 提示：可以随时运行此脚本检查环境状态"
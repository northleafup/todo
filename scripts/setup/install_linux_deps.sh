#!/bin/bash
# 安装 Linux 开发依赖脚本

echo "正在安装 Todo App Linux 开发依赖..."

# 更新包列表
echo "更新包列表..."
sudo apt update

# 安装必要的开发包
echo "安装开发依赖..."
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

echo "安装完成！"
echo "现在可以运行: cd src && flutter build linux --release"
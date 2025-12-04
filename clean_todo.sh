#!/bin/sh

# Todo应用彻底卸载脚本
echo "🗑️  开始彻底卸载Todo应用..."

# 检查是否有权限
if [ "$(id -u)" -eq 0 ]; then
    echo "⚠️  请不要以root身份运行此脚本，使用普通用户运行"
    exit 1
fi

# 1. 删除dpkg包
echo "📦 删除系统包..."
sudo dpkg -r todo-app 2>/dev/null || true
sudo dpkg -P todo-app 2>/dev/null || true

# 2. 删除应用文件
echo "🗂️  删除应用文件..."
sudo rm -rf /opt/todo_app/ 2>/dev/null || true
sudo rm -f /usr/bin/todo_app 2>/dev/null || true
sudo rm -f /usr/share/applications/todo_app.desktop 2>/dev/null || true
sudo rm -f /usr/share/icons/hicolor/256x256/apps/todo_app.png 2>/dev/null || true

# 3. 删除用户数据目录
echo "🏠 删除用户数据目录..."
rm -rf ~/.local/share/com.example.todo_app 2>/dev/null || true
rm -rf ~/.local/share/todo_app 2>/dev/null || true
rm -rf ~/.config/todo_app 2>/dev/null || true

# 4. 删除数据库文件
echo "💾 删除数据库文件..."
find ~ -name "todos.db" 2>/dev/null | xargs rm -f 2>/dev/null || true
find ~ -name "*todo*.db" 2>/dev/null | xargs rm -f 2>/dev/null || true
find ~ -path "*todo*/todos.db" 2>/dev/null | xargs rm -f 2>/dev/null || true

# 5. 删除应用配置文件
echo "⚙️  删除配置文件..."
rm -rf ~/.local/state/todo_app 2>/dev/null || true
rm -rf ~/.cache/todo_app 2>/dev/null || true
rm -rf ~/.cache/com.example.todo_app 2>/dev/null || true

# 6. 删除共享偏好设置
echo "🔄 删除共享偏好设置..."
if command -v gsettings >/dev/null 2>&1; then
    gsettings reset com.example.todo_app 2>/dev/null || true
    gsettings reset com.beautifultodo.todo 2>/dev/null || true
fi

# 7. 删除系统密钥环中的凭据（如果存在）
echo "🔐 清理系统密钥环数据..."
# 尝试删除GNOME密钥环中的条目
if command -v secret-tool >/dev/null 2>&1; then
    secret-tool clear todo-app 2>/dev/null || true
    secret-tool clear com.example.todo_app 2>/dev/null || true
    secret-tool search all todo-app 2>/dev/null | awk '{print $1}' | xargs -I {} secret-tool clear {} 2>/dev/null || true
fi

# 8. 删除临时文件
echo "🗑️  删除临时文件..."
find /tmp -name "*todo*" 2>/dev/null | xargs rm -rf 2>/dev/null || true
find /var/tmp -name "*todo*" 2>/dev/null | xargs rm -rf 2>/dev/null || true

# 9. 删除用户手动创建的数据库
echo "📂 删除手动数据库..."
find ~ -type d -name "todo_data" 2>/dev/null | xargs rm -rf 2>/dev/null || true
find ~ -type d -name "todo_app_data" 2>/dev/null | xargs rm -rf 2>/dev/null || true

# 10. 清理可能的日志文件
echo "📝 删除日志文件..."
rm -f ~/.local/share/todo-app.log 2>/dev/null || true
rm -f ~/.cache/todo-app.log 2>/dev/null || true

# 验证卸载是否完全
echo ""
echo "🔍 验证卸载结果..."

# 检查包是否已卸载
if dpkg -l | grep -q todo-app; then
    echo "⚠️  警告：todo-app包可能仍存在"
else
    echo "✅ todo-app包已完全卸载"
fi

# 检查应用文件是否已删除
if [ -d "/opt/todo_app" ] || [ -f "/usr/bin/todo_app" ]; then
    echo "⚠️  警告：部分应用文件可能仍存在"
else
    echo "✅ 应用文件已完全删除"
fi

# 检查用户数据是否已清理
if [ -d "$HOME/.local/share/com.example.todo_app" ] || [ -d "$HOME/.local/share/todo_app" ]; then
    echo "⚠️  警告：部分用户数据可能仍存在"
else
    echo "✅ 用户数据已完全清理"
fi

echo ""
echo "🎉 Todo应用彻底卸载完成！"
echo ""
echo "📋 清理总结："
echo "  ✓ 系统包和文件"
echo "  ✓ 用户数据目录"
echo "  ✓ 数据库文件"
echo "  ✓ 配置文件和偏好设置"
echo "  ✓ 系统密钥环凭据"
echo "  ✓ 临时文件和日志"
echo ""
echo "💡 提示："
echo "  - 现在可以重新安装应用，将像首次安装一样"
echo "  - 如果仍有残留文件，请检查上述警告信息"
echo "  - 密钥环中的凭据可能需要手动清理（如有权限）"
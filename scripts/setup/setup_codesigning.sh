#!/bin/bash

# 🍎 macOS 代码签名配置工具
# 支持自签名和无签名构建

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

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

# 创建自签名证书
create_self_signed_certificate() {
    log_info "创建自签名开发证书..."

    # 检查是否已存在证书
    if security find-identity -v -p codesigning 2>/dev/null | grep -q "Beautiful Todo"; then
        log_success "自签名证书已存在"
        return 0
    fi

    # 创建证书配置文件
    cat > /tmp/certificate.conf << EOF
[req]
distinguished_name = req_distinguished_name
x509_extensions = v3_req
prompt = no

[req_distinguished_name]
CN = Beautiful Todo Developer
OU = Development
O = Beautiful Todo
L = Your City
C = Your Country

[v3_req]
basicConstraints = critical, CA:false
keyUsage = critical, digitalSignature, keyEncipherment
extendedKeyUsage = codeSigning
EOF

    # 创建私钥
    openssl genrsa -out /tmp/certificate.key 2048

    # 创建证书签名请求
    openssl req -new -key /tmp/certificate.key -out /tmp/certificate.csr -config /tmp/certificate.conf

    # 创建自签名证书（有效期1年）
    openssl x509 -req -days 365 -in /tmp/certificate.csr -signkey /tmp/certificate.key -out /tmp/certificate.crt -extensions v3_req -extfile /tmp/certificate.conf

    # 创建 PKCS12 格式
    openssl pkcs12 -export -out /tmp/certificate.p12 -inkey /tmp/certificate.key -in /tmp/certificate.crt -password pass:beautifultodo -name "Beautiful Todo Developer"

    # 导入证书到钥匙串
    security import /tmp/certificate.p12 -k ~/Library/Keychains/login.keychain-db -P beautifultodo -T /usr/bin/codesign

    # 设置证书信任
    security set-trust -r trustAsRoot /tmp/certificate.crt

    # 清理临时文件
    rm -f /tmp/certificate.*

    log_success "✅ 自签名证书创建并导入成功"
}

# 配置 Flutter 项目使用自签名证书
configure_flutter_project() {
    log_info "配置 Flutter 项目使用自签名证书..."

    local config_file="macos/Runner/DebugProfile.entitlements"

    # 检查权限文件是否存在
    if [ ! -f "$config_file" ]; then
        log_warning "权限文件不存在，将创建基本配置"

        # 创建基本的权限文件
        cat > "$config_file" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.app-sandbox</key>
    <false/>
    <key>com.apple.security.files.user-selected.read-write</key>
    <true/>
</dict>
</plist>
EOF
    fi

    log_success "✅ Flutter 项目配置完成"
}

# 测试代码签名
test_codesigning() {
    log_info "测试代码签名..."

    local app_path="build/macos/Build/Products/Release/todo.app"

    if [ ! -d "$app_path" ]; then
        log_warning "应用文件不存在，请先构建应用"
        return 1
    fi

    # 尝试使用自签名证书签名
    local certificate_id=$(security find-identity -v -p codesigning | grep "Beautiful Todo" | head -n 1 | awk '{print $2}')

    if [ -n "$certificate_id" ]; then
        log_info "使用自签名证书: $certificate_id"
        codesign --force --verify --verbose --sign "$certificate_id" "$app_path"
        log_success "✅ 自签名完成"
    else
        log_warning "未找到自签名证书，尝试无签名构建"
        log_info "你可以使用 --no-codesign 选项构建无签名版本"
    fi

    # 验证签名
    local signing_status=$(codesign -dv "$app_path" 2>&1)
    echo "📋 签名验证结果:"
    echo "$signing_status"
}

# 显示签名选项
show_signing_options() {
    echo ""
    echo "🍎 macOS 代码签名选项："
    echo ""
    echo "1. 🆕 创建自签名证书（推荐用于开发和测试）"
    echo "2. ⏭️  使用无签名构建（仅用于本地测试）"
    echo "3. 🔍 验证现有签名"
    echo "4. 📋 查看现有证书"
    echo "5. 🚪 退出"
    echo ""
}

# 显示现有证书
show_existing_certificates() {
    log_info "查看现有的代码签名证书："
    echo ""
    security find-identity -v -p codesigning 2>/dev/null || echo "未找到代码签名证书"
}

# 主函数
main() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}              ${WHITE}🍎 macOS 代码签名工具${NC}                    ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}              美丽的待办事项 - 证书管理器${NC}              ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    show_signing_options

    while true; do
        echo -ne "${WHITE}请选择操作 [1-5]: ${NC}"
        read choice

        case $choice in
            1)
                echo ""
                create_self_signed_certificate
                configure_flutter_project
                echo ""
                log_success "🎉 自签名证书配置完成！"
                echo "现在可以使用以下命令构建应用："
                echo "flutter build macos --release"
                break
                ;;
            2)
                echo ""
                log_info "使用无签名构建命令："
                echo "flutter build macos --release --no-codesign"
                echo ""
                echo "⚠️  注意：无签名应用只能在当前设备上运行，无法分发给其他用户"
                break
                ;;
            3)
                echo ""
                test_codesigning
                break
                ;;
            4)
                echo ""
                show_existing_certificates
                echo ""
                ;;
            5)
                echo ""
                log_info "退出代码签名工具"
                exit 0
                ;;
            *)
                echo ""
                log_error "无效选项，请选择 1-5"
                ;;
        esac
    done
}

# 运行主函数
main "$@"
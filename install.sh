#!/bin/bash
# V2Ray Manager 一键安装脚本

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

# 安装目录
INSTALL_DIR="/usr/local/share/v2ray-manager"
BIN_DIR="/usr/local/bin"
CONFIG_DIR="/etc/v2ray-manager"
COMPLETION_DIR="/etc/bash_completion.d"

# 检测root权限
check_root() {
    if [ "$(id -u)" != "0" ]; then
        echo -e "${RED}错误: 必须使用root用户运行此脚本${NC}"
        exit 1
    fi
}

# 安装依赖
install_deps() {
    echo -e "${YELLOW}正在安装依赖包...${NC}"
    if [ -f /etc/debian_version ]; then
        apt-get update
        apt-get install -y curl wget jq qrencode
    elif [ -f /etc/redhat-release ]; then
        yum install -y curl wget jq qrencode
    else
        echo -e "${RED}不支持的Linux发行版${NC}"
        exit 1
    fi
}

# 下载最新版本
download_latest() {
    echo -e "${YELLOW}正在下载最新版本...${NC}"
    local repo_url="https://github.com/your-repo/v2ray-manager"
    local temp_dir=$(mktemp -d)
    
    git clone "$repo_url" "$temp_dir" || {
        echo -e "${RED}下载失败${NC}"
        exit 1
    }

    mkdir -p "$INSTALL_DIR"
    cp -r "$temp_dir"/* "$INSTALL_DIR"/
    rm -rf "$temp_dir"
}

# 设置系统命令
setup_commands() {
    echo -e "${YELLOW}设置系统命令...${NC}"
    ln -sf "$INSTALL_DIR/v2ray-manager-main.sh" "$BIN_DIR/v2ray"
    chmod +x "$INSTALL_DIR"/*.sh
}

# 设置自动补全
setup_completion() {
    echo -e "${YELLOW}设置命令补全...${NC}"
    cat > "$COMPLETION_DIR/v2ray" <<'EOF'
_v2ray_commands() {
    local cur=${COMP_WORDS[COMP_CWORD]}
    COMPREPLY=( $(compgen -W "menu config service install update help" -- $cur) )
}
complete -F _v2ray_commands v2ray
EOF
}

# 初始化配置
init_config() {
    echo -e "${YELLOW}初始化配置...${NC}"
    mkdir -p "$CONFIG_DIR"
    [ -f "$CONFIG_DIR/config.json" ] || cp "$INSTALL_DIR/configs/default.json" "$CONFIG_DIR/config.json"
}

# 主安装流程
main() {
    check_root
    install_deps
    download_latest
    setup_commands
    setup_completion
    init_config
    
    echo -e "\n${GREEN}安装成功!${NC}"
    echo -e "使用命令:"
    echo -e "  v2ray menu       # 打开管理菜单"
    echo -e "  v2ray help       # 查看帮助\n"
}

main "$@"
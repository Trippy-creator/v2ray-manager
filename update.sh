#!/bin/bash
# V2Ray Manager 升级脚本

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

# 安装目录
INSTALL_DIR="/usr/local/share/v2ray-manager"
CONFIG_DIR="/etc/v2ray-manager"
REPO_URL="https://github.com/your-repo/v2ray-manager"
VERSION_FILE="$INSTALL_DIR/version"

# 获取当前版本
current_version() {
    [ -f "$VERSION_FILE" ] && cat "$VERSION_FILE" || echo "0.0.0"
}

# 获取最新版本
latest_version() {
    curl -s "$REPO_URL/raw/main/version" || echo "0.0.0"
}

# 检查更新
check_update() {
    echo -e "${YELLOW}正在检查更新...${NC}"
    local current=$(current_version)
    local latest=$(latest_version)
    
    if [ "$current" = "$latest" ]; then
        echo -e "${GREEN}当前已是最新版本 ($current)${NC}"
        exit 0
    fi
    
    echo -e "当前版本: ${YELLOW}$current${NC}"
    echo -e "最新版本: ${GREEN}$latest${NC}"
    read -p "是否要升级到最新版？[Y/n] " -n 1 -r
    echo
    [[ $REPLY =~ ^[Nn]$ ]] && exit 0
}

# 备份当前版本
backup_current() {
    echo -e "${YELLOW}备份当前版本...${NC}"
    local backup_dir="/tmp/v2ray-backup-$(date +%Y%m%d)"
    mkdir -p "$backup_dir"
    cp -r "$INSTALL_DIR" "$backup_dir/"
    echo -e "备份已保存到: $backup_dir"
}

# 执行升级
perform_upgrade() {
    echo -e "${YELLOW}开始升级...${NC}"
    local temp_dir=$(mktemp -d)
    
    echo -e "1. 下载最新版本"
    git clone "$REPO_URL" "$temp_dir" || {
        echo -e "${RED}下载失败${NC}"
        exit 1
    }
    
    echo -e "2. 停止运行的服务"
    "$INSTALL_DIR/src/service-manager.sh" stop_all
    
    echo -e "3. 安装新版本"
    rsync -a --delete "$temp_dir/" "$INSTALL_DIR/" --exclude=configs/
    
    echo -e "4. 恢复配置文件"
    [ -d "$CONFIG_DIR" ] && cp -r "$CONFIG_DIR"/* "$INSTALL_DIR/configs/"
    
    echo -e "5. 更新权限"
    chmod +x "$INSTALL_DIR"/*.sh
    chmod +x "$INSTALL_DIR"/src/*.sh
    
    rm -rf "$temp_dir"
}

# 验证升级
verify_upgrade() {
    echo -e "${YELLOW}验证安装...${NC}"
    if [ ! -f "$INSTALL_DIR/v2ray-manager-main.sh" ]; then
        echo -e "${RED}升级失败: 主脚本丢失${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}升级成功!${NC}"
    echo -e "新版本: $(cat "$INSTALL_DIR/version")"
    echo -e "使用命令: v2ray menu"
}

main() {
    check_update
    backup_current
    perform_upgrade
    verify_upgrade
}

main "$@"
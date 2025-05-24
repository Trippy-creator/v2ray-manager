#!/bin/bash
# V2Ray Manager 卸载脚本

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

# 安装目录
INSTALL_DIR="/usr/local/share/v2ray-manager"
BIN_LINK="/usr/local/bin/v2ray"
CONFIG_DIR="/etc/v2ray-manager"
COMPLETION_FILE="/etc/bash_completion.d/v2ray"

# 确认卸载
confirm_uninstall() {
    echo -e "${YELLOW}即将卸载 V2Ray Manager，此操作会：${NC}"
    echo -e " - 删除程序文件 ($INSTALL_DIR)"
    echo -e " - 移除系统命令 (v2ray)"
    echo -e " - 删除命令补全配置"
    echo -e "${RED}注意: 配置文件 ($CONFIG_DIR) 将保留${NC}"
    read -p "确定要卸载吗？[y/N] " -n 1 -r
    echo
    [[ $REPLY =~ ^[Yy]$ ]] || exit 0
}

# 停止运行的服务
stop_services() {
    echo -e "${YELLOW}停止运行的服务...${NC}"
    if [ -f "$INSTALL_DIR/src/service-manager.sh" ]; then
        "$INSTALL_DIR/src/service-manager.sh" stop_all
    fi
}

# 移除安装文件
remove_files() {
    echo -e "${YELLOW}移除程序文件...${NC}"
    
    # 移除系统命令
    [ -L "$BIN_LINK" ] && rm -f "$BIN_LINK"
    
    # 移除命令补全
    [ -f "$COMPLETION_FILE" ] && rm -f "$COMPLETION_FILE"
    
    # 移除程序目录
    [ -d "$INSTALL_DIR" ] && rm -rf "$INSTALL_DIR"
}

# 备份配置
backup_config() {
    local backup_dir="$HOME/v2ray-backup-$(date +%Y%m%d)"
    echo -e "${YELLOW}备份配置文件到 $backup_dir ...${NC}"
    
    mkdir -p "$backup_dir"
    [ -d "$CONFIG_DIR" ] && cp -r "$CONFIG_DIR" "$backup_dir/"
    
    echo -e "${GREEN}配置备份完成:${NC}"
    tree "$backup_dir"
}

main() {
    echo -e "\n${RED}=== V2Ray Manager 卸载程序 ===${NC}\n"
    confirm_uninstall
    stop_services
    backup_config
    remove_files
    
    echo -e "\n${GREEN}卸载完成!${NC}"
    echo -e "您的配置文件已保留在:"
    echo -e " - $CONFIG_DIR"
    echo -e " - $HOME/v2ray-backup-*"
    echo -e "\n如需完全清理，请手动删除上述目录\n"
}

main "$@"
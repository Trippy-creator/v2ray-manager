#!/bin/bash
# V2Ray Manager 版本回滚脚本

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

# 目录配置
INSTALL_DIR="/usr/local/share/v2ray-manager"
BACKUP_DIR="/var/lib/v2ray-manager/backups"
CONFIG_DIR="/etc/v2ray-manager"

# 检查root权限
check_root() {
    if [ "$(id -u)" != "0" ]; then
        echo -e "${RED}错误: 必须使用root用户运行此脚本${NC}"
        exit 1
    fi
}

# 列出可用备份
list_backups() {
    echo -e "${YELLOW}可用的备份版本:${NC}"
    local count=0
    for backup in "$BACKUP_DIR"/*; do
        if [ -d "$backup" ]; then
            local version=$(basename "$backup")
            local date=$(stat -c %y "$backup" | cut -d' ' -f1)
            echo -e "  $((++count)). ${GREEN}$version${NC} (备份于 $date)"
        fi
    done
    
    if [ "$count" -eq 0 ]; then
        echo -e "${RED}没有找到可用的备份${NC}"
        exit 1
    fi
}

# 选择备份版本
select_backup() {
    local backups=("$BACKUP_DIR"/*)
    read -p "选择要回滚的版本编号: " choice
    
    if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt "${#backups[@]}" ]; then
        echo -e "${RED}无效的选择${NC}"
        exit 1
    fi
    
    echo "${backups[$((choice-1))]}"
}

# 确认回滚
confirm_rollback() {
    echo -e "\n${RED}警告: 即将回滚到 $1 ${NC}"
    echo -e "这将:"
    echo -e " - 恢复程序文件到 $1 版本"
    echo -e " - 覆盖当前配置"
    echo -e " - 需要重启相关服务"
    read -p "确认要回滚吗？[y/N] " -n 1 -r
    echo
    [[ $REPLY =~ ^[Yy]$ ]] || exit 0
}

# 执行回滚
perform_rollback() {
    local target="$1"
    echo -e "${YELLOW}正在回滚到 $target ...${NC}"
    
    # 停止服务
    "$INSTALL_DIR/src/service-manager.sh" stop_all
    
    # 恢复程序文件
    echo -e "1. 恢复程序文件"
    rsync -a --delete "$target/" "$INSTALL_DIR/"
    
    # 恢复配置
    echo -e "2. 恢复配置文件"
    if [ -d "$target/configs" ]; then
        cp -r "$target/configs/"* "$CONFIG_DIR/"
    fi
    
    # 修复权限
    echo -e "3. 修复权限"
    chmod +x "$INSTALL_DIR"/*.sh
    chmod +x "$INSTALL_DIR"/src/*.sh
    
    echo -e "${GREEN}回滚完成!${NC}"
}

# 验证回滚
verify_rollback() {
    echo -e "${YELLOW}验证回滚结果...${NC}"
    if [ ! -f "$INSTALL_DIR/version" ]; then
        echo -e "${RED}回滚验证失败: 版本文件丢失${NC}"
        exit 1
    fi
    
    echo -e "当前版本: ${GREEN}$(cat "$INSTALL_DIR/version")${NC}"
    echo -e "使用命令: v2ray menu 启动管理界面"
}

main() {
    check_root
    echo -e "\n${RED}=== V2Ray Manager 版本回滚 ===${NC}\n"
    list_backups
    local backup=$(select_backup)
    confirm_rollback "$(basename "$backup")"
    perform_rollback "$backup"
    verify_rollback
}

main "$@"
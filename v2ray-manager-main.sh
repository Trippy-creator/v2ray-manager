#!/bin/bash
#
# V2Ray 统一管理入口脚本
# 支持命令: 
#   v2ray [menu|config|service|install|help]
# 示例:
#   v2ray menu       # 打开交互菜单
#   v2ray install    # 快速安装

# 自动检测调用方式
if [[ "$0" == "v2ray" || "$(basename "$0")" == "v2ray" ]]; then
    MODE="$1"
else
    MODE="menu"
fi
#
# V2Ray模块化管理主脚本
# 版本：2.1.0

# 初始化设置
set -euo pipefail
shopt -s nocasematch

### 全局配置 ##############################################################

# 基础目录
readonly BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SRC_DIR="${BASE_DIR}/src"

# 配置文件
readonly CONFIG_DIR="/etc/v2ray-manager"
readonly CONFIG_FILE="${CONFIG_DIR}/config.json"

# 加载模块
source "${SRC_DIR}/utils.sh"
source "${SRC_DIR}/config-manager.sh"
source "${SRC_DIR}/service-manager.sh"
source "${SRC_DIR}/install.sh"

### 主菜单 ###############################################################

show_main_menu() {
    clear
    log "INFO" "显示主菜单"
    
    echo -e "${GREEN}V2Ray 模块化管理脚本 v2.1.0${NC}"
    echo -e "${BLUE}================================${NC}"
    echo -e "1. 配置管理"
    echo -e "2. 服务管理" 
    echo -e "3. 安装更新"
    echo -e "4. 查看日志"
    echo -e "0. 退出"
    echo -e "${BLUE}================================${NC}"
    echo -n "请选择操作: "
}

### 主循环 ###############################################################

main() {
    # 初始化检查
    check_root
    check_dependencies
    
    # 创建必要目录
    mkdir -p "${CONFIG_DIR}"
    
    while true; do
        show_main_menu
        read -r choice
        
        case $choice in
            1) config_menu ;;
            2) service_menu ;;
            3) install_menu ;;
            4) show_logs ;;
            0) exit 0 ;;
            *) log "WARNING" "无效选择: $choice" ;;
        esac
        
        press_any_key
    done
}

# 启动主程序
main "$@"
#!/bin/bash
#
# V2Ray服务管理模块

### 初始化配置 ##########################################################

# 加载工具模块
source "${SRC_DIR}/utils.sh"

# 服务名称
readonly SERVICE_NAME="v2ray"
readonly SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"

### 服务菜单 ############################################################

service_menu() {
    while true; do
        clear
        log $LOG_INFO "显示服务管理菜单"
        
        echo -e "${GREEN}V2Ray 服务管理${NC}"
        echo -e "${BLUE}================================${NC}"
        echo -e "1. 启动服务"
        echo -e "2. 停止服务"
        echo -e "3. 重启服务"
        echo -e "4. 查看状态"
        echo -e "5. 查看日志"
        echo -e "6. 性能监控"
        echo -e "0. 返回主菜单"
        echo -e "${BLUE}================================${NC}"
        echo -n "请选择操作: "
        
        read -r choice
        case $choice in
            1) start_service ;;
            2) stop_service ;;
            3) restart_service ;;
            4) check_status ;;
            5) show_logs ;;
            6) monitor_performance ;;
            0) return ;;
            *) log $LOG_WARNING "无效选择: $choice" ;;
        esac
        
        press_any_key
    done
}

### 服务操作 ############################################################

# 检查服务状态
check_status() {
    log $LOG_INFO "检查服务状态"
    
    if systemctl is-active --quiet "$SERVICE_NAME"; then
        echo -e "${GREEN}服务正在运行${NC}"
        systemctl status "$SERVICE_NAME" --no-pager
    else
        echo -e "${YELLOW}服务未运行${NC}"
    fi
    
    # 显示监听端口
    echo -e "\n${CYAN}当前监听端口:${NC}"
    ss -tulnp | grep v2ray || echo "没有找到V2Ray监听端口"
}

# 启动服务
start_service() {
    log $LOG_INFO "启动V2Ray服务"
    
    if systemctl is-active --quiet "$SERVICE_NAME"; then
        log $LOG_WARNING "服务已经在运行"
        return
    fi
    
    if ! systemctl start "$SERVICE_NAME"; then
        log $LOG_ERROR "服务启动失败"
        journalctl -u "$SERVICE_NAME" -n 10 --no-pager
        return 1
    fi
    
    log $LOG_INFO "服务启动成功"
    check_status
}

# 停止服务
stop_service() {
    log $LOG_INFO "停止V2Ray服务"
    
    if ! systemctl is-active --quiet "$SERVICE_NAME"; then
        log $LOG_WARNING "服务已经停止"
        return
    fi
    
    if ! systemctl stop "$SERVICE_NAME"; then
        log $LOG_ERROR "服务停止失败"
        journalctl -u "$SERVICE_NAME" -n 10 --no-pager
        return 1
    fi
    
    log $LOG_INFO "服务停止成功"
    check_status
}

# 重启服务
restart_service() {
    log $LOG_INFO "重启V2Ray服务"
    
    if ! systemctl restart "$SERVICE_NAME"; then
        log $LOG_ERROR "服务重启失败"
        journalctl -u "$SERVICE_NAME" -n 10 --no-pager
        return 1
    fi
    
    log $LOG_INFO "服务重启成功"
    check_status
}

# 查看日志
show_logs() {
    log $LOG_INFO "显示服务日志"
    
    echo -e "${GREEN}最近50条日志:${NC}"
    journalctl -u "$SERVICE_NAME" -n 50 --no-pager
    
    echo -e "\n${YELLOW}按F键跟踪实时日志，按Q键退出${NC}"
    read -n 1 -s -r -p "按任意键继续..."
    
    if [[ $REPLY == "f" ]] || [[ $REPLY == "F" ]]; then
        journalctl -u "$SERVICE_NAME" -f
    fi
}

# 监控性能
monitor_performance() {
    log $LOG_INFO "监控服务性能"
    
    echo -e "${GREEN}资源使用情况:${NC}"
    top -bn1 | grep -i v2ray || echo "没有找到V2Ray进程"
    
    echo -e "\n${CYAN}网络连接:${NC}"
    ss -tup | grep v2ray || echo "没有V2Ray网络连接"
    
    echo -e "\n${YELLOW}按R键刷新，按其他键退出${NC}"
    read -n 1 -s -t 5 -r
    
    if [[ $REPLY == "r" ]] || [[ $REPLY == "R" ]]; then
        clear
        monitor_performance
    fi
}

# 初始化服务配置
init_service() {
    log $LOG_INFO "初始化服务配置"
    
    if [[ -f "$SERVICE_FILE" ]]; then
        log $LOG_DEBUG "服务文件已存在"
        return
    fi
    
    cat > "$SERVICE_FILE" <<EOF
[Unit]
Description=V2Ray Service
After=network.target

[Service]
User=root
ExecStart=/usr/local/bin/v2ray -config $CONFIG_FILE
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable "$SERVICE_NAME" --now
    log $LOG_INFO "服务配置初始化完成"
}
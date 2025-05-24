#!/bin/bash
#
# V2Ray管理工具模块
# 包含通用函数和工具

### 常量定义 #############################################################

# 颜色定义
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[0;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color

# 日志级别
readonly LOG_DEBUG=0
readonly LOG_INFO=1
readonly LOG_WARNING=2
readonly LOG_ERROR=3

# 全局配置
readonly LOG_FILE="/var/log/v2ray-manager.log"

### 日志函数 #############################################################

# 记录日志
# 参数: 日志级别 日志内容
log() {
    local level=$1
    local message=$2
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    
    # 确定日志级别和颜色
    local level_str
    local color
    case $level in
        $LOG_DEBUG)
            level_str="DEBUG"
            color=$CYAN
            ;;
        $LOG_INFO)
            level_str="INFO" 
            color=$BLUE
            ;;
        $LOG_WARNING)
            level_str="WARNING"
            color=$YELLOW
            ;;
        $LOG_ERROR)
            level_str="ERROR"
            color=$RED
            ;;
        *)
            level_str="UNKNOWN"
            color=$NC
            ;;
    esac
    
    # 输出到屏幕和日志文件
    echo -e "${color}[${timestamp}] [${level_str}] ${message}${NC}"
    echo "[${timestamp}] [${level_str}] ${message}" >> "$LOG_FILE"
}

### 验证函数 #############################################################

# 检查root权限
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log $LOG_ERROR "此脚本必须以root用户运行"
        exit 1
    fi
}

# 检查命令是否存在
check_command() {
    local cmd=$1
    if ! command -v "$cmd" &> /dev/null; then
        log $LOG_ERROR "命令 $cmd 未找到"
        return 1
    fi
    return 0
}

# 检查端口是否可用
check_port() {
    local port=$1
    if ! [[ $port =~ ^[0-9]+$ ]] || ((port < 1 || port > 65535)); then
        log $LOG_WARNING "无效端口号: $port"
        return 1
    fi
    
    if ss -tuln | grep -q ":$port "; then
        log $LOG_WARNING "端口 $port 已被占用"
        return 1
    fi
    return 0
}

### 工具函数 #############################################################

# 生成UUID
generate_uuid() {
    if check_command "uuidgen"; then
        uuidgen
    else
        cat /proc/sys/kernel/random/uuid
    fi
}

# 等待按键继续
press_any_key() {
    read -n 1 -s -r -p "按任意键继续..."
    echo
}

# 验证JSON格式
validate_json() {
    local json_file=$1
    if ! jq empty "$json_file" &>/dev/null; then
        log $LOG_ERROR "无效的JSON格式: $json_file"
        return 1
    fi
    return 0
}
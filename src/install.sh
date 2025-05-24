#!/bin/bash
#
# V2Ray安装管理模块

### 初始化配置 ##########################################################

# 加载工具模块
source "${SRC_DIR}/utils.sh"

# 安装配置
readonly V2RAY_VERSION="latest"
readonly V2RAY_URL="https://github.com/v2fly/v2ray-core/releases/download"
readonly TEMP_DIR="/tmp/v2ray-install"

### 安装菜单 ############################################################

install_menu() {
    while true; do
        clear
        log $LOG_INFO "显示安装管理菜单"
        
        echo -e "${GREEN}V2Ray 安装管理${NC}"
        echo -e "${BLUE}================================${NC}"
        echo -e "1. 全新安装"
        echo -e "2. 更新V2Ray"
        echo -e "3. 卸载V2Ray" 
        echo -e "4. 修复安装"
        echo -e "0. 返回主菜单"
        echo -e "${BLUE}================================${NC}"
        echo -n "请选择操作: "
        
        read -r choice
        case $choice in
            1) full_install ;;
            2) update_v2ray ;;
            3) uninstall_v2ray ;;
            4) repair_install ;;
            0) return ;;
            *) log $LOG_WARNING "无效选择: $choice" ;;
        esac
        
        press_any_key
    done
}

### 安装功能 ############################################################

# 全新安装
full_install() {
    log $LOG_INFO "开始全新安装V2Ray"
    
    # 检查现有安装
    if check_v2ray_installed; then
        log $LOG_WARNING "V2Ray已安装，请使用更新功能"
        return 1
    fi
    
    # 安装依赖
    install_dependencies
    
    # 安装V2Ray核心
    install_v2ray_core
    
    # 初始化配置
    init_config
    
    # 配置服务
    "${SRC_DIR}/service-manager.sh" init_service
    
    log $LOG_INFO "V2Ray安装完成"
    check_status
}

# 安装依赖
install_dependencies() {
    log $LOG_INFO "安装系统依赖"
    
    local pkg_manager
    if command -v apt-get &> /dev/null; then
        pkg_manager="apt-get"
    elif command -v yum &> /dev/null; then
        pkg_manager="yum"
    elif command -v dnf &> /dev/null; then
        pkg_manager="dnf"
    elif command -v pacman &> /dev/null; then
        pkg_manager="pacman"
    else
        log $LOG_ERROR "不支持的包管理器"
        return 1
    fi
    
    case $pkg_manager in
        "apt-get")
            apt-get update -q
            apt-get install -y -q curl wget unzip jq
            ;;
        "yum"|"dnf")
            $pkg_manager install -y -q curl wget unzip jq
            ;;
        "pacman")
            pacman -Syu --noconfirm --needed curl wget unzip jq
            ;;
    esac
    
    log $LOG_INFO "依赖安装完成"
}

# 安装V2Ray核心
install_v2ray_core() {
    log $LOG_INFO "安装V2Ray核心"
    
    mkdir -p "$TEMP_DIR"
    cd "$TEMP_DIR" || return 1
    
    # 检测系统架构
    local arch
    case $(uname -m) in
        "x86_64") arch="64" ;;
        "aarch64") arch="arm64-v8a" ;;
        "armv7l") arch="arm32-v7a" ;;
        *) arch="64" ;;
    esac
    
    # 下载V2Ray
    local pkg_name="v2ray-linux-${arch}.zip"
    local download_url="${V2RAY_URL}/${V2RAY_VERSION}/${pkg_name}"
    
    if ! curl -sL "$download_url" -o "$pkg_name"; then
        log $LOG_ERROR "下载V2Ray失败"
        return 1
    fi
    
    # 解压安装
    unzip -q "$pkg_name"
    cp v2ray v2ctl /usr/local/bin/
    cp geoip.dat geosite.dat /usr/local/bin/
    chmod +x /usr/local/bin/v2ray /usr/local/bin/v2ctl
    
    # 清理临时文件
    cd "$BASE_DIR" || return 1
    rm -rf "$TEMP_DIR"
    
    log $LOG_INFO "V2Ray核心安装完成"
}

# 初始化配置
init_config() {
    log $LOG_INFO "初始化配置文件"
    
    mkdir -p "$CONFIG_DIR"
    
    if [[ ! -f "$CONFIG_FILE" ]]; then
        cat > "$CONFIG_FILE" <<EOF
{
    "inbounds": [],
    "outbounds": [
        {
            "protocol": "freedom",
            "settings": {}
        }
    ],
    "routing": {
        "domainStrategy": "AsIs",
        "rules": []
    }
}
EOF
        log $LOG_INFO "默认配置文件已创建"
    else
        log $LOG_DEBUG "配置文件已存在，跳过创建"
    fi
}

# 检查V2Ray是否安装
check_v2ray_installed() {
    if [[ -f "/usr/local/bin/v2ray" ]]; then
        return 0
    fi
    return 1
}

# 更新V2Ray
update_v2ray() {
    log $LOG_INFO "开始更新V2Ray"
    
    if ! check_v2ray_installed; then
        log $LOG_WARNING "V2Ray未安装，请先执行全新安装"
        return 1
    fi
    
    # 备份当前配置
    local backup_file="${CONFIG_DIR}/config-$(date +%Y%m%d).json"
    cp "$CONFIG_FILE" "$backup_file"
    log $LOG_INFO "配置文件已备份到: $backup_file"
    
    # 安装新版本
    install_v2ray_core
    
    log $LOG_INFO "V2Ray更新完成，请手动重启服务"
}

# 卸载V2Ray
uninstall_v2ray() {
    log $LOG_INFO "开始卸载V2Ray"
    
    read -rp "确定要卸载V2Ray吗？(y/n): " confirm
    if [[ "$confirm" != "y" ]]; then
        log $LOG_INFO "取消卸载"
        return
    fi
    
    # 停止服务
    "${SRC_DIR}/service-manager.sh" stop_service
    
    # 删除文件
    rm -f /usr/local/bin/v2ray /usr/local/bin/v2ctl
    rm -f /usr/local/bin/geoip.dat /usr/local/bin/geosite.dat
    rm -f "$SERVICE_FILE"
    
    log $LOG_INFO "V2Ray已卸载，配置文件保留在: $CONFIG_DIR"
}

# 修复安装
repair_install() {
    log $LOG_INFO "开始修复安装"
    
    # 重新安装核心
    install_v2ray_core
    
    # 修复服务配置
    "${SRC_DIR}/service-manager.sh" init_service
    
    log $LOG_INFO "修复安装完成"
}

# 检查安装状态
check_status() {
    echo -e "${GREEN}V2Ray安装状态:${NC}"
    if check_v2ray_installed; then
        echo -e "${GREEN}✓ V2Ray已安装${NC}"
        /usr/local/bin/v2ray -version | head -n 1
    else
        echo -e "${RED}✗ V2Ray未安装${NC}"
    fi
    
    echo -e "\n${GREEN}配置文件:${NC} $CONFIG_FILE"
    echo -e "${GREEN}服务状态:${NC}"
    systemctl status "$SERVICE_NAME" --no-pager || echo "服务未配置"
}
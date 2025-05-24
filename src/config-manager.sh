#!/bin/bash
#
# V2Ray配置管理模块

### 初始化配置 ##########################################################

# 加载工具模块
source "${SRC_DIR}/utils.sh"

# 协议类型定义
readonly PROTOCOLS=(
    "vmess" "vless" "trojan" "shadowsocks" 
    "socks" "http" "dns" "mtproto"
)
readonly SECURITYS=("auto" "aes-128-gcm" "chacha20-poly1305" "none")
readonly NETWORKS=("tcp" "kcp" "ws" "h2" "quic" "grpc")

### 配置菜单 ############################################################

config_menu() {
    while true; do
        clear
        log $LOG_INFO "显示配置管理菜单"
        
        echo -e "${GREEN}V2Ray 配置管理${NC}"
        echo -e "${BLUE}================================${NC}"
        echo -e "1. 添加入站配置"
        echo -e "2. 列出当前配置"
        echo -e "3. 删除入站配置"
        echo -e "4. 生成客户端配置"
        echo -e "0. 返回主菜单"
        echo -e "${BLUE}================================${NC}"
        echo -n "请选择操作: "
        
        read -r choice
        case $choice in
            1) add_inbound ;;
            2) list_inbounds ;;
            3) delete_inbound ;;
            4) generate_client ;;
            0) return ;;
            *) log $LOG_WARNING "无效选择: $choice" ;;
        esac
        
        press_any_key
    done
}

### 配置操作 ############################################################

# 添加入站配置
add_inbound() {
    log $LOG_INFO "开始添加入站配置"
    
    # 选择协议
    echo -e "${GREEN}>>> 选择协议类型${NC}"
    select protocol in "${PROTOCOLS[@]}"; do
        [[ -n $protocol ]] && break
    done
    
    # 输入端口
    while true; do
        read -rp "请输入监听端口(1-65535): " port
        if check_port "$port"; then
            break
        fi
    done
    
    # 生成UUID
    local uuid=$(generate_uuid)
    log $LOG_DEBUG "生成UUID: $uuid"
    
    # 选择传输方式
    echo -e "${GREEN}>>> 选择传输协议${NC}"
    select network in "${NETWORKS[@]}"; do
        [[ -n $network ]] && break
    done
    
    # 根据协议生成配置
        local inbound_config
        case $protocol in
            "vmess"|"vless"|"trojan")
                inbound_config=$(cat <<EOF
    {
        "port": $port,
        "protocol": "$protocol",
        "settings": {
            "clients": [
                {
                    "id": "$uuid",
                    "level": 0
                }
            ]
        },
        "streamSettings": {
            "network": "$network"
        }
    }
    EOF
                )
                ;;
            "shadowsocks")
                local password=$(openssl rand -base64 16 | tr -d '=+')
                inbound_config=$(cat <<EOF
    {
        "port": $port,
        "protocol": "$protocol",
        "settings": {
            "method": "aes-256-gcm",
            "password": "$password",
            "network": "$network"
        }
    }
    EOF
                )
                ;;
            "socks"|"http")
                read -rp "输入认证用户名: " username
                read -rp "输入认证密码: " password
                inbound_config=$(cat <<EOF
    {
        "port": $port,
        "protocol": "$protocol",
        "settings": {
            "auth": "password",
            "accounts": [
                {
                    "user": "$username",
                    "pass": "$password"
                }
            ],
            "network": "$network"
        }
    }
    EOF
                )
                ;;
            "dns")
                inbound_config=$(cat <<EOF
    {
        "port": 53,
        "protocol": "dns",
        "settings": {
            "servers": [
                {
                    "address": "1.1.1.1",
                    "port": 53,
                    "domains": ["geosite:geolocation-!cn"]
                }
            ]
        }
    }
    EOF
                )
                ;;
            "mtproto")
                local secret=$(openssl rand -hex 16)
                inbound_config=$(cat <<EOF
    {
        "port": $port,
        "protocol": "mtproto",
        "settings": {
            "users": [
                {
                    "secret": "$secret"
                }
            ]
        }
    }
    EOF
                )
                ;;
        esac
    
    # 更新配置文件
    update_config "$inbound_config"
}

# 更新配置文件
update_config() {
    local config=$1
    local temp_file="${CONFIG_FILE}.tmp"
    
    if ! jq --argjson new "$config" '.inbounds += [$new]' "$CONFIG_FILE" > "$temp_file"; then
        log $LOG_ERROR "配置更新失败"
        return 1
    fi
    
    if ! validate_json "$temp_file"; then
        log $LOG_ERROR "生成无效的JSON配置"
        rm -f "$temp_file"
        return 1
    fi
    
    mv "$temp_file" "$CONFIG_FILE"
    log $LOG_INFO "配置更新成功"
    echo -e "${GREEN}当前配置:${NC}"
    jq '.' "$CONFIG_FILE"
}

# 列出所有入站配置
list_inbounds() {
    log $LOG_INFO "列出当前配置"
    
    if ! jq -e '.inbounds[]' "$CONFIG_FILE" &>/dev/null; then
        log $LOG_WARNING "没有找到入站配置"
        return
    fi
    
    echo -e "${GREEN}当前入站配置:${NC}"
    jq '.inbounds[] | "\(.protocol)://[::]:\(.port) [\(.streamSettings.network)]"' "$CONFIG_FILE"
}

# 删除入站配置
delete_inbound() {
    log $LOG_INFO "开始删除入站配置"
    
    list_inbounds
    echo -e "${YELLOW}请输入要删除的配置序号: ${NC}"
    read -r index
    
    local count=$(jq '.inbounds | length' "$CONFIG_FILE")
    if ! [[ $index =~ ^[0-9]+$ ]] || ((index < 0 || index >= count)); then
        log $LOG_ERROR "无效的配置序号"
        return 1
    fi
    
    local temp_file="${CONFIG_FILE}.tmp"
    jq "del(.inbounds[$index])" "$CONFIG_FILE" > "$temp_file" && \
    mv "$temp_file" "$CONFIG_FILE"
    
    log $LOG_INFO "配置删除成功"
    list_inbounds
}

# 生成客户端配置
generate_client() {
    log $LOG_INFO "生成客户端配置"
    
    list_inbounds
    echo -e "${YELLOW}请选择要导出的配置序号: ${NC}"
    read -r index
    
    local count=$(jq '.inbounds | length' "$CONFIG_FILE")
    if ! [[ $index =~ ^[0-9]+$ ]] || ((index < 0 || index >= count)); then
        log $LOG_ERROR "无效的配置序号"
        return 1
    fi
    
    local protocol=$(jq -r ".inbounds[$index].protocol" "$CONFIG_FILE")
    local output_file="v2ray-client-${protocol}-$(date +%Y%m%d).json"
    local client_config
    
    case $protocol in
        "vmess"|"vless"|"trojan")
            client_config=$(jq ".inbounds[$index]" "$CONFIG_FILE")
            ;;
        "shadowsocks")
            local method=$(jq -r ".inbounds[$index].settings.method" "$CONFIG_FILE")
            local password=$(jq -r ".inbounds[$index].settings.password" "$CONFIG_FILE")
            local server_ip=$(curl -s ifconfig.me)
            local port=$(jq -r ".inbounds[$index].port" "$CONFIG_FILE")
            client_config="ss://$(echo -n "${method}:${password}@${server_ip}:${port}" | base64 -w 0)#V2Ray-Manager"
            ;;
        "socks"|"http")
            local username=$(jq -r ".inbounds[$index].settings.accounts[0].user" "$CONFIG_FILE")
            local password=$(jq -r ".inbounds[$index].settings.accounts[0].pass" "$CONFIG_FILE")
            local server_ip=$(curl -s ifconfig.me)
            local port=$(jq -r ".inbounds[$index].port" "$CONFIG_FILE")
            client_config="${protocol}://${username}:${password}@${server_ip}:${port}"
            ;;
        "mtproto")
            local secret=$(jq -r ".inbounds[$index].settings.users[0].secret" "$CONFIG_FILE")
            client_config="tg://proxy?server=$(curl -s ifconfig.me)&port=$(jq -r ".inbounds[$index].port" "$CONFIG_FILE")&secret=${secret}"
            ;;
        *)
            client_config=$(jq ".inbounds[$index]" "$CONFIG_FILE")
            ;;
    esac
    
    echo "$client_config" > "$output_file"
    log $LOG_INFO "客户端配置已保存到: $output_file"
    
    # 生成二维码
    if check_command "qrencode"; then
        echo -e "\n${CYAN}扫描二维码导入配置:${NC}"
        qrencode -t UTF8 -o - <<< "$client_config"
    fi
    
    # 显示分享链接
    if [[ $protocol == "vmess" ]]; then
        local vmess_link=$(echo -n "$client_config" | base64 -w 0)
        echo -e "\n${CYAN}VMess分享链接:${NC}"
        echo "vmess://$vmess_link"
    fi
}
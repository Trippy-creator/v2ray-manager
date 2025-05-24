# V2Ray Manager 变更日志

## [1.0.0] - 2023-11-20
### 新增功能
- 全协议支持：VMess/VLESS/Trojan/Shadowsocks/Socks/HTTP/DNS/MTProto
- 一键安装脚本：`bash <(curl -sL https://git.io/v2ray.sh)`
- 系统命令集成：`v2ray [menu|config|service|install|update]`
- 交互式配置向导
- 客户端配置导出与二维码生成

### 改进优化
- 模块化脚本结构
- 彩色终端输出
- 详细的日志记录
- 自动补全支持
- 配置验证检查

### 修复问题
- 修复Shadowsocks密码生成问题
- 修正MTProto密钥格式
- 解决DNS配置保存错误
- 修复服务管理竞争条件

## [0.9.0] - 2023-10-15
### 初始版本
- 基础VMess/VLESS支持
- 简单配置管理
- 基本服务控制

---

> 完整更新历史请参考Git提交记录
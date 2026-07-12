#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Xray + Caddy + Cloudflare CDN 一键部署脚本
# 架构: 用户 → CF CDN → Caddy(443/TLS) → Xray(本地/WS)
# 用法: DOMAIN=你的域名 PORT=10000 PATH=/ws bash setup-xray-caddy.sh
# ============================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log()  { echo -e "${GREEN}[+]${NC} $*"; }
warn() { echo -e "${YELLOW}[!]${NC} $*"; }
err()  { echo -e "${RED}[-]${NC} $*"; }
info() { echo -e "${CYAN}[*]${NC} $*"; }

if [[ $EUID -ne 0 ]]; then
    err "请用 root 运行: sudo bash $0"
    exit 1
fi

# ---- 参数 ----
WS_PORT="${WS_PORT:-10000}"       # Xray 本地 WS 端口
WS_PATH="${WS_PATH:-$(openssl rand -hex 8)}"  # 随机 WS 路径
DOMAIN="${DOMAIN:-}"

echo ""
echo -e "${CYAN}============================================${NC}"
echo -e "  Xray + Caddy + Cloudflare CDN 部署脚本"
echo -e "${CYAN}============================================${NC}"
echo ""

# 如果没有通过环境变量传域名，交互式询问
if [[ -z "$DOMAIN" ]]; then
    read -rp "请输入你的域名 (如 node.example.com): " DOMAIN
    if [[ -z "$DOMAIN" ]]; then
        err "域名不能为空"
        exit 1
    fi
fi

log "域名:    $DOMAIN"
log "WS 端口: $WS_PORT"
log "WS 路径: /$WS_PATH"
echo ""

# ---- 安装 Xray ----
if command -v xray &>/dev/null; then
    log "Xray 已安装: $(xray version | head -1)"
else
    info "安装 Xray-core..."
    bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install
    log "Xray 安装完成"
fi

# ---- 修复 systemd nobody 用户 ----
SERVICE_FILE=/etc/systemd/system/xray.service
if [ -f "$SERVICE_FILE" ] && grep -q 'User=nobody' "$SERVICE_FILE"; then
    log "修复 systemd 单元..."
    if ! id xray &>/dev/null; then
        useradd -r -d /var/lib/xray -s /usr/sbin/nologin xray 2>/dev/null || true
    fi
    sed -i 's/User=nobody/User=xray/' "$SERVICE_FILE"
    systemctl daemon-reload
fi

# ---- 生成密钥 ----
info "生成 VMess UUID..."
UUID=$(xray uuid)
log "UUID: $UUID"

# ---- 生成 Xray 配置 ----
CONFIG=/usr/local/etc/xray/config.json
if [ -f "$CONFIG" ]; then
    cp "$CONFIG" "${CONFIG}.bak.$(date +%s)"
    log "旧配置已备份"
fi

log "生成 Xray 配置文件..."
cat > "$CONFIG" <<EOF
{
  "log": {
    "loglevel": "warning"
  },
  "inbounds": [
    {
      "listen": "127.0.0.1",
      "port": $WS_PORT,
      "protocol": "vmess",
      "settings": {
        "clients": [
          {
            "id": "$UUID",
            "alterId": 0
          }
        ]
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {
          "path": "/$WS_PATH"
        }
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom",
      "tag": "direct"
    }
  ]
}
EOF

log "配置文件已写入 $CONFIG"

# ---- 防火墙 ----
info "配置防火墙 (仅需放行 443, WS 端口只在本地监听不需放行)..."

if command -v ufw &>/dev/null && ufw status | grep -q "Status: active"; then
    ufw allow 443/tcp 2>/dev/null || true
    log "ufw: 443/tcp 已放行"
elif command -v firewall-cmd &>/dev/null && systemctl is-active --quiet firewalld 2>/dev/null; then
    firewall-cmd --permanent --add-port=443/tcp 2>/dev/null || true
    firewall-cmd --reload 2>/dev/null || true
    log "firewalld: 443/tcp 已放行"
elif command -v iptables &>/dev/null; then
    iptables -I INPUT -p tcp --dport 443 -j ACCEPT 2>/dev/null || true
    netfilter-persistent save 2>/dev/null || iptables-save > /etc/iptables/rules.v4 2>/dev/null || true
    log "iptables: 443/tcp 已放行"
fi

warn "记得去云服务商控制台放行 443/tcp 端口!"

# ---- 启动 Xray ----
info "启动 Xray..."
systemctl enable xray
systemctl restart xray
sleep 1

if systemctl is-active --quiet xray; then
    log "Xray 运行中"
else
    err "Xray 启动失败, 查看: journalctl -u xray -e"
    exit 1
fi

if ss -tlnp | grep "127.0.0.1:$WS_PORT" > /dev/null; then
    log "本地端口 127.0.0.1:$WS_PORT 监听正常"
else
    err "本地端口未监听, 查看: journalctl -u xray -e"
    exit 1
fi

# ---- 输出信息 ----
SERVER_IP=$(curl -s4 ifconfig.me 2>/dev/null || curl -s4 ip.sb 2>/dev/null || echo "YOUR_IP")

echo ""
echo -e "${CYAN}============================================${NC}"
echo -e " ${GREEN}Xray 部署完成!${NC}"
echo -e "${CYAN}============================================${NC}"
echo ""
echo -e " ${YELLOW}【1】Caddy 配置 (粘贴到 Caddyfile):${NC}"
echo ""
echo -e "  ${GREEN}${DOMAIN} {${NC}"
echo -e "      reverse_proxy ${GREEN}/${WS_PATH}${NC} 127.0.0.1:${WS_PORT}"
echo -e "  ${GREEN}}${NC}"
echo ""
echo -e " ${YELLOW}【2】Cloudflare DNS 设置:${NC}"
echo "  类型: A 记录"
echo "  名称: ${DOMAIN%%.*}"
echo "  内容: $SERVER_IP"
echo -e "  代理: ${GREEN}开启 (橙色云朵)${NC}"
echo -e "  SSL/TLS: ${GREEN}Full 或 Full (strict)${NC}"
echo ""
echo -e " ${YELLOW}【3】v2rayA 节点信息:${NC}"
echo "  地址:       $DOMAIN"
echo "  端口:       443"
echo "  协议:       VMess"
echo "  传输:       ws"
echo "  路径:       /$WS_PATH"
echo "  TLS:        开启"
echo "  UUID:       $UUID"
echo "  alterId:    0"
echo ""
echo -e " ${CYAN}VMess 分享链接 (v2rayA 直接导入):${NC}"
VMESS_BASE=$(echo -n "{\"v\":\"2\",\"ps\":\"${DOMAIN}\",\"add\":\"${DOMAIN}\",\"port\":\"443\",\"id\":\"${UUID}\",\"aid\":\"0\",\"scy\":\"auto\",\"net\":\"ws\",\"type\":\"none\",\"host\":\"${DOMAIN}\",\"path\":\"/${WS_PATH}\",\"tls\":\"tls\",\"sni\":\"${DOMAIN}\",\"alpn\":\"\"}" | base64 -w0)
echo "  vmess://${VMESS_BASE}"
echo ""
echo -e " ${CYAN}【4】常用命令:${NC}"
echo "  systemctl status xray     # 查看状态"
echo "  journalctl -u xray -f     # 实时日志"
echo "  caddy fmt --overwrite     # Caddy 配置格式化"
echo "  systemctl reload caddy    # Caddy 重载配置"
echo ""
echo -e " ${YELLOW}装完 Caddy 后执行 'systemctl reload caddy' 即可生效${NC}"
echo -e "${CYAN}============================================${NC}"

#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Xray + VLESS + Reality 一键部署脚本
# 每步都会打印说明，不是黑盒
# 用法: bash <(curl -fsSL https://...) 或直接 bash setup-xray-reality.sh
# ============================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

log()  { echo -e "${GREEN}[+]${NC} $*"; }
warn() { echo -e "${YELLOW}[!]${NC} $*"; }
err()  { echo -e "${RED}[-]${NC} $*"; }
info() { echo -e "${CYAN}[*]${NC} $*"; }

# ---- 检查 root ----
if [[ $EUID -ne 0 ]]; then
    err "请用 root 运行: sudo bash $0"
    exit 1
fi

# ---- 可配置参数 (可通过环境变量覆盖) ----
PORT="${PORT:-443}"
DEST_SITE="${DEST_SITE:-www.microsoft.com:443}"
SHORT_ID_LEN=8

# ============================================================
# Step 1: 检查系统
# ============================================================
info "Step 1/6: 检查系统环境"
log "系统: $(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
log "架构: $(uname -m)"
log "内存: $(free -h | awk '/^Mem:/{print $2}')"

# ============================================================
# Step 2: 安装 Xray-core
# ============================================================
info "Step 2/6: 安装 Xray-core"

if command -v xray &>/dev/null; then
    log "Xray 已安装: $(xray version | head -1)"
    warn "如需重新生成配置，继续执行；如需全新安装请先卸载 Xray"
else
    log "下载并安装 Xray-core (官方脚本)..."
    bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install
    log "安装完成: $(xray version | head -1)"
fi

# ---- 修复 systemd User=nobody 警告 ----
SERVICE_FILE=/etc/systemd/system/xray.service
if [ -f "$SERVICE_FILE" ] && grep -q 'User=nobody' "$SERVICE_FILE"; then
    log "修复 systemd 单元 (nobody -> xray 用户)..."
    if ! id xray &>/dev/null; then
        useradd -r -d /var/lib/xray -s /usr/sbin/nologin xray 2>/dev/null || true
    fi
    sed -i 's/User=nobody/User=xray/' "$SERVICE_FILE"
    systemctl daemon-reload
    log "systemd 单元已修复"
fi

# ============================================================
# Step 3: 生成密钥和 UUID
# ============================================================
info "Step 3/6: 生成 Reality 密钥和 UUID"

log "生成 x25519 密钥对..."
# 实际输出格式:
#   PrivateKey: xxxxx
#   Password (PublicKey): xxxxx
#   Hash32: xxxxx      (忽略)
KEYS=$(xray x25519 2>&1)
PRIVATE_KEY=$(echo "$KEYS" | awk -F': *' '/^PrivateKey:/{print $2}')
PUBLIC_KEY=$(echo "$KEYS"  | awk -F': *' '/PublicKey\)/{print $2}')

if [[ -z "$PRIVATE_KEY" ]] || [[ -z "$PUBLIC_KEY" ]]; then
    err "密钥提取失败，xray x25519 原始输出:"
    echo "$KEYS"
    exit 1
fi

log "私钥: $PRIVATE_KEY"
log "公钥: $PUBLIC_KEY"

log "生成 UUID..."
UUID=$(xray uuid)
log "UUID: $UUID"

log "生成 shortId..."
SHORT_ID=$(openssl rand -hex $SHORT_ID_LEN)
log "shortId: $SHORT_ID"

# ============================================================
# Step 4: 生成配置文件
# ============================================================
info "Step 4/6: 生成 Xray 配置文件"
log "目标站点: $DEST_SITE"
log "端口: $PORT"

# 从 dest 提取 serverName
SITE_DOMAIN="${DEST_SITE%:*}"  # 去掉 :443

CONFIG=/usr/local/etc/xray/config.json

# 如果已有配置，先备份
if [ -f "$CONFIG" ]; then
    BACKUP="${CONFIG}.bak.$(date +%s)"
    cp "$CONFIG" "$BACKUP"
    log "旧配置已备份到 $BACKUP"
fi

log "写入 $CONFIG ..."
cat > "$CONFIG" <<EOF
{
  "log": {
    "loglevel": "warning"
  },
  "inbounds": [
    {
      "listen": "0.0.0.0",
      "port": $PORT,
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "id": "$UUID",
            "flow": "xtls-rprx-vision"
          }
        ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "tcp",
        "security": "reality",
        "realitySettings": {
          "dest": "$DEST_SITE",
          "serverNames": [
            "$SITE_DOMAIN"
          ],
          "privateKey": "$PRIVATE_KEY",
          "shortIds": [
            "$SHORT_ID"
          ]
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

log "配置文件已生成"

# ============================================================
# Step 5: 配置防火墙
# ============================================================
info "Step 5/6: 配置防火墙"

# 尝试 ufw
if command -v ufw &>/dev/null && ufw status | grep -q "Status: active"; then
    log "检测到 ufw, 开放 $PORT 端口..."
    ufw allow "$PORT"/tcp
    log "ufw 已放行"

# 尝试 firewalld
elif command -v firewall-cmd &>/dev/null && systemctl is-active --quiet firewalld 2>/dev/null; then
    log "检测到 firewalld, 开放 $PORT 端口..."
    firewall-cmd --permanent --add-port="$PORT"/tcp
    firewall-cmd --reload
    log "firewalld 已放行"

# bare iptables
elif command -v iptables &>/dev/null; then
    log "使用 iptables 开放 $PORT 端口..."
    iptables -I INPUT -p tcp --dport "$PORT" -j ACCEPT
    # 持久化(如果装了 iptables-persistent)
    if command -v iptables-save &>/dev/null; then
        netfilter-persistent save 2>/dev/null || iptables-save > /etc/iptables/rules.v4 2>/dev/null || true
    fi
    log "iptables 已放行"
else
    warn "未检测到防火墙工具，请手动确保 $PORT 端口已放行"
fi

warn "别忘了去云服务商控制台的安全组/防火墙也放行 $PORT 端口!"

# ============================================================
# Step 6: 启动服务 & 验证
# ============================================================
info "Step 6/6: 启动 Xray 服务"

systemctl enable xray
systemctl restart xray

sleep 1

if systemctl is-active --quiet xray; then
    log "Xray 运行中"
else
    err "Xray 启动失败, 查看日志: journalctl -u xray -e"
    exit 1
fi

if ss -tlnp | grep -q ":$PORT"; then
    log "端口 $PORT 监听正常"
else
    err "端口 $PORT 未监听, 请检查: journalctl -u xray -e"
    exit 1
fi

# ============================================================
# 输出客户端连接信息
# ============================================================
SERVER_IP=$(curl -s4 ifconfig.me 2>/dev/null || curl -s4 ip.sb 2>/dev/null || echo "YOUR_SERVER_IP")

echo ""
echo "============================================"
echo -e " ${GREEN}部署完成!${NC}"
echo "============================================"
echo ""
echo -e " ${CYAN}节点信息:${NC}"
echo "  地址:       $SERVER_IP"
echo "  端口:       $PORT"
echo "  协议:       VLESS"
echo -e "  传输:       tcp + reality"
echo -e "  Flow:       xtls-rprx-vision"
echo "  UUID:       $UUID"
echo "  公钥:       $PUBLIC_KEY"
echo "  SNI:        $SITE_DOMAIN"
echo "  shortId:    $SHORT_ID"
echo ""
echo -e " ${CYAN}v2rayA 分享链接:${NC}"
SHARE_LINK="vless://${UUID}@${SERVER_IP}:${PORT}?security=reality&encryption=none&flow=xtls-rprx-vision&type=tcp&sni=${SITE_DOMAIN}&fp=chrome&pbk=${PUBLIC_KEY}&sid=${SHORT_ID}#Xray-Reality-${SERVER_IP}"
echo "  $SHARE_LINK"
echo ""
echo -e " ${CYAN}常用命令:${NC}"
echo "  systemctl status xray     # 查看状态"
echo "  systemctl restart xray    # 重启"
echo "  journalctl -u xray -f     # 实时日志"
echo "  xray version              # 版本"
echo "  配置文件: $CONFIG"
echo ""
echo -e " ${YELLOW}将上面的分享链接复制到 v2rayA 导入即可使用${NC}"
echo "============================================"

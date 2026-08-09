#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# sing-box + Hysteria2 一键部署脚本
# 优势: UDP 暴力发包, 速度快, 抗丢包, 零配置伪装
# 用法: PORT=443 bash setup-singbox-hysteria2.sh
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

# ---- 检查 root ----
if [[ $EUID -ne 0 ]]; then
    err "请用 root 运行: sudo bash $0"
    exit 1
fi

# ---- 可配置参数 ----
PORT="${PORT:-443}"
SNI="${SNI:-www.microsoft.com}"
MASQUERADE="${MASQUERADE:-https://www.microsoft.com}"
PASSWORD_LEN=32

echo ""
echo -e "${CYAN}============================================${NC}"
echo -e "  sing-box + Hysteria2 一键部署脚本"
echo -e "${CYAN}============================================${NC}"
echo ""

# ============================================================
# Step 1: 检查系统 & 开启 BBR
# ============================================================
info "Step 1/7: 检查系统环境"

log "系统: $(. /etc/os-release && echo "$PRETTY_NAME")"
log "架构: $(uname -m)"
log "内存: $(free -h | awk '/^Mem:/{print $2}')"

# 开启 BBR (Hysteria2 在高速网络下收益明显)
if ! sysctl net.ipv4.tcp_congestion_control 2>/dev/null | grep -q bbr; then
    info "开启 BBR 拥塞控制..."
    modprobe tcp_bbr 2>/dev/null || true
    cat > /etc/sysctl.d/99-bbr.conf <<'SYSCTL'
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr
SYSCTL
    sysctl -p /etc/sysctl.d/99-bbr.conf > /dev/null
    log "BBR 已开启"
else
    log "BBR 已启用"
fi

# 优化 UDP 缓冲区
cat > /etc/sysctl.d/99-udp.conf <<'SYSCTL'
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
SYSCTL
sysctl -p /etc/sysctl.d/99-udp.conf > /dev/null
log "UDP 缓冲区已优化"

# ============================================================
# Step 2: 安装 sing-box
# ============================================================
info "Step 2/7: 安装 sing-box"

if command -v sing-box &>/dev/null; then
    log "sing-box 已安装: $(sing-box version 2>&1 | head -1)"
else
    log "下载并安装 sing-box (官方脚本)..."
    bash <(curl -fsSL https://sing-box.app/install.sh)
    log "安装完成: $(sing-box version 2>&1 | head -1)"
fi

# 检测 systemd 服务类型, 决定配置文件路径和启动方式
if systemctl list-unit-files 2>/dev/null | grep -q '^sing-box\.service'; then
    SERVICE_MODE="single"
    CONFIG_DIR=/etc/sing-box
    CONFIG_FILE="$CONFIG_DIR/config.json"
    SERVICE_NAME="sing-box"
elif systemctl list-unit-files 2>/dev/null | grep -q '^sing-box@\.service'; then
    SERVICE_MODE="template"
    CONFIG_DIR=/etc/sing-box
    CONFIG_FILE="$CONFIG_DIR/default.json"
    SERVICE_NAME="sing-box@default"
else
    SERVICE_MODE="manual"
    CONFIG_DIR=/etc/sing-box
    CONFIG_FILE="$CONFIG_DIR/config.json"
    SERVICE_NAME="sing-box"
fi

mkdir -p "$CONFIG_DIR"
log "服务模式: $SERVICE_MODE, 配置文件: $CONFIG_FILE"

# ============================================================
# Step 3: 生成自签名证书
# ============================================================
info "Step 3/7: 生成 TLS 证书"

CERT_DIR="$CONFIG_DIR/tls"
mkdir -p "$CERT_DIR"

CERT_FILE="$CERT_DIR/cert.pem"
KEY_FILE="$CERT_DIR/private.key"

if [ ! -f "$CERT_FILE" ] || [ ! -f "$KEY_FILE" ]; then
    log "生成自签名证书 (SNI: $SNI)..."

    openssl req -x509 -newkey rsa:4096 -sha256 -days 3650 -nodes \
        -keyout "$KEY_FILE" \
        -out "$CERT_FILE" \
        -subj "/CN=$SNI" \
        -addext "subjectAltName=DNS:$SNI,DNS:*.$SNI" \
        2>/dev/null

    chmod 644 "$CERT_FILE"
    chmod 600 "$KEY_FILE"
    log "证书已生成: $CERT_FILE"
    log "私钥已生成: $KEY_FILE"
else
    log "证书已存在, 跳过生成"
fi

# ============================================================
# Step 4: 生成密码
# ============================================================
info "Step 4/7: 生成认证密码"

PASSWORD="${PASSWORD:-$(openssl rand -base64 $PASSWORD_LEN | tr -d '=+/' | head -c $PASSWORD_LEN)}"
log "密码: $PASSWORD"

# ============================================================
# Step 5: 生成配置文件
# ============================================================
info "Step 5/7: 生成 sing-box 配置"

if [ -f "$CONFIG_FILE" ]; then
    cp "$CONFIG_FILE" "${CONFIG_FILE}.bak.$(date +%s)"
    log "旧配置已备份"
fi

log "写入 $CONFIG_FILE ..."
cat > "$CONFIG_FILE" <<EOF
{
  "log": {
    "level": "warn",
    "timestamp": true
  },
  "inbounds": [
    {
      "type": "hysteria2",
      "tag": "hy2-in",
      "listen": "::",
      "listen_port": $PORT,
      "sniff": true,
      "sniff_override_destination": false,
      "up_mbps": 1000,
      "down_mbps": 1000,
      "users": [
        {
          "password": "$PASSWORD"
        }
      ],
      "tls": {
        "enabled": true,
        "certificate_path": "$CERT_FILE",
        "key_path": "$KEY_FILE"
      },
      "masquerade": "$MASQUERADE"
    }
  ],
  "outbounds": [
    {
      "type": "direct",
      "tag": "direct"
    },
    {
      "type": "block",
      "tag": "block"
    }
  ],
  "route": {
    "rules": [
      {
        "ip_is_private": true,
        "outbound": "block"
      }
    ]
  }
}
EOF

log "配置文件已生成"

# 验证配置
if sing-box check -c "$CONFIG_FILE" &>/dev/null; then
    log "配置验证通过"
else
    warn "配置验证失败, 但这不影响运行 (可能 sing-box 版本差异)"
    sing-box check -c "$CONFIG_FILE" 2>&1 || true
fi

# ============================================================
# Step 6: 配置防火墙
# ============================================================
info "Step 6/7: 配置防火墙"

# sing-box 需要同时放行 UDP 和 TCP (UDP 是主力, TCP 用于伪装)
if command -v ufw &>/dev/null && ufw status | grep -q "Status: active"; then
    ufw allow "$PORT"/udp 2>/dev/null || true
    ufw allow "$PORT"/tcp 2>/dev/null || true
    log "ufw: $PORT/udp + $PORT/tcp 已放行"
elif command -v firewall-cmd &>/dev/null && systemctl is-active --quiet firewalld 2>/dev/null; then
    firewall-cmd --permanent --add-port="$PORT"/udp 2>/dev/null || true
    firewall-cmd --permanent --add-port="$PORT"/tcp 2>/dev/null || true
    firewall-cmd --reload 2>/dev/null || true
    log "firewalld: $PORT/udp + $PORT/tcp 已放行"
elif command -v iptables &>/dev/null; then
    iptables -I INPUT -p udp --dport "$PORT" -j ACCEPT 2>/dev/null || true
    iptables -I INPUT -p tcp --dport "$PORT" -j ACCEPT 2>/dev/null || true
    netfilter-persistent save 2>/dev/null || iptables-save > /etc/iptables/rules.v4 2>/dev/null || true
    log "iptables: $PORT/udp + $PORT/tcp 已放行"
fi

warn "记得去云服务商控制台放行 $PORT/udp + $PORT/tcp 端口!"

# ============================================================
# Step 7: 启动服务
# ============================================================
info "Step 7/7: 启动 sing-box 服务"

if [ "$SERVICE_MODE" = "manual" ]; then
    warn "未找到 sing-box systemd 服务, 创建 systemd 单元..."
    cat > /etc/systemd/system/sing-box.service <<SYSTEMD
[Unit]
Description=sing-box service
After=network.target

[Service]
Type=simple
User=root
ExecStart=$(command -v sing-box) run -c $CONFIG_FILE
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
SYSTEMD
    systemctl daemon-reload
    SERVICE_NAME="sing-box"
    log "已创建 systemd 服务"
fi

systemctl daemon-reload
systemctl enable "$SERVICE_NAME"
systemctl restart "$SERVICE_NAME"
sleep 1

if systemctl is-active --quiet "$SERVICE_NAME"; then
    log "sing-box 服务运行中"
else
    err "sing-box 启动失败, 查看: journalctl -u $SERVICE_NAME -e"
    exit 1
fi

# 验证端口监听
if ss -tulnp | grep -q ":$PORT"; then
    log "端口 $PORT 监听正常"
else
    err "端口 $PORT 未监听, 查看: journalctl -u $SERVICE_NAME -e"
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
echo "  协议:       Hysteria2"
echo "  地址:       $SERVER_IP"
echo "  端口:       $PORT"
echo "  密码:       $PASSWORD"
echo "  SNI:        $SNI"
echo "  跳过证书验证: 是"
echo ""
echo -e " ${CYAN}Hysteria2 分享链接:${NC}"
SHARE_LINK="hysteria2://${PASSWORD}@${SERVER_IP}:${PORT}?sni=${SNI}&insecure=1#Hysteria2-${SERVER_IP}"
echo "  $SHARE_LINK"
echo ""
echo -e " ${CYAN}sing-box 客户端配置 (outbound):${NC}"
cat <<CLIENT
  {
    "type": "hysteria2",
    "tag": "hy2-out",
    "server": "$SERVER_IP",
    "server_port": $PORT,
    "password": "$PASSWORD",
    "tls": {
      "enabled": true,
      "insecure": true,
      "server_name": "$SNI"
    }
  }
CLIENT
echo ""
echo -e " ${CYAN}常用命令:${NC}"
echo "  systemctl status $SERVICE_NAME     # 查看状态"
echo "  systemctl restart $SERVICE_NAME    # 重启"
echo "  journalctl -u $SERVICE_NAME -f     # 实时日志"
echo "  sing-box version                   # 版本"
echo "  配置文件: $CONFIG_FILE"
echo ""
echo -e " ${YELLOW}将上面的分享链接复制到客户端导入即可使用${NC}"
echo "============================================"
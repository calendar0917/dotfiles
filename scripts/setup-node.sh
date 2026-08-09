#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# sing-box 交互式统一部署脚本 (适配 sing-box 1.11.0+)
# 用法: 直接运行, 交互式选择协议和参数
# ============================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${GREEN}[+]${NC} $*"; }
warn() { echo -e "${YELLOW}[!]${NC} $*"; }
err() { echo -e "${RED}[-]${NC} $*"; }
info() { echo -e "${CYAN}[*]${NC} $*"; }
prompt() { echo -ne "${BLUE}[?]${NC} $* "; }

if [[ $EUID -ne 0 ]]; then
  err "请用 root 运行: sudo bash $0"
  exit 1
fi

# ---- 交互式参数收集 ----
printf '\033[2J\033[H' 2>/dev/null || true
echo ""
echo -e "${CYAN}╔══════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║        sing-box 统一部署脚本                 ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════╝${NC}"
echo ""

# ----- 协议选择 -----
echo -e "  ${YELLOW}选择要部署的协议:${NC}"
echo ""
echo -e "  ${GREEN}1${NC}) Hysteria2          — UDP 极速, 抗丢包, 推荐首选"
echo -e "  ${GREEN}2${NC}) VLESS Reality      — TCP 伪装, Clash Meta 兼容"
echo -e "  ${GREEN}3${NC}) Hysteria2 + Reality — 两个都要, 不同端口同时跑 (推荐)"
echo ""

while true; do
  prompt "请输入选项 [1-3, 默认: 3]"
  read -r CHOICE
  CHOICE="${CHOICE:-3}"
  case "$CHOICE" in
  1)
    PROTO="hy2"
    break
    ;;
  2)
    PROTO="reality"
    break
    ;;
  3)
    PROTO="all"
    break
    ;;
  *) echo -e "  ${RED}无效选项, 请输入 1/2/3${NC}" ;;
  esac
done

echo ""
echo -e "  ${CYAN}已选择: ${GREEN}$PROTO${NC}"
echo ""

# ----- 端口配置 -----
if [ "$PROTO" = "hy2" ] || [ "$PROTO" = "all" ]; then
  prompt "Hysteria2 端口 [默认: 443]"
  read -r HY2_PORT
  HY2_PORT="${HY2_PORT:-443}"
fi

if [ "$PROTO" = "reality" ] || [ "$PROTO" = "all" ]; then
  prompt "VLESS Reality 端口 [默认: 8443]"
  read -r REALITY_PORT
  REALITY_PORT="${REALITY_PORT:-8443}"
fi

# ----- SNI (伪装站点) -----
echo ""
echo -e "  ${YELLOW}伪装站点 (SNI), 默认 www.microsoft.com:${NC}"
echo -e "  ${CYAN}1${NC}) www.microsoft.com"
echo -e "  ${CYAN}2${NC}) www.bing.com"
echo -e "  ${CYAN}3${NC}) www.google.com"
echo -e "  ${CYAN}4${NC}) 自定义"

while true; do
  prompt "请选择 [1-4, 默认: 1]"
  read -r SNI_CHOICE
  SNI_CHOICE="${SNI_CHOICE:-1}"
  case "$SNI_CHOICE" in
  1)
    SNI="www.microsoft.com"
    break
    ;;
  2)
    SNI="www.bing.com"
    break
    ;;
  3)
    SNI="www.google.com"
    break
    ;;
  4)
    prompt "输入自定义 SNI (如 cdn.jsdelivr.net)"
    read -r SNI
    [ -n "$SNI" ] && break || echo -e "  ${RED}SNI 不能为空${NC}"
    ;;
  *) echo -e "  ${RED}无效选项${NC}" ;;
  esac
done

MASQUERADE="https://${SNI}"

# ----- 确认配置 -----
echo ""
echo -e "${CYAN}╔══════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║              配置确认                         ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  协议:       ${GREEN}$PROTO${NC}"
echo -e "  伪装站点:   ${GREEN}$SNI${NC}"
if [ "$PROTO" = "hy2" ] || [ "$PROTO" = "all" ]; then
  echo -e "  Hysteria2:  ${GREEN}端口 $HY2_PORT${NC}"
fi
if [ "$PROTO" = "reality" ] || [ "$PROTO" = "all" ]; then
  echo -e "  VLESS:      ${GREEN}端口 $REALITY_PORT${NC}"
fi
echo ""

prompt "确认开始部署? [Y/n]"
read -r CONFIRM
if [[ "$CONFIRM" =~ ^[Nn] ]]; then
  echo "已取消"
  exit 0
fi

echo ""
echo -e "${CYAN}════════════════════════════════════════════════${NC}"
echo ""

# ============================================================
# Step 1: 系统优化
# ============================================================
info "Step 1/6: 系统优化"

log "系统: $(. /etc/os-release && echo "$PRETTY_NAME")"
log "架构: $(uname -m)"

if ! sysctl net.ipv4.tcp_congestion_control 2>/dev/null | grep -q bbr; then
  info "开启 BBR..."
  modprobe tcp_bbr 2>/dev/null || true
  cat >/etc/sysctl.d/99-bbr.conf <<'SYSCTL'
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr
SYSCTL
  sysctl -p /etc/sysctl.d/99-bbr.conf >/dev/null
  log "BBR 已开启"
fi

cat >/etc/sysctl.d/99-udp.conf <<'SYSCTL'
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
SYSCTL
sysctl -p /etc/sysctl.d/99-udp.conf >/dev/null
log "UDP 缓冲区已优化"

# ============================================================
# Step 2: 安装 sing-box
# ============================================================
info "Step 2/6: 安装 sing-box"

if command -v sing-box &>/dev/null; then
  log "sing-box 已安装: $(sing-box version 2>&1 | head -1)"
else
  log "安装 sing-box (官方脚本)..."
  bash <(curl -fsSL https://sing-box.app/install.sh)
  log "安装完成: $(sing-box version 2>&1 | head -1)"
fi

# 检测服务类型
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

# ============================================================
# Step 3: 生成密钥材料
# ============================================================
info "Step 3/6: 生成密钥材料"

CERT_DIR="$CONFIG_DIR/tls"
mkdir -p "$CERT_DIR"
CERT_FILE="$CERT_DIR/cert.pem"
KEY_FILE="$CERT_DIR/private.key"

# 自签名证书 (Hysteria2 用)
if [ "$PROTO" = "hy2" ] || [ "$PROTO" = "all" ]; then
  if [ ! -f "$CERT_FILE" ] || [ ! -f "$KEY_FILE" ]; then
    log "生成自签名证书 (SNI: $SNI)..."
    openssl req -x509 -newkey rsa:4096 -sha256 -days 3650 -nodes \
      -keyout "$KEY_FILE" -out "$CERT_FILE" \
      -subj "/CN=$SNI" \
      -addext "subjectAltName=DNS:$SNI,DNS:*.$SNI" \
      2>/dev/null
    chmod 644 "$CERT_FILE"
    chmod 600 "$KEY_FILE"
    log "证书已生成"
  fi
  HY2_PASSWORD="$(openssl rand -base64 32 | tr -d '=+/' | head -c 32)"
  log "Hysteria2 密码: $HY2_PASSWORD"
fi

# Reality 密钥 (VLESS Reality 用)
if [ "$PROTO" = "reality" ] || [ "$PROTO" = "all" ]; then
  REALITY_KEYS=$(sing-box generate reality-keypair 2>&1 || true)
  if [ -z "$REALITY_KEYS" ]; then
    REALITY_SKIP=true
    warn "当前 sing-box 版本不支持 generate reality-keypair, 跳过 Reality"
  else
    REALITY_PRIVATE_KEY=$(echo "$REALITY_KEYS" | awk -F': *' '/PrivateKey:/{print $2}')
    REALITY_PUBLIC_KEY=$(echo "$REALITY_KEYS" | awk -F': *' '/PublicKey:/{print $2}')
    if [[ -z "$REALITY_PRIVATE_KEY" ]]; then
      REALITY_SKIP=true
      warn "Reality 密钥提取失败, 跳过 Reality"
    else
      REALITY_SKIP=false
      REALITY_UUID=$(sing-box generate uuid 2>/dev/null || cat /proc/sys/kernel/random/uuid)
      REALITY_SHORT_ID=$(openssl rand -hex 8)
      log "Reality UUID:     $REALITY_UUID"
      log "Reality 公钥:     $REALITY_PUBLIC_KEY"
      log "Reality shortId:  $REALITY_SHORT_ID"
    fi
  fi
fi

# 如果选择了 Reality 但密钥生成失败，报错退出
if [ "$PROTO" = "reality" ] && [ "${REALITY_SKIP:-false}" = "true" ]; then
  err "Reality 密钥生成失败，无法继续部署 Reality 协议"
  exit 1
fi

# ============================================================
# Step 4: 生成 sing-box 配置 (适配 1.11.0+ 规则动作)
# ============================================================
info "Step 4/6: 生成 sing-box 配置"

if [ -f "$CONFIG_FILE" ]; then
  cp "$CONFIG_FILE" "${CONFIG_FILE}.bak.$(date +%s)"
  log "旧配置已备份"
fi

OUTBOUNDS='[
    { "type": "direct", "tag": "direct" },
    { "type": "block",  "tag": "block"  }
]'

# ---- 构建 INBOUNDS (移除所有 sniff 字段) ----
INBOUNDS="["

if [ "$PROTO" = "hy2" ] || [ "$PROTO" = "all" ]; then
  INBOUNDS+="
    {
      \"type\": \"hysteria2\",
      \"tag\": \"hy2-in\",
      \"listen\": \"::\",
      \"listen_port\": $HY2_PORT,
      \"up_mbps\": 1000,
      \"down_mbps\": 1000,
      \"users\": [ { \"password\": \"$HY2_PASSWORD\" } ],
      \"tls\": {
        \"enabled\": true,
        \"certificate_path\": \"$CERT_FILE\",
        \"key_path\": \"$KEY_FILE\"
      },
      \"masquerade\": \"$MASQUERADE\"
    }"
fi

if [ "$PROTO" = "reality" ] || ([ "$PROTO" = "all" ] && [ "${REALITY_SKIP:-false}" != "true" ]); then
  [ "$PROTO" = "all" ] && INBOUNDS+=","
  INBOUNDS+="
    {
      \"type\": \"vless\",
      \"tag\": \"reality-in\",
      \"listen\": \"::\",
      \"listen_port\": $REALITY_PORT,
      \"users\": [
        {
          \"uuid\": \"$REALITY_UUID\",
          \"flow\": \"xtls-rprx-vision\"
        }
      ],
      \"tls\": {
        \"enabled\": true,
        \"server_name\": \"$SNI\",
        \"reality\": {
          \"enabled\": true,
          \"handshake\": {
            \"server\": \"$SNI\",
            \"server_port\": 443
          },
          \"private_key\": \"$REALITY_PRIVATE_KEY\",
          \"short_id\": [ \"$REALITY_SHORT_ID\" ]
        }
      }
    }"
fi

INBOUNDS+="
  ]"

# ---- 构建 route.rules (使用 action 对象启用嗅探) ----
RULES="["
# 为每个启用且有效的 inbound 添加 sniff action (注意 action 是对象，不是数组)
if [ "$PROTO" = "hy2" ] || [ "$PROTO" = "all" ]; then
  RULES+=" { \"inbound\": [\"hy2-in\"], \"action\": \"sniff\" },"
fi

if [ "$PROTO" = "reality" ] && [ "${REALITY_SKIP:-false}" != "true" ]; then
  RULES+=" { \"inbound\": [\"reality-in\"], \"action\": \"sniff\" },"
elif [ "$PROTO" = "all" ] && [ "${REALITY_SKIP:-false}" != "true" ]; then
  RULES+=" { \"inbound\": [\"reality-in\"], \"action\": \"sniff\" },"
fi

# 添加私有 IP 阻止规则
RULES+=" { \"ip_is_private\": true, \"action\": \"route\", \"outbound\": \"block\" } ]"

# ---- 写入配置文件 ----
log "写入 $CONFIG_FILE ..."
cat >"$CONFIG_FILE" <<EOF
{
  "log": { "level": "warn", "timestamp": true },
  "inbounds": $INBOUNDS,
  "outbounds": $OUTBOUNDS,
  "route": {
    "rules": $RULES
  }
}
EOF

log "配置文件已生成"

if sing-box check -c "$CONFIG_FILE" &>/dev/null; then
  log "配置验证通过"
else
  warn "配置验证有警告 (可能不影响运行):"
  sing-box check -c "$CONFIG_FILE" 2>&1 || true
fi

# ============================================================
# Step 5: 防火墙 & 启动
# ============================================================
info "Step 5/6: 配置防火墙 & 启动服务"

open_port() {
  local p=$1
  if command -v ufw &>/dev/null && ufw status 2>/dev/null | grep -q "Status: active"; then
    ufw allow "$p"/udp 2>/dev/null || true
    ufw allow "$p"/tcp 2>/dev/null || true
  elif command -v firewall-cmd &>/dev/null && systemctl is-active --quiet firewalld 2>/dev/null; then
    firewall-cmd --permanent --add-port="$p"/udp 2>/dev/null || true
    firewall-cmd --permanent --add-port="$p"/tcp 2>/dev/null || true
    firewall-cmd --reload 2>/dev/null || true
  elif command -v iptables &>/dev/null; then
    iptables -I INPUT -p udp --dport "$p" -j ACCEPT 2>/dev/null || true
    iptables -I INPUT -p tcp --dport "$p" -j ACCEPT 2>/dev/null || true
    netfilter-persistent save 2>/dev/null || true
  fi
}

if [ "$PROTO" = "hy2" ] || [ "$PROTO" = "all" ]; then
  open_port "$HY2_PORT"
  log "防火墙: $HY2_PORT 已放行"
fi
if [ "$PROTO" = "reality" ] || [ "$PROTO" = "all" ]; then
  open_port "$REALITY_PORT"
  log "防火墙: $REALITY_PORT 已放行"
fi

warn "记得去云服务商控制台放行对应端口!"

# 启动服务
if [ "$SERVICE_MODE" = "manual" ]; then
  cat >/etc/systemd/system/sing-box.service <<SYSTEMD
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
fi

systemctl daemon-reload
systemctl enable "$SERVICE_NAME"
systemctl restart "$SERVICE_NAME"
sleep 1

if systemctl is-active --quiet "$SERVICE_NAME"; then
  log "sing-box 服务运行中"
else
  err "sing-box 启动失败: journalctl -u $SERVICE_NAME -e"
  exit 1
fi

# ============================================================
# Step 6: 输出客户端配置
# ============================================================
SERVER_IP=$(curl -s4 ifconfig.me 2>/dev/null || curl -s4 ip.sb 2>/dev/null || echo "YOUR_SERVER_IP")

echo ""
echo -e "${CYAN}╔══════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║            部署完成!  IP: ${GREEN}${SERVER_IP}${CYAN}              ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════╝${NC}"
echo ""

# ---- Hysteria2 ----
if [ "$PROTO" = "hy2" ] || [ "$PROTO" = "all" ]; then
  echo -e " ${YELLOW}━━━ Hysteria2 (端口 $HY2_PORT) ━━━${NC}"
  echo ""
  echo -e " ${CYAN}▸ 分享链接 (v2rayN / Nekoray / sing-box):${NC}"
  echo "  hysteria2://${HY2_PASSWORD}@${SERVER_IP}:${HY2_PORT}?sni=${SNI}&insecure=1#Hy2-${SERVER_IP}"
  echo ""
  echo -e " ${CYAN}▸ Clash Meta (mihomo):${NC}"
  cat <<CLASH_HY2
  - name: "Hy2-${SERVER_IP}"
    type: hysteria2
    server: ${SERVER_IP}
    port: ${HY2_PORT}
    password: "${HY2_PASSWORD}"
    sni: ${SNI}
    skip-cert-verify: true
CLASH_HY2
  echo ""
fi

# ---- VLESS Reality ----
if { [ "$PROTO" = "reality" ] || [ "$PROTO" = "all" ]; } && [ "${REALITY_SKIP:-false}" != "true" ]; then
  echo -e " ${YELLOW}━━━ VLESS Reality (端口 $REALITY_PORT) ━━━${NC}"
  echo ""
  echo -e " ${CYAN}▸ 分享链接:${NC}"
  echo "  vless://${REALITY_UUID}@${SERVER_IP}:${REALITY_PORT}?security=reality&encryption=none&flow=xtls-rprx-vision&type=tcp&sni=${SNI}&fp=chrome&pbk=${REALITY_PUBLIC_KEY}&sid=${REALITY_SHORT_ID}#Reality-${SERVER_IP}"
  echo ""
  echo -e " ${CYAN}▸ Clash Meta (mihomo):${NC}"
  cat <<CLASH_VLESS
  - name: "Reality-${SERVER_IP}"
    type: vless
    server: ${SERVER_IP}
    port: ${REALITY_PORT}
    uuid: ${REALITY_UUID}
    flow: xtls-rprx-vision
    tls: true
    client-fingerprint: chrome
    servername: ${SNI}
    reality-opts:
      public-key: ${REALITY_PUBLIC_KEY}
      short-id: ${REALITY_SHORT_ID}
    network: tcp
CLASH_VLESS
  echo ""
fi

# ---- 通用 ----
echo -e " ${CYAN}▸ 常用命令:${NC}"
echo "  systemctl status $SERVICE_NAME     # 查看状态"
echo "  systemctl restart $SERVICE_NAME    # 重启"
echo "  journalctl -u $SERVICE_NAME -f     # 实时日志"
echo "  配置文件: $CONFIG_FILE"
echo ""
echo -e " ${YELLOW}需要 Clash Meta (mihomo) / Clash Verge, 原版 Clash 不支持${NC}"
echo -e "${CYAN}════════════════════════════════════════════════${NC}"

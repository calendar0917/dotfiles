#!/usr/bin/env bash
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log()  { echo -e "${GREEN}[+]${NC} $*"; }
warn() { echo -e "${YELLOW}[!]${NC} $*"; }
err()  { echo -e "${RED}[-]${NC} $*"; }
info() { echo -e "${CYAN}[*]${NC} $*"; }

echo ""
echo -e "${CYAN}========================================${NC}"
echo -e "  系统清理"
echo -e "${CYAN}========================================${NC}"
echo ""

info "Step 1/5: 清理孤儿包..."

ORPHANS=$(pacman -Qtdq 2>/dev/null || true)
if [[ -n "$ORPHANS" ]]; then
    log "找到孤儿包:"
    echo "$ORPHANS" | sed 's/^/  /'
    sudo pacman -Rns --noconfirm $ORPHANS
    log "孤儿包已清理"
else
    log "没有孤儿包"
fi

echo ""

info "Step 2/5: 清理 pacman 缓存..."
if command -v paccache &>/dev/null; then
    sudo paccache -rk2
    sudo paccache -ruk0
    log "pacman 缓存已清理"
else
    warn "paccache 未安装，跳过缓存清理"
fi

echo ""

info "Step 3/5: 清理 yay 编译缓存..."
if [[ -d "$HOME/.cache/yay" ]]; then
    yay -Sc --noconfirm 2>/dev/null || true
    log "yay 缓存已清理"
else
    log "没有 yay 缓存"
fi

echo ""

info "Step 4/5: 清理 systemd journal..."
sudo journalctl --vacuum-time=7d --quiet
log "journal 已清理（保留 7 天）"

echo ""

info "Step 5/5: 清理 ~/.cache..."
CACHE_SIZE=$(du -sh "$HOME/.cache" 2>/dev/null | cut -f1)
log "~/.cache 当前大小: $CACHE_SIZE"
warn "跳过 ~/.cache 清理（可能影响应用），可手动执行: rm -rf ~/.cache/*"

echo ""
echo -e "${CYAN}========================================${NC}"
echo -e " ${GREEN}清理完成${NC}"
echo -e "${CYAN}========================================${NC}"

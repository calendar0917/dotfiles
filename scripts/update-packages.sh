#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$(dirname "$(readlink -f "$0")")")" && pwd)"

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
echo -e "  Arch Linux 系统更新"
echo -e "${CYAN}========================================${NC}"
echo ""

info "Step 1/3: 更新官方源包列表..."
sudo pacman -Qqen > "$DOTFILES_DIR/pkglist-repo.txt"
log "已更新: pkglist-repo.txt ($(wc -l < "$DOTFILES_DIR/pkglist-repo.txt") 个包)"

echo ""

info "Step 2/3: 更新 AUR 包列表..."
pacman -Qqem > "$DOTFILES_DIR/pkglist-aur.txt" 2>/dev/null || true
log "已更新: pkglist-aur.txt ($(wc -l < "$DOTFILES_DIR/pkglist-aur.txt") 个包)"

echo ""

info "Step 3/3: 执行系统更新..."

log "官方源更新 (pacman -Syu)..."
sudo pacman -Syu --noconfirm
log "官方源更新完成"

echo ""

if command -v yay &>/dev/null; then
    log "AUR 更新 (yay -Sua)..."
    yay -Sua --noconfirm
    log "AUR 更新完成"
else
    warn "yay 未安装，跳过 AUR 更新"
fi

echo ""
echo -e "${CYAN}========================================${NC}"
echo -e " ${GREEN}系统更新完成${NC}"
echo -e "${CYAN}========================================${NC}"

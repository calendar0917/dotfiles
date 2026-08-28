#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$(dirname "$(readlink -f "$0")")")" && pwd)"
PKGLIST_DIR="$DOTFILES_DIR/pkglist"
mkdir -p "$PKGLIST_DIR"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log()  { echo -e "${GREEN}[+]${NC} $*"; }
warn() { echo -e "${YELLOW}[!]${NC} $*"; }
err()  { echo -e "${RED}[-]${NC} $*"; }
info() { echo -e "${CYAN}[*]${NC} $*"; }

detect_distro() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        echo "$ID"
    else
        echo "unknown"
    fi
}

DISTRO="$(detect_distro)"

case "$DISTRO" in
    arch)
        echo ""
        echo -e "${CYAN}========================================${NC}"
        echo -e "  Arch Linux 系统更新"
        echo -e "${CYAN}========================================${NC}"
        echo ""

        info "Step 1/4: 更新官方源包列表..."
        sudo pacman -Qqen > "$PKGLIST_DIR/arch-repo.txt"
        log "已更新: pkglist/arch-repo.txt ($(wc -l < "$PKGLIST_DIR/arch-repo.txt") 个包)"

        info "Step 2/4: 更新 AUR 包列表..."
        pacman -Qqem > "$PKGLIST_DIR/arch-aur.txt" 2>/dev/null || true
        log "已更新: pkglist/arch-aur.txt ($(wc -l < "$PKGLIST_DIR/arch-aur.txt") 个包)"

        info "Step 3/4: 执行系统更新..."
        sudo pacman -Syu --noconfirm
        log "官方源更新完成"

        if command -v yay &>/dev/null; then
            info "Step 4/4: AUR 更新 (yay -Sua)..."
            yay -Sua --noconfirm
            log "AUR 更新完成"
        else
            warn "yay 未安装，跳过 AUR 更新"
        fi
        ;;

    fedora)
        echo ""
        echo -e "${CYAN}========================================${NC}"
        echo -e "  Fedora 系统更新"
        echo -e "${CYAN}========================================${NC}"
        echo ""

        info "Step 1/4: 更新 dnf 用户安装包列表..."
        dnf repoquery --userinstalled --qf '%{name}' 2>/dev/null | sort > "$PKGLIST_DIR/fedora.txt" || {
            warn "dnf repoquery --userinstalled 失败，回退到 --qf '%{name}'"
            dnf repoquery --qf '%{name}' --installed 2>/dev/null | sort > "$PKGLIST_DIR/fedora.txt" || true
        }
        log "已更新: pkglist/fedora.txt ($(wc -l < "$PKGLIST_DIR/fedora.txt") 个包)"

        info "Step 2/4: 更新 Flatpak 应用列表..."
        flatpak list --app --columns=application 2>/dev/null | sort > "$PKGLIST_DIR/flatpak.txt" || true
        log "已更新: pkglist/flatpak.txt ($(wc -l < "$PKGLIST_DIR/flatpak.txt") 个应用)"

        info "Step 3/4: 执行系统更新 (dnf upgrade)..."
        sudo dnf upgrade --refresh -y
        log "dnf 更新完成"

        info "Step 4/4: 更新 Flatpak... (在 GNOME 非图形会话可能跳过)"
        if [[ -z "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ]]; then
            warn "检测到无图形会话，跳过 Flatpak 更新"
        else
            flatpak update -y
            log "Flatpak 更新完成"
        fi
        ;;

    *)
        err "未知发行版: $DISTRO（仅支持 arch 和 fedora）"
        exit 1
        ;;
esac

echo ""
echo -e "${CYAN}========================================${NC}"
echo -e " ${GREEN}系统更新完成${NC}"
echo -e "${CYAN}========================================${NC}"
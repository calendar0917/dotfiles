#!/usr/bin/env bash
set -euo pipefail

# GNOME 设置备份/恢复：dconf dump + GNOME 扩展列表
# 跨发行版通用，适用于 Fedora/Arch 上的 GNOME。
#
# 用法:
#   backup-gnome.sh              备份（写入 <dotfiles>/gnome/）
#   backup-gnome.sh --restore    从 <dotfiles>/gnome/ 恢复
#   backup-gnome.sh --list       显示已备份的记录
#   backup-gnome.sh --help
#
# 备份文件:
#   gnome/settings.dconf            全部 dconf 设置（键位/主题/input/扩展启用状态…）
#   gnome/extensions.enabled.txt    启用的扩展 UUID 列表

DOTFILES_DIR="$(cd "$(dirname "$(dirname "$(readlink -f "$0")")")" && pwd)"
GNOME_DIR="$DOTFILES_DIR/gnome"
SETTINGS_FILE="$GNOME_DIR/settings.dconf"
EXTENSIONS_FILE="$GNOME_DIR/extensions.enabled.txt"
ACTION="backup"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log()  { echo -e "${GREEN}[+]${NC} $*"; }
warn() { echo -e "${YELLOW}[!]${NC} $*"; }
err()  { echo -e "${RED}[-]${NC} $*"; }
info() { echo -e "${CYAN}[*]${NC} $*"; }

usage() {
    echo "用法: $0 [操作]"
    echo ""
    echo "操作:"
    echo "  （无参数）   备份到 <dotfiles>/gnome/"
    echo "  --restore    从备份恢复"
    echo "  --list       列出备份概要"
    echo "  --help, -h   显示帮助"
}

require_dconf() {
    if ! command -v dconf &>/dev/null; then
        err "未找到 dconf（当前不是 GNOME 会话？）"
        exit 1
    fi
}

for arg in "$@"; do
    case "$arg" in
        --restore) ACTION="restore" ;;
        --list)    ACTION="list" ;;
        --help|-h) usage; exit 0 ;;
        *)         warn "忽略未知参数: $arg" ;;
    esac
done

case "$ACTION" in
    backup)
        require_dconf
        mkdir -p "$GNOME_DIR"

        info "备份 GNOME 设置到: $GNOME_DIR"
        dconf dump / > "$SETTINGS_FILE"
        log "已备份: settings.dconf ($(wc -l < "$SETTINGS_FILE") 行)"

        if command -v gnome-extensions &>/dev/null; then
            gnome-extensions list --enabled 2>/dev/null | sort > "$EXTENSIONS_FILE" || true
            log "已备份: extensions.enabled.txt ($(wc -l < "$EXTENSIONS_FILE") 个扩展)"
        else
            warn "gnome-extensions 不可用，跳过扩展列表"
            : > "$EXTENSIONS_FILE"
        fi
        ;;

    restore)
        require_dconf
        if [[ ! -f "$SETTINGS_FILE" ]]; then
            err "找不到备份: $SETTINGS_FILE"
            exit 1
        fi
        info "恢复 GNOME 设置..."
        dconf load / < "$SETTINGS_FILE"
        log "已从 settings.dconf 恢复"
        warn "扩展代码本体需手动安装：导入 extensions.enabled.txt 中的 UUID"
        ;;

    list)
        if [[ -f "$SETTINGS_FILE" ]]; then
            info "settings.dconf: $(wc -l < "$SETTINGS_FILE") 行 (last key 见文件末尾)"
            tail -n 1 "$SETTINGS_FILE"
        else
            warn "尚无备份: $SETTINGS_FILE"
        fi
        if [[ -f "$EXTENSIONS_FILE" ]]; then
            info "启用的扩展 ($(wc -l < "$EXTENSIONS_FILE") 个):"
            sed 's/^/  /' "$EXTENSIONS_FILE"
        fi
        ;;
esac

echo ""
echo -e "${CYAN}========================================${NC}"
case "$ACTION" in
    backup)  echo -e " ${GREEN}GNOME 备份完成${NC}" ;;
    restore) echo -e " ${GREEN}GNOME 恢复完成（部分设置需重新登录生效）${NC}" ;;
    list)    echo -e " ${GREEN}备份清单如上${NC}" ;;
esac
echo -e "${CYAN}========================================${NC}"
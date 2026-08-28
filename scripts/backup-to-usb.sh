#!/usr/bin/env bash
set -euo pipefail

# 交互式备份/恢复工具：~/life ⇄ U盘（exFAT/NTFS，Windows 可读）
#
# 用法:
#   backup-to-usb.sh [U盘挂载点]                 交互式菜单（备份/恢复/查看）
#   backup-to-usb.sh [U盘挂载点] --backup        直接完整备份（主数据 + secrets）
#   backup-to-usb.sh [U盘挂载点] --backup --secrets-only   只备份 secrets
#   backup-to-usb.sh [U盘挂载点] --restore       直接进入恢复流程
#   backup-to-usb.sh [U盘挂载点] --list          列出已有备份
#   backup-to-usb.sh --keep N                   保留最近 N 份备份（默认 5）
#   backup-to-usb.sh --help
#
# 备份文件（位于 <U盘>/backup/）:
#   life-YYYY-MM-DD.tar.zst   主数据归档（保留 Linux 权限，不含 secrets）
#   secrets-YYYY-MM-DD.7z     secrets 口令加密（AES-256，7-Zip 可直接打开）
#
# 自动保留最近 N 份，旧备份会被清理。

DOTFILES_DIR="$(cd "$(dirname "$(dirname "$(readlink -f "$0")")")" && pwd)"
LIFE_DIR="${HOME}/life"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log()  { echo -e "${GREEN}[+]${NC} $*"; }
warn() { echo -e "${YELLOW}[!]${NC} $*"; }
err()  { echo -e "${RED}[-]${NC} $*"; }
info() { echo -e "${CYAN}[*]${NC} $*"; }

USB=""
ACTION=""
SECRETS_ONLY=0
KEEP=5
CHOSEN=""

usage() {
    echo "用法: $0 [U盘挂载点] [操作] [选项]"
    echo ""
    echo "操作:"
    echo "  --backup       备份（可加 --secrets-only 只备份 secrets）"
    echo "  --restore      恢复（交互选择备份）"
    echo "  --list         列出已有备份"
    echo "  （不带操作 = 进入交互菜单）"
    echo ""
    echo "选项:"
    echo "  --secrets-only 只处理 secrets"
    echo "  --keep N       保留最近 N 份（默认 $KEEP）"
    echo "  --help, -h     显示帮助"
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --backup)       ACTION=backup ;;
        --restore)      ACTION=restore ;;
        --list)         ACTION=list ;;
        --secrets-only) SECRETS_ONLY=1 ;;
        --keep)         KEEP="$2"; shift ;;
        --help|-h)      usage; exit 0 ;;
        --*)            err "未知选项: $1"; usage; exit 1 ;;
        *)              USB="$1" ;;
    esac
    shift
done

if [[ ! "$KEEP" =~ ^[0-9]+$ ]]; then
    err "无效的 --keep 值: $KEEP"
    exit 1
fi

detect_usb() {
    if [[ -n "$USB" ]]; then
        if ! findmnt --noheadings "$USB" >/dev/null 2>&1; then
            err "挂载点不存在或未挂载: $USB"
            exit 1
        fi
        return
    fi
    local candidate
    for candidate in /mnt/usb /run/media/"$USER"/*; do
        [[ -d "$candidate" ]] || continue
        if findmnt --noheadings "$candidate" >/dev/null 2>&1; then
            USB="$candidate"
            return
        fi
    done
    auto_mount_usb
    for candidate in /run/media/"$USER"/*; do
        [[ -d "$candidate" ]] || continue
        if findmnt --noheadings "$candidate" >/dev/null 2>&1; then
            USB="$candidate"
            return
        fi
    done
    err "未找到已挂载的 U 盘"
    info "请先挂载 U 盘，或指定挂载点：$0 <挂载点>"
    exit 1
}

auto_mount_usb() {
    if ! command -v udisksctl >/dev/null 2>&1; then
        info "未安装 udisksctl，无法自动挂载"
        return 1
    fi
    local dev fstype
    while read -r dev fstype; do
        [[ -n "$dev" && -n "$fstype" ]] || continue
        info "检测到未挂载的可移动设备 /dev/$dev（$fstype），尝试自动挂载..."
        if udisksctl mount -b "/dev/$dev" >/dev/null 2>&1; then
            log "已挂载 /dev/$dev"
            return 0
        fi
        warn "自动挂载失败: /dev/$dev（可能需 root 或检查文件系统）"
    done < <(lsblk -P -o NAME,RM,MOUNTPOINT,FSTYPE | awk -F'"' '$4=="1" && $6=="" && $8!="" {print $2, $8}')
    return 1
}

confirm() {
    local ans
    read -rp "$1 [y/N] " ans || ans="n"
    [[ "$ans" =~ ^[yY]$ ]]
}

pause() {
    read -rp "按回车返回菜单..." _ || true
}

# ── 备份 ─────────────────────────────────────────
backup() {
    detect_usb
    if [[ ! -d "$LIFE_DIR" ]]; then
        err "~/life 不存在，请先运行 migrate-to-life.sh"
        exit 1
    fi
    [[ -d "$BACKUP_DIR" ]] || mkdir -p "$BACKUP_DIR"

    local avail need
    avail=$(df -Pk "$BACKUP_DIR" 2>/dev/null | awk 'NR==2{print $4}'); avail=${avail:-0}
    need=$(du -sk --exclude="$LIFE_DIR/secrets" "$LIFE_DIR" 2>/dev/null | cut -f1); need=${need:-0}
    if (( need > avail )); then
        err "U盘空间不足：需要约 $(( need / 1024 )) MiB，可用 $(( avail / 1024 )) MiB"
        exit 1
    fi

    echo ""
    echo -e "${CYAN}========================================${NC}"
    echo -e "  备份 ~/life → U盘"
    echo -e "${CYAN}========================================${NC}"
    echo ""
    info "U盘: $USB"
    info "备份目录: $BACKUP_DIR"
    info "保留份数: 最近 $KEEP 份"
    echo ""

    if [[ $SECRETS_ONLY -eq 0 ]]; then
        backup_main
    else
        info "只备份 secrets（跳过主数据）"
        echo ""
    fi
    backup_secrets
    write_readme
    prune
    show_result
}

backup_main() {
    local archive="$BACKUP_DIR/life-$(date +%F).tar.zst"
    local size
    size=$(du -sh --exclude="$LIFE_DIR/secrets" "$LIFE_DIR" 2>/dev/null | cut -f1)
    info "Step 1/2: 主数据归档（排除 secrets，预计 $size）..."
    [[ -f "$archive" ]] && warn "已存在 $(basename "$archive")，将覆盖"

    tar --zstd -cf "$archive" \
        --exclude-from="$EXCLUDES" \
        --exclude='life/secrets' \
        -C "$HOME" life

    size=$(du -h "$archive" | cut -f1)
    log "主归档完成: $(basename "$archive") ($size)"
    echo ""
}

backup_secrets() {
    local archive="$BACKUP_DIR/secrets-$(date +%F).7z"
    if [[ ! -d "$LIFE_DIR/secrets" ]] || [[ -z "$(ls -A "$LIFE_DIR/secrets" 2>/dev/null)" ]]; then
        warn "~/life/secrets 为空，跳过"
        return
    fi

    if [[ $SECRETS_ONLY -eq 0 ]]; then
        info "Step 2/2: secrets 口令加密归档..."
    else
        info "Step 1/1: secrets 口令加密归档..."
    fi
    if [[ -f "$archive" ]]; then
        warn "已存在 $(basename "$archive")，将覆盖（删除旧文件重新加密）"
        rm -f "$archive"
    fi

    local size tmp
    size=$(du -sh "$LIFE_DIR/secrets" | cut -f1)
    info "secrets 大小: $size"
    info "将用 7z 口令加密（AES-256），请输入密码（需牢记）"
    echo ""

    tmp=$(mktemp "${TMPDIR:-/tmp}/secrets.XXXXXX.tar.zst")
    tar --zstd -cf "$tmp" -C "$LIFE_DIR" secrets
    if ! 7z a -t7z -mhe=on -mx=5 -p "$archive" "$tmp" >/dev/null; then
        rm -f "$tmp"
        err "加密归档失败"
        exit 1
    fi
    rm -f "$tmp"

    size=$(du -h "$archive" | cut -f1)
    log "secrets 加密归档完成: $(basename "$archive") ($size)"
    echo ""
}

# ── 保留策略：清理旧备份 ─────────────────────────
prune() {
    prune_one "$KEEP" "life-*.tar.zst" "主数据"
    prune_one "$KEEP" "secrets-*.7z" "secrets"
}

prune_one() {
    local keep="$1" pattern="$2" label="$3"
    local files=()
    mapfile -t files < <(ls -1 "$BACKUP_DIR"/$pattern 2>/dev/null | sort)
    local n=${#files[@]}
    (( n == 0 )) && return
    if (( n > keep )); then
        local old=("${files[@]:0:$(( n - keep ))}")
        info "$label: 共 $n 份，保留最近 $keep 份，清理 ${#old[@]} 份旧备份"
        rm -f "${old[@]}"
    else
        info "$label: $n 份（上限 $keep），无需清理"
    fi
}

# ── 恢复 ─────────────────────────────────────────
choose_backup() {
    local kind="$1" pattern label
    if [[ "$kind" == main ]]; then
        pattern="life-*.tar.zst"; label="主数据"
    else
        pattern="secrets-*.7z"; label="secrets"
    fi
    local files=()
    mapfile -t files < <(ls -1 "$BACKUP_DIR"/$pattern 2>/dev/null | sort -r)
    if (( ${#files[@]} == 0 )); then
        err "没有可恢复的 $label 备份"
        return 1
    fi
    echo ""
    info "可用的 $label 备份（最新在前）:"
    local i size
    for i in "${!files[@]}"; do
        size=$(du -h "${files[$i]}" 2>/dev/null | cut -f1)
        printf '  [%d] %s  (%s)\n' "$((i+1))" "$(basename "${files[$i]}")" "$size"
    done
    echo ""
    local choice=""
    read -rp "输入编号恢复（回车=最新，q=跳过）: " choice || true
    CHOSEN=""
    case "$choice" in
        "" ) CHOSEN="${files[0]}" ;;
        q|Q ) return 1 ;;
        * ) if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#files[@]} )); then
                CHOSEN="${files[$((choice-1))]}"
            else
                err "无效编号: $choice"
                return 1
            fi ;;
    esac
}

restore() {
    detect_usb
    if [[ ! -d "$BACKUP_DIR" ]] || [[ -z "$(ls -A "$BACKUP_DIR" 2>/dev/null)" ]]; then
        err "备份目录为空: $BACKUP_DIR"
        return 1
    fi

    echo ""
    echo -e "${CYAN}========================================${NC}"
    echo -e "  从 U盘 恢复 ~/life"
    echo -e "${CYAN}========================================${NC}"
    echo ""
    info "U盘: $USB"
    info "备份目录: $BACKUP_DIR"

    CHOSEN=""
    if choose_backup main; then
        echo ""
        warn "将解压并覆盖现有 ~/life 文件: $(basename "$CHOSEN")"
        if confirm "确认继续?"; then
            tar --zstd -xf "$CHOSEN" -C "$HOME"
            log "主数据还原完成"
        else
            warn "已取消主数据还原"
        fi
    fi

    echo ""
    CHOSEN=""
    if choose_backup secrets; then
        echo ""
        info "将还原 secrets（需要备份时设置的密码）: $(basename "$CHOSEN")"
        if confirm "确认继续?"; then
            [[ -d "$LIFE_DIR" ]] || mkdir -p "$LIFE_DIR"
            7z x -so "$CHOSEN" | tar --zstd -xf - -C "$LIFE_DIR"
            log "secrets 还原完成"
        else
            warn "已取消 secrets 还原"
        fi
    fi
}

# ── 查看 ─────────────────────────────────────────
list_backups() {
    detect_usb
    echo ""
    info "备份目录: $BACKUP_DIR"
    local main_files=() sec_files=() i size
    mapfile -t main_files < <(ls -1 "$BACKUP_DIR"/life-*.tar.zst 2>/dev/null | sort -r)
    mapfile -t sec_files < <(ls -1 "$BACKUP_DIR"/secrets-*.7z 2>/dev/null | sort -r)
    if (( ${#main_files[@]} == 0 && ${#sec_files[@]} == 0 )); then
        warn "暂无备份"
        return
    fi
    echo ""
    echo "主数据 (life-*.tar.zst):"
    if (( ${#main_files[@]} == 0 )); then
        echo "  （无）"
    else
        for i in "${!main_files[@]}"; do
            size=$(du -h "${main_files[$i]}" 2>/dev/null | cut -f1)
            printf '  %s  (%s)\n' "$(basename "${main_files[$i]}")" "$size"
        done
    fi
    echo ""
    echo "secrets (secrets-*.7z):"
    if (( ${#sec_files[@]} == 0 )); then
        echo "  （无）"
    else
        for i in "${!sec_files[@]}"; do
            size=$(du -h "${sec_files[$i]}" 2>/dev/null | cut -f1)
            printf '  %s  (%s)\n' "$(basename "${sec_files[$i]}")" "$size"
        done
    fi
}

# ── 收尾 ─────────────────────────────────────────
write_readme() {
    local readme="$BACKUP_DIR/README-还原说明.txt"
    cat > "$readme" << 'EOF'
========================================
  备份还原说明
========================================

本 U 盘 backup/ 目录含两类文件：

1. life-YYYY-MM-DD.tar.zst
   主数据归档（保留 Linux 权限，不含 secrets）
   还原: tar --zstd -xf life-YYYY-MM-DD.tar.zst -C ~/

2. secrets-YYYY-MM-DD.7z
   secrets 口令加密归档（AES-256，7-Zip 可打开）
   还原: 7z x secrets-YYYY-MM-DD.7z -so | tar --zstd -xf - -C ~/life/
   （在本机可直接运行: backup-to-usb.sh --restore）

注意:
- tar.zst 需要 zstd（Arch: pacman -S zstd）
- Windows 下 7-Zip 可直接打开 .7z；打开 .tar.zst 需 zstd 插件
- .7z 需要备份时设置的密码才能还原，请务必牢记
- 权限（uid/gid/mode）在 tar 解压回 Linux 后才会正确还原
- 仅保留最近 N 份备份，旧的会被自动清理
EOF
    info "已写入还原说明: $(basename "$readme")"
}

show_result() {
    echo ""
    echo -e "${CYAN}========================================${NC}"
    echo -e " ${GREEN}备份完成${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""
    list_backups
    echo ""
    warn "建议：拔出 U 盘前执行 sync 确保写入完成"
}

# ── 菜单 ─────────────────────────────────────────
menu() {
    while true; do
        echo ""
        echo -e "${CYAN}=============== ~/life 备份 / 恢复 ===============${NC}"
        info "U盘: $USB"
        info "备份目录: $BACKUP_DIR"
        echo ""
        echo "  1) 完整备份 (主数据 + secrets)"
        echo "  2) 只备份 secrets"
        echo "  3) 恢复"
        echo "  4) 列出已有备份"
        echo "  5) 退出"
        echo ""
        local choice=""
        read -rp "请选择 [1-5]: " choice || { echo ""; exit 0; }
        case "$choice" in
            1) SECRETS_ONLY=0; backup; pause ;;
            2) SECRETS_ONLY=1; backup; pause ;;
            3) restore; pause ;;
            4) list_backups; pause ;;
            5|q|Q) echo "再见"; exit 0 ;;
            *) warn "无效选择: $choice" ;;
        esac
    done
}

# ── 入口 ─────────────────────────────────────────
EXCLUDES="${HOME}/.config/backup/excludes"
[[ -f "$EXCLUDES" ]] || EXCLUDES="${DOTFILES_DIR}/config/common/backup/excludes"

detect_usb
BACKUP_DIR="$USB/backup"
[[ -d "$BACKUP_DIR" ]] || mkdir -p "$BACKUP_DIR"

case "$ACTION" in
    backup)  backup ;;
    restore) restore ;;
    list)    list_backups ;;
    *)       menu ;;
esac

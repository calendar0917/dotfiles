#!/usr/bin/env bash
set -euo pipefail

# 将 ~/life 备份到 U 盘（exFAT/NTFS，Windows 可读）
# 主数据 → tar.zst 归档（保留 Linux 权限）
# secrets → tar.zst.gpg 加密归档
#
# 用法: backup-to-usb.sh [U盘挂载点] [--secrets-only]
#   无参数 = 自动检测 U 盘
#   指定路径 = 用该挂载点
#   --secrets-only = 只备份加密的 secrets 部分

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

SECRETS_ONLY=0
USB=""

for arg in "$@"; do
    case "$arg" in
        --secrets-only) SECRETS_ONLY=1 ;;
        --help|-h)
            echo "用法: $0 [U盘挂载点] [--secrets-only]"
            echo "  无参数 = 自动检测 U 盘"
            echo "  --secrets-only = 只备份 secrets"
            exit 0 ;;
        *) USB="$arg" ;;
    esac
done

# ── 检测 U 盘 ──────────────────────────────────
if [[ -z "$USB" ]]; then
    for candidate in /mnt/usb /run/media/"$USER"/*; do
        if [[ -d "$candidate" ]] && findmnt --noheadings "$candidate" >/dev/null 2>&1; then
            USB="$candidate"
            break
        fi
    done
fi

if [[ -z "$USB" ]] || ! findmnt --noheadings "$USB" >/dev/null 2>&1; then
    err "未找到已挂载的 U 盘"
    echo ""
    echo "用法: $0 <U盘挂载点>"
    echo "示例: $0 /mnt/usb"
    echo "      $0 /run/media/$USER/MyUSB"
    exit 1
fi

EXCLUDES="${HOME}/.config/backup/excludes"
[[ -f "$EXCLUDES" ]] || EXCLUDES="${DOTFILES_DIR}/config/backup/excludes"

if [[ ! -d "$LIFE_DIR" ]]; then
    err "~/life 不存在，请先运行 migrate-to-life.sh"
    exit 1
fi

BACKUP_DIR="$USB/backup"
DATE=$(date +%F)
mkdir -p "$BACKUP_DIR"

echo ""
echo -e "${CYAN}========================================${NC}"
echo -e "  备份 ~/life → U盘"
echo -e "${CYAN}========================================${NC}"
echo ""
info "U盘: $USB"
info "备份目录: $BACKUP_DIR"
info "日期: $DATE"
echo ""

# ── 主备份（排除 secrets）──────────────────────
if [[ $SECRETS_ONLY -eq 0 ]]; then
    MAIN_ARCHIVE="$BACKUP_DIR/life-$DATE.tar.zst"

    info "Step 1/2: 主数据归档（排除 secrets）..."
    echo ""

    if [[ -f "$MAIN_ARCHIVE" ]]; then
        warn "已存在 $MAIN_ARCHIVE，将覆盖"
    fi

    life_size=$(du -sh --exclude="$LIFE_DIR/secrets" "$LIFE_DIR" 2>/dev/null | cut -f1)
    info "归档大小（估计）: $life_size"

    tar --zstd -cf "$MAIN_ARCHIVE" \
        --exclude-from="$EXCLUDES" \
        --exclude='life/secrets' \
        -C "$HOME" life

    archive_size=$(du -sh "$MAIN_ARCHIVE" | cut -f1)
    log "主归档完成: $MAIN_ARCHIVE ($archive_size)"
    echo ""
fi

# ── secrets 加密备份 ───────────────────────────
SECRETS_ARCHIVE="$BACKUP_DIR/secrets-$DATE.tar.zst.gpg"

if [[ $SECRETS_ONLY -eq 0 ]]; then
    info "Step 2/2: secrets 加密归档..."
else
    info "secrets 加密归档..."
fi
echo ""

if [[ ! -d "$LIFE_DIR/secrets" ]] || [[ -z "$(ls -A "$LIFE_DIR/secrets" 2>/dev/null)" ]]; then
    warn "~/life/secrets 为空，跳过"
else
    if [[ -f "$SECRETS_ARCHIVE" ]]; then
        warn "已存在 $SECRETS_ARCHIVE，将覆盖"
    fi

    secrets_size=$(du -sh "$LIFE_DIR/secrets" 2>/dev/null | cut -f1)
    info "secrets 大小: $secrets_size"
    info "将使用 gpg 对称加密，请输入密码（需牢记）..."
    echo ""

    tar --zstd -cf - -C "$LIFE_DIR" secrets | gpg -c --cipher-algo AES256 -o "$SECRETS_ARCHIVE"

    gpg_size=$(du -sh "$SECRETS_ARCHIVE" | cut -f1)
    log "secrets 加密归档完成: $SECRETS_ARCHIVE ($gpg_size)"
fi

# ── 写入还原说明 ──────────────────────────────
README="$BACKUP_DIR/README-还原说明.txt"
cat > "$README" << 'EOF'
========================================
  备份还原说明
========================================

本 U 盘含两类文件：

1. life-YYYY-MM-DD.tar.zst
   主数据归档（保留 Linux 权限）
   还原: tar --zstd -xf life-YYYY-MM-DD.tar.zst -C ~/

2. secrets-YYYY-MM-DD.tar.zst.gpg
   secrets 加密归档（gpg 对称加密）
   还原: gpg -d secrets-YYYY-MM-DD.tar.zst.gpg | tar --zstd -xf - -C ~/life/

注意:
- tar.zst 需要安装 zstd（pacman -S zstd）
- Windows 下可用 7-Zip + zstd 插件打开 .tar.zst
- .gpg 文件需要密码才能解密，请务必牢记
- 权限（uid/gid/mode）在 tar 解压回 Linux 后才能正确还原
EOF

echo ""
echo -e "${CYAN}========================================${NC}"
echo -e " ${GREEN}备份完成${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""
info "U盘备份目录内容:"
ls -lh "$BACKUP_DIR" 2>/dev/null | tail -n +2 | while read -r line; do
    echo -e "  $line"
done
echo ""
warn "建议：拔出 U 盘前执行 sync 确保写入完成"

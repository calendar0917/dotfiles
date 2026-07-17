#!/usr/bin/env bash
set -euo pipefail

# 将 /mnt/d/Z-study 等散落数据迁移到 ~/life 统一结构
# 默认 dry-run，加 --apply 才真正执行
# 不删除任何源文件，D 盘原地保留作冷备份

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

DRY_RUN=1
[[ "${1:-}" == "--apply" ]] && DRY_RUN=0
if [[ $# -gt 0 && "$1" != "--apply" && "$1" != "--help" && "$1" != "-h" ]]; then
    err "未知参数: $1"
    echo "用法: $0 [--apply]"
    exit 1
fi
if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
    echo "用法: $0 [--apply]"
    echo "  无参数 = dry-run（只预览不写入）"
    echo "  --apply = 真正执行 rsync"
    exit 0
fi

EXCLUDES="${HOME}/.config/backup/excludes"
[[ -f "$EXCLUDES" ]] || EXCLUDES="${DOTFILES_DIR}/config/backup/excludes"

RSYNC_BASE="rsync -a --info=progress2 --exclude-from=$EXCLUDES"
if [[ $DRY_RUN -eq 1 ]]; then
    RSYNC_BASE="$RSYNC_BASE --dry-run"
fi

echo ""
echo -e "${CYAN}========================================${NC}"
if [[ $DRY_RUN -eq 1 ]]; then
    echo -e "  数据迁移到 ~/life  ${YELLOW}(DRY-RUN)${NC}"
else
    echo -e "  数据迁移到 ~/life  ${GREEN}(APPLY)${NC}"
fi
echo -e "${CYAN}========================================${NC}"
echo ""
info "目标: $LIFE_DIR"
info "排除列表: $EXCLUDES"
echo ""

# ── 创建目录结构 ──────────────────────────────
for sub in notes reference code library archive secrets; do
    mkdir -p "$LIFE_DIR/$sub"
done

# ── 迁移定义 ──────────────────────────────────
# 目录迁移: "源目录|目标子路径(相对 ~/life)"
DIR_MIGRATIONS=(
    # 笔记（自己的 vault）
    "/mnt/d/Z-study/private|notes"

    # 外部参考笔记
    "/mnt/d/Z-study/obsidian/new_note/小枳壳的APT笔记|reference/小枳壳的APT笔记"
    "/mnt/d/Z-study/obsidian/new_note/小枳壳讲SRC挖掘|reference/小枳壳讲SRC挖掘"

    # 代码/项目
    "/mnt/d/Z-study/keyan|code/keyan"
    "/mnt/d/Z-study/paper|code/paper"
    "/mnt/d/Z-study/quartz|code/quartz"
    "/home/calendar/code/YulinSecRecruit2026|code/YulinSecRecruit2026"

    # 资料库
    "/mnt/d/Z-study/papers|library/papers"
    "/mnt/d/Z-study/课外书|library/books"
    "/mnt/d/Z-study/学习资料|library/courses"

    # 归档
    "/mnt/d/Z-study/材料备份|archive/材料备份"
    "/mnt/d/Z-study/备份/生活|archive/生活"

    # 密钥（live 副本）
    "/home/calendar/.ssh|secrets/ssh"
)

# 文件迁移: "源文件|目标路径(相对 ~/life)"
FILE_MIGRATIONS=(
    # 归档：报告/PPT
    "/mnt/d/Z-study/14张图.pptx|archive/14张图.pptx"
    "/mnt/d/Z-study/班级+学号+姓名（生产实习报告模板）.docx|archive/生产实习报告模板.docx"
    "/mnt/d/Z-study/第4组-组长-陈昱-20260710.doc|archive/第4组-组长-陈昱-20260710.doc"

    # 参考资料中散落的大文件
    "/mnt/d/Z-study/漏洞靶场源码.zip|reference/漏洞靶场源码.zip"
    "/mnt/d/Z-study/axonhub.zip|archive/axonhub.zip"

    # 敏感文件
    "/mnt/d/Z-study/bitwarden_export_20260712153926.json|secrets/bitwarden_export.json"
    "/mnt/d/Z-study/config.yaml|secrets/config.yaml"
    "/mnt/d/Z-study/cookies.json|secrets/cookies.json"
)

# ── 执行目录迁移 ──────────────────────────────
info "目录迁移 (${#DIR_MIGRATIONS[@]} 项)"
echo ""
for entry in "${DIR_MIGRATIONS[@]}"; do
    src="${entry%%|*}"
    dst="${entry##*|}"
    dst_full="$LIFE_DIR/$dst"

    if [[ ! -d "$src" ]]; then
        warn "跳过（源不存在）: $src"
        continue
    fi

    mkdir -p "$(dirname "$dst_full")"
    src_size=$(du -sh "$src" --exclude='.venv' --exclude='node_modules' 2>/dev/null | cut -f1)

    if [[ $DRY_RUN -eq 1 ]]; then
        echo -e "  ${CYAN}→${NC} $src ($src_size) → $dst/"
    else
        log "同步: $src → $dst/"
        $RSYNC_BASE "$src/" "$dst_full/"
    fi
done

# ── 执行文件迁移 ──────────────────────────────
echo ""
info "文件迁移 (${#FILE_MIGRATIONS[@]} 项)"
echo ""
for entry in "${FILE_MIGRATIONS[@]}"; do
    src="${entry%%|*}"
    dst="${entry##*|}"
    dst_full="$LIFE_DIR/$dst"

    if [[ ! -f "$src" ]]; then
        warn "跳过（源不存在）: $src"
        continue
    fi

    mkdir -p "$(dirname "$dst_full")"
    src_size=$(du -sh "$src" 2>/dev/null | cut -f1)

    if [[ $DRY_RUN -eq 1 ]]; then
        echo -e "  ${CYAN}→${NC} $src ($src_size) → $dst"
    else
        log "复制: $src → $dst"
        rsync -a "$src" "$dst_full"
    fi
done

# ── 完成 ──────────────────────────────────────
echo ""
if [[ $DRY_RUN -eq 1 ]]; then
    echo -e "${YELLOW}========================================${NC}"
    echo -e " ${YELLOW}DRY-RUN 预览完成${NC}"
    echo -e "${YELLOW}========================================${NC}"
    echo ""
    info "确认无误后执行: $0 --apply"
else
    # 统计结果
    echo -e "${CYAN}========================================${NC}"
    echo -e " 迁移完成，各目录大小:"
    echo -e "${CYAN}========================================${NC}"
    echo ""
    du -sh "$LIFE_DIR"/* 2>/dev/null | while read -r line; do
        echo -e "  ${GREEN}[+]${NC} $line"
    done
    echo ""
    log "源文件未删除，D 盘保留作冷备份"
    warn "确认无误后可手动清理 ~/code（已复制到 ~/life/code/）"
fi
echo ""

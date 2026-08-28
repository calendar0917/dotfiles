# Dotfiles

用 stow 管理的 dotfiles，多包结构，ArchLinux / Fedora 共用。

## 部署

每个发行版 stow 对应的包：

```bash
cd ~/dotfiles

# Arch
stow -d config -t ~/.config common arch

# Fedora 纯 GNOME
stow -d config -t ~/.config common fedora
```

### 包说明

| 包 | 内容 | 跨发行版 |
| --- | --- | --- |
| `config/common` | fish, kitty, nvim, keyd, fcitx5, backup | 是 |
| `config/arch` | niri, kanshi | 否（仅 Arch） |
| `config/fedora` | gtk-3.0, gtk-4.0 | 否（仅 Fedora） |

### 额外步骤

keyd 需要 root 权限，stow 后执行一次：

```bash
sudo ln -sf ~/.config/keyd/default.conf /etc/keyd/default.conf
sudo systemctl restart keyd
```

## 包清单

包清单按发行版分在 `pkglist/` 下：

```
pkglist/
├── arch-repo.txt     # Arch 官方源显式安装的包（pacman -Qqen）
├── arch-aur.txt      # Arch AUR 安装的包
├── fedora.txt        # Fedora dnf 用户安装包
└── flatpak.txt       # Flatpak 应用（跨发行版）
```

### 更新清单

自动检测当前发行版，与系统更新一体：

```bash
~/dotfiles/scripts/update-packages.sh
```

## 数据迁移与备份

### 目录结构

个人数据统一放在 `~/life/`，excludes 列表位于 `~/.config/backup/excludes`：

```
~/life/
├── notes/       # 自己的笔记 vault
├── reference/   # 外部参考笔记
├── code/        # 代码/项目
├── library/     # 论文/书籍/课件
├── archive/     # 作业/获奖/报告等归档
└── secrets/     # 密钥/导出（加密备份）
```

### 脚本

- `scripts/migrate-to-life.sh` — 将 D 盘散落数据 rsync 到 `~/life`（dry-run 预览，`--apply` 执行，不删源）
- `scripts/backup-to-usb.sh` — 交互式备份/恢复 `~/life` ⇄ U 盘（主数据 tar.zst 保权限，secrets 用 7z 口令加密，自动保留最近 N 份）
- `scripts/backup-gnome.sh` — GNOME dconf 设置备份/恢复 + 扩展列表

```bash
# 迁移（先预览）
~/dotfiles/scripts/migrate-to-life.sh
~/dotfiles/scripts/migrate-to-life.sh --apply

# 备份到 U 盘（无参数自动检测；不指定操作则进入交互菜单）
~/dotfiles/scripts/backup-to-usb.sh
~/dotfiles/scripts/backup-to-usb.sh /mnt/usb --backup
~/dotfiles/scripts/backup-to-usb.sh --restore     # 恢复（交互选择备份）
~/dotfiles/scripts/backup-to-usb.sh --list        # 列出已有备份
~/dotfiles/scripts/backup-to-usb.sh --keep 10     # 保留最近 10 份

# GNOME 备份/恢复
~/dotfiles/scripts/backup-gnome.sh                # 备份
~/dotfiles/scripts/backup-gnome.sh --restore      # 恢复
~/dotfiles/scripts/backup-gnome.sh --list         # 查看备份
```
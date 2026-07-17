# Dotfiles

用 stow 管理的 dotfiles，单 `config/` 包部署。

## 部署

```bash
cd ~/dotfiles
stow -t ~/.config config
```

## 包含

- niri (DMS 模块化)
- kitty
- fish
- kanshi
- keyd
- fcitx5
- nvim (LazyVim)

## 包清单

- `pkglist-repo.txt` — 官方源显式安装的包
- `pkglist-aur.txt` — AUR 安装的包

## 额外步骤

keyd 需要 root 权限，stow 后执行一次：

```bash
sudo ln -sf ~/.config/keyd/default.conf /etc/keyd/default.conf
sudo systemctl restart keyd
```

## 数据迁移与备份

### 目录结构

个人数据统一放在 `~/life/`，stow 后排除列表位于 `~/.config/backup/excludes`：

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
- `scripts/backup-to-usb.sh` — 将 `~/life` 打包备份到 U 盘（tar.zst 保权限，secrets 用 gpg 加密）

```bash
# 迁移（先预览）
~/dotfiles/scripts/migrate-to-life.sh
~/dotfiles/scripts/migrate-to-life.sh --apply

# 备份到 U 盘（自动检测，或指定挂载点）
~/dotfiles/scripts/backup-to-usb.sh
~/dotfiles/scripts/backup-to-usb.sh /mnt/usb
```

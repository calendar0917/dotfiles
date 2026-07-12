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

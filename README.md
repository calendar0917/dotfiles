# Arch Linux / Sway Dotfiles — 部署说明

本仓库包含用于在 Arch Linux (Wayland/Sway/Niri) 环境下快速搭建一致桌面体验的 dotfiles。内容包括 Sway / Niri、Waybar、Kitty、Fuzzel、Kanshi、Neovim、Shell 配置以及若干实用脚本（例如剪贴板桥接 `clip-bridge.py`）。

本说明提供功能概览、前置依赖、逐项部署步骤以及常见故障排查，目标是让你能用最少步骤在新机器上恢复相同桌面环境。

**注意**: 本文以 `~/dotfiles` 为仓库路径假设（可自行替换）。部署采用 `stow` 管理符号链接，便于后续维护。

**主要功能一览**
- 系统层级：Sway 窗口管理与键位绑定、Kanshi 多显示器配置、锁屏与屏幕节能
- 状态栏：Waybar（含自定义样式与 power 菜单脚本）
- 启动器：Fuzzel（含 Catppuccin 主题）
- 终端：Kitty（主题配置）
- Shell：`zsh`（Powerlevel10k）、`fish`（补充配置与提示）
- 编辑器：Neovim（LazyVim + 插件配置）
- 实用脚本：`script/clip-bridge.py`（X11<->Wayland 剪贴板桥接）、Waybar power 菜单等

**目录与关键文件**
- 根 README: [README.md](README.md)
- 脚本: `script/clip-bridge.py`, `script/clip-bridge.sh`
- Sway: `sway/.config/sway/config`
- Waybar: `waybar/.config/waybar/config`, `waybar/.config/waybar/style.css`, `waybar/.config/waybar/power_menu.sh`
- Fuzzel: `fuzzel/.config/fuzzel/fuzzel.ini`（主题在 `fuzzel/.../themes/`）
- Kitty: `kitty/.config/kitty/kitty.conf`（主题文件在 `kitty/.../themes/frappe.conf`）
- Neovim: `nvim/.config/nvim/init.lua`, `nvim/.config/nvim/lazy-lock.json`
- Shell: `zsh/.zshrc`, `zsh/.p10k.zsh`; `fish/.config/fish/config.fish`

- Niri: `niri/.config/niri/config.kdl`, `niri/.config/niri/scripts/swayidle.sh`

## 先决条件
在目标系统上请先安装以下常用包（以 Arch/Manjaro 为例）：

```bash
sudo pacman -Syu
sudo pacman -S --needed \
    sway waybar fuzzel kitty mako grim slurp wl-clipboard \
    kanshi swaylock wl-clipboard grim slurp wofi \
    git stow python-pip fcitx5 pamixer brightnessctl \
    python-pywal # 可选
```

若使用 AUR 包（例如某些主题或工具），请用 `yay` 或其他 AUR 助手安装。

## 快速部署（推荐）
1. 克隆仓库到主目录：

```bash
git clone <仓库地址> ~/dotfiles
cd ~/dotfiles
```

2. 使用 `stow` 部署所需模块（按需运行）：

```bash
# 示例：部署 sway, waybar, kitty, zsh
stow -v sway
stow -v waybar
stow -v kitty
stow -v zsh
stow -v fuzzel
stow -v nvim
```

3. 安装 Neovim 插件（如果使用）：

```bash
# 启动 Neovim 并按提示安装插件（LazyVim/mason）
nvim
```

4. 启动/重载 Sway（在 Sway 会话内）：

```bash
# 重新加载配置
swaymsg reload

# 若要重启 Sway 会话（谨慎使用）
swaymsg exit && sway
```

5. 验证常驻程序是否运行（Waybar、mako、kanshi、clip-bridge 等）

```bash
# 检查 Waybar
pgrep -a waybar
# 检查 clip-bridge.py（如果启用）
pgrep -a clip-bridge.py || pgrep -a wl-copy # 根据环境判断
```

## 模块部署示例与说明

- Sway
    - 文件路径：`sway/.config/sway/config`。
    - 说明：本配置为基于 Sway 的 Wayland 会话准备，包含全面的键位绑定、窗口布局、bar/状态栏启动与脚本集成（例如 Waybar、mako、kanshi、clip-bridge）。
    - 简要键位映射示例（更多请查看配置文件）：常用有 `bindsym $mod+t` 启动终端、`bindsym $mod+d` 启动器、`bindsym $mod+Shift+c` 重载配置、`bindsym Alt+l` 锁屏。

- Niri
    - 文件路径：`niri/.config/niri/config.kdl`，启动脚本：`niri/.config/niri/scripts/swayidle.sh`。
    - 说明：仓库同时提供 Niri（另一个 Wayland 会话/窗口管理选择）的配置，它与 Sway 在操作逻辑上有重叠但配置语法与行为不同。Niri 配置包含输入设备、布局、窗口规则、以及启动项（例如 waybar、mako、clip-bridge 等）的 spawn 设置。
    - 简要键位映射示例（更多请查看配置文件）：常用有 `Mod+T` 启动终端（Kitty）、`Mod+D` 启动 `fuzzel`、`Alt+L` 锁屏、`Mod+R` 进入调整模式（resize）。

- Waybar
    - 文件路径：`waybar/.config/waybar/config` 与 `style.css`
    - 自定义模块包括 `custom/power`，以及网络、CPU、电池等展示
    - `power_menu.sh` 提供关机/锁屏菜单，需确保 `wofi`/`swaylock` 可用

- Fuzzel
    - 文件路径：`fuzzel/.config/fuzzel/fuzzel.ini`
    - 主题位于 `fuzzel/.config/fuzzel/fuzzel/themes/`（大量 Catppuccin 变体）

- Kitty
    - 文件路径：`kitty/.config/kitty/kitty.conf`，主题在 `kitty/.../themes/frappe.conf`

- 剪贴板桥接（X11 <-> Wayland）
    - `script/clip-bridge.py`：自动将由 X11 应用（例如部分 QQ）放入剪贴板的图片路径转换为真实图片数据并同步到 Wayland；同时将图片数据写回 X11，保证双向兼容。
    - 若遇剪贴板不稳定，可参考仓内 `script/clip-bridge.sh` 作为轻量替代脚本。

## 常见故障与排查
- 无法看到 Waybar 或模块：确认 `waybar` 是否在 `ps` 中运行，并检查 `~/.config/waybar/config` 与 `style.css` 是否链接正确。
- 剪贴板图片不显示：若是从 X11 应用复制图片路径到剪贴板，需启用 `clip-bridge.py`，并确保 `xclip`、`wl-copy` 可用。
- Neovim 插件未安装：打开 `nvim`，等待 LazyVim/Mason 自动安装或手动运行 `:Lazy sync`。
- 权限/系统命令失败：power 菜单调用了 `systemctl poweroff` / `reboot`，请确保当前用户有权限或通过 polkit 配置允许。

## 安全与隐私提示
- 仓库中 `.gitignore` 提示存在私钥路径（例如 `.ssh/`, `.gnupg/`），请务必不要把真实密钥或 secrets 提交到远程仓库。
- `clip-bridge.py` 会读取本地文件路径并将文件内容写入剪贴板，请注意不要在不受信任环境下运行导致敏感文件意外泄露。

## 自定义与维护建议
- 若想切换主题：调整 `fuzzel` 的 `include`，或替换 `kitty` 的主题文件。
- 更新插件：在 `nvim` 中运行 `:Lazy update` 或使用 `git` 在仓库内更新子模块/锁文件（如果适用）。
- 若希望按功能分组部署，使用 `stow` 时传递模块名，例如 `stow -v waybar kitty zsh`。

---

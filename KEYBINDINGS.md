# 键位映射（Keybindings）

本文件把仓库中针对 `Sway` 与 `Niri` 的主要键位映射分别列出，便于查阅与自定义。完整、权威的配置仍以各自的配置文件为准：

- Sway 配置文件：`sway/.config/sway/config`
- Niri 配置文件：`niri/.config/niri/config.kdl`

说明：两套配置都使用了一个主修饰键（配置中称为 `$mod` 或 `Mod`）。
- Sway：`$mod` 通常为 `Mod4`（Super/Win键）
- Niri：在配置中也按 `Mod` 使用（同为 Super）

---

## Sway 键位映射（摘录与注释）

基础与通用

- `Mod + t`：打开终端（`kitty`）。
- `Mod + d`：启动器（`fuzzel`）。
- `Mod + Shift + c`：重新加载 Sway 配置（等同于 `swaymsg reload`）。
- `Mod + Shift + e`：退出 Sway（会询问确认）。
- `Alt + l`：锁屏（调用 `swaylock -f -i /home/.../壁纸.jpg -s fill`）。
- `Alt + Shift + l`：锁屏并睡眠（lock -> sleep）。

窗口/焦点导航（Vim 风格）

- `Mod + h` / `Mod + j` / `Mod + k` / `Mod + l`：在列/窗口间移动焦点（左/下/上/右）。
- `Mod + Left/Down/Up/Right`：同上（方向键）。
- `Mod + Shift + h/j/k/l`：移动窗口（调整窗口在列内位置）。
- `Mod + Home` / `Mod + End`：聚焦列首/列尾。

工作区与布局

- `Mod + 1..9`：切换工作区 1..9。
- `Mod + Shift + 1..9`：把当前窗口移动到对应工作区。
- `Mod + s`：切换堆叠（stacking）布局。
- `Mod + w`：切换标签（tabbed）布局。
- `Mod + e`：在平铺/堆叠/标签间切换布局（toggle split）。
- `Mod + f`：最大化列（expand to available width）。
- `Mod + Shift + F`：全屏当前窗口。

浮动/草稿本（scratchpad）

- `Mod + v`：切换窗口浮动模式。
- `Mod + Shift + -`：把窗口移入 scratchpad（隐藏）。
- `Mod + -`：显示/循环 scratchpad 中的窗口。

截屏与录制

- `Ctrl + Q`：截图（mapped to `screenshot` 命令）。
- `Ctrl + Print`：截取整屏。
- `Alt + Print`：截取窗口。
- `Ctrl + 1`：录屏快捷键（使用 `wl-screenrec` 录制并保存到 Downloads）。

媒体 / 音量 / 亮度

- `XF86AudioRaiseVolume`：提升音量（示例：`wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.1+`）。
- `XF86AudioLowerVolume`：降低音量。
- `XF86AudioMute`：切换静音。
- `XF86MonBrightnessUp` / `XF86MonBrightnessDown`：亮度加/减（`brightnessctl`）。

多显示器与焦点监控

- `Mod + Alt + Left/Right/Up/Down`：在显示器间切换焦点。
- 配合 `kanshi` 的自动布局（`exec_always pkill kanshi; exec kanshi`）。

条目级自定义脚本

- 启动时会自动 `exec` 若干服务：`waybar`, `mako`, `kanshi`, `clip-bridge.py` 等，见 `sway/.config/sway/config` 的 `exec`/`spawn` 部分。
- `Mod + v` 绑定用于切换浮动模式；`Mod + d` 用于 `fuzzel` 启动器。

备注：Sway 的实际配置中包含更多边角键、鼠标 wheel 映射、mode（例如 resize 模式）等高级绑定，建议把完整键位保留在 `sway/.config/sway/config` 中以便维护。

---

## Niri 键位映射（摘录与注释）

说明：Niri 的语法为 KDL，配置文件为 `niri/.config/niri/config.kdl`，其 `binds` 或 `binds {}` 段定义键位。以下为仓库中 `niri` 配置的主要绑定摘要。

基础与通用

- `Mod + T`：打开终端（`kitty`）。
- `Mod + D`：启动器（`fuzzel`）。
- `Alt + L`：仅锁屏（`swaylock -f -i /home/.../壁纸.jpg -s fill`）。
- `Alt + Shift + L`：锁屏并睡眠（lock -> suspend）。
- `Mod + Shift + P`：重启 `waybar`（`pkill waybar || true && waybar`）。

窗口/焦点导航

- `Mod + H/J/K/L`：焦点左/下/上/右（与 Sway 类似）。
- `Mod + Shift + H/J/K/L`：移动窗口到左/下/上/右。
- `Mod + Home/End`：聚焦列首/列尾。

工作区/布局

- `Mod + 1..9`：切换工作区 1..9。
- `Mod + Shift + 1..9`：把当前列/窗口移动到对应工作区。
- `Mod + R`：切换预设列宽（或进入 resize 模式，取决于配置）。
- `Mod + W`：切换列的标签显示模式（tabbed）。

调整模式（Resize Mode）

Niri 配置里定义了 `mode "resize"`，进入后可用：

- `h / Left`：缩小宽度（shrink width 10px）
- `l / Right`：增大宽度（grow width 10px）
- `j / Down`、`k / Up`：缩放高度
- `Return / Escape / Mod + r`：退出 resize 模式

截屏、剪贴板与辅助脚本

- `Ctrl + Q`：截图（调用 `screenshot`）
- `Ctrl + Print`：截图整屏
- `Alt + Print`：截图窗口
- `exec_always wl-paste --watch cliphist store`：在启动项中启用剪贴板历史监听
- `exec ~/dotfiles/script/clip-bridge.py`：自动运行剪贴板桥接脚本（如配置）

多媒体 / 系统控制

- `XF86AudioRaiseVolume / Lower / Mute`：音量控制，通常映射到 `wpctl` 或 `pamixer` 命令。
- `XF86MonBrightnessUp / Down`：亮度控制（`brightnessctl`）。

会话与自动启动

- Niri 的 `spawn-at-startup` / `spawn-sh-at-startup` 用来在会话启动时启动 `waybar`, `mako`, `kanshi`, `fcitx5` 等服务，详见 `niri/.config/niri/config.kdl` 的 `spawn-at-startup` 段。

备注：Niri 的 `mode` 与 `window-rule` 更灵活（例如 focus-ring、border、shadow 等视觉样式均可在配置内调整），因此键位与行为可能略有不同，建议在迁移或并用时保留两套配置并明确当前会话是哪一套正在运行。

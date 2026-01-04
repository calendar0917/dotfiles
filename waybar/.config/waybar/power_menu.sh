#!/bin/bash

# 定义选项 (图标 + 文字)
# 注意：这里使用的是 Nerd Font 图标
lock="  Lock"
logout="  Logout"
suspend="  Suspend"
reboot="  Reboot"
shutdown="  Shutdown"

# 构建菜单内容
options="$lock\n$suspend\n$logout\n$reboot\n$shutdown"

# 调用 Wofi 显示菜单
# --dmenu: 只有文字列表模式
# --cache-file /dev/null: 不记录历史，每次顺序固定
selected=$(echo -e "$options" | wofi --dmenu --width 200 --height 200 --cache-file /dev/null --prompt "Power Menu")

# 根据选择执行命令
case $selected in
"$lock")
  swaylock -f -i /home/calendar/Pictures/background/壁纸.jpg -s fill
  ;;
"$suspend")
  swaylock -f -i /home/calendar/Pictures/background/壁纸.jpg -s fill && sleep 0.2 && systemctl suspend
  ;;
"$logout")
  swaymsg exit
  ;;
"$reboot")
  systemctl reboot
  ;;
"$shutdown")
  systemctl poweroff
  ;;
esac

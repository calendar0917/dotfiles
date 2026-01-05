#!/bin/bash
# 建议保存为 ~/scripts/clip-bridge-v2.sh

while true; do
  # 1. 检查 X11 剪贴板中有哪些类型
  TYPES=$(xclip -selection clipboard -t TARGETS -o 2>/dev/null)

  if echo "$TYPES" | grep -q "image/png"; then
    # 同时以多种图片格式写入 Wayland 剪贴板
    # 这样无论网页找 PNG 还是 JPEG，都能对上暗号
    xclip -selection clipboard -t image/png -o | wl-copy --type image/png --type image/jpeg --type image/bmp --type "image/x-icns"
  elif echo "$TYPES" | grep -q "image/jpeg"; then
    xclip -selection clipboard -t image/jpeg -o | wl-copy --type image/jpeg --type image/png
  fi

  # 适当降低频率，防止占用过高，0.5s 对粘贴感官影响不大
  sleep 0.5
done

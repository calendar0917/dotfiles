#!/usr/bin/env python3
import subprocess
import re
import os
import time
import signal

# 存储当前的 wl-copy 进程，确保数据持久
current_wl_proc = None

def clear_prev_sync():
    global current_wl_proc
    if current_wl_proc:
        current_wl_proc.terminate()
        current_wl_proc = None

def sync_logic():
    global current_wl_proc
    last_path = ""
    print("Sway Multi-Platform Clip-Bridge Active...")

    while True:
        try:
            # 1. 从 X11 获取 HTML（检测 QQ 动作）
            html_content = subprocess.check_output(
                ['xclip', '-selection', 'clipboard', '-t', 'text/html', '-o'], 
                stderr=subprocess.DEVNULL
            ).decode('utf-8', errors='ignore')
        except:
            html_content = ""

        # 匹配 QQ 路径
        match = re.search(r'src="file://(/[^"]+)"', html_content)
        if match:
            file_path = match.group(1)
            if file_path != last_path and os.path.exists(file_path):
                print(f"[*] Standardizing Image: {file_path}")
                
                with open(file_path, 'rb') as f:
                    img_data = f.read()

                clear_prev_sync()

                # --- 核心行动 1：同步到 Wayland (供 Zen 使用) ---
                # 使用 --foreground 保证数据在被读取前一直有效
                current_wl_proc = subprocess.Popen(
                    ['wl-copy', '--type', 'image/png', '--foreground'],
                    stdin=subprocess.PIPE
                )
                current_wl_proc.stdin.write(img_data)
                current_wl_proc.stdin.close()

                # --- 核心行动 2：同步回 X11 (供 QQ 本身使用) ---
                # 这一步非常重要！把路径变回真实的图片数据塞回 X11
                # 这样 QQ 就能在它自己的地盘看到“图”而不是“路径”
                subprocess.run(
                    ['xclip', '-selection', 'clipboard', '-t', 'image/png'],
                    input=img_data,
                    stderr=subprocess.DEVNULL
                )

                last_path = file_path
                print("[+] Bi-directional Sync Complete.")

        time.sleep(0.5)

if __name__ == "__main__":
    # 处理退出信号
    signal.signal(signal.SIGINT, lambda x, y: clear_prev_sync() or exit(0))
    sync_logic()

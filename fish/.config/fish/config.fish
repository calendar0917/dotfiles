# =============================================================================
# 环境变量 (Environment Variables)
# =============================================================================

# 路径设置
fish_add_path "$HOME/.config/emacs/bin"

# Java 环境设置
set -gx JAVA_TOOL_OPTIONS "-Dsun.java2d.uiScale=2.0 -Dsun.java2d.dpiaware=false"
set -g GTK_CSD 0

# Cargo 路径配置
if test -d $HOME/.cargo/bin
    set -gx PATH $HOME/.cargo/bin $PATH
end

# 路径跳转
zoxide init fish | source

# vim 模式
#set -g fish_key_bindings fish_vi_key_bindings
# 设置 vi 模式下的光标形状
#set fish_cursor_default block # Normal 模式：方块
#set fish_cursor_insert line # Insert 模式：竖线
#set fish_cursor_replace_one underscore # 替换模式：下划线
#set fish_cursor_visual block # Visual 模式：方块

# =============================================================================
# 别名设置 (Aliases)
# =============================================================================

# 代理设置
alias proxy='set -gx all_proxy http://127.0.0.1:20172'
alias unproxy='set -e all_proxy'
# 路径跳转
alias cdot='cd ~/dotfiles/'
alias cc='cd ~/Project/code'
alias cdon='cd ~/Downloads/'
alias ccon='cd ~/Project/quartz/content'
alias ch='cd ~'
# pacman
alias psyu='sudo pacman -Syu'
# 快速开启应用
alias n='nvim'
alias bt='btop'

# AI 工具设置 (AIChat)
alias ask="aichat -m deepseek:deepseek-chat -- --stram true --role assistant -e"
alias chat="aichat -m deepseek:deepseek-chat --role assistant"
alias think="aichat -m deepseek:deepseek-reasoner"

abbr ps 'sudo pacman -S'
abbr -a ydon 'y ~/Downloads'
abbr -a yconf 'y ~/.config'
abbr -a ypro 'y ~/Project'
abbr -a yc 'y ~/Project/code/'
abbr -a ycon 'y ~/Project/quartz/content'
abbr -a ga 'git add .'
abbr -a gm 'git commit -m'
abbr -a gp 'git push'

if status is-interactive
    # 禁用 Fish 默认的问候语
    set -g fish_greeting ""
end

function y
    set tmp (mktemp -t "yazi-cwd.XXXXXX")
    yazi $argv --cwd-file="$tmp"
    if set cwd (command cat -- "$tmp"); and [ -n "$cwd" ]; and [ "$cwd" != "$PWD" ]
        builtin cd -- "$cwd"
    end
    rm -f -- "$tmp"
end

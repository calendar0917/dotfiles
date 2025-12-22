# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"
export PATH="$HOME/.config/emacs/bin:$PATH"

# =============================================================================
# 主题设置
# =============================================================================
ZSH_THEME="powerlevel10k/powerlevel10k"

# =============================================================================
# 插件设置
# =============================================================================
# 注意：fzf-tab 建议放在 autosuggestions 和 syntax-highlighting 之前
plugins=(
  git 
  fzf 
  fzf-tab 
  zsh-autosuggestions 
  zsh-syntax-highlighting
)

# =============================================================================
# 用户自定义配置 (Aliases & Environment)
# =============================================================================

# 代理设置
alias proxy='export all_proxy=http://127.0.0.1:20172' # 端口根据实际情况调整
alias unproxy='unset all_proxy'

# AI 工具设置 (AIChat)
alias ask="aichat -m deepseek:deepseek-chat -- --stram true --role assistant -e"
alias chat="aichat -m deepseek:deepseek-chat --role assistant"
alias think="aichat -m deepseek:deepseek-reasoner"

# Java 环境设置
export JAVA_TOOL_OPTIONS="-Dsun.java2d.uiScale=2.0 -Dsun.java2d.dpiaware=false"


# 加载 Oh My Zsh
source $ZSH/oh-my-zsh.sh

# =============================================================================
# FZF-TAB 深度配置 (解决盲输问题)
# =============================================================================

# 1. 禁用 Zsh 默认的补全菜单，交给 fzf 接管
zstyle ':completion:*' menu no

# 2. 基础 FZF 行为设置
# --multi: 启用 TAB 键多选
# --info=inline: 节省空间，信息显示在一行
zstyle ':fzf-tab:*' fzf-flags --multi --height=60%

# 3. 智能预览命令生成器
# 检测是否安装了 bat (用于语法高亮)，如果没有则使用 cat
if command -v bat &> /dev/null; then
  # 使用 bat 进行高亮，--style=plain 去除边框，--color=always 强制颜色
  _PREVIEW_CMD='pacman -Si $word 2>/dev/null || yay -Si $word | bat --color=always --style=plain --paging=never'
else
  _PREVIEW_CMD='pacman -Si $word 2>/dev/null || yay -Si $word'
fi

# 4. 针对 Pacman 和 Yay 的具体配置
# 当使用 -S (安装) 时，预览包的详细信息
zstyle ':fzf-tab:complete:(yay|pacman):-S:*' fzf-preview "$_PREVIEW_CMD"

# 当使用 -R (卸载) 时，预览已安装包的信息 (-Qi)
zstyle ':fzf-tab:complete:(yay|pacman):-R:*' fzf-preview 'pacman -Qi $word 2>/dev/null || yay -Qi $word | bat --color=always --style=plain --paging=never 2>/dev/null || cat'

# 5. 预览窗口样式
# right:60%:wrap -> 预览窗口在右侧，占 60% 宽度，文本自动换行
zstyle ':fzf-tab:*' fzf-preview-window 'right:60%:wrap'

# 6. (可选) 其他实用预览
# `cd` 命令预览目录内容
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls -1 --color=always $realpath'
# `kill` 命令预览进程详情
zstyle ':completion:*:*:*:*:processes' command "ps -u $USER -o pid,user,comm -w -w"
zstyle ':fzf-tab:complete:(kill|ps):argument-rest' fzf-preview '[[ $group == "[process ID]" ]] && ps --pid $word -o cmd --no-headers -w -w'

# =============================================================================
# P10k 配置文件加载
# =============================================================================
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

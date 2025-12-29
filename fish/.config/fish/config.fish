# =============================================================================
# 环境变量 (Environment Variables)
# =============================================================================

# 路径设置
fish_add_path "$HOME/.config/emacs/bin"

# Java 环境设置
set -gx JAVA_TOOL_OPTIONS "-Dsun.java2d.uiScale=2.0 -Dsun.java2d.dpiaware=false"

# =============================================================================
# 别名设置 (Aliases)
# =============================================================================

# 代理设置
alias proxy='set -gx all_proxy http://127.0.0.1:20172'
alias unproxy='set -e all_proxy'

# AI 工具设置 (AIChat)
alias ask="aichat -m deepseek:deepseek-chat -- --stram true --role assistant -e"
alias chat="aichat -m deepseek:deepseek-chat --role assistant"
alias think="aichat -m deepseek:deepseek-reasoner"

if status is-interactive
    # 禁用 Fish 默认的问候语
    set -g fish_greeting ""
end

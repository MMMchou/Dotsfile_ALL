
# Load shared shell environment
[ -f "$HOME/.shell_env" ] && . "$HOME/.shell_env"

# 加载 ~/.bashrc（里面有 ~/bin、~/.local/bin 的 PATH，kiro-cli 就在 ~/.local/bin）
# 登录 shell（Ghostty / herdr 新 pane）默认只读 .bash_profile，不读 .bashrc，
# 所以以前要手动 source ~/.bashrc，现在自动加载。
[ -f "$HOME/.bashrc" ] && . "$HOME/.bashrc"


# 命令行工具 + 代理自动检测（yazi / fzf / zoxide / eza / bat / starship 等）
[ -f "$HOME/.shell_tools" ] && . "$HOME/.shell_tools"

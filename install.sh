#!/usr/bin/env bash
# ============================================================
# Dotsfile_ALL 一键安装脚本
#
# 用法：
#   git clone https://github.com/MMMchou/Dotsfile_ALL.git ~/Dotsfile_ALL
#   cd ~/Dotsfile_ALL
#   chmod +x install.sh
#   ./install.sh
#
# 功能：
#   1. 检测并安装 Homebrew
#   2. 通过 brew 安装所有工具
#   3. 备份已有配置文件
#   4. 创建符号链接
#   5. 安装 TPM（tmux 插件管理器）+ tmux 插件
#   6. 同步 LazyVim 插件
#   7. 提示手动操作
# ============================================================

set -e

# ---- 颜色 ----
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles_backup/$(date +%Y%m%d_%H%M%S)"

# ============================================================
# 1) Homebrew
# ============================================================
install_homebrew() {
    if command -v brew &>/dev/null; then
        info "Homebrew 已安装，跳过"
    else
        info "正在安装 Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        # Apple Silicon
        if [[ -f /opt/homebrew/bin/brew ]]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        fi
    fi
}

# ============================================================
# 2) 安装工具
# ============================================================
install_tools() {
    info "正在安装工具..."

    local formulae=(tmux neovim git ripgrep)
    local casks=(orbstack)

    for pkg in "${formulae[@]}"; do
        if brew list "$pkg" &>/dev/null; then
            info "$pkg 已安装，跳过"
        else
            info "安装 $pkg..."
            brew install "$pkg"
        fi
    done

    for pkg in "${casks[@]}"; do
        if brew list --cask "$pkg" &>/dev/null; then
            info "$pkg 已安装，跳过"
        else
            info "安装 $pkg..."
            brew install --cask "$pkg"
        fi
    done

    # AeroSpace 需要先 tap
    if brew list --cask aerospace &>/dev/null; then
        info "aerospace 已安装，跳过"
    else
        info "安装 AeroSpace..."
        brew install --cask nikitabobko/tap/aerospace
    fi
}

# ============================================================
# 3) 备份已有配置
# ============================================================
backup_existing() {
    info "备份已有配置到 $BACKUP_DIR ..."
    mkdir -p "$BACKUP_DIR"

    local files=(
        "$HOME/.shell_env"
        "$HOME/.bash_profile"
        "$HOME/.zshrc"
        "$HOME/.tmux.conf"
        "$HOME/.config/nvim"
        "$HOME/.config/aerospace/aerospace.toml"
        "$HOME/.ssh/config"
        "$HOME/.claude/settings.json"
    )

    for f in "${files[@]}"; do
        if [[ -e "$f" || -L "$f" ]]; then
            local rel="${f#$HOME/}"
            local target_dir="$BACKUP_DIR/$(dirname "$rel")"
            mkdir -p "$target_dir"
            cp -rL "$f" "$BACKUP_DIR/$rel" 2>/dev/null || true
            info "  已备份 $f"
        fi
    done
}

# ============================================================
# 4) 创建符号链接
# ============================================================
create_symlinks() {
    info "创建符号链接..."

    # shell
    if [[ -f "$DOTFILES_DIR/shell/.shell_env" ]]; then
        ln -sf "$DOTFILES_DIR/shell/.shell_env" "$HOME/.shell_env"
    else
        warn ".shell_env 不存在（含密钥，不在仓库中）"
        if [[ ! -f "$HOME/.shell_env" ]]; then
            cp "$DOTFILES_DIR/shell/.shell_env.example" "$HOME/.shell_env"
            warn "已从模板创建 ~/.shell_env，请编辑填入你的真实 API Key"
        fi
    fi

    ln -sf "$DOTFILES_DIR/shell/.bash_profile" "$HOME/.bash_profile"
    ln -sf "$DOTFILES_DIR/shell/.zshrc" "$HOME/.zshrc"

    # tmux
    ln -sf "$DOTFILES_DIR/tmux/.tmux.conf" "$HOME/.tmux.conf"

    # nvim
    mkdir -p "$HOME/.config"
    rm -rf "$HOME/.config/nvim"
    ln -sf "$DOTFILES_DIR/nvim" "$HOME/.config/nvim"

    # aerospace
    mkdir -p "$HOME/.config/aerospace"
    ln -sf "$DOTFILES_DIR/aerospace/aerospace.toml" "$HOME/.config/aerospace/aerospace.toml"

    # ssh
    mkdir -p "$HOME/.ssh/sockets"
    chmod 700 "$HOME/.ssh"
    ln -sf "$DOTFILES_DIR/ssh/config" "$HOME/.ssh/config"
    chmod 600 "$HOME/.ssh/config"

    # claude
    mkdir -p "$HOME/.claude"
    ln -sf "$DOTFILES_DIR/claude/settings.json" "$HOME/.claude/settings.json"

    info "符号链接创建完成"
}

# ============================================================
# 5) 安装 TPM + tmux 插件
# ============================================================
install_tpm() {
    local tpm_dir="$HOME/.tmux/plugins/tpm"
    if [[ -d "$tpm_dir" ]]; then
        info "TPM 已安装，跳过"
    else
        info "安装 TPM..."
        git clone --depth 1 https://github.com/tmux-plugins/tpm "$tpm_dir"
    fi

    info "安装 tmux 插件..."
    "$tpm_dir/bin/install_plugins" || warn "tmux 插件安装失败（可稍后在 tmux 中按 Control+a 再按 Shift+i 手动安装）"
}

# ============================================================
# 6) 同步 LazyVim 插件
# ============================================================
sync_nvim() {
    if command -v nvim &>/dev/null; then
        info "同步 Neovim 插件（首次可能较慢）..."
        nvim --headless "+Lazy! sync" +qa 2>/dev/null || warn "Neovim 插件同步失败（可稍后打开 nvim 自动安装）"
    else
        warn "nvim 未找到，跳过插件同步"
    fi
}

# ============================================================
# 主流程
# ============================================================
main() {
    echo ""
    echo "============================================"
    echo "  Dotsfile_ALL 一键安装"
    echo "============================================"
    echo ""

    install_homebrew
    install_tools
    backup_existing
    create_symlinks
    install_tpm
    sync_nvim

    echo ""
    info "============================================"
    info "  安装完成！"
    info "============================================"
    echo ""
    info "后续手动操作："
    echo "  1. 编辑 ~/.shell_env 填入你的 API Key（如果还没填）"
    echo "  2. source ~/.shell_env  让环境变量生效"
    echo "  3. 打开 OrbStack App 完成初始化"
    echo "  4. 打开 AeroSpace App（或重启后自动启动）"
    echo "  5. 进入 tmux 按 Control+a 再按 Shift+i 确认插件已安装"
    echo "  6. 打开 nvim 等待插件自动加载"
    echo ""
    info "配置文件修改指南见 README.md"
    echo ""
}

main "$@"

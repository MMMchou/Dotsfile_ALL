#!/usr/bin/env bash
# ============================================================
# Dotsfile_ALL 一键安装脚本（macOS + Linux 兼容）
#
# 用法：
#   git clone https://github.com/MMMchou/Dotsfile_ALL.git ~/Dotsfile_ALL
#   cd ~/Dotsfile_ALL
#   chmod +x install.sh
#   ./install.sh
#
# 自动检测操作系统：
#   macOS  → 用 Homebrew 安装，包含 AeroSpace / OrbStack / Alacritty
#   Linux  → 用 apt / yum 安装，只装 tmux / neovim / git 等命令行工具
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
OS="$(uname -s)"

# ============================================================
# 1) 安装工具（自动区分 macOS / Linux）
# ============================================================
install_tools_macos() {
    # 安装 Homebrew
    if command -v brew &>/dev/null; then
        info "Homebrew 已安装，跳过"
    else
        info "正在安装 Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        if [[ -f /opt/homebrew/bin/brew ]]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        fi
    fi

    local formulae=(tmux neovim git ripgrep fd)
    local casks=(orbstack)

    for pkg in "${formulae[@]}"; do
        if brew list "$pkg" &>/dev/null; then
            info "$pkg 已安装，跳过"
        else
            info "安装 $pkg..."
            HOMEBREW_NO_AUTO_UPDATE=1 brew install "$pkg"
        fi
    done

    for pkg in "${casks[@]}"; do
        if brew list --cask "$pkg" &>/dev/null; then
            info "$pkg 已安装，跳过"
        else
            info "安装 $pkg..."
            HOMEBREW_NO_AUTO_UPDATE=1 brew install --cask "$pkg"
        fi
    done

    if brew list --cask aerospace &>/dev/null; then
        info "aerospace 已安装，跳过"
    else
        info "安装 AeroSpace..."
        HOMEBREW_NO_AUTO_UPDATE=1 brew install --cask nikitabobko/tap/aerospace
    fi
}

install_tools_linux() {
    # 检测包管理器
    if command -v apt-get &>/dev/null; then
        local PM="apt"
        info "检测到 apt（Debian/Ubuntu 系列）"
    elif command -v yum &>/dev/null; then
        local PM="yum"
        info "检测到 yum（CentOS/RHEL 系列）"
    elif command -v dnf &>/dev/null; then
        local PM="dnf"
        info "检测到 dnf（Fedora 系列）"
    elif command -v pacman &>/dev/null; then
        local PM="pacman"
        info "检测到 pacman（Arch 系列）"
    else
        error "未检测到已知的包管理器，请手动安装 tmux neovim git ripgrep fd-find"
        return 1
    fi

    local need_sudo=""
    if [[ "$(id -u)" -ne 0 ]]; then
        need_sudo="sudo"
    fi

    info "正在安装工具..."

    case "$PM" in
        apt)
            $need_sudo apt-get update -qq
            $need_sudo apt-get install -y -qq tmux git ripgrep fd-find curl xclip nodejs npm
            # Ubuntu/Debian 的 fd 命令叫 fdfind，需要创建别名
            if command -v fdfind &>/dev/null && ! command -v fd &>/dev/null; then
                mkdir -p "$HOME/.local/bin"
                ln -sf "$(which fdfind)" "$HOME/.local/bin/fd"
                info "已创建 fd 软链接到 ~/.local/bin/fd"
            fi
            # neovim：apt 仓库版本可能太旧，尝试用 snap 或 appimage
            if command -v nvim &>/dev/null; then
                local nvim_ver
                nvim_ver=$(nvim --version | head -1 | grep -oE '[0-9]+\.[0-9]+' | head -1)
                if awk "BEGIN{exit ($nvim_ver >= 0.9) ? 0 : 1}"; then
                    info "neovim $nvim_ver 已安装，版本 OK"
                else
                    warn "neovim 版本太旧（$nvim_ver），LazyVim 需要 0.9+。尝试安装新版..."
                    install_neovim_linux
                fi
            else
                install_neovim_linux
            fi
            ;;
        yum|dnf)
            $need_sudo $PM install -y tmux git ripgrep xclip
            # node（markdown-preview 等插件需要）
            $need_sudo $PM install -y nodejs npm 2>/dev/null || warn "nodejs 安装失败，markdown-preview 可能不可用"
            # fd
            if ! command -v fd &>/dev/null; then
                $need_sudo $PM install -y fd-find 2>/dev/null || warn "fd-find 安装失败，可忽略"
            fi
            # neovim
            if ! command -v nvim &>/dev/null; then
                install_neovim_linux
            fi
            ;;
        pacman)
            $need_sudo pacman -Sy --noconfirm tmux neovim git ripgrep fd xclip nodejs npm
            ;;
    esac
}

install_neovim_linux() {
    local nvim_dir="$HOME/.local/bin"
    mkdir -p "$nvim_dir"
    local arch
    arch="$(uname -m)"

    if [[ "$arch" == "x86_64" ]]; then
        info "安装 Neovim AppImage（x86_64）..."
        curl -fsSL -o "$nvim_dir/nvim.appimage" "https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.appimage"
        chmod +x "$nvim_dir/nvim.appimage"

        if "$nvim_dir/nvim.appimage" --version &>/dev/null; then
            ln -sf "$nvim_dir/nvim.appimage" "$nvim_dir/nvim"
            info "Neovim AppImage 安装成功"
        else
            info "FUSE 不可用，解压 AppImage..."
            cd "$nvim_dir"
            ./nvim.appimage --appimage-extract &>/dev/null
            ln -sf "$nvim_dir/squashfs-root/AppRun" "$nvim_dir/nvim"
            info "Neovim 解压安装成功"
        fi
    elif [[ "$arch" == "aarch64" || "$arch" == "arm64" ]]; then
        info "ARM64 架构，尝试从包管理器安装 Neovim（无 ARM AppImage）..."
        if command -v apt-get &>/dev/null; then
            # 添加 neovim PPA 获取新版
            local need_sudo=""
            [[ "$(id -u)" -ne 0 ]] && need_sudo="sudo"
            $need_sudo apt-get install -y software-properties-common 2>/dev/null || true
            $need_sudo add-apt-repository -y ppa:neovim-ppa/unstable 2>/dev/null || true
            $need_sudo apt-get update -qq
            $need_sudo apt-get install -y neovim
        else
            warn "ARM64 上无法自动安装新版 Neovim，请手动编译或使用 snap install neovim --classic"
        fi
    else
        warn "未知架构 $arch，请手动安装 Neovim 0.9+"
    fi

    if ! echo "$PATH" | grep -q "$HOME/.local/bin"; then
        warn "请确保 ~/.local/bin 在 PATH 中"
    fi
}

# ============================================================
# 2) 备份已有配置
# ============================================================
backup_existing() {
    info "备份已有配置到 $BACKUP_DIR ..."
    mkdir -p "$BACKUP_DIR"

    local files=(
        "$HOME/.tmux.conf"
        "$HOME/.config/nvim"
        "$HOME/.ssh/config"
    )

    # macOS 特有的配置
    if [[ "$OS" == "Darwin" ]]; then
        files+=(
            "$HOME/.shell_env"
            "$HOME/.bash_profile"
            "$HOME/.zshrc"
            "$HOME/.config/aerospace/aerospace.toml"
            "$HOME/.config/alacritty/alacritty.toml"
            "$HOME/.claude/settings.json"
        )
    else
        files+=(
            "$HOME/.bashrc"
            "$HOME/.shell_env"
        )
    fi

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
# 3) 创建符号链接
# ============================================================
create_symlinks() {
    info "创建符号链接..."

    # shell 环境变量
    if [[ -f "$DOTFILES_DIR/shell/.shell_env" ]]; then
        ln -sf "$DOTFILES_DIR/shell/.shell_env" "$HOME/.shell_env"
    else
        warn ".shell_env 不存在（含密钥，不在仓库中）"
        if [[ ! -f "$HOME/.shell_env" ]] && [[ -f "$DOTFILES_DIR/shell/.shell_env.example" ]]; then
            cp "$DOTFILES_DIR/shell/.shell_env.example" "$HOME/.shell_env"
            warn "已从模板创建 ~/.shell_env，请编辑填入你的真实值"
        fi
    fi

    # tmux
    ln -sf "$DOTFILES_DIR/tmux/.tmux.conf" "$HOME/.tmux.conf"

    # nvim
    mkdir -p "$HOME/.config"
    rm -rf "$HOME/.config/nvim"
    ln -sf "$DOTFILES_DIR/nvim" "$HOME/.config/nvim"

    # ssh
    mkdir -p "$HOME/.ssh/sockets"
    chmod 700 "$HOME/.ssh"
    if [[ -f "$DOTFILES_DIR/ssh/config" ]]; then
        ln -sf "$DOTFILES_DIR/ssh/config" "$HOME/.ssh/config"
        chmod 600 "$HOME/.ssh/config"
    fi

    # ---- macOS 特有 ----
    if [[ "$OS" == "Darwin" ]]; then
        # shell 配置
        [[ -f "$DOTFILES_DIR/shell/.bash_profile" ]] && ln -sf "$DOTFILES_DIR/shell/.bash_profile" "$HOME/.bash_profile"
        [[ -f "$DOTFILES_DIR/shell/.zshrc" ]] && ln -sf "$DOTFILES_DIR/shell/.zshrc" "$HOME/.zshrc"

        # alacritty
        mkdir -p "$HOME/.config/alacritty"
        [[ -f "$DOTFILES_DIR/alacritty/alacritty.toml" ]] && ln -sf "$DOTFILES_DIR/alacritty/alacritty.toml" "$HOME/.config/alacritty/alacritty.toml"

        # aerospace
        mkdir -p "$HOME/.config/aerospace"
        [[ -f "$DOTFILES_DIR/aerospace/aerospace.toml" ]] && ln -sf "$DOTFILES_DIR/aerospace/aerospace.toml" "$HOME/.config/aerospace/aerospace.toml"

        # claude
        mkdir -p "$HOME/.claude"
        [[ -f "$DOTFILES_DIR/claude/settings.json" ]] && ln -sf "$DOTFILES_DIR/claude/settings.json" "$HOME/.claude/settings.json"
    fi

    # ---- Linux 特有 ----
    if [[ "$OS" == "Linux" ]]; then
        # 确保 .bashrc 加载 .shell_env
        if [[ -f "$HOME/.bashrc" ]] && ! grep -q 'shell_env' "$HOME/.bashrc"; then
            echo '' >> "$HOME/.bashrc"
            echo '# 加载共享环境变量' >> "$HOME/.bashrc"
            echo '[ -f "$HOME/.shell_env" ] && . "$HOME/.shell_env"' >> "$HOME/.bashrc"
            info "已在 .bashrc 中添加 .shell_env 加载"
        fi
        # 确保 ~/.local/bin 在 PATH 里
        if [[ -f "$HOME/.bashrc" ]] && ! grep -q '.local/bin' "$HOME/.bashrc"; then
            echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
            info "已在 .bashrc 中添加 ~/.local/bin 到 PATH"
        fi
    fi

    info "符号链接创建完成"
}

# ============================================================
# 4) 安装 TPM + tmux 插件
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
# 5) 同步 LazyVim 插件
# ============================================================
sync_nvim() {
    if command -v nvim &>/dev/null; then
        info "同步 Neovim 插件（首次可能较慢）..."
        timeout 120 nvim --headless "+Lazy! sync" +qa 2>/dev/null || warn "Neovim 插件同步超时或失败（可稍后打开 nvim 自动安装）"
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
    echo "  操作系统：$OS"
    echo "============================================"
    echo ""

    # 安装工具
    if [[ "$OS" == "Darwin" ]]; then
        info "检测到 macOS，使用 Homebrew"
        install_tools_macos
    elif [[ "$OS" == "Linux" ]]; then
        info "检测到 Linux"
        install_tools_linux
    else
        error "不支持的操作系统：$OS"
        exit 1
    fi

    backup_existing
    create_symlinks
    install_tpm
    sync_nvim

    echo ""
    info "============================================"
    info "  安装完成！"
    info "============================================"
    echo ""

    if [[ "$OS" == "Darwin" ]]; then
        info "后续操作（macOS）："
        echo "  1. 编辑 ~/.shell_env 填入你的 API Key（如果还没填）"
        echo "  2. source ~/.shell_env"
        echo "  3. 打开 OrbStack App 完成初始化"
        echo "  4. 打开 AeroSpace App"
        echo "  5. 进入 tmux 按 Control+a 再按 Shift+i 确认插件已安装"
        echo "  6. 打开 nvim 等待插件自动加载"
    else
        info "后续操作（Linux）："
        echo "  1. source ~/.bashrc  加载新配置"
        echo "  2. 编辑 ~/.shell_env 填入你的环境变量（如果需要）"
        echo "  3. 进入 tmux 按 Control+a 再按 Shift+i 确认插件已安装"
        echo "  4. 打开 nvim 等待插件自动加载"
        echo ""
        echo "  注意：Linux 上没有 AeroSpace / OrbStack / Alacritty（这些是 macOS 专属）"
        echo "  Linux 上直接用系统终端 + tmux + nvim 即可"
    fi

    echo ""
    info "配置文件说明见 README.md，插件说明见 nvim/PLUGINS.md"
    echo ""
}

main "$@"

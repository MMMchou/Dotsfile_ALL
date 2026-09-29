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
#   macOS       → Homebrew 安装全部工具 + Ghostty / AeroSpace / OrbStack / Alacritty / Nerd Font
#   Linux / WSL → 系统包管理器装基础依赖，再用 Homebrew on Linux 装同一套命令行工具
#                 （herdr / yazi / starship / eza / zoxide … apt 里没有或太旧）
#                 root 用户不能用 Homebrew，会退回只装 tmux / neovim / git 等基础工具
#
# 可选参数：
#   --no-tools   只链接配置文件，不安装任何软件
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
IS_WSL=false
if [[ "$OS" == "Linux" ]] && grep -qi microsoft /proc/version 2>/dev/null; then
    IS_WSL=true
fi


# ============================================================
# 两个平台共用的 Homebrew 包
# ============================================================
COMMON_FORMULAE=(
    # 基础
    bash bash-completion@2 coreutils git tmux neovim node jq
    # 搜索 / 文件
    ripgrep fd fzf bat eza zoxide yazi sevenzip
    # git
    lazygit git-delta
    # 预览：图片 / PDF / 视频 / SVG / Markdown / LaTeX
    imagemagick ghostscript poppler ffmpeg resvg glow tectonic
    # 外观 / 杂项
    starship fastfetch btop
    # AI agent 多路复用
    herdr
)

brew_install_list() {
    local pkg
    for pkg in "$@"; do
        if brew list "$pkg" &>/dev/null; then
            info "$pkg 已安装，跳过"
        else
            info "安装 $pkg..."
            HOMEBREW_NO_AUTO_UPDATE=1 brew install "$pkg" || warn "$pkg 安装失败，稍后可手动 brew install $pkg"
        fi
    done
}

install_npm_tools() {
    command -v npm &>/dev/null || { warn "没有 npm，跳过 mermaid-cli"; return; }
    if command -v mmdc &>/dev/null; then
        info "mermaid-cli 已安装，跳过"
    else
        info "安装 mermaid-cli（nvim 里渲染 Mermaid 图）..."
        # 只下载无界面浏览器，不下载完整 Chrome
        PUPPETEER_SKIP_DOWNLOAD=true npm install -g @mermaid-js/mermaid-cli || warn "mermaid-cli 安装失败，可忽略"
        npx --yes puppeteer browsers install chrome-headless-shell >/dev/null 2>&1 || true
    fi
}

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

    local formulae=("${COMMON_FORMULAE[@]}" terminal-notifier pngpaste)
    local casks=(ghostty orbstack alacritty font-hack-nerd-font)

    brew_install_list "${formulae[@]}"

    for pkg in "${casks[@]}"; do
        if brew list --cask "$pkg" &>/dev/null; then
            info "$pkg 已安装，跳过"
        else
            info "安装 $pkg..."
            HOMEBREW_NO_AUTO_UPDATE=1 brew install --cask "$pkg" || warn "$pkg 安装失败（如果已从官网装过可忽略）"
        fi
    done

    if brew list --cask aerospace &>/dev/null; then
        info "aerospace 已安装，跳过"
    else
        info "安装 AeroSpace..."
        HOMEBREW_NO_AUTO_UPDATE=1 brew install --cask nikitabobko/tap/aerospace
    fi

    install_npm_tools
}

install_tools_linux_basic() {
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
            $need_sudo apt-get install -y -qq tmux git ripgrep fd-find curl xclip nodejs npm || warn "部分包安装失败，可忽略非核心包"
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
            $need_sudo $PM install -y tmux git ripgrep xclip || warn "部分包安装失败"
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

# Linux / WSL：基础依赖用系统包管理器，其余用 Homebrew on Linux（和 macOS 同一套版本）
install_tools_linux() {
    if [[ "$(id -u)" -eq 0 ]]; then
        warn "当前是 root 用户，Homebrew 不支持 root，只安装基础工具（tmux / neovim / git …）"
        warn "想要完整环境：新建普通用户后用该用户重新运行 ./install.sh"
        install_tools_linux_basic
        return
    fi

    info "安装基础依赖（编译工具 / curl / 剪贴板等，需要 sudo 密码）..."
    if command -v apt-get &>/dev/null; then
        sudo apt-get update -qq
        sudo apt-get install -y -qq build-essential procps curl file git xclip wl-clipboard unzip || warn "部分基础包安装失败"
    elif command -v dnf &>/dev/null; then
        sudo dnf group install -y development-tools 2>/dev/null || sudo dnf groupinstall -y 'Development Tools' || true
        sudo dnf install -y procps-ng curl file git xclip wl-clipboard || warn "部分基础包安装失败"
    elif command -v yum &>/dev/null; then
        sudo yum groupinstall -y 'Development Tools' || true
        sudo yum install -y procps-ng curl file git xclip || warn "部分基础包安装失败"
    elif command -v pacman &>/dev/null; then
        sudo pacman -Sy --noconfirm --needed base-devel procps-ng curl file git xclip wl-clipboard || warn "部分基础包安装失败"
    fi

    if ! command -v brew &>/dev/null; then
        for b in /home/linuxbrew/.linuxbrew/bin/brew "$HOME/.linuxbrew/bin/brew"; do
            [[ -x "$b" ]] && eval "$("$b" shellenv)" && break
        done
    fi
    if ! command -v brew &>/dev/null; then
        info "安装 Homebrew on Linux..."
        NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || {
            warn "Homebrew 安装失败，退回只装基础工具"
            install_tools_linux_basic
            return
        }
        eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    fi

    brew_install_list "${COMMON_FORMULAE[@]}"
    install_npm_tools

    # Ghostty 不在 Homebrew for Linux 里（WSL 下终端在 Windows 那边，不需要）
    if [[ "$IS_WSL" != true ]] && ! command -v ghostty &>/dev/null; then
        warn "Linux 桌面想用 Ghostty（图片预览）：见 https://ghostty.org/docs/install/binary 按发行版安装"
    fi
    install_nerd_font_linux
}

install_nerd_font_linux() {
    if [[ "$IS_WSL" == true ]]; then
        warn "WSL：Nerd Font 要装在 Windows 那边（install.ps1 会装），WSL 里不需要"
        return
    fi
    local font_dir="$HOME/.local/share/fonts"
    if ls "$font_dir"/HackNerdFont* &>/dev/null; then
        info "Hack Nerd Font 已安装，跳过"
        return
    fi
    info "安装 Hack Nerd Font..."
    mkdir -p "$font_dir"
    curl -fsSL -o /tmp/Hack.zip https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Hack.zip \
        && unzip -oq /tmp/Hack.zip -d "$font_dir" && rm -f /tmp/Hack.zip \
        && { command -v fc-cache &>/dev/null && fc-cache -f "$font_dir" >/dev/null; info "字体已安装"; } \
        || warn "字体安装失败，可手动下载 https://www.nerdfonts.com"
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
            (cd "$nvim_dir" && ./nvim.appimage --appimage-extract &>/dev/null)
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

lazygit_config_dir() {
    if [[ "$OS" == "Darwin" ]]; then
        echo "$HOME/Library/Application Support/lazygit"
    else
        echo "${XDG_CONFIG_HOME:-$HOME/.config}/lazygit"
    fi
}

# 把仓库里的文件/目录链接到目标位置（目标是普通目录时先删掉，已备份过）
link() {
    local src="$1" dst="$2"
    [[ -e "$src" ]] || { warn "仓库里没有 $src，跳过"; return; }
    mkdir -p "$(dirname "$dst")"
    if [[ -d "$dst" && ! -L "$dst" ]]; then rm -rf "$dst"; fi
    ln -sfn "$src" "$dst"
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
        "$HOME/.shell_tools"
        "$HOME/.config/ghostty/config"
        "$HOME/.config/herdr/config.toml"
        "$HOME/.config/yazi"
        "$HOME/.config/starship"
        "$HOME/.config/delta"
        "$(lazygit_config_dir)/config.yml"
    )

    # macOS 特有的配置
    if [[ "$OS" == "Darwin" ]]; then
        files+=(
            "$HOME/.shell_env"
            "$HOME/.bash_profile"
            "$HOME/.bashrc"
            "$HOME/.zshrc"
            "$HOME/.config/aerospace/aerospace.toml"
            "$HOME/.config/alacritty/alacritty.toml"
            "$HOME/.claude/settings.json"
        )
    else
        files+=(
            "$HOME/.bashrc"
            "$HOME/.zshrc"
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
    link "$DOTFILES_DIR/nvim" "$HOME/.config/nvim"

    # 命令行工具配置（macOS / Linux 通用）
    link "$DOTFILES_DIR/shell/.shell_tools"  "$HOME/.shell_tools"
    link "$DOTFILES_DIR/herdr/config.toml"   "$HOME/.config/herdr/config.toml"
    link "$DOTFILES_DIR/yazi"                "$HOME/.config/yazi"
    link "$DOTFILES_DIR/starship"            "$HOME/.config/starship"
    link "$DOTFILES_DIR/delta"               "$HOME/.config/delta"
    link "$DOTFILES_DIR/lazygit/config.yml"  "$(lazygit_config_dir)/config.yml"
    [[ -f "$HOME/.config/starship/current" ]] || echo hacker > "$DOTFILES_DIR/starship/current"

    # Ghostty（WSL 不需要：终端在 Windows 那边）
    if [[ "$IS_WSL" != true ]]; then
        link "$DOTFILES_DIR/ghostty/config" "$HOME/.config/ghostty/config"
        local ghostty_local="$HOME/.config/ghostty/config.local"
        if [[ ! -f "$ghostty_local" ]]; then
            if [[ "$OS" == "Darwin" ]]; then
                echo "command = $(brew --prefix 2>/dev/null || echo /opt/homebrew)/bin/bash --login" > "$ghostty_local"
            else
                echo "# 这台机器自己的 Ghostty 设置（不进仓库）" > "$ghostty_local"
            fi
            info "已生成 $ghostty_local"
        fi
    fi

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
        [[ -f "$DOTFILES_DIR/shell/.bashrc" ]] && ln -sf "$DOTFILES_DIR/shell/.bashrc" "$HOME/.bashrc"
        [[ -f "$DOTFILES_DIR/shell/.zshrc" ]] && ln -sf "$DOTFILES_DIR/shell/.zshrc" "$HOME/.zshrc"

        # alacritty
        mkdir -p "$HOME/.config/alacritty"
        [[ -f "$DOTFILES_DIR/alacritty/alacritty.toml" ]] && ln -sf "$DOTFILES_DIR/alacritty/alacritty.toml" "$HOME/.config/alacritty/alacritty.toml"

        # aerospace
        mkdir -p "$HOME/.config/aerospace"
        [[ -f "$DOTFILES_DIR/aerospace/aerospace.toml" ]] && ln -sf "$DOTFILES_DIR/aerospace/aerospace.toml" "$HOME/.config/aerospace/aerospace.toml"

    fi

    # claude：settings.json 复制而不是链接（herdr 会往里写本机路径的 hook）
    mkdir -p "$HOME/.claude"
    if [[ ! -f "$HOME/.claude/settings.json" && -f "$DOTFILES_DIR/claude/settings.json" ]]; then
        cp "$DOTFILES_DIR/claude/settings.json" "$HOME/.claude/settings.json"
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
        # 加载命令行工具 + 代理检测（~/.shell_tools 里自己判断平台）
        if [[ -f "$HOME/.bashrc" ]] && ! grep -q 'shell_tools' "$HOME/.bashrc"; then
            echo '[ -f "$HOME/.shell_tools" ] && . "$HOME/.shell_tools"' >> "$HOME/.bashrc"
            info "已在 .bashrc 中添加 .shell_tools 加载"
        fi
        # 确保 ~/.local/bin 在 PATH 里
        if [[ -f "$HOME/.bashrc" ]] && ! grep -q '.local/bin' "$HOME/.bashrc"; then
            echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
            info "已在 .bashrc 中添加 ~/.local/bin 到 PATH"
        fi

        # 如果用户使用 zsh，也配置 .zshrc
        if [[ "$SHELL" == */zsh ]] || command -v zsh &>/dev/null; then
            local zshrc="$HOME/.zshrc"
            # 链接项目中的 .zshrc（已做 macOS/Linux 条件判断）
            if [[ -f "$DOTFILES_DIR/shell/.zshrc" ]]; then
                ln -sf "$DOTFILES_DIR/shell/.zshrc" "$zshrc"
                info "已链接 .zshrc"
            else
                # 如果没有项目 .zshrc，手动确保加载 .shell_env
                [[ -f "$zshrc" ]] || touch "$zshrc"
                if ! grep -q 'shell_env' "$zshrc"; then
                    echo '' >> "$zshrc"
                    echo '# 加载共享环境变量' >> "$zshrc"
                    echo '[ -f "$HOME/.shell_env" ] && . "$HOME/.shell_env"' >> "$zshrc"
                    info "已在 .zshrc 中添加 .shell_env 加载"
                fi
                if ! grep -q '.local/bin' "$zshrc"; then
                    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$zshrc"
                    info "已在 .zshrc 中添加 ~/.local/bin 到 PATH"
                fi
            fi
        fi
    fi

    info "符号链接创建完成"
}

# ============================================================
# 4) 安装 TPM + tmux 插件
# ============================================================
install_tpm() {
    if ! command -v git &>/dev/null || ! command -v tmux &>/dev/null; then
        warn "没有 git 或 tmux，跳过 tmux 插件"
        return 0
    fi
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
# git：delta 显示 diff（catppuccin 配色，左右并排 + 行号）
# ============================================================
setup_git_delta() {
    command -v git &>/dev/null || { warn "没有 git，跳过 delta 配置"; return 0; }
    local inc="$HOME/.config/delta/catppuccin.gitconfig"
    if ! git config --global --get-all include.path 2>/dev/null | grep -qF "$inc"; then
        git config --global --add include.path "$inc"
    fi
    git config --global core.pager delta
    git config --global interactive.diffFilter "delta --color-only"
    git config --global delta.features catppuccin-mocha
    git config --global delta.navigate true
    git config --global delta.dark true
    git config --global delta.line-numbers true
    git config --global delta.side-by-side true
    git config --global merge.conflictstyle diff3
    git config --global diff.colorMoved default
    info "git 已配置 delta"
}

# ============================================================
# yazi 插件 / 主题（package.toml 里锁定的版本）
# ============================================================
setup_yazi() {
    if command -v ya &>/dev/null; then
        info "安装 yazi 插件和主题..."
        (cd "$HOME/.config/yazi" && ya pkg install) || warn "yazi 插件安装失败（稍后可运行 ya pkg install）"
    fi
}

# ============================================================
# herdr 插件
# ============================================================
setup_herdr() {
    command -v herdr &>/dev/null || { warn "没有 herdr，跳过 herdr 插件"; return; }
    info "安装 herdr 插件..."
    local plugins=(
        lmilojevicc/herdr-splits.nvim     # Ctrl+h/j/k/l 在 nvim 分屏和 herdr pane 之间无缝移动
        ddfonseca/herdr-paste-image       # Ctrl+a i：剪贴板截图存成文件并粘贴路径
    )
    if [[ "$OS" == "Darwin" ]]; then
        plugins+=(
            nwarwick/herdr-caffeinate                    # agent 干活时不休眠
            ppggff/herdr-plugin/input-method-keeper      # 每个 pane 记住自己的输入法
        )
    fi
    local p
    for p in "${plugins[@]}"; do
        herdr plugin install "$p" --yes >/dev/null 2>&1 && info "  $p" || warn "  $p 安装失败（稍后可运行 herdr plugin install $p --yes）"
    done
    # 仓库里自己写的插件
    herdr plugin link "$DOTFILES_DIR/herdr/plugins/kiro-resume" >/dev/null 2>&1 && info "  local kiro-resume" || true
    if [[ "$OS" == "Darwin" ]]; then
        herdr plugin link "$DOTFILES_DIR/herdr/plugins/translate" >/dev/null 2>&1 && info "  local translate" || true
    fi
    # Claude Code 状态上报（herdr 侧边栏显示 claude 在干活/等你）
    herdr integration install claude >/dev/null 2>&1 || true
    herdr server reload-config >/dev/null 2>&1 || true
}

# ============================================================
# 5) 同步 LazyVim 插件
# ============================================================
sync_nvim() {
    if command -v nvim &>/dev/null; then
        # restore = 按 nvim/lazy-lock.json 装锁定的版本（sync 会升级到最新，可能和 nvim 版本不兼容）
        info "安装 Neovim 插件（按 lazy-lock.json 锁定的版本，首次较慢）..."
        local t=""; command -v timeout &>/dev/null && t="timeout 300"; command -v gtimeout &>/dev/null && t="gtimeout 300"
        $t nvim --headless "+Lazy! restore" +qa 2>/dev/null || warn "Neovim 插件安装超时或失败（可稍后打开 nvim 自动安装）"
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
    if [[ "$IS_WSL" == true ]]; then
        echo "  环境：WSL (Windows Subsystem for Linux)"
    fi
    echo "============================================"
    echo ""

    # 安装工具
    if [[ "$NO_TOOLS" == true ]]; then
        info "--no-tools：跳过软件安装，只链接配置"
    elif [[ "$OS" == "Darwin" ]]; then
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
    setup_git_delta
    setup_yazi
    install_tpm
    setup_herdr
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
        echo "  3. 打开 Ghostty，输入 herdr 开始使用（图片预览只在 Ghostty 里有）"
        echo "  4. 打开 AeroSpace / OrbStack App 完成初始化"
        echo "  5. 打开 nvim 等待插件自动加载"
        echo "  6. 第一次截图/通知时，按系统提示给权限"
    else
        if [[ "$IS_WSL" == true ]]; then
            info "后续操作（WSL）："
            echo "  1. source ~/.bashrc  加载新配置"
            echo "  2. 编辑 ~/.shell_env 填入你的环境变量（如果需要）"
            echo "  3. 进入 tmux 按 Control+a 再按 Shift+i 确认插件已安装"
            echo "  4. 打开 nvim 等待插件自动加载"
            echo ""
            echo "  提示：建议使用 Windows Terminal 获得最佳体验"
            echo "  在 Windows Terminal 中可直接选择 Ubuntu 标签页进入 WSL"
        else
            info "后续操作（Linux）："
            echo "  1. source ~/.bashrc  加载新配置"
            echo "  2. 编辑 ~/.shell_env 填入你的环境变量（如果需要）"
            echo "  3. 进入 tmux 按 Control+a 再按 Shift+i 确认插件已安装"
            echo "  4. 打开 nvim 等待插件自动加载"
        fi
        echo ""
        echo "  用法：在终端输入 herdr 开始（或继续用 tmux）"
        echo "  注意：AeroSpace / OrbStack / 输入法记忆 / 不休眠 / 翻译插件是 macOS 专属"
        echo "  图片预览需要终端支持 Kitty 图片协议：Linux 用 Ghostty / Kitty；Windows 用 WezTerm"
    fi

    echo ""
    info "配置文件说明见 README.md，插件说明见 nvim/PLUGINS.md"
    echo ""
}

NO_TOOLS=false
for arg in "$@"; do
    case "$arg" in
        --no-tools) NO_TOOLS=true ;;
    esac
done

main "$@"

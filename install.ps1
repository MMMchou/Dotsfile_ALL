# ============================================================
# Dotsfile_ALL Windows 安装脚本（原生 Windows 版，不用 WSL）
#
# 用法（普通 PowerShell 就行，不需要管理员）：
#   git clone https://github.com/MMMchou/Dotsfile_ALL.git $HOME\Dotsfile_ALL
#   cd $HOME\Dotsfile_ALL
#   powershell -ExecutionPolicy Bypass -File .\install.ps1
#
# 做的事：
#   1. 用 Scoop（装在用户目录，不要管理员）安装：
#      WezTerm 终端 / PowerShell 7 / Neovim / git / yazi / starship / lazygit / delta /
#      eza / bat / fzf / zoxide / ripgrep / fd / glow / btop / fastfetch /
#      预览依赖（imagemagick / ghostscript / poppler / ffmpeg / 7zip / resvg / tectonic）/
#      nvim 编译 treesitter 用的 gcc + tree-sitter / Hack Nerd Font
#   2. 安装 herdr（官方 Windows 安装脚本）
#   3. 把仓库里的配置链接到 Windows 对应位置（已有配置先备份）
#   4. 配置 PowerShell 配置文件、git delta、yazi 插件、herdr 插件、nvim 插件
#
# 想用 WSL（在 Ubuntu 里跑 Linux 那一套）：用 install-wsl.ps1
#
# 和 macOS 的区别：
#   - nvim 里直接看图片（snacks.image）需要 Kitty 图片协议，Windows 上的终端都不支持，
#     图片用 空格+f+o 调系统程序打开；yazi 在 WezTerm nightly / Windows Terminal 1.22+ 里可以预览图片
#   - herdr 的输入法记忆 / 不休眠 / 翻译插件是 macOS 专属
#   - bash 写的 herdr 插件（无缝移动 / 截图粘贴）靠 Git 自带的 bash 运行，未在 Windows 实测
# ============================================================

# 不用 "Stop"：Windows PowerShell 5.1 里外部命令往 stderr 输出就会被当成致命错误
$ErrorActionPreference = "Continue"

function Write-Info  { param($msg) Write-Host "[INFO] $msg" -ForegroundColor Green }
function Write-Warn  { param($msg) Write-Host "[WARN] $msg" -ForegroundColor Yellow }
function Write-Err   { param($msg) Write-Host "[ERROR] $msg" -ForegroundColor Red }

$DotfilesDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$BackupDir   = Join-Path $HOME (".dotfiles_backup\" + (Get-Date -Format "yyyyMMdd_HHmmss"))
$NoTools     = $args -contains "--no-tools"

function Refresh-Path {
    $env:Path = [Environment]::GetEnvironmentVariable("Path", "User") + ";" +
                [Environment]::GetEnvironmentVariable("Path", "Machine")
}

# ============================================================
# 1) Scoop + 工具
# ============================================================
$ScoopBuckets = @(
    @{ Name = "extras" },       # lazygit
    @{ Name = "versions" },     # wezterm-nightly（yazi 在 Windows 上预览图片要 nightly 版）
    @{ Name = "nerd-fonts" }    # Hack-NF-Mono
)
$ScoopApps = @(
    # 基础
    "git", "pwsh", "neovim", "nodejs-lts", "python", "jq",
    # 搜索 / 文件
    "ripgrep", "fd", "fzf", "bat", "eza", "zoxide", "yazi", "7zip",
    # git
    "lazygit", "delta",
    # 预览：图片 / PDF / 视频 / SVG / Markdown / LaTeX
    "imagemagick", "ghostscript", "poppler", "ffmpeg", "resvg", "glow", "tectonic",
    # nvim-treesitter 编译语法解析器需要 C 编译器 + tree-sitter CLI
    "mingw", "tree-sitter",
    # 外观 / 杂项
    "starship", "fastfetch", "btop",
    # 终端 + 字体
    "wezterm-nightly", "Hack-NF-Mono"
)

function Install-Tools {
    if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
        Write-Info "安装 Scoop（装在 $HOME\scoop，不需要管理员）..."
        Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
        Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression
        Refresh-Path
    } else {
        Write-Info "Scoop 已安装"
    }

    # 先装 git（加 bucket 需要）
    scoop install git *> $null
    foreach ($b in $ScoopBuckets) {
        if (-not (scoop bucket list | Where-Object { $_.Name -eq $b.Name })) {
            Write-Info "添加 scoop bucket: $($b.Name)"
            scoop bucket add $b.Name *> $null
        }
    }

    $installed = (scoop list 6>$null | ForEach-Object { $_.Name })
    foreach ($app in $ScoopApps) {
        if ($installed -contains $app) {
            Write-Info "$app 已安装，跳过"
        } else {
            Write-Info "安装 $app..."
            scoop install $app *> $null
            if (-not (scoop prefix $app 2>$null)) { Write-Warn "$app 安装失败，稍后可手动 scoop install $app" }
        }
    }
    Refresh-Path

    # herdr：官方 Windows 安装脚本（装在用户目录）
    if (Get-Command herdr -ErrorAction SilentlyContinue) {
        Write-Info "herdr 已安装，跳过"
    } else {
        Write-Info "安装 herdr..."
        try {
            Invoke-RestMethod https://herdr.dev/install.ps1 | Invoke-Expression
            Refresh-Path
        } catch { Write-Warn "herdr 安装失败：$_  （手动：irm https://herdr.dev/install.ps1 | iex）" }
    }

    # mermaid-cli：nvim 里渲染 Mermaid 图（只下载无界面浏览器）
    if (-not (Get-Command mmdc -ErrorAction SilentlyContinue) -and (Get-Command npm -ErrorAction SilentlyContinue)) {
        Write-Info "安装 mermaid-cli..."
        $env:PUPPETEER_SKIP_DOWNLOAD = "true"
        npm install -g @mermaid-js/mermaid-cli 2>&1 | Out-Null
        Remove-Item Env:PUPPETEER_SKIP_DOWNLOAD
        npx --yes puppeteer browsers install chrome-headless-shell 2>&1 | Out-Null
    }

    # PowerShell 模块：PSFzf（fzf 的 Ctrl+r / Ctrl+t）
    foreach ($shell in @("pwsh", "powershell")) {
        if (Get-Command $shell -ErrorAction SilentlyContinue) {
            & $shell -NoProfile -Command "if (-not (Get-Module -ListAvailable PSFzf)) { if (`$PSVersionTable.PSVersion.Major -lt 6) { Install-PackageProvider NuGet -MinimumVersion 2.8.5.201 -Scope CurrentUser -Force | Out-Null }; Set-PSRepository PSGallery -InstallationPolicy Trusted; Install-Module PSFzf -Scope CurrentUser -Force }" *> $null
        }
    }
}

# ============================================================
# 2) 链接配置
# ============================================================
function Test-IsLink($path) {
    $item = Get-Item -LiteralPath $path -Force -ErrorAction SilentlyContinue
    return $item -and ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)
}

function Backup-Path($path) {
    # 已经是链接（上次安装建的）就不用备份
    if ((Test-Path -LiteralPath $path) -and -not (Test-IsLink $path)) {
        $rel = $path.Substring($HOME.Length).TrimStart('\')
        $dst = Join-Path $BackupDir $rel
        New-Item -ItemType Directory -Force -Path (Split-Path $dst) | Out-Null
        Copy-Item -LiteralPath $path -Destination $dst -Recurse -Force -ErrorAction SilentlyContinue
        Write-Info "  已备份 $path"
    }
}

# 目录用 Junction（不需要管理员）；文件优先 SymbolicLink（需要开发者模式），不行就复制
function Link-Item($src, $dst) {
    if (-not (Test-Path -LiteralPath $src)) { Write-Warn "仓库里没有 $src，跳过"; return }
    Backup-Path $dst
    New-Item -ItemType Directory -Force -Path (Split-Path $dst) | Out-Null
    if (Test-IsLink $dst) {
        # 只删链接本身。不能 Remove-Item -Recurse：Windows PowerShell 5.1 会顺着 Junction 把仓库里的文件删掉
        if ((Get-Item -LiteralPath $dst -Force).PSIsContainer) { [IO.Directory]::Delete($dst) } else { [IO.File]::Delete($dst) }
    } elseif (Test-Path -LiteralPath $dst) {
        Remove-Item -LiteralPath $dst -Recurse -Force
    }
    if ((Get-Item -LiteralPath $src).PSIsContainer) {
        New-Item -ItemType Junction -Path $dst -Target $src | Out-Null
    } else {
        try {
            New-Item -ItemType SymbolicLink -Path $dst -Target $src -ErrorAction Stop | Out-Null
        } catch {
            Copy-Item -LiteralPath $src -Destination $dst -Force
            $script:CopiedFiles += $dst
        }
    }
}

function Link-Configs {
    Write-Info "链接配置文件（已有的先备份到 $BackupDir）..."
    $script:CopiedFiles = @()
    $appdata = $env:APPDATA; $local = $env:LOCALAPPDATA

    Link-Item "$DotfilesDir\nvim"                "$local\nvim"
    Link-Item "$DotfilesDir\yazi"                "$appdata\yazi\config"
    Link-Item "$DotfilesDir\starship"            "$HOME\.config\starship"
    Link-Item "$DotfilesDir\delta"               "$HOME\.config\delta"
    Link-Item "$DotfilesDir\lazygit\config.yml"  "$local\lazygit\config.yml"
    Link-Item "$DotfilesDir\herdr\config.toml"   "$appdata\herdr\config.toml"
    Link-Item "$DotfilesDir\wezterm\wezterm.lua" "$HOME\.wezterm.lua"

    $cur = "$DotfilesDir\starship\current"
    if (-not (Test-Path $cur)) { Set-Content -Path $cur -Value "hacker" }

    # claude：复制（herdr 会往里写本机的 hook）
    $claude = "$HOME\.claude\settings.json"
    if (-not (Test-Path $claude) -and (Test-Path "$DotfilesDir\claude\settings.json")) {
        New-Item -ItemType Directory -Force -Path (Split-Path $claude) | Out-Null
        Copy-Item "$DotfilesDir\claude\settings.json" $claude
    }

    if ($script:CopiedFiles.Count -gt 0) {
        Write-Warn "没开「开发者模式」，下面这些文件是复制过去的（改仓库后要重新运行 install.ps1 才会同步）："
        $script:CopiedFiles | ForEach-Object { Write-Host "    $_" }
        Write-Host "    开启方法：设置 → 系统 → 开发者选项 → 开发人员模式（需要管理员），然后重新运行"
    }
}

# PowerShell 配置文件：pwsh 和 Windows PowerShell 都加一行加载仓库里的 profile.ps1
function Setup-Profile {
    $line = ". `"$DotfilesDir\powershell\profile.ps1`""
    $profiles = @(
        (Join-Path ([Environment]::GetFolderPath("MyDocuments")) "PowerShell\Microsoft.PowerShell_profile.ps1"),
        (Join-Path ([Environment]::GetFolderPath("MyDocuments")) "WindowsPowerShell\Microsoft.PowerShell_profile.ps1")
    )
    foreach ($p in $profiles) {
        New-Item -ItemType Directory -Force -Path (Split-Path $p) | Out-Null
        if (-not (Test-Path $p)) { New-Item -ItemType File -Path $p | Out-Null }
        if (-not (Select-String -Path $p -SimpleMatch "powershell\profile.ps1" -Quiet)) {
            Add-Content -Path $p -Value "`n# Dotsfile_ALL：命令行工具 + 代理检测 + 提示符`n$line"
            Write-Info "已在 $p 加载 profile.ps1"
        }
    }
    # yazi 识别文件类型要用 Git 自带的 file.exe
    $fileExe = Join-Path $HOME "scoop\apps\git\current\usr\bin\file.exe"
    if (Test-Path $fileExe) { [Environment]::SetEnvironmentVariable("YAZI_FILE_ONE", $fileExe, "User") }
}

# ============================================================
# 3) git delta / yazi 插件 / herdr 插件 / nvim 插件
# ============================================================
function Setup-GitDelta {
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) { return }
    $inc = ("$HOME\.config\delta\catppuccin.gitconfig") -replace '\\', '/'
    $existing = git config --global --get-all include.path 2>$null
    if (-not ($existing -contains $inc)) { git config --global --add include.path $inc }
    git config --global core.pager delta
    git config --global interactive.diffFilter "delta --color-only"
    git config --global delta.features catppuccin-mocha
    git config --global delta.navigate true
    git config --global delta.dark true
    git config --global delta.line-numbers true
    git config --global delta.side-by-side true
    git config --global merge.conflictstyle diff3
    git config --global diff.colorMoved default
    Write-Info "git 已配置 delta"
}

function Setup-Yazi {
    if (Get-Command ya -ErrorAction SilentlyContinue) {
        Write-Info "安装 yazi 插件和主题..."
        Push-Location "$env:APPDATA\yazi\config"
        try { ya pkg install 2>&1 | Out-Null } catch { Write-Warn "yazi 插件安装失败（稍后可运行 ya pkg install）" }
        Pop-Location
    }
}

function Setup-Herdr {
    if (-not (Get-Command herdr -ErrorAction SilentlyContinue)) { Write-Warn "没有 herdr，跳过 herdr 插件"; return }
    Write-Info "安装 herdr 插件..."
    # 这两个插件是 bash 脚本，靠 Git 自带的 bash 运行（未在 Windows 实测）
    foreach ($p in @("lmilojevicc/herdr-splits.nvim", "ddfonseca/herdr-paste-image")) {
        herdr plugin install $p --yes 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) { Write-Info "  $p" } else { Write-Warn "  $p 安装失败" }
    }
    herdr integration install claude 2>&1 | Out-Null
}

function Sync-Nvim {
    if (Get-Command nvim -ErrorAction SilentlyContinue) {
        # restore = 按 nvim/lazy-lock.json 装锁定的版本
        Write-Info "安装 Neovim 插件（按 lazy-lock.json 锁定的版本，首次较慢）..."
        nvim --headless "+Lazy! restore" +qa 2>&1 | Out-Null
    }
}

# ============================================================
# 主流程
# ============================================================
Write-Host ""
Write-Host "============================================"
Write-Host "  Dotsfile_ALL Windows 安装（原生，不用 WSL）"
Write-Host "============================================"
Write-Host ""

if ($NoTools) { Write-Info "--no-tools：跳过软件安装，只链接配置" } else { Install-Tools }
Link-Configs
Setup-Profile
Setup-GitDelta
Setup-Yazi
Setup-Herdr
Sync-Nvim

Write-Host ""
Write-Info "============================================"
Write-Info "  安装完成！"
Write-Info "============================================"
Write-Host ""
Write-Info "后续操作："
Write-Host "  1. 打开 WezTerm（默认进入 PowerShell 7，提示符、别名都已配置）"
Write-Host "  2. 输入 herdr 开始使用；nvim 打开编辑器；y 打开 yazi"
Write-Host "  3. 代理端口不是 33210 的话，在用户环境变量里设 PROXY_HTTP_PORT（例如 7897）"
Write-Host "  4. Claude Code 的 API Key：在用户环境变量里设 ANTHROPIC_AUTH_TOKEN 等（参考 shell\.shell_env.example）"
Write-Host ""
Read-Host "按回车退出"

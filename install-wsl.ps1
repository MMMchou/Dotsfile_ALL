# ============================================================
# Dotsfile_ALL Windows 安装脚本（WSL 版：在 WSL 的 Ubuntu 里跑 Linux 那一套）
# 不想用 WSL 的话用 install.ps1（原生 Windows 版）
#
# 用法（以管理员身份运行 PowerShell）：
#   .\install-wsl.ps1
#
# 功能：
#   1. 自动检测并安装 WSL2 + Ubuntu
#   2. 在 WSL 内 clone 并运行 install.sh 完成全部配置
#   3. 安装 WezTerm 终端 + Hack Nerd Font，并复制 WezTerm 配置
#      （WezTerm 支持终端图片，nvim / yazi 能预览图片；Windows Terminal 不支持）
#
# 注意：tmux 没有 Windows 原生版本，必须通过 WSL 使用
# ============================================================

$ErrorActionPreference = "Stop"

# ---- 颜色输出 ----
function Write-Info  { param($msg) Write-Host "[INFO] $msg" -ForegroundColor Green }
function Write-Warn  { param($msg) Write-Host "[WARN] $msg" -ForegroundColor Yellow }
function Write-Err   { param($msg) Write-Host "[ERROR] $msg" -ForegroundColor Red }

# ---- 检查管理员权限 ----
function Test-Admin {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-Admin)) {
    Write-Warn "需要管理员权限来安装 WSL，正在提权..."
    $scriptPath = $MyInvocation.MyCommand.Path
    Start-Process powershell.exe -ArgumentList "-ExecutionPolicy Bypass -File `"$scriptPath`"" -Verb RunAs
    exit
}

# ---- 检测 WSL ----
function Test-WSLInstalled {
    try {
        $result = wsl --status 2>&1
        if ($LASTEXITCODE -eq 0) { return $true }
    } catch {}
    # 备用检测：看是否有任何已安装的发行版
    try {
        $distros = wsl --list --quiet 2>&1
        if ($LASTEXITCODE -eq 0 -and $distros) { return $true }
    } catch {}
    return $false
}

function Test-UbuntuInstalled {
    try {
        $distros = wsl --list --quiet 2>&1
        if ($distros -match "Ubuntu") { return $true }
    } catch {}
    return $false
}

# ============================================================
# 1) 安装 WSL2 + Ubuntu
# ============================================================
Write-Host ""
Write-Host "============================================"
Write-Host "  Dotsfile_ALL Windows 安装"
Write-Host "============================================"
Write-Host ""

if (Test-WSLInstalled) {
    Write-Info "WSL 已安装"
} else {
    Write-Info "正在安装 WSL2..."
    Write-Info "这可能需要几分钟，安装完成后需要重启电脑"
    wsl --install --no-distribution
    if ($LASTEXITCODE -ne 0) {
        Write-Err "WSL 安装失败，请手动运行: wsl --install"
        Write-Host "安装完成后重启电脑，再次运行此脚本"
        Read-Host "按回车退出"
        exit 1
    }
    Write-Warn "WSL 已安装，请重启电脑后重新运行此脚本"
    Read-Host "按回车退出并重启"
    Restart-Computer -Confirm
    exit
}

if (Test-UbuntuInstalled) {
    Write-Info "Ubuntu 已安装"
} else {
    Write-Info "正在安装 Ubuntu..."
    wsl --install -d Ubuntu
    if ($LASTEXITCODE -ne 0) {
        Write-Err "Ubuntu 安装失败，请手动运行: wsl --install -d Ubuntu"
        Read-Host "按回车退出"
        exit 1
    }
    Write-Info "Ubuntu 安装完成"
    Write-Warn "请在弹出的 Ubuntu 窗口中设置用户名和密码"
    Write-Warn "设置完成后，关闭 Ubuntu 窗口，再次运行此脚本"
    Read-Host "按回车退出"
    exit
}

# ============================================================
# 2) 在 WSL 内部署 dotfiles
# ============================================================
Write-Info "在 WSL Ubuntu 中部署 dotfiles..."

# 检查 WSL 内是否已有 dotfiles
$checkResult = wsl -d Ubuntu -- bash -c "test -d ~/Dotsfile_ALL && echo 'exists'" 2>&1
if ($checkResult -match "exists") {
    Write-Info "WSL 内已有 ~/Dotsfile_ALL，更新中..."
    wsl -d Ubuntu -- bash -c "cd ~/Dotsfile_ALL && git pull"
} else {
    Write-Info "在 WSL 内 clone Dotsfile_ALL..."
    # 获取当前脚本所在目录的 git remote
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    $gitRemote = ""
    try {
        Push-Location $scriptDir
        $gitRemote = git remote get-url origin 2>&1
        Pop-Location
    } catch {
        Pop-Location
    }

    if ($gitRemote -and $gitRemote -notmatch "fatal") {
        Write-Info "从 $gitRemote clone..."
        wsl -d Ubuntu -- bash -c "git clone '$gitRemote' ~/Dotsfile_ALL"
    } else {
        # 使用 Windows 路径转 WSL 路径复制
        $wslPath = wsl -d Ubuntu -- wslpath -a "$scriptDir" 2>&1
        Write-Info "从 Windows 路径复制: $wslPath"
        wsl -d Ubuntu -- bash -c "cp -r '$wslPath' ~/Dotsfile_ALL"
    }
}

# 运行 install.sh
Write-Info "在 WSL 内运行 install.sh..."
wsl -d Ubuntu -- bash -c "cd ~/Dotsfile_ALL && chmod +x install.sh && ./install.sh"

if ($LASTEXITCODE -ne 0) {
    Write-Warn "install.sh 执行过程中有错误，请检查上面的输出"
} else {
    Write-Info "WSL 内 dotfiles 安装完成"
}

# ============================================================
# 3) WezTerm + Nerd Font（Windows 这边的终端）
# ============================================================
Write-Info "安装 WezTerm 和 Hack Nerd Font..."
if (Get-Command winget -ErrorAction SilentlyContinue) {
    winget install --id wez.wezterm -e --accept-source-agreements --accept-package-agreements --silent 2>&1 | Out-Null
} else {
    Write-Warn "没有 winget，请手动安装 WezTerm: https://wezfurlong.org/wezterm/"
}

# Hack Nerd Font：从 Nerd Fonts 官方 release 下载，只装给当前用户（不需要管理员）
$fontDir = Join-Path $env:LOCALAPPDATA "Microsoft\Windows\Fonts"
if (Get-ChildItem $fontDir -Filter "HackNerdFont*" -ErrorAction SilentlyContinue) {
    Write-Info "Hack Nerd Font 已安装，跳过"
} else {
    try {
        $zip = Join-Path $env:TEMP "Hack.zip"
        $tmp = Join-Path $env:TEMP "HackNF"
        Invoke-WebRequest -Uri "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Hack.zip" -OutFile $zip -UseBasicParsing
        Expand-Archive $zip -DestinationPath $tmp -Force
        New-Item -ItemType Directory -Force -Path $fontDir | Out-Null
        $reg = "HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts"
        Get-ChildItem $tmp -Filter "*.ttf" | ForEach-Object {
            Copy-Item $_.FullName $fontDir -Force
            New-ItemProperty -Path $reg -Name "$($_.BaseName) (TrueType)" -Value (Join-Path $fontDir $_.Name) -PropertyType String -Force | Out-Null
        }
        Remove-Item $zip, $tmp -Recurse -Force
        Write-Info "Hack Nerd Font 安装完成（新打开的程序才能看到）"
    } catch {
        Write-Warn "字体安装失败，请手动下载 Hack Nerd Font: https://www.nerdfonts.com/font-downloads"
    }
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$weztermSrc = Join-Path $scriptDir "wezterm\wezterm.lua"
$weztermDst = Join-Path $HOME ".wezterm.lua"
if (Test-Path $weztermSrc) {
    if (Test-Path $weztermDst) { Copy-Item $weztermDst "$weztermDst.bak" -Force }
    Copy-Item $weztermSrc $weztermDst -Force
    Write-Info "已复制 WezTerm 配置到 $weztermDst"
    # WSL 版：WezTerm 默认进入 WSL 的 Ubuntu
    Set-Content -Path (Join-Path $HOME ".wezterm.local.lua") -Encoding UTF8 -Value 'return function(config) config.default_domain = "WSL:Ubuntu" end'
    Write-Info "WezTerm 默认进入 WSL Ubuntu（改回 PowerShell：删掉 ~\.wezterm.local.lua）"
}

Write-Host ""
Write-Info "============================================"
Write-Info "  安装完成！"
Write-Info "============================================"
Write-Host ""
Write-Info "后续操作："
Write-Host "  1. 打开 WezTerm（默认直接进入 WSL Ubuntu）"
Write-Host "  2. 输入 herdr 开始使用（或 tmux）"
Write-Host "  3. 输入 nvim 打开编辑器，y 打开 yazi 文件管理器"
Write-Host "  4. 编辑 ~/.shell_env 填入 API Key；代理端口不同的话在 ~/.shell_env 里设 PROXY_HTTP_PORT"
Write-Host ""
Write-Host "  WSL 里访问 Windows 上的代理：WSL 2 需开启镜像网络（%USERPROFILE%\.wslconfig 加 [wsl2] networkingMode=mirrored）"
Write-Host "  macOS 专属功能（输入法记忆 / 不休眠 / 翻译插件）在 Windows 上没有"
Write-Host ""
Read-Host "按回车退出"

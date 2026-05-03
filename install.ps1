# ============================================================
# Dotsfile_ALL Windows 安装脚本
#
# 用法（以管理员身份运行 PowerShell）：
#   .\install.ps1
#
# 功能：
#   1. 自动检测并安装 WSL2 + Ubuntu
#   2. 在 WSL 内 clone 并运行 install.sh 完成全部配置
#   3. 提示安装 Windows Terminal（可选）
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
# 3) Windows Terminal 提示
# ============================================================
Write-Host ""
Write-Info "============================================"
Write-Info "  安装完成！"
Write-Info "============================================"
Write-Host ""
Write-Info "后续操作："
Write-Host "  1. 打开 Windows Terminal (推荐) 或 PowerShell"
Write-Host "  2. 输入 wsl 进入 Ubuntu 环境"
Write-Host "  3. 输入 tmux 开始使用"
Write-Host "  4. 输入 nvim 打开编辑器"
Write-Host ""

# 检查 Windows Terminal
$wtInstalled = Get-AppxPackage -Name "Microsoft.WindowsTerminal" -ErrorAction SilentlyContinue
if (-not $wtInstalled) {
    Write-Warn "建议安装 Windows Terminal 以获得更好的终端体验"
    Write-Host "  安装方式: 打开 Microsoft Store 搜索 'Windows Terminal'"
    Write-Host "  或运行: winget install Microsoft.WindowsTerminal"
}

Write-Host ""
Read-Host "按回车退出"

# ============================================================
# PowerShell 配置（原生 Windows，不用 WSL）
# 作用和 macOS/Linux 的 shell/.shell_tools 一样：命令行工具 + 代理检测 + 提示符
# install.ps1 会在 $PROFILE 里加一行 . "<仓库>\powershell\profile.ps1" 来加载它
#
# 速查：
#   y            打开 yazi 文件管理器（带预览），退出后 PowerShell 进入最后所在目录
#   z 目录片段    智能跳转到去过的目录；zi = 交互式选
#   Ctrl+r       模糊搜索历史命令（fzf）
#   Ctrl+t       模糊搜索文件，把路径插入命令行
#   ls / ll / la / lt   eza：带图标、颜色、git 状态；lt = 树形
#   cat 文件      bat：带语法高亮
#   md 文件.md    在终端里渲染 Markdown（glow）
#   img 图片      在 WezTerm 里直接显示图片
#   top          btop 系统监控
#   starship_style hacker|minimal|pure|brackets|powerline   换提示符样式
#   proxy_status / proxy_on / proxy_off                     代理
# ============================================================

$env:EDITOR = "nvim"
$env:VISUAL = "nvim"

# ---------- 代理：本机代理端口开着就自动设置 ----------
# 端口按自己的代理软件改：在「用户环境变量」里设 PROXY_HTTP_PORT，或者改下面的默认值
$script:ProxyHost = if ($env:PROXY_HOST) { $env:PROXY_HOST } else { "127.0.0.1" }
$script:ProxyPort = if ($env:PROXY_HTTP_PORT) { [int]$env:PROXY_HTTP_PORT } else { 33210 }

function Test-ProxyPort {
    $client = New-Object System.Net.Sockets.TcpClient
    try {
        $task = $client.ConnectAsync($script:ProxyHost, $script:ProxyPort)
        return $task.Wait(200) -and $client.Connected
    } catch { return $false } finally { $client.Dispose() }
}

function Set-ProxyEnv {
    $p = "http://$($script:ProxyHost):$($script:ProxyPort)"
    $env:HTTP_PROXY = $p; $env:HTTPS_PROXY = $p; $env:ALL_PROXY = $p
    $env:http_proxy = $p; $env:https_proxy = $p; $env:all_proxy = $p
    $env:NO_PROXY = "localhost,127.0.0.1,::1,.local"; $env:no_proxy = $env:NO_PROXY
}
function proxy_on { Set-ProxyEnv; proxy_status }
function proxy_off {
    foreach ($v in "HTTP_PROXY","HTTPS_PROXY","ALL_PROXY","NO_PROXY","http_proxy","https_proxy","all_proxy","no_proxy") {
        Remove-Item "Env:$v" -ErrorAction SilentlyContinue
    }
    Write-Host "代理已关闭"
}
function proxy_status {
    if ($env:HTTPS_PROXY) {
        Write-Host "代理：$env:HTTPS_PROXY"
        $code = & curl.exe -s -o NUL -m 5 -w "%{http_code}" https://www.google.com
        Write-Host "访问 google：HTTP $code"
    } else { Write-Host "代理：未设置" }
}
if (-not $env:HTTPS_PROXY -and (Test-ProxyPort)) { Set-ProxyEnv }

# ---------- 历史 / 补全（PSReadLine）----------
if (Get-Module -ListAvailable PSReadLine) {
    Set-PSReadLineOption -EditMode Windows -HistoryNoDuplicates -MaximumHistoryCount 50000
    try { Set-PSReadLineOption -PredictionSource History -PredictionViewStyle ListView } catch { Write-Verbose "旧版 PSReadLine 不支持列表预测" }
    Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
}

# ---------- eza：好看的 ls ----------
if (Get-Command eza -ErrorAction SilentlyContinue) {
    Remove-Item Alias:ls -Force -ErrorAction SilentlyContinue
    function ls { eza --icons=auto --group-directories-first @args }
    function ll { eza -l --icons=auto --group-directories-first --git --time-style=relative @args }
    function la { eza -la --icons=auto --group-directories-first --git --time-style=relative @args }
    function lt { eza --tree --level=2 --icons=auto --git-ignore @args }
}

# ---------- bat：高亮 cat ----------
if (Get-Command bat -ErrorAction SilentlyContinue) {
    $env:BAT_THEME = "Catppuccin Mocha"
    Remove-Item Alias:cat -Force -ErrorAction SilentlyContinue
    function cat { bat --paging=never --style=plain @args }
}

# ---------- 小工具 ----------
Remove-Item Alias:md -Force -ErrorAction SilentlyContinue   # 自带的 md 是 mkdir 的别名
function md { glow @args }
function top { btop @args }
function img {
    param([Parameter(Mandatory)] [string] $Path)
    if ($env:TERM_PROGRAM -eq "WezTerm") { wezterm imgcat $Path } else { Invoke-Item $Path }
}

# ---------- yazi：y 打开，退出后进入最后所在目录 ----------
# yazi 在 Windows 上需要 Git 自带的 file.exe 来识别文件类型
if (-not $env:YAZI_FILE_ONE) {
    $gitFile = Join-Path $HOME "scoop\apps\git\current\usr\bin\file.exe"
    if (Test-Path $gitFile) { $env:YAZI_FILE_ONE = $gitFile }
}
function y {
    $tmp = (New-TemporaryFile).FullName
    yazi $args --cwd-file="$tmp"
    $cwd = Get-Content -Path $tmp -Encoding UTF8
    if (-not [String]::IsNullOrEmpty($cwd) -and $cwd -ne $PWD.Path) {
        Set-Location -LiteralPath (Resolve-Path -LiteralPath $cwd).Path
    }
    Remove-Item -Path $tmp
}

# ---------- fzf：Ctrl+r 历史 / Ctrl+t 文件（PSFzf 模块）----------
if ((Get-Command fzf -ErrorAction SilentlyContinue) -and (Get-Module -ListAvailable PSFzf)) {
    $env:FZF_DEFAULT_COMMAND = "fd --type f --hidden --follow --exclude .git"
    $env:FZF_DEFAULT_OPTS = "--height 60% --layout=reverse --border=rounded " +
        "--color=bg+:#313244,spinner:#f5e0dc,hl:#f38ba8,fg:#cdd6f4,header:#f38ba8 " +
        "--color=info:#cba6f7,pointer:#f5e0dc,marker:#b4befe,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8"
    Import-Module PSFzf
    Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'
}

# ---------- zoxide：z 智能跳转 ----------
if (Get-Command zoxide -ErrorAction SilentlyContinue) {
    Invoke-Expression (& { (zoxide init powershell | Out-String) })
}

# ---------- starship：提示符 ----------
$script:StarshipDir = Join-Path $HOME ".config\starship"
function starship_style {
    param([string] $Name)
    $styles = Get-ChildItem $script:StarshipDir -Filter *.toml | ForEach-Object BaseName
    if (-not $Name) {
        Write-Host "当前：$([IO.Path]::GetFileNameWithoutExtension($env:STARSHIP_CONFIG))    可选：$($styles -join ' ')"
        return
    }
    if ($styles -notcontains $Name) { Write-Host "没有这个样式：$Name"; return }
    Set-Content -Path (Join-Path $script:StarshipDir "current") -Value $Name
    $env:STARSHIP_CONFIG = Join-Path $script:StarshipDir "$Name.toml"
    Write-Host "已切换到 $Name"
}
if (Get-Command starship -ErrorAction SilentlyContinue) {
    $currentFile = Join-Path $script:StarshipDir "current"
    $style = if (Test-Path $currentFile) { (Get-Content $currentFile -TotalCount 1).Trim() } else { "hacker" }
    $env:STARSHIP_CONFIG = Join-Path $script:StarshipDir "$style.toml"
    Invoke-Expression (&starship init powershell)
}

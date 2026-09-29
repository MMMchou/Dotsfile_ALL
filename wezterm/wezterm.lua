-- ============================================================
-- WezTerm 配置（Windows 用；install.ps1 / install-wsl.ps1 会复制到 %USERPROFILE%\.wezterm.lua）
-- 作用和 macOS 上的 Ghostty 一样：外观对齐、终端里显示图片（yazi 预览、img 命令）
-- 默认打开 PowerShell 7（原生 Windows 版）；
-- WSL 版在 %USERPROFILE%\.wezterm.local.lua 里改成默认进入 WSL 的 Ubuntu（install-wsl.ps1 自动生成）
-- 文档：https://wezfurlong.org/wezterm/config/files.html
-- 改完保存自动生效
-- ============================================================
local wezterm = require("wezterm")
local config = wezterm.config_builder()

-- 默认打开 PowerShell 7（install.ps1 会用 scoop 装好 pwsh）
if wezterm.target_triple:find("windows") then
  config.default_prog = { "pwsh", "-NoLogo" }
end

-- 外观：和 Ghostty / nvim / herdr 一致
config.color_scheme = "Catppuccin Mocha"
config.font = wezterm.font("Hack Nerd Font Mono")
config.font_size = 12
config.window_background_opacity = 0.95
config.window_padding = { left = 8, right = 8, top = 8, bottom = 8 }
config.hide_tab_bar_if_only_one_tab = true
config.initial_cols = 120
config.initial_rows = 36

-- 终端图片：yazi 预览 / wezterm imgcat 用 WezTerm 自己的 iTerm2 图片协议（默认开）
-- Kitty 图片协议 WezTerm 只支持一部分，开着给 WSL 里的程序用
config.enable_kitty_graphics = true

-- 选中即复制，和 Ghostty 一样
config.mouse_bindings = {
  {
    event = { Up = { streak = 1, button = "Left" } },
    mods = "NONE",
    action = wezterm.action.CompleteSelectionOrOpenLinkAtMouseCursor("ClipboardAndPrimarySelection"),
  },
}

-- 不让 WezTerm 占用 Ctrl+h/j/k/l 等键（交给 herdr / nvim）
config.disable_default_key_bindings = false

-- 每台机器自己的覆盖设置（不进仓库），例如 WSL 版：
--   return function(config) config.default_domain = "WSL:Ubuntu" end
local ok, local_override = pcall(dofile, wezterm.home_dir .. "/.wezterm.local.lua")
if ok and type(local_override) == "function" then
  local_override(config)
end

return config

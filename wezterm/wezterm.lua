-- ============================================================
-- WezTerm 配置（Windows 用；install.ps1 会复制到 %USERPROFILE%\.wezterm.lua）
-- 作用和 macOS 上的 Ghostty 一样：外观对齐、支持终端图片（nvim / yazi 图片预览）
-- 打开后直接进入 WSL 的 Ubuntu（herdr / nvim / yazi 都在 WSL 里）
-- 文档：https://wezfurlong.org/wezterm/config/files.html
-- 改完保存自动生效
-- ============================================================
local wezterm = require("wezterm")
local config = wezterm.config_builder()

-- 默认打开 WSL 的 Ubuntu（名字和 `wsl -l` 里显示的一致）
config.default_domain = "WSL:Ubuntu"

-- 外观：和 Ghostty / nvim / herdr 一致
config.color_scheme = "Catppuccin Mocha"
config.font = wezterm.font("Hack Nerd Font Mono")
config.font_size = 12
config.window_background_opacity = 0.95
config.window_padding = { left = 8, right = 8, top = 8, bottom = 8 }
config.hide_tab_bar_if_only_one_tab = true
config.initial_cols = 120
config.initial_rows = 36

-- 终端图片（Kitty 图片协议）：nvim 的 snacks.image、yazi 预览靠它
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

return config

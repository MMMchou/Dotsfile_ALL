local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  spec = {
    -- LazyVim 核心插件（必须保留）
    { "LazyVim/LazyVim", import = "lazyvim.plugins" },

    -- ===================== LazyVim Extras（官方语言/功能模块） =====================
    -- 每一行启用一个模块，会自动安装该语言需要的 LSP、格式化、调试器等全套工具
    -- 完整列表：https://www.lazyvim.org/extras
    -- 也可以在 nvim 里输入 :LazyExtras 用界面勾选

    -- ========== 语言支持 ==========
    { import = "lazyvim.plugins.extras.lang.python" },     -- Python 全家桶：pyright（补全）+ ruff（格式化）+ debugpy（调试）+ venv 选择器
    { import = "lazyvim.plugins.extras.lang.json" },       -- JSON：schema 验证（编辑配置文件很有用）
    { import = "lazyvim.plugins.extras.lang.markdown" },   -- Markdown：增强语法高亮
    { import = "lazyvim.plugins.extras.lang.docker" },     -- Docker：Dockerfile / compose 语法 + LSP
    { import = "lazyvim.plugins.extras.lang.yaml" },       -- YAML：k8s / GitHub Actions 等配置文件
    { import = "lazyvim.plugins.extras.lang.toml" },       -- TOML：你的 aerospace.toml / alacritty.toml
    { import = "lazyvim.plugins.extras.lang.git" },        -- Git：增强 git commit / rebase 编辑体验
    { import = "lazyvim.plugins.extras.lang.sql" },        -- SQL：写数据库查询时有补全和高亮

    -- ========== AI 辅助编程（写代码的 AI 助手） ==========
    { import = "lazyvim.plugins.extras.ai.copilot" },      -- GitHub Copilot：实时 AI 代码补全（需要 Copilot 订阅）
    { import = "lazyvim.plugins.extras.ai.copilot-chat" }, -- Copilot Chat：在 nvim 里跟 AI 对话问问题

    -- ========== 编辑器增强 ==========
    { import = "lazyvim.plugins.extras.editor.dial" },     -- 增强 Control+a/x：数字、布尔值、日期等快速递增递减
    { import = "lazyvim.plugins.extras.editor.mini-move" },-- 用 Option+hjkl 移动选中的行/块（在 nvim 内部，不冲突）

    -- ========== 调试 ==========
    { import = "lazyvim.plugins.extras.dap.core" },        -- 调试器核心：断点、单步、变量查看（配合 Python debugpy）

    -- ========== 格式化 ==========
    { import = "lazyvim.plugins.extras.formatting.prettier" }, -- Prettier：自动格式化 JSON/MD/YAML 等

    -- 你自己的插件（lua/plugins/ 文件夹里的所有文件）
    { import = "plugins" },
  },
  defaults = {
    -- By default, only LazyVim plugins will be lazy-loaded. Your custom plugins will load during startup.
    -- If you know what you're doing, you can set this to `true` to have all your custom plugins lazy-loaded by default.
    lazy = false,
    -- It's recommended to leave version=false for now, since a lot the plugin that support versioning,
    -- have outdated releases, which may break your Neovim install.
    version = false, -- always use the latest git commit
    -- version = "*", -- try installing the latest stable version for plugins that support semver
  },
  install = { colorscheme = { "tokyonight", "habamax" } },
  checker = {
    enabled = true, -- check for plugin updates periodically
    notify = false, -- notify on update
  }, -- automatically check for plugin updates
  performance = {
    rtp = {
      -- disable some rtp plugins
      disabled_plugins = {
        "gzip",
        -- "matchit",
        -- "matchparen",
        -- "netrwPlugin",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
  },
})

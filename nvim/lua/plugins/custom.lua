-- ============================================================
-- 自定义插件（你自己想加的插件都放这里）
-- 文件位置：~/.config/nvim/lua/plugins/custom.lua
--
-- 格式说明：
--   { "作者/仓库名" }                     ← 最简写法
--   { "作者/仓库名", opts = { ... } }     ← 带配置
--   { "作者/仓库名", enabled = false }    ← 禁用某个插件
--
-- 改完保存后重启 nvim，lazy.nvim 会自动安装新插件。
-- 也可以按 <leader>l 打开 Lazy 面板手动同步。
-- ============================================================

return {

  -- ---- 主题：catppuccin（与 tmux 主题呼应）----
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    opts = {
      flavour = "mocha", -- latte / frappe / macchiato / mocha
    },
  },

  -- 让 LazyVim 使用 catppuccin 作为默认主题
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "catppuccin",
    },
  },

  -- ---- 自动补全括号 ----
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    opts = {},
  },

  -- ---- TODO 高亮（在注释里写 TODO / FIXME / HACK 会自动高亮）----
  {
    "folke/todo-comments.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {},
  },

  -- ============================================================
  -- 以下是"可选"插件示例，取消注释即可启用
  -- ============================================================

  -- ---- 平滑滚动 ----
  -- { "karb94/neoscroll.nvim", opts = {} },

  -- ---- 缩进参考线 ----
  -- { "lukas-reineke/indent-blankline.nvim", main = "ibl", opts = {} },

  -- ---- Markdown 预览（需要 Node.js）----
  -- {
  --   "iamcco/markdown-preview.nvim",
  --   cmd = { "MarkdownPreviewToggle", "MarkdownPreview" },
  --   build = "cd app && npx --yes yarn install",
  --   ft = { "markdown" },
  -- },
}

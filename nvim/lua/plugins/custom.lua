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

  -- ===================== 主题 =====================

  -- Catppuccin 主题（与 tmux 主题呼应）
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    opts = {
      flavour = "mocha", -- latte(亮) / frappe / macchiato / mocha(暗)
    },
  },

  -- 让 LazyVim 使用 catppuccin 作为默认主题
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "catppuccin",
    },
  },

  -- ===================== 编辑增强 =====================

  -- 自动补全括号：输入 ( 自动补 )
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    opts = {},
  },

  -- TODO 高亮：在注释里写 TODO / FIXME / HACK / NOTE 会自动高亮
  -- 按 <leader>st 可以搜索所有 TODO
  {
    "folke/todo-comments.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {},
  },

  -- 快速包围文本：给文字加/删/改引号、括号、标签
  -- 用法：ysaw" 给单词加双引号，ds" 删双引号，cs"' 双引号改单引号
  {
    "kylechui/nvim-surround",
    version = "*",
    event = "VeryLazy",
    opts = {},
  },

  -- 平滑滚动：Control+d / Control+u 翻页时有动画，不会突然跳
  {
    "karb94/neoscroll.nvim",
    event = "VeryLazy",
    opts = {},
  },

  -- 缩进参考线：显示代码层级的竖线，看嵌套结构更清楚
  {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    event = "LazyFile",
    opts = {},
  },

  -- 高亮光标下相同的单词（LazyVim 已内置 vim-illuminate，无需重复配置）

  -- ===================== Git 增强 =====================

  -- Git diff 查看器：按 <leader>gd 打开，左右对比文件变更
  {
    "sindrets/diffview.nvim",
    cmd = { "DiffviewOpen", "DiffviewFileHistory" },
    keys = {
      { "<leader>gd", "<cmd>DiffviewOpen<cr>", desc = "Git Diff 查看" },
      { "<leader>gh", "<cmd>DiffviewFileHistory %<cr>", desc = "当前文件 Git 历史" },
    },
    opts = {},
  },

  -- ===================== 终端 =====================

  -- 浮动终端：按 Control+\ 弹出/隐藏一个浮动终端窗口
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    keys = {
      { "<C-\\>", desc = "打开/关闭浮动终端" },
    },
    opts = {
      open_mapping = [[<C-\>]],
      direction = "float",
      float_opts = { border = "rounded" },
    },
  },

  -- ===================== Jupyter / Python =====================

  -- Jupyter Notebook 支持：在 Neovim 中直接打开 .ipynb 文件
  -- 原理：用 jupytext 把 .ipynb 转成 .py 编辑，保存时自动转回 .ipynb
  -- 前置条件：pip install jupytext
  {
    "GCBallesteros/jupytext.nvim",
    config = true,
  },

  -- ===================== Markdown =====================

  -- Markdown 预览：写 Markdown 时实时在浏览器里看效果
  -- 用法：打开 .md 文件后输入 :MarkdownPreview
  -- 前置条件：需要 Node.js（brew install node）
  {
    "iamcco/markdown-preview.nvim",
    cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
    build = "cd app && npx --yes yarn install",
    ft = { "markdown" },
    init = function()
      vim.g.mkdp_filetypes = { "markdown" }
    end,
  },

  -- ===================== 其他实用工具 =====================

  -- 颜色高亮：CSS/HTML 里的颜色代码直接显示对应颜色
  -- 比如 #ff0000 会有红色背景
  {
    "norcalli/nvim-colorizer.lua",
    event = "LazyFile",
    opts = {},
  },

  -- 快速跳转：按 s 然后输入两个字符，直接跳到目标位置
  -- LazyVim 默认用 flash.nvim，这里确保配置合理
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    opts = {},
    keys = {
      { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash 跳转" },
      { "S", mode = { "n", "x", "o" }, function() require("flash").treesitter() end, desc = "Flash Treesitter 选择" },
    },
  },
}

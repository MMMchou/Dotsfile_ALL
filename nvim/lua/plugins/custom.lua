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

  -- ===================== 文件树 =====================

  -- 禁用 Neo-tree（LazyVim v8 默认用 Snacks Explorer）
  { "nvim-neo-tree/neo-tree.nvim", enabled = false },

  -- Snacks Explorer：显示被 gitignore 忽略的文件（如 external-projects/）
  {
    "folke/snacks.nvim",
    opts = {
      explorer = {
        replace_netrw = true,
      },
      -- 图片预览：直接 nvim a.png 能看图；文件树/搜索里选中图片、PDF 有预览；
      -- Markdown 里的图片会显示出来。
      -- 前置条件：终端要支持 Kitty 图片协议（Ghostty / Kitty，Alacritty 不行），
      --           brew install imagemagick ghostscript（格式转换 / PDF）
      -- 检查是否正常：:checkhealth snacks
      image = {
        enabled = true,
      },
      picker = {
        sources = {
          explorer = {
            ignored = true,
          },
        },
      },
    },
  },

  -- ===================== 外观 =====================

  -- 彩虹括号：嵌套的 ( [ { 按层级显示不同颜色
  {
    "HiPhish/rainbow-delimiters.nvim",
    event = "LazyFile",
    submodules = false,
  },

  -- 诊断信息显示成行尾圆角小气泡（替代默认的一长串虚拟文本）
  {
    "rachartier/tiny-inline-diagnostic.nvim",
    event = "LspAttach",
    priority = 1000,
    opts = {
      preset = "modern", -- 可选：modern / classic / minimal / powerline / ghost / simple / nonerdfont / amongus
      options = {
        multilines = { enabled = true }, -- 多行报错也完整显示
        show_source = { enabled = true }, -- 显示来源（pyright / ruff 等）
      },
    },
  },
  -- 关掉 LazyVim 默认的行尾诊断文字，避免和上面的小气泡重复
  {
    "neovim/nvim-lspconfig",
    opts = { diagnostics = { virtual_text = false } },
  },

  -- 每个窗口右上角浮一个小标签：图标 + 文件名（有改动时加 ●）
  {
    "b0o/incline.nvim",
    event = "VeryLazy",
    config = function()
      local devicons_ok, icons = pcall(require, "mini.icons")
      require("incline").setup({
        window = { padding = 1, margin = { horizontal = 1, vertical = 0 } },
        hide = { cursorline = true }, -- 光标行挡住标签时自动隐藏
        render = function(props)
          local name = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(props.buf), ":t")
          if name == "" then
            name = "[No Name]"
          end
          local icon, hl = "", nil
          if devicons_ok then
            icon, hl = icons.get("file", name)
          end
          local modified = vim.bo[props.buf].modified
          return {
            { icon .. " ", group = hl },
            { name, gui = modified and "bold,italic" or "bold" },
            modified and { " ●", group = "DiagnosticWarn" } or "",
          }
        end,
      })
    end,
  },

  -- 启动页标题改成 ASHAN ^_^
  {
    "folke/snacks.nvim",
    opts = {
      dashboard = {
        width = 70, -- 默认 60，标题 68 列宽，放不下会错行
        -- 标题每行长短不一，而启动页是逐行居中的，所以在这里用代码补齐到同一宽度。
        -- （不能靠行尾空格补齐：保存时的“自动去行尾空格”会把它删掉，导致错位）
        preset = {
          header = (function()
            local lines = {
            " █████╗ ███████╗██╗  ██╗ █████╗ ███╗   ██╗     ██╗             ██╗",
            "██╔══██╗██╔════╝██║  ██║██╔══██╗████╗  ██║    ████╗           ████╗",
            "███████║███████╗███████║███████║██╔██╗ ██║   ██╔═██╗         ██╔═██╗",
            "██╔══██║╚════██║██╔══██║██╔══██║██║╚██╗██║   ╚═╝ ╚═╝         ╚═╝ ╚═╝",
            "██║  ██║███████║██║  ██║██║  ██║██║ ╚████║          ████████╗",
            "╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝          ╚═══════╝",
            }
            local w = 0
            for _, l in ipairs(lines) do
              w = math.max(w, vim.fn.strdisplaywidth(l))
            end
            for i, l in ipairs(lines) do
              lines[i] = l .. string.rep(" ", w - vim.fn.strdisplaywidth(l))
            end
            return table.concat(lines, "\n")
          end)(),
        },
      },
    },
  },

  -- ===================== 学 vim / 趣味 =====================

  -- precognition：在屏幕上提示 w/b/e/$/^ 等按键会跳到哪里（学 vim 时很有用）
  -- <leader>uP 开关；熟练后可以把 startVisible 改成 false
  {
    "tris203/precognition.nvim",
    event = "VeryLazy",
    opts = { startVisible = true, showBlankVirtLine = false },
    keys = {
      {
        "<leader>uP",
        function()
          require("precognition").toggle()
        end,
        desc = "开关 precognition 按键提示",
      },
    },
  },


  -- ===================== 文件管理 / 预览 =====================

  -- herdr-splits：Ctrl+h/j/k/l 在 nvim 分屏和 herdr pane 之间无缝移动
  -- 在 nvim 分屏之间移动；到了最边上再按，就跳到隔壁的 herdr pane。
  -- herdr 那边的配套插件和快捷键在 ~/.config/herdr/config.toml（插件快捷键部分）
  -- 只在 herdr 里生效（HERDR_ENV=1），单独开的 nvim 还是 LazyVim 默认的窗口切换。
  -- 调整大小的 Option+h/j/k/l 没开：mini.move 在用 Option+h/j/k/l 移动行。
  {
    "lmilojevicc/herdr-splits.nvim",
    cond = vim.env.HERDR_ENV == "1",
    event = "VeryLazy",
    opts = {
      at_edge = "stop", -- nvim 内部到边上不绕回（交给 herdr 跳 pane）
      nav_at_edge = "stop", -- herdr 最外侧 pane 再按也不绕回另一头
    },
    keys = {
      { "<C-h>", function() require("herdr-splits").move_cursor_left() end, desc = "左边的窗口 / herdr pane" },
      { "<C-j>", function() require("herdr-splits").move_cursor_down() end, desc = "下边的窗口 / herdr pane" },
      { "<C-k>", function() require("herdr-splits").move_cursor_up() end, desc = "上边的窗口 / herdr pane" },
      { "<C-l>", function() require("herdr-splits").move_cursor_right() end, desc = "右边的窗口 / herdr pane" },
    },
  },

  -- Yazi 文件管理器（浮窗）：图片 / PDF / 视频 / 压缩包都能在右侧预览
  --   <leader>fy  在当前文件所在目录打开 yazi
  --   <leader>fY  在项目根目录（cwd）打开 yazi
  --   yazi 里按 Enter/l 打开文件到 nvim；Ctrl+v 竖分屏打开；q 退出
  {
    "mikavilpas/yazi.nvim",
    version = "*",
    event = "VeryLazy",
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
      { "<leader>fy", "<cmd>Yazi<cr>", desc = "Yazi（当前文件目录）" },
      { "<leader>fY", "<cmd>Yazi cwd<cr>", desc = "Yazi（项目根目录）" },
    },
    opts = {
      open_for_directories = false, -- 目录仍然交给 Snacks Explorer
      floating_window_scaling_factor = 0.9,
      yazi_floating_window_border = "rounded",
    },
  },

  -- 图片文档渲染需要的 treesitter 语法（CSS 颜色、LaTeX 公式、Typst 等）
  {
    "nvim-treesitter/nvim-treesitter",
    opts = { ensure_installed = { "css", "scss", "latex", "typst", "vue", "svelte" } },
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

  -- 平滑滚动 / 缩进竖线：LazyVim 自带的 snacks.scroll 和 snacks.indent 已经提供，
  -- 以前另装的 neoscroll 和 indent-blankline 会重复（两套竖线、滚动打架），已移除。
  -- 开关：<leader>ug 缩进线；滚动动画 <leader>uS

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
      {
        "s",
        mode = { "n", "x", "o" },
        function()
          require("flash").jump()
        end,
        desc = "Flash 跳转",
      },
      {
        "S",
        mode = { "n", "x", "o" },
        function()
          require("flash").treesitter()
        end,
        desc = "Flash Treesitter 选择",
      },
    },
  },
}

-- ============================================================
-- Neovim 选项设置（LazyVim 新手友好版）
-- 文件位置：~/.config/nvim/lua/config/options.lua
--
-- LazyVim 默认选项参考：
-- https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
--
-- 这个文件里的设置会 **覆盖/补充** LazyVim 的默认值。
-- 你可以在这里加自己喜欢的选项。
-- ============================================================

local opt = vim.opt

-- ---- 外观 ----
opt.number = true         -- 显示行号
opt.relativenumber = true -- 相对行号（方便 5j / 10k 跳行）
opt.cursorline = true     -- 高亮当前行
opt.termguicolors = true  -- 启用真彩色（配合 tmux 的 RGB 设置）
opt.signcolumn = "yes"    -- 始终显示左侧标记列（Git/诊断信息不会抖动）
opt.wrap = false          -- 不自动折行（长行横向滚动）
opt.scrolloff = 8         -- 光标距顶/底保留 8 行（滚动时不至于看不到上下文）
opt.sidescrolloff = 8     -- 水平滚动同理

-- ---- 缩进 ----
opt.tabstop = 4           -- Tab 显示宽度 = 4 空格
opt.shiftwidth = 4        -- 自动缩进宽度 = 4 空格
opt.expandtab = true      -- 按 Tab 时插入空格，而非制表符
opt.smartindent = true    -- 智能缩进（写代码时自动调整层级）

-- ---- 搜索 ----
opt.ignorecase = true     -- 搜索时忽略大小写
opt.smartcase = true      -- 如果搜索词含大写，则变为精确匹配
opt.hlsearch = true       -- 高亮搜索结果
opt.incsearch = true      -- 输入时实时显示匹配

-- ---- 文件 ----
opt.autowrite = true      -- 切换 buffer 时自动保存
opt.undofile = true       -- 持久化 undo 历史（关闭后再开还能撤销）
opt.swapfile = false      -- 不生成 .swp 文件（减少烦人提示）
opt.backup = false        -- 不生成备份文件

-- ---- 分屏 ----
opt.splitbelow = true     -- 水平分屏：新窗口在下方
opt.splitright = true     -- 垂直分屏：新窗口在右方

-- ---- 剪贴板 ----
opt.clipboard = "unnamedplus" -- 与系统剪贴板互通（复制/粘贴都走系统）

-- ---- 其他 ----
opt.mouse = "a"           -- 所有模式都可以用鼠标
opt.updatetime = 250      -- 加快 CursorHold 事件触发（让 Git 标记等更灵敏）
opt.timeoutlen = 300      -- 快捷键组合等待时间（毫秒），300 比默认 1000 更跟手
opt.completeopt = "menu,menuone,noselect" -- 补全菜单行为

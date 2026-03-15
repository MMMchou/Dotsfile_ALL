-- ============================================================
-- 自定义快捷键（LazyVim 新手友好版）
-- 文件位置：~/.config/nvim/lua/config/keymaps.lua
--
-- LazyVim 默认快捷键参考：
-- https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- 在线速查：https://www.lazyvim.org/keymaps
--
-- 说明：
-- <leader> 键默认是 空格（Space）
-- <C-x>    表示 Control + x（键盘左下角 ⌃ 键，不是 Command）
-- <S-x>    表示 Shift + x
--
-- 按键分工（避免冲突）：
-- Option (⌥)  → AeroSpace 窗口管理（系统层，不要在这里绑）
-- Control (⌃) → tmux 面板切换 / Neovim 操作
-- Space        → LazyVim leader 键
-- ============================================================

local map = vim.keymap.set

-- ---- 保存 / 退出 ----
map("n", "<C-s>", "<cmd>w<cr>", { desc = "保存文件" })
map("n", "<C-q>", "<cmd>qa<cr>", { desc = "退出全部" })

-- ---- 移动行（Control+Shift+j/k 上下挪整行）----
-- 不用 Option+j/k，因为 AeroSpace 会拦截 Option 键
map("n", "<C-S-j>", "<cmd>m .+1<cr>==", { desc = "当前行下移" })
map("n", "<C-S-k>", "<cmd>m .-2<cr>==", { desc = "当前行上移" })
map("v", "<C-S-j>", ":m '>+1<cr>gv=gv", { desc = "选中行下移" })
map("v", "<C-S-k>", ":m '<-2<cr>gv=gv", { desc = "选中行上移" })

-- ---- 调整分屏大小 ----
map("n", "<C-Up>", "<cmd>resize +2<cr>", { desc = "窗口高度+2" })
map("n", "<C-Down>", "<cmd>resize -2<cr>", { desc = "窗口高度-2" })
map("n", "<C-Left>", "<cmd>vertical resize -2<cr>", { desc = "窗口宽度-2" })
map("n", "<C-Right>", "<cmd>vertical resize +2<cr>", { desc = "窗口宽度+2" })

-- ---- Buffer 切换（类似浏览器 Tab 切换）----
map("n", "<S-h>", "<cmd>bprevious<cr>", { desc = "上一个 Buffer" })
map("n", "<S-l>", "<cmd>bnext<cr>", { desc = "下一个 Buffer" })

-- ---- 取消搜索高亮 ----
map("n", "<Esc>", "<cmd>nohlsearch<cr>", { desc = "取消搜索高亮" })

-- ---- 快速缩进（选中后可以反复按 < > 不丢选区）----
map("v", "<", "<gv", { desc = "向左缩进并保持选中" })
map("v", ">", ">gv", { desc = "向右缩进并保持选中" })

-- ---- 粘贴时不覆盖寄存器（选中文本再粘贴不会丢剪贴板内容）----
map("v", "p", '"_dP', { desc = "粘贴但不覆盖寄存器" })

-- ============================================================
-- LazyVim 内置常用快捷键速查（不需要你配置，直接能用）
-- ============================================================
-- <leader>e       打开/关闭文件树（neo-tree）
-- <leader>ff      查找文件（Telescope）
-- <leader>fg      全局搜索文本（Telescope grep）
-- <leader>fb      搜索已打开的 Buffer
-- <leader>fr      最近打开的文件
-- <leader>s       搜索相关（symbols / references 等）
-- <leader>c       代码相关（code actions / format 等）
-- <leader>x       诊断列表（Trouble）
-- <leader>gg      打开 lazygit（终端 Git 管理）
-- <leader>l       Lazy 插件管理器面板
-- K               悬浮查看文档（hover）
-- gd              跳转到定义
-- gr              查看引用
-- ]d / [d         下一个/上一个诊断
-- gcc             注释/取消注释当前行
-- gc              注释/取消注释选中区域

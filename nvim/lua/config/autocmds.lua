-- ============================================================
-- 自动命令（LazyVim 新手友好版）
-- 文件位置：~/.config/nvim/lua/config/autocmds.lua
--
-- "自动命令"就是"当某个事件发生时，自动执行一段操作"。
-- LazyVim 默认参考：
-- https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- ============================================================

local autocmd = vim.api.nvim_create_autocmd

-- 打开文件时自动跳到上次编辑的位置
autocmd("BufReadPost", {
  callback = function()
    local mark = vim.api.nvim_buf_get_mark(0, '"')
    local lcount = vim.api.nvim_buf_line_count(0)
    if mark[1] > 0 and mark[1] <= lcount then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- 保存文件时自动去掉行尾空格
autocmd("BufWritePre", {
  pattern = "*",
  callback = function()
    local save_cursor = vim.fn.getpos(".")
    vim.cmd([[%s/\s\+$//e]])
    vim.fn.setpos(".", save_cursor)
  end,
})

-- 高亮复制的文本（复制后短暂闪烁，方便确认选中了什么）
autocmd("TextYankPost", {
  callback = function()
    vim.highlight.on_yank({ higroup = "IncSearch", timeout = 200 })
  end,
})

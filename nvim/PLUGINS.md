# Neovim 插件与功能完整说明

> 配置基于 **LazyVim**（Neovim 的预配置框架），插件由 **lazy.nvim** 管理。
> 配置文件位置：`~/.config/nvim/`
>
> **Mac 按键提醒**：Control = 键盘左下角 ⌃ ，Option = Command 旁边 ⌥ ，空格 = leader 键

---

## 目录

1. [配置文件结构](#1-配置文件结构)
2. [LazyVim Extras 官方模块](#2-lazyvim-extras-官方模块)
3. [自定义插件](#3-自定义插件)
4. [Python 开发完整指南](#4-python-开发完整指南)
5. [AI 辅助编程（Copilot）](#5-ai-辅助编程copilot)
6. [调试器（DAP）使用指南](#6-调试器dap使用指南)
7. [全部快捷键速查表](#7-全部快捷键速查表)
8. [插件管理操作](#8-插件管理操作)
9. [常见问题](#9-常见问题)

---

## 1. 配置文件结构

```
~/.config/nvim/
├── init.lua                      ← 入口文件
├── lua/
│   ├── config/
│   │   ├── lazy.lua              ← 插件加载器配置（Extras 模块在这里启用）
│   │   ├── options.lua           ← 编辑器选项（行号、缩进、搜索等）
│   │   ├── keymaps.lua           ← 自定义快捷键
│   │   └── autocmds.lua          ← 自动命令（保存时去空格等）
│   └── plugins/
│       └── custom.lua            ← 你手动安装的插件都在这里
└── lazy-lock.json                ← 插件版本锁定（自动生成）
```

**修改规则**：
- 想加/删插件 → 编辑 `lua/plugins/custom.lua`
- 想启用新的语言模块 → 编辑 `lua/config/lazy.lua` 的 `spec` 部分
- 想改快捷键 → 编辑 `lua/config/keymaps.lua`
- 想改编辑器行为 → 编辑 `lua/config/options.lua`

---

## 2. LazyVim Extras 官方模块

> 配置位置：`lua/config/lazy.lua` 的 `spec` 部分
> 官方完整列表：https://www.lazyvim.org/extras
> 也可以在 nvim 中输入 `:LazyExtras` 用界面勾选/取消

### 2.1 语言支持

| 模块 | 作用 | 自动安装了什么 |
|------|------|--------------|
| `lang.python` | Python 全家桶 | **pyright**（智能补全/类型检查）+ **ruff**（格式化/lint）+ **debugpy**（断点调试）+ **venv-selector**（虚拟环境切换） |
| `lang.json` | JSON 支持 | 语法高亮 + JSON Schema 验证（编辑 package.json 等会自动校验格式） |
| `lang.markdown` | Markdown 增强 | 增强语法高亮 + 折叠 |
| `lang.docker` | Docker 支持 | Dockerfile / docker-compose 语法高亮 + LSP 补全 |
| `lang.yaml` | YAML 支持 | 语法高亮 + Schema 验证（k8s / GitHub Actions 配置文件） |
| `lang.toml` | TOML 支持 | 语法高亮（编辑 aerospace.toml / alacritty.toml / pyproject.toml） |
| `lang.git` | Git 编辑增强 | 编辑 git commit / rebase 时的语法高亮和补全 |
| `lang.sql` | SQL 支持 | SQL 语法高亮 + 补全（写数据库查询时好用） |

### 2.2 AI 辅助编程

| 模块 | 作用 | 说明 |
|------|------|------|
| `ai.copilot` | GitHub Copilot 代码补全 | 写代码时实时显示灰色的 AI 建议，按 Tab 接受。需要 GitHub Copilot 订阅（$10/月，学生免费） |
| `ai.copilot-chat` | Copilot 对话 | 在 nvim 侧边栏里跟 AI 对话，可以选中代码让它解释/优化/重构 |

### 2.3 编辑器增强

| 模块 | 作用 | 说明 |
|------|------|------|
| `editor.dial` | 增强递增递减 | Control+a/x 不仅能递增数字，还能切换 `true↔false`、`yes↔no`、日期等 |
| `editor.mini-move` | 移动行/块 | 在 nvim 内部用快捷键移动选中的代码块 |

### 2.4 调试

| 模块 | 作用 | 说明 |
|------|------|------|
| `dap.core` | 调试器核心 | 提供断点、单步执行、变量查看等调试功能。配合 `lang.python` 的 debugpy 实现 Python 断点调试 |

### 2.5 格式化

| 模块 | 作用 | 说明 |
|------|------|------|
| `formatting.prettier` | Prettier 格式化 | 自动格式化 JSON / Markdown / YAML / HTML / CSS 等文件 |

---

## 3. 自定义插件

> 配置位置：`lua/plugins/custom.lua`

### 3.1 主题

| 插件 | 作用 | 说明 |
|------|------|------|
| **catppuccin/nvim** | Catppuccin 主题 | 当前使用 mocha（深色）风格，与 tmux 主题统一。可选：`latte`（浅色）/ `frappe` / `macchiato` / `mocha`（深色） |

### 3.2 编辑增强

| 插件 | 作用 | 怎么用 |
|------|------|--------|
| **nvim-autopairs** | 自动补全括号 | 输入 `(` 自动补 `)`，输入 `{` 自动补 `}`，输入 `"` 自动补 `"` |
| **todo-comments.nvim** | TODO 高亮 | 在注释里写 `TODO:` / `FIXME:` / `HACK:` / `NOTE:` 会自动变彩色高亮。`空格+st` 搜索所有 TODO |
| **nvim-surround** | 快速包围文本 | 见下方详细用法 |
| **neoscroll.nvim** | 平滑滚动 | Control+d / Control+u 翻页时有平滑动画，不再突然跳 |
| **indent-blankline.nvim** | 缩进参考线 | 自动在代码左侧显示竖线，看清楚 if / for / def 的嵌套层级 |
| **vim-illuminate** | 相同单词高亮 | 光标停在一个变量上，文件里所有同名变量都会高亮 |
| **flash.nvim** | 快速跳转 | 按 `s` + 两个字符，直接跳到屏幕上任意位置 |

**nvim-surround 详细用法**：

```
添加包围：
  ysiw"       给光标所在的单词加双引号     hello → "hello"
  ysiw(       给单词加括号                 hello → (hello)
  yss"        给整行加双引号

删除包围：
  ds"         删掉双引号                   "hello" → hello
  ds(         删掉括号                     (hello) → hello

修改包围：
  cs"'        双引号改成单引号             "hello" → 'hello'
  cs"(        双引号改成括号               "hello" → (hello)
```

### 3.3 Git 增强

| 插件 | 作用 | 快捷键 |
|------|------|--------|
| **diffview.nvim** | Git diff 可视化 | `空格+gd` 打开 diff 对比视图，`空格+gh` 查看当前文件 git 历史 |

### 3.4 终端

| 插件 | 作用 | 快捷键 |
|------|------|--------|
| **toggleterm.nvim** | 浮动终端 | `Control+\` 弹出/隐藏一个浮动终端窗口。不用退出 nvim 就能跑命令 |

### 3.5 Jupyter / Python

| 插件 | 作用 | 说明 |
|------|------|------|
| **jupytext.nvim** | Jupyter Notebook 支持 | `nvim notebook.ipynb` 直接打开 .ipynb 文件。自动用 jupytext 转成 .py 编辑，保存时转回 .ipynb。前置条件：`pip install jupytext` |

### 3.6 Markdown

| 插件 | 作用 | 说明 |
|------|------|------|
| **markdown-preview.nvim** | Markdown 实时预览 | 打开 .md 文件后输入 `:MarkdownPreview`，自动在浏览器里打开实时预览页面。前置条件：`brew install node` |

### 3.7 其他工具

| 插件 | 作用 | 说明 |
|------|------|------|
| **nvim-colorizer.lua** | 颜色代码可视化 | CSS/HTML 里的 `#ff0000` 会显示红色背景，`rgb(0,255,0)` 会显示绿色背景 |

---

## 4. Python 开发完整指南

### 4.1 智能补全（pyright）

打开任何 `.py` 文件，输入代码时自动弹出补全菜单：

```
import torch
torch.nn.    ← 自动弹出 Linear / Conv2d / ReLU 等选项
```

| 操作 | 快捷键 |
|------|--------|
| 确认选中的补全项 | `Tab` |
| 补全列表向下选 | `Control+n` |
| 补全列表向上选 | `Control+p` |
| 查看函数文档（悬浮窗） | `K`（Normal 模式，光标在函数名上） |
| 查看函数签名参数 | `Control+k`（Insert 模式，输入到参数时） |

### 4.2 代码格式化（ruff）

| 操作 | 快捷键 / 方式 |
|------|--------------|
| 保存时自动格式化 | 默认开启，保存即格式化 |
| 手动格式化 | `空格+cf` |
| 自动整理 import 顺序 | `空格+co` |

ruff 会自动帮你：
- 统一缩进和空格
- 删除未使用的 import
- 按规范排序 import（标准库 → 第三方库 → 本地模块）

### 4.3 错误诊断

pyright 会实时检查类型错误，行号旁边出现标记：

| 操作 | 快捷键 |
|------|--------|
| 跳到下一个错误 | `]d` |
| 跳到上一个错误 | `[d` |
| 查看当前行错误详情 | `空格+cd` |
| 打开错误列表面板 | `空格+xx` |

### 4.4 代码导航（跳转）

| 操作 | 快捷键 |
|------|--------|
| 跳到定义 | `gd`（比如跳到 `torch.nn.Linear` 的源码） |
| 跳到类型定义 | `gy` |
| 跳到实现 | `gI` |
| 查看所有引用 | `gr`（谁调用了这个函数） |
| 查看函数文档 | `K` |
| 返回上一个位置 | `Control+o` |
| 前进到下一个位置 | `Control+i` |

**典型场景**：你在 `train.py` 里看到 `model = ResNet50()`，把光标放在 `ResNet50` 上按 `gd`，直接跳到 model 的定义文件。看完了按 `Control+o` 跳回来。

### 4.5 虚拟环境切换

做 AI 项目经常有多个 conda / venv 环境：

| 操作 | 快捷键 |
|------|--------|
| 打开虚拟环境选择器 | `空格+cv` |

选了之后 pyright 会自动识别该环境下安装的包（torch / transformers / numpy 等），补全和类型检查都会正确。

### 4.6 代码搜索

| 操作 | 快捷键 |
|------|--------|
| 搜索文件名 | `空格+ff`（模糊匹配，输入 "train" 找到 train.py） |
| 全局搜索文字 | `空格+fg`（在所有文件里搜索，比如搜 "learning_rate"） |
| 搜索符号（函数名/类名） | `空格+ss` |
| 搜索所有 TODO | `空格+st` |
| 打开文件树 | `空格+e` |

### 4.7 Jupyter Notebook

```bash
# 直接用 nvim 打开 .ipynb 文件
nvim notebook.ipynb
```

jupytext 会自动把 notebook 转成 `.py` 格式编辑（用 `# %%` 标记 cell 边界），保存时自动转回 `.ipynb`。

---

## 5. AI 辅助编程（Copilot）

### 5.1 首次登录

在 nvim 中输入：

```
:Copilot auth
```

会显示一个链接和一次性代码，在浏览器里登录 GitHub 账号授权即可。

### 5.2 实时代码补全

写代码时 Copilot 自动在光标后面显示灰色建议：

| 操作 | 快捷键 |
|------|--------|
| 接受整个建议 | `Tab` |
| 下一个建议 | `Option+]` |
| 上一个建议 | `Option+[` |
| 取消建议 | `Esc` |

### 5.3 Copilot Chat（AI 对话）

| 操作 | 快捷键 |
|------|--------|
| 打开 Chat 侧边栏 | `空格+aa` |
| 选中代码后打开 Chat | 先 Visual 模式选中代码，再 `空格+aa` |

可以问它：
- "解释一下这段代码在做什么"
- "帮我优化这个训练循环的性能"
- "这个 loss 不收敛可能是什么原因"
- "把这个函数改成支持 multi-GPU"
- "给这个函数写单元测试"

### 5.4 费用说明

- GitHub Copilot：$10/月（学生通过 GitHub Education 免费）
- 如果不想付费，可以在 `lazy.lua` 中注释掉 `ai.copilot` 和 `ai.copilot-chat` 两行，不影响其他功能

---

## 6. 调试器（DAP）使用指南

对 AI 算法开发特别有用——调试训练循环、检查 tensor 维度、排查 loss 异常。

### 6.1 基本操作

| 操作 | 快捷键 |
|------|--------|
| 设置/取消断点 | `空格+db` |
| 设置条件断点 | `空格+dB`（比如输入 `epoch == 5`，只在第5轮时停） |
| 开始调试 / 继续运行 | `空格+dc` |
| 单步执行下一行 | `空格+dn` |
| 单步进入函数 | `空格+di` |
| 单步跳出函数 | `空格+do` |
| 终止调试 | `空格+dt` |
| 打开 REPL | `空格+dr`（在断点处交互式查看变量） |
| 查看变量悬浮窗 | 光标放在变量上，按 `K` |

### 6.2 调试 Python 脚本

```
1. nvim train.py
2. 把光标移到你想停的那一行（比如 loss = criterion(output, target)）
3. 空格+db    设置断点（行号旁边出现红点）
4. 空格+dc    开始调试（会弹出选择：选 Python File）
5. 程序运行到断点停住
6. 鼠标悬停在变量上看值，或者用 空格+dr 打开 REPL 交互查看
7. 空格+dn    单步执行下一行
8. 空格+dc    继续运行到下一个断点
9. 空格+dt    结束调试
```

### 6.3 调试时的界面

调试开始后，屏幕左侧会自动弹出面板显示：
- **Scopes**：当前作用域的所有变量和值
- **Breakpoints**：所有断点列表
- **Stacks**：调用栈（当前在哪个函数里，从哪调用过来的）

---

## 7. 全部快捷键速查表

### 7.1 基础操作

| 操作 | 快捷键 | 说明 |
|------|--------|------|
| 保存 | `Control+s` | |
| 退出 | `:q` 或 `Control+q` | |
| 保存并退出 | `:wq` | |
| 不保存强制退出 | `:q!` | |
| 撤销 | `u` | |
| 重做 | `Control+r` | |
| 进入编辑模式 | `i` | |
| 回到 Normal 模式 | `Esc` | |

### 7.2 文件与搜索

| 操作 | 快捷键 |
|------|--------|
| 文件树 | `空格+e` |
| 搜索文件 | `空格+ff` |
| 全局搜索文字 | `空格+fg` |
| 搜索已打开的 Buffer | `空格+fb` |
| 最近打开的文件 | `空格+fr` |
| 搜索符号 | `空格+ss` |
| 搜索 TODO | `空格+st` |

### 7.3 代码导航

| 操作 | 快捷键 |
|------|--------|
| 跳到定义 | `gd` |
| 跳到类型定义 | `gy` |
| 跳到实现 | `gI` |
| 查看引用 | `gr` |
| 查看文档 | `K` |
| 返回上一个位置 | `Control+o` |
| 前进 | `Control+i` |
| 下一个错误 | `]d` |
| 上一个错误 | `[d` |

### 7.4 编辑

| 操作 | 快捷键 |
|------|--------|
| 删除整行 | `dd` |
| 复制整行 | `yy` |
| 粘贴 | `p` |
| 注释/取消注释 | `gcc`（当前行）/ `gc`（选中区域） |
| 移动行上下 | `Control+Shift+j/k` |
| 格式化文件 | `空格+cf` |
| 整理 import | `空格+co` |
| 缩进 | 选中后按 `>` / `<` |
| 快速跳转 | `s` + 两个字符 |

### 7.5 窗口与 Buffer

| 操作 | 快捷键 |
|------|--------|
| 下一个 Buffer | `Shift+l` |
| 上一个 Buffer | `Shift+h` |
| 关闭当前 Buffer | `空格+bd` |
| 窗口高度调整 | `Control+↑/↓` |
| 窗口宽度调整 | `Control+←/→` |

### 7.6 Git

| 操作 | 快捷键 |
|------|--------|
| 打开 lazygit | `空格+gg` |
| Git diff 对比 | `空格+gd` |
| 当前文件 Git 历史 | `空格+gh` |

### 7.7 调试

| 操作 | 快捷键 |
|------|--------|
| 设置断点 | `空格+db` |
| 条件断点 | `空格+dB` |
| 开始/继续 | `空格+dc` |
| 下一步 | `空格+dn` |
| 进入函数 | `空格+di` |
| 跳出函数 | `空格+do` |
| 终止 | `空格+dt` |
| REPL | `空格+dr` |

### 7.8 AI（Copilot）

| 操作 | 快捷键 |
|------|--------|
| 接受建议 | `Tab` |
| 下一个建议 | `Option+]` |
| 上一个建议 | `Option+[` |
| 打开 Chat | `空格+aa` |
| Copilot 登录 | `:Copilot auth` |

### 7.9 其他

| 操作 | 快捷键 |
|------|--------|
| 浮动终端 | `Control+\` |
| Lazy 插件管理 | `空格+l` |
| LazyExtras 模块管理 | `:LazyExtras` |
| Markdown 预览 | `:MarkdownPreview` |
| 错误列表 | `空格+xx` |
| 递增数字/布尔 | `Control+a` |
| 递减数字/布尔 | `Control+x` |

---

## 8. 插件管理操作

### 查看已安装插件

```
空格+l          打开 Lazy 插件管理面板
```

在 Lazy 面板里：
- `S` — 同步所有插件（安装新的 + 更新旧的）
- `U` — 只更新
- `C` — 检查更新
- `X` — 清理已删除的插件
- `q` — 退出面板

### 添加新插件

编辑 `~/.config/nvim/lua/plugins/custom.lua`，在 `return { ... }` 里面加一行：

```lua
{ "作者/仓库名", opts = {} },
```

保存后重启 nvim，自动安装。

### 启用新的语言模块

编辑 `~/.config/nvim/lua/config/lazy.lua`，在 `spec` 里加一行：

```lua
{ import = "lazyvim.plugins.extras.lang.typescript" },
```

或者更方便：在 nvim 里输入 `:LazyExtras`，用界面勾选。

### 禁用某个插件

在 `custom.lua` 里把对应行改成：

```lua
{ "作者/仓库名", enabled = false },
```

---

## 9. 常见问题

### Q: 补全菜单不弹出来？
A: 检查是否有 LSP 在运行：输入 `:LspInfo`。如果没有 pyright，运行 `:Mason` 搜索 pyright 安装。

### Q: 格式化不生效？
A: 输入 `:ConformInfo` 查看当前文件用的格式化工具。Python 应该是 ruff。

### Q: Copilot 没反应？
A: 先确认登录了：`:Copilot auth`。状态栏右边应该有 Copilot 图标。

### Q: 调试时选不到 Python？
A: 确认 debugpy 已安装：`:Mason` 搜索 debugpy 安装。或者 `pip install debugpy`。

### Q: 虚拟环境没识别到？
A: `空格+cv` 打开选择器时，确认你的 venv / conda 环境在标准位置。也可以手动指定路径。

### Q: 某个插件报错怎么办？
A: 在 `custom.lua` 里给那个插件加 `enabled = false` 临时禁用，然后重启 nvim。

### Q: 怎么恢复到初始状态？
```bash
# 清空所有插件数据，重新安装
rm -rf ~/.local/share/nvim
rm -rf ~/.local/state/nvim
nvim   # 重新打开，自动从零安装
```

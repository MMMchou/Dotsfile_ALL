# Neovim 插件与功能完整说明

> 配置基于 **LazyVim**（Neovim 的预配置框架），插件由 **lazy.nvim** 管理。
> 配置文件位置：`~/.config/nvim/`
>
> **Mac 按键提醒**：Control = 键盘左下角 ⌃ ，Option = Command 旁边 ⌥ ，空格 = leader 键

---

## 目录

1. [配置文件结构](#1-配置文件结构)
2. [系统依赖](#2-系统依赖)
3. [LazyVim Extras 官方模块](#3-lazyvim-extras-官方模块)
4. [自定义插件](#4-自定义插件)
5. [Flash 快速跳转详细教程](#5-flash-快速跳转详细教程)
6. [Python LSP 完整功能指南](#6-python-lsp-完整功能指南)
7. [调试器（DAP）使用指南](#7-调试器dap使用指南)
8. [全部快捷键速查表](#8-全部快捷键速查表)
9. [插件管理操作](#9-插件管理操作)
10. [常见问题](#10-常见问题)

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

## 2. 系统依赖

这些是 Neovim 和插件需要的命令行工具：

```bash
# macOS
brew install fd ripgrep node
pip install jupytext debugpy

# Linux (Ubuntu/Debian)
sudo apt install -y fd-find ripgrep nodejs npm
pip install jupytext debugpy
# 注意：Ubuntu 上 fd 叫 fd-find，需要创建软链接：
# ln -sf $(which fdfind) ~/.local/bin/fd
```

| 工具 | 作用 | 谁需要它 |
|------|------|---------|
| **fd** | 快速文件搜索 | venv-selector（虚拟环境选择器）、Telescope 文件搜索 |
| **ripgrep (rg)** | 快速文本搜索 | Telescope 全局搜索（`空格+fg`） |
| **node** | JavaScript 运行时 | markdown-preview 插件、Prettier 格式化 |
| **jupytext** | Jupyter notebook 转换 | jupytext.nvim（在 nvim 里打开 .ipynb） |
| **debugpy** | Python 调试器 | DAP 断点调试 |

---

## 3. LazyVim Extras 官方模块

> 配置位置：`lua/config/lazy.lua` 的 `spec` 部分
> 官方完整列表：https://www.lazyvim.org/extras
> 也可以在 nvim 中输入 `:LazyExtras` 用界面勾选/取消

### 3.1 语言支持

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

### 3.2 AI 辅助编程（当前已禁用）

| 模块 | 作用 | 状态 |
|------|------|------|
| `ai.copilot` | GitHub Copilot 代码补全 | 已注释（需要付费订阅 $10/月） |
| `ai.copilot-chat` | Copilot 对话 | 已注释 |

如果以后购买了 Copilot 订阅，在 `lazy.lua` 里取消注释即可启用。

### 3.3 编辑器增强

| 模块 | 作用 | 说明 |
|------|------|------|
| `editor.dial` | 增强递增递减 | Control+a/x 不仅能递增数字，还能切换 `true↔false`、`yes↔no`、日期等 |
| `editor.mini-move` | 移动行/块 | 在 nvim 内部用快捷键移动选中的代码块 |

### 3.4 调试

| 模块 | 作用 | 说明 |
|------|------|------|
| `dap.core` | 调试器核心 | 提供断点、单步执行、变量查看等调试功能。配合 `lang.python` 的 debugpy 实现 Python 断点调试 |

### 3.5 格式化

| 模块 | 作用 | 说明 |
|------|------|------|
| `formatting.prettier` | Prettier 格式化 | 自动格式化 JSON / Markdown / YAML / HTML / CSS 等文件 |

---

## 4. 自定义插件

> 配置位置：`lua/plugins/custom.lua`

### 4.1 主题

| 插件 | 作用 | 说明 |
|------|------|------|
| **catppuccin/nvim** | Catppuccin 主题 | 当前使用 mocha（深色）风格，与 tmux 主题统一。可选：`latte`（浅色）/ `frappe` / `macchiato` / `mocha`（深色） |

### 4.2 编辑增强

| 插件 | 作用 | 怎么用 |
|------|------|--------|
| **nvim-autopairs** | 自动补全括号 | 输入 `(` 自动补 `)`，输入 `{` 自动补 `}`，输入 `"` 自动补 `"` |
| **todo-comments.nvim** | TODO 高亮 | 在注释里写 `TODO:` / `FIXME:` / `HACK:` / `NOTE:` 会自动变彩色高亮。`空格+st` 搜索所有 TODO |
| **nvim-surround** | 快速包围文本 | 见下方详细用法 |
| **neoscroll.nvim** | 平滑滚动 | Control+d / Control+u 翻页时有平滑动画，不再突然跳 |
| **indent-blankline.nvim** | 缩进参考线 | 自动在代码左侧显示竖线，看清楚 if / for / def 的嵌套层级 |
| **flash.nvim** | 快速跳转 | 按 `s` + 两个字符跳到屏幕任意位置（详见第 5 节） |

**nvim-surround 用法**：

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

### 4.3 Git 增强

| 插件 | 作用 | 快捷键 |
|------|------|--------|
| **diffview.nvim** | Git diff 可视化 | `空格+gd` 打开 diff 对比视图，`空格+gh` 查看当前文件 git 历史 |

### 4.4 终端

| 插件 | 作用 | 快捷键 |
|------|------|--------|
| **toggleterm.nvim** | 浮动终端 | `Control+\` 弹出/隐藏一个浮动终端窗口。不用退出 nvim 就能跑命令 |

### 4.5 Jupyter / Python

| 插件 | 作用 | 说明 |
|------|------|------|
| **jupytext.nvim** | Jupyter Notebook 支持 | `nvim notebook.ipynb` 直接打开 .ipynb 文件。自动用 jupytext 转成 .py 编辑，保存时转回 .ipynb。前置条件：`pip install jupytext` |

### 4.6 Markdown

| 插件 | 作用 | 说明 |
|------|------|------|
| **markdown-preview.nvim** | Markdown 实时预览 | 打开 .md 文件后输入 `:MarkdownPreview`，自动在浏览器里打开实时预览页面。前置条件：macOS `brew install node` / Linux `sudo apt install nodejs npm` |

### 4.7 其他工具

| 插件 | 作用 | 说明 |
|------|------|------|
| **nvim-colorizer.lua** | 颜色代码可视化 | CSS/HTML 里的 `#ff0000` 会显示红色背景，`rgb(0,255,0)` 会显示绿色背景 |

---

## 5. Flash 快速跳转详细教程

Flash 是 Neovim 里最提升效率的插件之一。不用一行行按 `j/k` 移动光标了，直接"瞬移"。

### 5.1 基本跳转（最常用）

```
操作步骤：
1. 在 Normal 模式下按 s
2. 屏幕上的文字会变暗
3. 输入你要跳到的位置的前两个字符（比如你想跳到 "model" 这个词，就输入 mo）
4. 所有匹配 "mo" 的位置旁边会出现一个高亮字母标签（比如 a、b、c）
5. 按对应的字母就瞬间跳过去了
```

**实际例子**：

```python
# 假设你的代码是这样的，光标在第 1 行开头：

def train(model, optimizer, criterion, dataloader):    # 第 1 行
    for epoch in range(10):                             # 第 2 行
        for batch in dataloader:                        # 第 3 行
            output = model(batch)                       # 第 4 行 ← 你想跳到这里的 model
            loss = criterion(output, target)            # 第 5 行

# 操作：
# 1. 按 s
# 2. 输入 mo（model 的前两个字母）
# 3. 屏幕上第 1 行的 model 旁边出现 "a"，第 4 行的 model 旁边出现 "b"
# 4. 按 b → 光标瞬间跳到第 4 行的 model
```

### 5.2 Treesitter 选择（选中代码块）

```
操作步骤：
1. 按 S（大写）
2. 会高亮不同的代码块（函数体、if 块、for 循环等）
3. 按对应的字母选中整个代码块
```

**适用场景**：想快速选中一整个函数、一整个 for 循环、一整个 if 语句时用。

### 5.3 配合其他操作

Flash 不只是跳转，还能跟删除、复制、替换等操作配合：

```
ds + [Flash跳转]    删除从当前位置到目标位置的内容
ys + [Flash跳转]"   给跳转范围内的内容加引号
```

### 5.4 日常使用建议

```
最常用的就两个：
- s + 两个字符 + 标签字母    →  跳到屏幕上任意位置
- S                          →  快速选中代码块

比 hjkl 一行行移动快 10 倍，几天就能形成肌肉记忆。
```

---

## 6. Python LSP 完整功能指南

LSP（Language Server Protocol）是让 Neovim 拥有 IDE 级别智能的核心。
`lang.python` 模块自动安装了两个 LSP：**pyright**（智能分析）+ **ruff**（格式化/lint）。

### 6.1 智能补全

打开任何 `.py` 文件，输入代码时自动弹出补全菜单。

| 操作 | 快捷键 | 说明 |
|------|--------|------|
| 确认选中项 | `Tab` | 选中菜单中高亮的那一项 |
| 向下选择 | `Control+n` | 在补全菜单里往下翻 |
| 向上选择 | `Control+p` | 在补全菜单里往上翻 |
| 触发补全 | `Control+Space` | 如果菜单没自动弹出，手动触发 |
| 关闭补全菜单 | `Esc` | |

**能补全什么**：
- 变量名、函数名、类名
- 模块和包名（`import torch.` 后面自动列出所有子模块）
- 函数参数名（`nn.Linear(` 后面自动提示 `in_features`, `out_features`）
- 字典的 key（如果类型注解写了 TypedDict）
- 文件路径（在字符串里输入路径时）

### 6.2 悬浮文档 / 签名帮助

| 操作 | 快捷键 | 说明 |
|------|--------|------|
| 查看文档 | `K` | Normal 模式，光标放在函数/类上。弹出悬浮窗显示函数说明、参数类型、返回值 |
| 查看签名 | `Control+k` | Insert 模式，正在输入参数时。显示当前参数的类型和说明 |

**例子**：光标放在 `torch.nn.CrossEntropyLoss` 上按 `K`，会弹出：
```
class CrossEntropyLoss(weight=None, size_average=None, 
    ignore_index=-100, reduce=None, reduction='mean',
    label_smoothing=0.0)

This criterion computes the cross entropy loss between 
input logits and target.
```

### 6.3 代码导航（跳转）

| 操作 | 快捷键 | 说明 |
|------|--------|------|
| 跳到定义 | `gd` | 跳到函数/类/变量被定义的地方 |
| 跳到类型定义 | `gy` | 跳到变量的类型定义处 |
| 跳到实现 | `gI` | 跳到接口/抽象方法的具体实现 |
| 查看所有引用 | `gr` | 列出所有用到这个函数/变量的地方 |
| 返回上一个位置 | `Control+o` | 跳转后想跳回来 |
| 前进到下一个位置 | `Control+i` | 跳回来后又想跳过去 |

**AI 开发典型场景**：

```
1. 在 train.py 里看到 model = MyModel(config)
   → 光标放在 MyModel 上按 gd → 跳到 models.py 里 class MyModel 的定义
   → 看完了按 Control+o → 跳回 train.py

2. 在 loss = criterion(output, target) 上按 K
   → 弹出文档看参数说明
   → 按 gd 跳到 criterion 的定义看它用的是什么 loss

3. 想看 learning_rate 在哪些地方用到了
   → 光标放在 learning_rate 上按 gr
   → 列出所有文件中引用了这个变量的位置
```

### 6.4 错误诊断（实时检查）

pyright 会实时检查代码中的错误，不用运行就能发现问题：

| 操作 | 快捷键 | 说明 |
|------|--------|------|
| 跳到下一个错误 | `]d` | |
| 跳到上一个错误 | `[d` | |
| 查看当前行错误详情 | `空格+cd` | 弹出悬浮窗显示完整错误信息 |
| 打开错误列表面板 | `空格+xx` | 列出当前文件所有错误和警告 |

**能查出什么错误**：
- 类型不匹配：`x: int = "hello"` → 报错
- 未定义的变量：`print(undefined_var)` → 报错
- 参数数量错误：`torch.zeros(1, 2, 3, 4, 5)` → 如果参数不对会提示
- 属性不存在：`model.nonexistent_method()` → 报错
- import 找不到：`import nonexistent_package` → 报错
- 返回值类型不对：函数声明返回 int 但实际返回了 str → 报错

### 6.5 代码格式化（ruff）

| 操作 | 快捷键 | 说明 |
|------|--------|------|
| 保存时自动格式化 | 自动 | 按 Control+s 保存时自动执行 |
| 手动格式化 | `空格+cf` | |
| 整理 import | `空格+co` | 自动排序、删除未使用的 import |

**ruff 会自动帮你**：
- 统一缩进（4 个空格）
- 统一字符串引号风格
- 删除多余空行
- 删除行尾空格
- 删除未使用的 import
- 按 PEP8 规范排序 import（标准库 → 第三方 → 本地）
- 修复常见的代码风格问题

### 6.6 代码操作（Code Actions）

| 操作 | 快捷键 | 说明 |
|------|--------|------|
| 代码操作菜单 | `空格+ca` | 弹出可用的自动修复选项 |
| 整理 import | `空格+co` | |
| 重命名变量 | `空格+cr` | 在所有文件里同时改名（比如把 `lr` 改成 `learning_rate`） |

**重命名是最实用的功能之一**：
```
1. 光标放在变量名 lr 上
2. 按 空格+cr
3. 输入新名字 learning_rate
4. 回车 → 所有文件里的 lr 都自动改成 learning_rate
   比手动搜索替换安全得多（不会误改字符串里的 lr）
```

### 6.7 虚拟环境切换

| 操作 | 快捷键 | 说明 |
|------|--------|------|
| 打开虚拟环境选择器 | `空格+cv` | 列出所有 venv / conda 环境 |

**为什么要切换虚拟环境**：
- pyright 需要知道你用的是哪个 Python 环境
- 切换后它才能正确识别 `torch`、`transformers` 等包
- 补全菜单里才会出现这些包的 API

**支持的环境类型**：
- `venv`（项目目录里的 `.venv/`）
- `conda`（`~/miniconda3/envs/` 或 `~/anaconda3/envs/`）
- `pyenv`
- 系统 Python

### 6.8 代码搜索

| 操作 | 快捷键 | 说明 |
|------|--------|------|
| 搜索文件名 | `空格+ff` | 模糊匹配，输入 "train" 找到 train.py |
| 全局搜索文字 | `空格+fg` | 在所有文件里搜索，比如搜 "learning_rate" |
| 搜索符号 | `空格+ss` | 搜索函数名/类名/变量名 |
| 搜索所有 TODO | `空格+st` | 列出所有 TODO / FIXME / HACK 注释 |
| 打开文件树 | `空格+e` | 侧边栏文件浏览器 |

### 6.9 Jupyter Notebook

```bash
nvim notebook.ipynb
```

jupytext 自动把 notebook 转成 `.py` 格式编辑（用 `# %%` 标记 cell 边界），保存时自动转回 `.ipynb`。

### 6.10 LSP 状态检查

| 命令 | 作用 |
|------|------|
| `:LspInfo` | 查看当前文件有哪些 LSP 在运行 |
| `:Mason` | 打开 LSP/工具安装管理器（可以搜索安装新的 LSP） |
| `:ConformInfo` | 查看当前文件用的格式化工具 |
| `:checkhealth` | 全面检查 Neovim 和插件的健康状态 |

---

## 7. 调试器（DAP）使用指南

对 AI 算法开发特别有用——调试训练循环、检查 tensor 维度、排查 loss 异常。

### 7.1 前置条件

```bash
pip install debugpy
```

也可以在 nvim 里输入 `:Mason`，搜索 `debugpy` 安装。

### 7.2 基本操作

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

### 7.3 调试 Python 脚本（完整步骤）

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

### 7.4 调试时的界面

调试开始后，屏幕左侧会自动弹出面板显示：
- **Scopes**：当前作用域的所有变量和值
- **Breakpoints**：所有断点列表
- **Stacks**：调用栈（当前在哪个函数里，从哪调用过来的）

### 7.5 AI 开发调试技巧

```
调试 tensor 维度问题：
  在 output = model(input) 这一行设断点
  停住后在 REPL 里输入 output.shape → 看维度对不对

调试 loss 不收敛：
  在 loss.backward() 前设断点
  查看 loss.item() 的值
  查看 model.parameters() 的梯度

条件断点（只在特定条件下停）：
  空格+dB → 输入 epoch == 5 and batch_idx == 0
  只在第 5 个 epoch 的第一个 batch 时停住
```

---

## 8. 全部快捷键速查表

### 8.1 基础操作

| 操作 | 快捷键 |
|------|--------|
| 保存 | `Control+s` |
| 退出 | `:q` 或 `Control+q` |
| 保存并退出 | `:wq` |
| 不保存强制退出 | `:q!` |
| 撤销 | `u` |
| 重做 | `Control+r` |
| 进入编辑模式 | `i` |
| 回到 Normal 模式 | `Esc` |

### 8.2 Flash 跳转

| 操作 | 快捷键 |
|------|--------|
| 跳到任意位置 | `s` + 两个字符 + 标签字母 |
| 选中代码块 | `S`（大写） |

### 8.3 文件与搜索

| 操作 | 快捷键 |
|------|--------|
| 文件树 | `空格+e` |
| 搜索文件 | `空格+ff` |
| 全局搜索文字 | `空格+fg` |
| 搜索已打开的 Buffer | `空格+fb` |
| 最近打开的文件 | `空格+fr` |
| 搜索符号 | `空格+ss` |
| 搜索 TODO | `空格+st` |

### 8.4 代码导航（LSP）

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
| 错误详情 | `空格+cd` |

### 8.5 代码操作（LSP）

| 操作 | 快捷键 |
|------|--------|
| 格式化文件 | `空格+cf` |
| 整理 import | `空格+co` |
| 代码操作菜单 | `空格+ca` |
| 重命名（全局） | `空格+cr` |
| 选择虚拟环境 | `空格+cv` |

### 8.6 编辑

| 操作 | 快捷键 |
|------|--------|
| 删除整行 | `dd` |
| 复制整行 | `yy` |
| 粘贴 | `p` |
| 注释/取消注释 | `gcc`（当前行）/ `gc`（选中区域） |
| 移动行上下 | `Control+Shift+j/k` |
| 缩进 | 选中后按 `>` / `<` |
| 递增数字/布尔 | `Control+a` |
| 递减数字/布尔 | `Control+x` |

### 8.7 包围操作（surround）

| 操作 | 快捷键 |
|------|--------|
| 给单词加引号 | `ysiw"` |
| 给单词加括号 | `ysiw(` |
| 给整行加引号 | `yss"` |
| 删引号 | `ds"` |
| 双引号改单引号 | `cs"'` |

### 8.8 窗口与 Buffer

| 操作 | 快捷键 |
|------|--------|
| 下一个 Buffer | `Shift+l` |
| 上一个 Buffer | `Shift+h` |
| 关闭当前 Buffer | `空格+bd` |
| 窗口高度调整 | `Control+↑/↓` |
| 窗口宽度调整 | `Control+←/→` |

### 8.9 Git

| 操作 | 快捷键 |
|------|--------|
| 打开 lazygit | `空格+gg` |
| Git diff 对比 | `空格+gd` |
| 当前文件 Git 历史 | `空格+gh` |

### 8.10 调试

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

### 8.11 其他

| 操作 | 快捷键 |
|------|--------|
| 浮动终端 | `Control+\` |
| Lazy 插件管理 | `空格+l` |
| LazyExtras 模块管理 | `:LazyExtras` |
| Markdown 预览 | `:MarkdownPreview` |
| 错误列表 | `空格+xx` |
| LSP 状态 | `:LspInfo` |
| 工具安装器 | `:Mason` |

---

## 9. 插件管理操作

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

## 10. 常见问题

### Q: 报错 "Cannot find any fd binary"？
A: 安装 fd：macOS `brew install fd` / Linux `sudo apt install fd-find`（然后 `ln -sf $(which fdfind) ~/.local/bin/fd`）。这是虚拟环境选择器和文件搜索需要的工具。

### Q: 补全菜单不弹出来？
A: 输入 `:LspInfo` 检查是否有 LSP 在运行。如果没有 pyright，输入 `:Mason` 搜索 pyright 安装。

### Q: 格式化不生效？
A: 输入 `:ConformInfo` 查看当前文件用的格式化工具。Python 应该是 ruff。

### Q: 调试时选不到 Python？
A: 确认 debugpy 已安装：`:Mason` 搜索 debugpy 安装。或者 `pip install debugpy`。

### Q: 虚拟环境没识别到？
A: `空格+cv` 打开选择器。确认 fd 已安装（macOS: `brew install fd` / Linux: `sudo apt install fd-find`），确认 venv / conda 在标准位置。

### Q: 打开 .ipynb 报错？
A: 确认 jupytext 已安装且在 PATH 里：`which jupytext`。如果找不到，运行 `pip install jupytext`，然后重开终端。

### Q: 某个插件报错怎么办？
A: 在 `custom.lua` 里给那个插件加 `enabled = false` 临时禁用，然后重启 nvim。

### Q: 怎么恢复到初始状态？
```bash
rm -rf ~/.local/share/nvim
rm -rf ~/.local/state/nvim
nvim   # 重新打开，自动从零安装
```

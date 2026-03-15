# Dotsfile_ALL

macOS 开发环境一键配置：tmux + Neovim(LazyVim) + AeroSpace + OrbStack + SSH + Claude Code。

克隆仓库、运行脚本，即可在任意 Mac 上还原完整开发环境。

---

## 快速开始

```bash
# 1. 克隆仓库
git clone https://github.com/MMMchou/Dotsfile_ALL.git ~/Dotsfile_ALL

# 2. 运行安装脚本
cd ~/Dotsfile_ALL
chmod +x install.sh
./install.sh

# 3. 填入你的 API Key（首次安装）
nano ~/.shell_env

# 4. 让环境变量生效
source ~/.shell_env
```

---

## 目录结构

```
Dotsfile_ALL/
├── install.sh                  # 一键安装脚本
├── README.md                   # 本文档
├── .gitignore
├── shell/
│   ├── .shell_env.example      # 环境变量模板（脱敏）
│   ├── .bash_profile           # bash 启动文件
│   └── .zshrc                  # zsh 启动文件
├── tmux/
│   └── .tmux.conf              # tmux 完整配置
├── nvim/                       # Neovim + LazyVim 配置
│   ├── init.lua                # 入口（含总说明）
│   ├── stylua.toml
│   └── lua/
│       ├── config/
│       │   ├── lazy.lua        # 插件管理器引导
│       │   ├── options.lua     # 编辑器选项
│       │   ├── keymaps.lua     # 快捷键
│       │   └── autocmds.lua    # 自动命令
│       └── plugins/
│           ├── custom.lua      # 自定义插件（改这个）
│           └── example.lua     # 官方示例（仅参考）
├── aerospace/
│   └── aerospace.toml          # AeroSpace 窗口管理器配置
├── ssh/
│   └── config                  # SSH 连接配置模板
└── claude/
    └── settings.json           # Claude Code 模型设置
```

---

## 工具介绍

| 工具 | 是什么 | 为什么用 |
|------|--------|----------|
| **tmux** | 终端复用器 | 一个终端窗口里开多个面板/窗口，断开后还能恢复 |
| **Neovim + LazyVim** | 终端编辑器 | 轻量、快速、高度可定制的代码编辑器 |
| **AeroSpace** | 平铺窗口管理器 | 自动排列窗口，用键盘操控一切，不用鼠标拖拽 |
| **OrbStack** | Docker + Linux VM | 比 Docker Desktop 更快更轻，还能直接跑 Linux 虚拟机 |
| **SSH** | 远程连接 | 连接远程服务器，配置好后一条命令直连 |
| **Claude Code** | AI 编程助手 | 终端里的 AI 助手，帮你写代码、debug |

---

## 常用操作速查

### tmux

前缀键 = `Ctrl-a`（先按 Ctrl-a，松开，再按后面的键）

| 操作 | 快捷键 |
|------|--------|
| 新建会话 | `tmux new -s 会话名` |
| 进入会话 | `tmux attach -t 会话名` |
| 列出会话 | `tmux ls` |
| 退出会话（不关闭） | 前缀 + `d` |
| 新建窗口 | 前缀 + `c` |
| 下一个窗口 | 前缀 + `n` |
| 上一个窗口 | 前缀 + `p` |
| 重命名窗口 | 前缀 + `,` |
| 左右分屏 | 前缀 + `\|` |
| 上下分屏 | 前缀 + `-` |
| 切换面板 | `Alt + h/j/k/l` |
| 调整面板大小 | 前缀 + `H/J/K/L` |
| 进入复制模式 | 前缀 + `[` |
| 复制到剪贴板 | `v` 选中 -> `y` 复制 |
| 重载配置 | 前缀 + `r` |
| 安装插件 | 前缀 + `I`（大写 i） |
| 更新插件 | 前缀 + `U`（大写 u） |

### Neovim (LazyVim)

`<leader>` 键 = 空格键

| 操作 | 快捷键 |
|------|--------|
| 打开文件树 | `<leader>e` |
| 搜索文件 | `<leader>ff` |
| 全局搜索文字 | `<leader>fg` 或 `<leader>/` |
| 最近打开的文件 | `<leader>fr` |
| 搜索已打开的 Buffer | `<leader>fb` |
| 打开 lazygit | `<leader>gg` |
| 打开插件管理器 | `<leader>l` |
| 跳转到定义 | `gd` |
| 查看引用 | `gr` |
| 悬浮文档 | `K` |
| 注释/取消注释 | `gcc`（当前行）/ `gc`（选中区域） |
| 保存文件 | `Ctrl+s` |
| 退出 | `:q` 或 `Ctrl+q` |
| 下一个 Buffer | `Shift+l` |
| 上一个 Buffer | `Shift+h` |
| 移动行 | `Alt+j/k` |

### AeroSpace

所有快捷键用 `Alt`（Option）键触发：

| 操作 | 快捷键 |
|------|--------|
| 在窗口间移动焦点 | `Alt + h/j/k/l` |
| 移动窗口位置 | `Alt + Shift + h/j/k/l` |
| 切换到桌面 1-9 | `Alt + 1-9` |
| 把窗口发送到桌面 1-9 | `Alt + Shift + 1-9` |
| 打开终端 | `Alt + Enter` |
| 窗口全屏 | `Alt + f` |
| 平铺布局 | `Alt + t` |
| 堆叠布局 | `Alt + s` |
| 浮动/平铺切换 | `Alt + Shift + Space` |
| 缩小窗口 | `Alt + -` |
| 放大窗口 | `Alt + =` |
| 关闭窗口 | `Alt + Shift + q` |
| 重载配置 | `Alt + Shift + r` |

桌面分配建议：1=终端 / 2=浏览器 / 3=编辑器 / 4=通讯 / 5=其他

### OrbStack

```bash
# Docker 相关
docker ps                        # 查看运行中的容器
docker run -it ubuntu bash       # 临时跑一个 Ubuntu 容器
docker compose up -d             # 启动 docker-compose 项目

# Linux 虚拟机
orb create ubuntu dev            # 创建名为 dev 的 Ubuntu 机器
orb                              # 进入默认机器
orb -m dev                       # 进入 dev 机器
orb list                         # 列出所有机器
orb delete dev                   # 删除 dev 机器

# 文件共享
# Mac 文件在 Linux 里：/mnt/mac/Users/你的用户名/
# Linux 文件在 Mac 里：~/OrbStack/机器名/
```

### SSH

```bash
# 连接服务器（用 ~/.ssh/config 里配置的别名）
ssh dev                          # 连接"dev"服务器
ssh prod                         # 连接"prod"服务器

# 生成 SSH Key（首次使用）
ssh-keygen -t ed25519 -C "你的邮箱"

# 把公钥复制到服务器
ssh-copy-id -i ~/.ssh/id_ed25519.pub 用户名@服务器IP

# 添加新服务器：编辑 ~/.ssh/config，按照模板添加
```

---

## 日常工作流示例

### 开机后的完整流程

```
1. 开机 → AeroSpace 自动启动，窗口自动平铺

2. Alt+Enter 打开终端（自动到桌面1）
   → tmux new -s work

3. 在 tmux 中：
   → 前缀+| 左右分屏
   → 左边写代码：nvim .
   → 右边跑命令

4. Alt+2 切到桌面2 → 打开浏览器查文档

5. 需要测试 Linux 环境？
   → orb -m dev  进入 Linux 机器
   → 或者 docker run ...

6. 需要连远程服务器？
   → ssh dev
   → 服务器上也可以用 tmux（断开后不丢失）

7. 下班断开 tmux（前缀+d）
   → 第二天 tmux attach 恢复现场
```

### 在新 Mac 上部署

```bash
# 5 分钟搞定
git clone https://github.com/MMMchou/Dotsfile_ALL.git ~/Dotsfile_ALL
cd ~/Dotsfile_ALL && ./install.sh
# 编辑 ~/.shell_env 填入 API Key
# 完成！
```

### 在远程服务器上部署（精简版）

服务器通常不需要 AeroSpace 和 OrbStack，只需要 tmux + nvim：

```bash
# 在服务器上（需要先装 git/tmux/nvim）
git clone https://github.com/MMMchou/Dotsfile_ALL.git ~/Dotsfile_ALL

# 手动链接需要的配置
ln -sf ~/Dotsfile_ALL/tmux/.tmux.conf ~/.tmux.conf
mkdir -p ~/.config
ln -sf ~/Dotsfile_ALL/nvim ~/.config/nvim

# 安装 TPM
git clone --depth 1 https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

# 进 tmux 按 Ctrl-a + I 安装插件
# 打开 nvim 自动安装 LazyVim 插件
```

---

## 如何修改配置

| 想改什么 | 编辑哪个文件 |
|----------|-------------|
| API Key / URL / 模型 | `~/.shell_env` |
| tmux 快捷键 / 插件 / 主题 | `tmux/.tmux.conf` |
| Neovim 选项（缩进/行号等） | `nvim/lua/config/options.lua` |
| Neovim 快捷键 | `nvim/lua/config/keymaps.lua` |
| Neovim 插件 / 主题 | `nvim/lua/plugins/custom.lua` |
| AeroSpace 快捷键 / 桌面规则 | `aerospace/aerospace.toml` |
| SSH 服务器列表 | `ssh/config` |
| Claude Code 模型 | `claude/settings.json` |

改完后：

- **tmux**：在 tmux 内按 `Ctrl-a + r` 重载
- **Neovim**：重启 nvim 即可
- **AeroSpace**：按 `Alt+Shift+r` 重载
- **Shell 环境变量**：`source ~/.shell_env`
- **SSH**：下次连接自动生效

---

## 同步更新到 GitHub

当你在本地修改了配置后，推送到 GitHub：

```bash
cd ~/Dotsfile_ALL
git add -A
git commit -m "update: 描述你改了什么"
git push
```

在另一台机器上拉取最新配置：

```bash
cd ~/Dotsfile_ALL
git pull
# tmux 中按 Ctrl-a + r 重载
# nvim 中按 <leader>l 检查插件更新
# AeroSpace 按 Alt+Shift+r 重载
```

---

## FAQ

### Q: 状态栏图标显示方块？
A: 你的终端字体不支持图标。安装 Nerd Font：
```bash
brew install --cask font-jetbrains-mono-nerd-font
```
然后在 Alacritty 配置里把字体改成 `JetBrainsMono Nerd Font`。

### Q: tmux 插件没装上？
A: 进入 tmux 后按 `Ctrl-a + I`（大写 i）手动安装。如果 GitHub 连不上，开 VPN 或用镜像。

### Q: Neovim 打开报错？
A: 首次打开可能需要下载插件，等待自动安装完成。如果失败，检查网络后运行：
```bash
nvim --headless "+Lazy! sync" +qa
```

### Q: AeroSpace 和 tmux 的 Alt 键冲突吗？
A: 不冲突。AeroSpace 在窗口级别工作（管理不同 App 窗口），tmux 在终端内部工作（管理终端面板）。

### Q: 怎么切换 Catppuccin 主题风格？
A: tmux 和 nvim 都可以独立切换：
- tmux：编辑 `.tmux.conf`，修改 `@catppuccin_flavor` 为 `latte`/`frappe`/`macchiato`/`mocha`
- nvim：编辑 `plugins/custom.lua`，修改 `flavour` 值

### Q: .shell_env 含密钥，会不会被传到 GitHub？
A: 不会。`.gitignore` 已排除 `shell/.shell_env`。仓库里只有脱敏的 `.shell_env.example`。

### Q: 在 Linux 服务器上能用吗？
A: tmux 和 nvim 的配置可以直接用。AeroSpace 和 OrbStack 仅限 macOS。SSH config 是客户端配置，放在你自己的 Mac 上。

---

## 参考链接

- [tmux 官方 Wiki](https://github.com/tmux/tmux/wiki)
- [LazyVim 文档](https://www.lazyvim.org/)
- [AeroSpace 指南](https://nikitabobko.github.io/AeroSpace/guide.html)
- [OrbStack 文档](https://docs.orbstack.dev/)
- [TPM 插件管理器](https://github.com/tmux-plugins/tpm)
- [Catppuccin 主题](https://github.com/catppuccin)

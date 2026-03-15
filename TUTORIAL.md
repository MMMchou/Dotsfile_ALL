# 从零开始：macOS 终端开发工作流新手训练教程

> 本教程面向完全没用过 tmux / Neovim / AeroSpace / OrbStack / SSH 的新手。
> 每一步都有完整操作和预期结果，建议你边看边跟着做。
> 快捷键速查请看 README.md。

---

## 目录

1. [你会学到什么](#1-你会学到什么)
2. [第一课：认识你的工具链](#2-第一课认识你的工具链)
3. [第二课：AeroSpace — 窗口不用鼠标拖了](#3-第二课aerospace--窗口不用鼠标拖了)
4. [第三课：tmux — 一个终端变成十个](#4-第三课tmux--一个终端变成十个)
5. [第四课：Neovim — 终端里的代码编辑器](#5-第四课neovim--终端里的代码编辑器)
6. [第五课：OrbStack — 在 Mac 上跑 Linux 和 Docker](#6-第五课orbstack--在-mac-上跑-linux-和-docker)
7. [第六课：SSH — 连接远程服务器](#7-第六课ssh--连接远程服务器)
8. [第七课：在容器和服务器之间切换](#8-第七课在容器和服务器之间切换)
9. [第八课：把你的配置同步到 GitHub](#9-第八课把你的配置同步到-github)
10. [第九课：在新机器上一键恢复环境](#10-第九课在新机器上一键恢复环境)
11. [第十课：日常训练计划（21天养成习惯）](#11-第十课日常训练计划21天养成习惯)
12. [附录：遇到问题怎么办](#12-附录遇到问题怎么办)

---

## 1. 你会学到什么

学完这个教程，你会掌握一套完整的终端工作流：

```
你的 Mac
├── AeroSpace    → 用键盘管理所有窗口（不用鼠标拖来拖去）
├── Alacritty    → 你的终端 App
│   └── tmux     → 终端内部分屏、多窗口、断开不丢失
│       ├── Neovim   → 在终端里写代码
│       ├── SSH      → 连远程服务器
│       └── OrbStack → 跑 Linux 虚拟机 / Docker 容器
└── 浏览器        → 查文档
```

核心思路：**能用键盘就不用鼠标，能自动化就不手动。**

---

## 2. 第一课：认识你的工具链

### 2.1 先搞清楚每个工具解决什么问题

| 你遇到的问题 | 用什么解决 |
|---|---|
| 窗口太多，来回切换很烦，要用鼠标拖 | AeroSpace |
| 终端只能做一件事，想同时看代码和跑命令 | tmux |
| SSH 断了，跑了一半的程序就没了 | tmux（在服务器上用） |
| 编辑服务器上的文件很麻烦 | Neovim |
| 想在 Mac 上测试 Linux 环境 | OrbStack |
| 连服务器要记 IP、端口、用户名 | SSH config |
| 换了电脑，所有配置都要重新弄 | Dotfiles + GitHub |

### 2.2 确认你的环境已就绪

打开你的 Alacritty 终端，依次运行：

```bash
tmux -V          # 应该显示 tmux 3.x
nvim --version   # 应该显示 NVIM v0.11.x
aerospace --help # 应该显示帮助信息
orb --version    # 应该显示 OrbStack 版本
ssh -V           # 应该显示 OpenSSH 版本
```

如果某个命令报错"command not found"，运行安装脚本：
```bash
cd ~/Dotsfile_ALL && ./install.sh
```

---

## 3. 第二课：AeroSpace — 窗口不用鼠标拖了

### 3.1 什么是平铺窗口管理器

你现在用 Mac 的方式：打开很多窗口 → 互相遮挡 → 用鼠标拖来拖去找窗口。

AeroSpace 的方式：打开窗口 → 自动并排排列 → 用键盘一秒切换。

### 3.2 第一次启动

1. 在 Spotlight（Cmd+Space）搜索 `AeroSpace`，打开
2. 系统会弹窗要求"辅助功能"权限 → 点允许
3. 启动后你的窗口会自动排列整齐

### 3.3 跟着练：基本操作

**练习 1：打开两个窗口看效果**

```
1. Alt+Enter          → 打开一个终端
2. 再按 Alt+Enter     → 打开第二个终端
3. 观察：两个终端自动左右平铺了！
```

**练习 2：在窗口间切换**

```
1. Alt+h              → 焦点移到左边的窗口
2. Alt+l              → 焦点移到右边的窗口
3. Alt+j / Alt+k      → 上下切换（如果有上下排列的窗口）
```

**练习 3：移动窗口位置**

```
1. Alt+Shift+l        → 把当前窗口移到右边
2. Alt+Shift+h        → 把当前窗口移到左边
```

**练习 4：使用多个桌面**

```
1. Alt+1              → 切到桌面 1（终端）
2. Alt+2              → 切到桌面 2（浏览器）
   打开 Safari 或 Chrome，它会自动跑到桌面 2
3. Alt+1              → 切回桌面 1
4. Alt+Shift+2        → 把当前窗口发送到桌面 2
```

**练习 5：窗口全屏**

```
1. Alt+f              → 当前窗口全屏
2. 再按 Alt+f         → 恢复平铺
```

### 3.4 小结

```
记住这几个就够日常用了：
- Alt+h/j/k/l          切换窗口
- Alt+1-9               切换桌面
- Alt+Enter             开终端
- Alt+f                 全屏
```

---

## 4. 第三课：tmux — 一个终端变成十个

### 4.1 为什么要用 tmux

不用 tmux：
- 一个终端只能做一件事
- 关了终端，正在跑的程序就没了
- SSH 断了，工作全丢

用 tmux：
- 一个终端里分成多个面板，同时看代码、跑命令、看日志
- 关掉终端、断开 SSH，程序照样跑
- 第二天打开终端，一秒恢复昨天的工作现场

### 4.2 核心概念（3 个层级）

```
Session（会话）
└── Window（窗口）= 浏览器的"标签页"
    └── Pane（面板）= 一个窗口内的分屏
```

例子：
```
会话 "work"
├── 窗口 1 "code"
│   ├── 面板：左边 nvim 写代码
│   └── 面板：右边跑命令
├── 窗口 2 "server"
│   └── 面板：SSH 连服务器
└── 窗口 3 "docker"
    └── 面板：docker logs
```

### 4.3 前缀键

tmux 的所有快捷键都需要先按"前缀键"，再按功能键。

我们的前缀键是 **Ctrl+a**（两个键同时按，然后松开，再按后面的键）。

写法约定：`前缀+x` 表示先按 Ctrl+a，松开，再按 x。

### 4.4 跟着练：完整流程

**练习 1：创建你的第一个会话**

```bash
# 在终端里输入：
tmux new -s learn
```

你会看到底部出现一条绿色状态栏，恭喜你已经在 tmux 里了。

**练习 2：分屏**

```
1. 前缀+|       → 左右分屏（按 Ctrl+a，松开，再按 |）
   现在你有左右两个面板了

2. 前缀+-       → 上下分屏
   现在右边又分成了上下两个

3. Alt+h        → 跳到左边面板
4. Alt+l        → 跳到右边面板
5. Alt+j        → 跳到下面面板
6. Alt+k        → 跳到上面面板
```

**练习 3：在面板里做不同的事**

```
1. 在左边面板输入：    ls -la
2. Alt+l 跳到右边面板
3. 在右边面板输入：    top      （查看系统进程）
4. Alt+h 跳回左边面板
5. 观察：两边同时显示不同内容！
```

**练习 4：新建窗口**

```
1. 前缀+c       → 新建一个窗口（看底部状态栏，多了一个标签）
2. 前缀+n       → 切换到下一个窗口
3. 前缀+p       → 切换到上一个窗口
4. 前缀+,       → 重命名当前窗口（输入名字，按 Enter）
```

**练习 5：断开与恢复（最重要的功能）**

```
1. 前缀+d       → 断开会话（你回到了普通终端，但 tmux 还在后台跑）

2. tmux ls       → 查看后台的会话列表
   你会看到：learn: 1 windows ...

3. tmux attach -t learn  → 重新进入！一切都在，什么都没丢

这就是为什么在服务器上一定要用 tmux：
SSH 断了 → 重新连 → tmux attach → 恢复现场
```

**练习 6：关闭面板和窗口**

```
1. 在某个面板里输入 exit  → 关闭这个面板
2. 所有面板都关了 → 窗口自动关闭
3. 所有窗口都关了 → 会话自动关闭
```

### 4.5 小结

```
日常只需要记住：
- tmux new -s 名字      创建会话
- tmux attach -t 名字   恢复会话
- 前缀+|               左右分屏
- 前缀+-               上下分屏
- Alt+h/j/k/l          切换面板
- 前缀+c/n/p           新建/切换窗口
- 前缀+d               断开（后台保留）
```

---

## 5. 第四课：Neovim — 终端里的代码编辑器

### 5.1 为什么在终端里用编辑器

- 在服务器上没有 VS Code，只能用终端编辑器
- Neovim 启动秒开，不像 IDE 要等半天
- 配合 tmux，分屏写代码 + 跑命令，不用切窗口

### 5.2 Neovim 的模式（最重要的概念）

Neovim 有 4 个模式，这是它和普通编辑器最大的区别：

```
Normal 模式（默认）  → 移动光标、删除、复制、执行命令
Insert 模式         → 打字写代码（和普通编辑器一样）
Visual 模式         → 选中文本
Command 模式        → 输入命令（保存、退出等）
```

切换方式：
```
任何模式 → Normal：  按 Esc
Normal → Insert：    按 i（在光标前插入）或 a（在光标后插入）
Normal → Visual：    按 v
Normal → Command：   按 :（冒号）
```

### 5.3 跟着练：从打开到保存退出

**练习 1：打开 Neovim**

```bash
# 在终端输入：
nvim
```

你会看到 LazyVim 的启动界面。首次打开会自动安装插件，等一会。

**练习 2：创建并编辑一个文件**

```bash
# 退出当前 nvim（输入 :q 按 Enter）
# 然后：
nvim test.txt
```

现在你在 Normal 模式（左下角显示 NORMAL）。

```
1. 按 i           → 进入 Insert 模式（左下角变成 INSERT）
2. 打字：Hello, Neovim!
3. 按 Esc          → 回到 Normal 模式
4. 输入 :w         → 保存（w = write）
5. 输入 :q         → 退出（q = quit）
   或者 :wq        → 保存并退出
```

**练习 3：基本移动（Normal 模式下）**

```
h = 左    j = 下    k = 上    l = 右

gg = 跳到文件开头
G  = 跳到文件末尾
w  = 跳到下一个单词
b  = 跳到上一个单词
0  = 跳到行首
$  = 跳到行尾
```

**练习 4：使用 LazyVim 的功能**

```bash
# 用 nvim 打开一个项目目录
cd ~/Dotsfile_ALL
nvim .
```

```
1. 空格+e          → 打开/关闭左边的文件树
   在文件树里用 j/k 上下移动，Enter 打开文件

2. 空格+ff         → 搜索文件（输入文件名，模糊匹配）
   试试输入 "tmux" → 选中 .tmux.conf → Enter 打开

3. 空格+fg         → 全局搜索文字
   试试搜索 "catppuccin"

4. 打开一个文件后：
   Shift+l         → 切换到下一个已打开的文件
   Shift+h         → 切换到上一个已打开的文件
```

**练习 5：编辑操作（Normal 模式下）**

```
dd   = 删除整行
yy   = 复制整行
p    = 粘贴
u    = 撤销
Ctrl+r = 重做
gcc  = 注释/取消注释当前行
```

### 5.4 小结

```
新手生存工具包（记住这些就能活下来）：
- i         进入编辑模式
- Esc       回到 Normal 模式
- :w        保存
- :q        退出
- :wq       保存退出
- :q!       不保存强制退出（改坏了用这个）
- 空格+e    文件树
- 空格+ff   搜索文件
- u         撤销
```

---

## 6. 第五课：OrbStack — 在 Mac 上跑 Linux 和 Docker

### 6.1 为什么需要 OrbStack

- 你的代码最终要部署到 Linux 服务器，需要在本地测试
- 很多开发工具（数据库、Redis、消息队列）用 Docker 跑最方便
- OrbStack 比 Docker Desktop 快很多，还能直接跑完整的 Linux 虚拟机

### 6.2 第一次启动

1. 在 Spotlight 搜索 `OrbStack`，打开
2. 按提示完成初始化（会下载一些组件）
3. 完成后你就有了 `docker` 和 `orb` 命令

### 6.3 跟着练：Docker 容器

**练习 1：跑一个临时容器**

```bash
# 拉取并运行一个 Ubuntu 容器，进入 bash
docker run -it ubuntu bash
```

你现在在一个 Ubuntu 系统里了！试试：
```bash
cat /etc/os-release     # 看看是什么系统
apt update              # 更新包管理器
apt install -y curl     # 装个工具
exit                    # 退出容器（容器也会停止）
```

**练习 2：后台跑一个服务**

```bash
# 跑一个 Nginx 网页服务器
docker run -d --name my-nginx -p 8080:80 nginx

# 打开浏览器访问 http://localhost:8080
# 你会看到 Nginx 欢迎页面！

# 查看正在运行的容器
docker ps

# 停止容器
docker stop my-nginx

# 删除容器
docker rm my-nginx
```

### 6.4 跟着练：Linux 虚拟机

Docker 容器是"用完即走"的，Linux 虚拟机是"长期使用"的。

**练习 1：创建一台 Linux 机器**

```bash
# 创建一台名叫 dev 的 Ubuntu 机器
orb create ubuntu dev
```

**练习 2：进入 Linux 机器**

```bash
# 进入 dev 机器
orb -m dev

# 你现在在一个完整的 Ubuntu 里了
uname -a             # 看系统信息
ls /mnt/mac/         # 看到你 Mac 的文件了！

# 退出
exit
```

**练习 3：文件共享（超级方便）**

```
Mac 的文件在 Linux 里的路径：
/mnt/mac/Users/mac/          → 对应你 Mac 的 ~/

Linux 的文件在 Mac 里的路径：
~/OrbStack/dev/              → 对应 dev 机器的 ~/

你可以直接在 Mac 上编辑 Linux 里的文件，反过来也行。
```

**练习 4：在 Linux 机器里部署你的配置**

```bash
# 进入 dev 机器
orb -m dev

# 安装必要工具
sudo apt update
sudo apt install -y git tmux neovim

# 直接用 Mac 上的 Dotsfile_ALL（通过文件共享）
ln -sf /mnt/mac/Users/mac/Dotsfile_ALL/tmux/.tmux.conf ~/.tmux.conf
mkdir -p ~/.config
ln -sf /mnt/mac/Users/mac/Dotsfile_ALL/nvim ~/.config/nvim

# 安装 TPM
git clone --depth 1 https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

# 进入 tmux
tmux new -s dev

# 按 Ctrl-a + I 安装 tmux 插件
# 打开 nvim，等待 LazyVim 自动安装插件
```

### 6.5 小结

```
Docker（轻量、临时）：
- docker run -it ubuntu bash     临时试一下
- docker run -d ...              后台跑服务
- docker ps / stop / rm          管理容器

OrbStack Linux 机器（完整、长期）：
- orb create ubuntu dev          创建
- orb -m dev                     进入
- orb list                       列出
- /mnt/mac/...                   访问 Mac 文件
```

---

## 7. 第六课：SSH — 连接远程服务器

### 7.1 基本概念

SSH 就是"安全远程登录"。你在终端输入一条命令，就能控制远在机房的服务器。

### 7.2 跟着练：生成 SSH 密钥（首次使用）

```bash
# 生成密钥对（一路按 Enter 用默认值就行）
ssh-keygen -t ed25519 -C "你的邮箱@example.com"

# 查看你的公钥（这个可以给别人/放到服务器上）
cat ~/.ssh/id_ed25519.pub

# 查看你的私钥位置（这个绝对不能给别人）
ls ~/.ssh/id_ed25519
```

### 7.3 跟着练：添加一台服务器

假设你有一台服务器：IP 是 `123.45.67.89`，用户名是 `root`。

**第一步：把公钥传到服务器**

```bash
ssh-copy-id -i ~/.ssh/id_ed25519.pub root@123.45.67.89
# 输入服务器密码（只需要这一次）
```

**第二步：在 SSH config 里添加别名**

```bash
nvim ~/.ssh/config
```

在文件末尾"你的服务器"那一节，添加：

```
Host myserver
    HostName 123.45.67.89
    User root
    Port 22
```

保存退出。

**第三步：一条命令连接**

```bash
ssh myserver       # 不用记 IP 了，直接用别名
```

### 7.4 在服务器上用 tmux（防止断开丢失工作）

```bash
# 连到服务器
ssh myserver

# 创建 tmux 会话
tmux new -s work

# 跑你的程序...
python train.py

# 需要离开了？断开 tmux（程序继续跑）
# 按 Ctrl-a + d

# 下次连回来
ssh myserver
tmux attach -t work    # 程序还在跑！
```

### 7.5 小结

```
一次性设置：
1. ssh-keygen          生成密钥
2. ssh-copy-id         传到服务器
3. 编辑 ~/.ssh/config  添加别名

日常使用：
- ssh 别名             连接
- tmux new -s 名字     创建工作区
- 前缀+d               断开
- tmux attach          恢复
```

---

## 8. 第七课：在容器和服务器之间切换

这是把前面所有工具串起来的实战课。

### 8.1 场景：你有三个工作环境

```
1. Mac 本地         → 写代码
2. OrbStack Linux   → 本地测试 Linux 环境
3. 远程服务器        → 部署 / 跑训练
```

### 8.2 用 tmux 窗口管理多个环境

核心思路：**在一个 tmux 会话里，用不同窗口连不同环境。**

```bash
# 第一步：在 Mac 上创建 tmux 会话
tmux new -s work

# 你现在在窗口 1（Mac 本地）
# 这里写代码
nvim .

# 第二步：新建窗口 2 → 连 OrbStack Linux
# 按 前缀+c 新建窗口
# 按 前缀+, 重命名为 "linux"
orb -m dev
# 你现在在 Linux 虚拟机里了

# 第三步：新建窗口 3 → 连远程服务器
# 按 前缀+c 新建窗口
# 按 前缀+, 重命名为 "server"
ssh myserver
# 你现在在远程服务器上了
```

### 8.3 在环境之间快速切换

```
前缀+1         → 跳到窗口 1（Mac 本地）
前缀+2         → 跳到窗口 2（Linux 虚拟机）
前缀+3         → 跳到窗口 3（远程服务器）
前缀+n         → 下一个窗口
前缀+p         → 上一个窗口
```

底部状态栏会显示所有窗口：`1:code  2:linux  3:server`，当前窗口高亮。

### 8.4 实战演练：本地写代码 → Linux 测试 → 服务器部署

```
步骤 1：在窗口 1 写代码
  前缀+1 → 切到 Mac 本地
  nvim app.py → 写代码 → :wq 保存

步骤 2：在窗口 2 测试
  前缀+2 → 切到 Linux
  cd /mnt/mac/Users/mac/项目目录
  python3 app.py    → 在 Linux 环境测试
  测试通过！

步骤 3：在窗口 3 部署
  前缀+3 → 切到服务器
  cd /opt/myapp
  git pull           → 拉最新代码
  systemctl restart myapp  → 重启服务

全程不用切换任何窗口/App，全在一个终端里完成。
```

### 8.5 进阶：服务器上也用 tmux（双层 tmux）

当你 SSH 到服务器，服务器上也有 tmux 时：

```
你的 Mac tmux（前缀 Ctrl-a）
└── 窗口 3：ssh myserver
    └── 服务器上的 tmux（前缀也是 Ctrl-a）
```

怎么区分哪个 tmux 收到指令？
- **按一次** Ctrl-a → 发给 Mac 上的 tmux
- **按两次** Ctrl-a Ctrl-a → 发给服务器上的 tmux

例如：
```
Ctrl-a + c    → 在 Mac 的 tmux 里新建窗口
Ctrl-a Ctrl-a + c  → 在服务器的 tmux 里新建窗口
```

### 8.6 进阶：同时管理多个 Docker 容器

```bash
# 窗口 1：主应用
docker run -it --name app -v $(pwd):/app python:3.11 bash

# 前缀+c 新建窗口 2：数据库
docker run -d --name db -p 5432:5432 -e POSTGRES_PASSWORD=123 postgres

# 前缀+c 新建窗口 3：Redis
docker run -d --name redis -p 6379:6379 redis

# 在窗口之间切换
前缀+1  → 回到应用容器
前缀+2  → 看数据库日志：docker logs -f db
前缀+3  → 看 Redis 日志：docker logs -f redis
```

---

## 9. 第八课：把你的配置同步到 GitHub

### 9.1 为什么要同步

- 换电脑不用重新配置
- 服务器上也能用同一套配置
- 改坏了可以回退

### 9.2 修改配置后推送

```bash
# 比如你刚改了 tmux 配置
# 第一步：进入仓库
cd ~/Dotsfile_ALL

# 第二步：看看改了什么
git status
git diff

# 第三步：提交并推送
git add -A
git commit -m "update: 修改了tmux的分屏快捷键"
git push
```

### 9.3 在另一台机器上拉取更新

```bash
cd ~/Dotsfile_ALL
git pull

# 让 tmux 重载
# 在 tmux 里按 前缀+r

# Neovim 重启就行
```

---

## 10. 第九课：在新机器上一键恢复环境

### 10.1 全新 Mac

```bash
# 安装 Xcode 命令行工具（如果没装过）
xcode-select --install

# 克隆并安装
git clone https://github.com/MMMchou/Dotsfile_ALL.git ~/Dotsfile_ALL
cd ~/Dotsfile_ALL
chmod +x install.sh
./install.sh

# 填入你的 API Key
cp shell/.shell_env.example ~/.shell_env
nano ~/.shell_env    # 修改里面的值
source ~/.shell_env
```

### 10.2 远程 Linux 服务器（精简版）

```bash
# 装工具（Ubuntu/Debian）
sudo apt update && sudo apt install -y git tmux neovim

# 装工具（CentOS/RHEL）
sudo yum install -y git tmux neovim

# 克隆配置
git clone https://github.com/MMMchou/Dotsfile_ALL.git ~/Dotsfile_ALL

# 链接 tmux 和 nvim 配置
ln -sf ~/Dotsfile_ALL/tmux/.tmux.conf ~/.tmux.conf
mkdir -p ~/.config
ln -sf ~/Dotsfile_ALL/nvim ~/.config/nvim

# 安装 TPM
git clone --depth 1 https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

# 进入 tmux，按 Ctrl-a + I 安装插件
tmux
# 打开 nvim，自动安装插件
nvim
```

### 10.3 OrbStack Linux 虚拟机

```bash
# 进入你的 Linux 机器
orb -m dev

# 因为文件共享，直接用 Mac 上的配置
sudo apt update && sudo apt install -y git tmux neovim
ln -sf /mnt/mac/Users/mac/Dotsfile_ALL/tmux/.tmux.conf ~/.tmux.conf
mkdir -p ~/.config
ln -sf /mnt/mac/Users/mac/Dotsfile_ALL/nvim ~/.config/nvim
git clone --depth 1 https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
```

---

## 11. 第十课：日常训练计划（21天养成习惯）

### 第 1 周：基础肌肉记忆

| 天 | 目标 | 练什么 |
|----|------|--------|
| 1 | AeroSpace 基础 | 用 Alt+h/j/k/l 切换窗口，用 Alt+1-9 切桌面，全天不用鼠标切窗口 |
| 2 | tmux 基础 | 创建会话、分屏、切换面板。试试断开再恢复 |
| 3 | Neovim 存活 | 用 nvim 打开文件，i 编辑，Esc 回来，:wq 保存退出。反复练 10 次 |
| 4 | Neovim 移动 | 全天用 nvim 编辑文件，只用 hjkl 移动，不用方向键 |
| 5 | 组合练习 | tmux 分屏：左边 nvim 写代码，右边跑命令 |
| 6 | OrbStack | 创建 Linux 机器，进去装 tmux，练分屏 |
| 7 | 回顾 | 不看教程，凭记忆完成：开 tmux → 分屏 → nvim 编辑 → 保存退出 |

### 第 2 周：效率提升

| 天 | 目标 | 练什么 |
|----|------|--------|
| 8 | tmux 多窗口 | 创建 3 个窗口，分别命名，用 前缀+1/2/3 切换 |
| 9 | Neovim 搜索 | 用 空格+ff 搜文件，空格+fg 搜内容，空格+e 文件树 |
| 10 | Neovim 编辑 | 练习 dd/yy/p 删除复制粘贴，u 撤销 |
| 11 | SSH | 在 config 里添加一台服务器，用别名连接 |
| 12 | 服务器 tmux | SSH 到服务器，在服务器上用 tmux |
| 13 | Docker | 用 docker run 跑一个容器，docker ps 查看，docker stop 停止 |
| 14 | 回顾 | 完成一个完整流程：Mac 写代码 → OrbStack 测试 → SSH 部署 |

### 第 3 周：融会贯通

| 天 | 目标 | 练什么 |
|----|------|--------|
| 15 | 多环境切换 | tmux 里三个窗口分别连：本地、Linux VM、远程服务器 |
| 16 | Neovim 进阶 | 练习 空格+gg 打开 lazygit，gcc 注释代码 |
| 17 | Git 同步 | 修改一个配置 → git add/commit/push → 另一台机器 git pull |
| 18 | Docker 项目 | 用 docker compose 跑一个多容器项目 |
| 19 | 全流程模拟 | 模拟"新机器部署"：删除配置 → 用 install.sh 恢复 |
| 20 | 自定义 | 改一个你想改的配置（tmux 快捷键 / nvim 插件 / AeroSpace 桌面规则） |
| 21 | 毕业 | 不看任何文档，完成：开机 → tmux → 写代码 → 测试 → 部署 → git push |

### 每天 5 分钟速练（养成后）

```
1. 打开终端
2. tmux new -s practice
3. 前缀+| 分屏
4. 左边 nvim，打开一个文件，编辑几行，保存
5. 右边跑一条命令
6. 前缀+d 断开
7. tmux attach -t practice 恢复
8. exit 退出
```

---

## 12. 附录：遇到问题怎么办

### "我按了快捷键没反应"

```
1. 确认你在对的模式：
   - AeroSpace 快捷键：在任何地方都能用
   - tmux 快捷键：必须在 tmux 里面
   - Neovim 快捷键：必须在 nvim 里面，且在 Normal 模式

2. tmux 前缀键是 Ctrl+a，不是 Ctrl+b（我们改过了）

3. 确认 tmux 配置已加载：
   在 tmux 里按 Ctrl-a + r 重载
```

### "Neovim 打开全是报错"

```bash
# 重新同步插件
nvim --headless "+Lazy! sync" +qa

# 如果还不行，清空重来
rm -rf ~/.local/share/nvim
nvim    # 重新自动安装
```

### "SSH 连不上服务器"

```bash
# 检查网络
ping 服务器IP

# 用详细模式看哪一步卡住了
ssh -vvv 别名

# 常见原因：
# - 服务器防火墙没开 22 端口
# - 公钥没传到服务器
# - config 里的 HostName/User/Port 写错了
```

### "Docker 命令不存在"

```bash
# 确认 OrbStack 已打开
open -a OrbStack

# 等几秒后重试
docker ps
```

### "tmux 里颜色不对 / 显示乱码"

```bash
# 确认终端支持 256 色
echo $TERM
# 应该是 xterm-256color 或 screen-256color

# 在 tmux 外面跑
export TERM=xterm-256color
tmux
```

### "GitHub push 不上去"

```bash
# 确认登录了
gh auth status

# 如果没登录
HTTPS_PROXY=http://127.0.0.1:33210 gh auth login --web

# push 时加代理
HTTPS_PROXY=http://127.0.0.1:33210 git push
```

---

> 有任何问题，可以在 Cursor 里问 AI 助手，或者查看 README.md 里的快捷键速查表。
> 祝你早日成为终端高手！

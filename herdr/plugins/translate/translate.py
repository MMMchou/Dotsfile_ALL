#!/usr/bin/env python3
"""herdr 本地翻译插件：翻译剪贴板里的文字（herdr 里鼠标选中即复制）。

- 英文等外文 -> 简体中文；主要是中文 -> 英文
- 走 Google 翻译网页接口（translate.googleapis.com，免 key）
  注意：选中的文字会发给 Google，别拿它翻译密码、密钥等敏感内容
- 代理：沿用环境里的 https_proxy；没有的话，本机 127.0.0.1:33210 开着就自动用
"""
import json
import os
import socket
import subprocess
import sys
import textwrap
import urllib.parse

PROXY_HOST, PROXY_PORT = "127.0.0.1", 33210
MAX_CHARS = 4000


def clipboard() -> str:
    try:
        return subprocess.run(["pbpaste"], capture_output=True, text=True, timeout=3).stdout.strip()
    except Exception:
        return ""


def cjk_ratio(s: str) -> float:
    letters = [c for c in s if c.isalpha()]
    if not letters:
        return 0.0
    cjk = sum(1 for c in letters if "\u4e00" <= c <= "\u9fff")
    return cjk / len(letters)


def proxy_url():
    proxy = os.environ.get("https_proxy") or os.environ.get("HTTPS_PROXY")
    if proxy:
        return proxy
    try:
        with socket.create_connection((PROXY_HOST, PROXY_PORT), timeout=0.3):
            return f"http://{PROXY_HOST}:{PROXY_PORT}"
    except OSError:
        return None


def translate(text: str, target: str) -> str:
    # 用 curl 而不是 urllib：Google 会对 Python 的 TLS 指纹返回 429
    query = urllib.parse.urlencode({"client": "gtx", "sl": "auto", "tl": target, "dt": "t", "q": text})
    url = "https://translate.googleapis.com/translate_a/single?" + query
    cmd = ["curl", "-fsS", "-m", "10", url]
    proxy = proxy_url()
    if proxy:
        cmd[1:1] = ["-x", proxy]
    out = subprocess.run(cmd, capture_output=True, text=True, timeout=15)
    if out.returncode != 0:
        raise RuntimeError(out.stderr.strip() or f"curl exit {out.returncode}")
    data = json.loads(out.stdout)
    return "".join(seg[0] for seg in data[0] if seg and seg[0])


def show(title: str, body: str, width: int) -> None:
    print(f"\033[1;38;2;203;166;247m{title}\033[0m")  # catppuccin mauve
    for para in body.splitlines() or [""]:
        print(textwrap.fill(para, width=width) if para else "")
    print()


def wait_key() -> None:
    print("\033[38;2;127;132;156m按任意键关闭\033[0m", end="", flush=True)
    try:
        import termios
        import tty
        fd = sys.stdin.fileno()
        old = termios.tcgetattr(fd)
        try:
            tty.setraw(fd)
            sys.stdin.read(1)
        finally:
            termios.tcsetattr(fd, termios.TCSADRAIN, old)
    except Exception:
        input()


def main() -> None:
    width = max(20, (os.get_terminal_size().columns if sys.stdout.isatty() else 80) - 2)
    text = clipboard()
    if not text:
        show("没有可翻译的内容", "先用鼠标选中（或复制）一段文字，再按 Ctrl+a t。", width)
        return wait_key()
    if len(text) > MAX_CHARS:
        text = text[:MAX_CHARS]
    target = "en" if cjk_ratio(text) > 0.3 else "zh-CN"
    try:
        result = translate(text, target)
    except Exception as e:  # 网络/代理问题
        show("翻译失败", f"{type(e).__name__}: {e}\n检查代理（proxy_status）或网络后再试。", width)
        return wait_key()
    show("原文", text, width)
    show("译文" if target == "zh-CN" else "Translation", result, width)
    wait_key()


if __name__ == "__main__":
    main()

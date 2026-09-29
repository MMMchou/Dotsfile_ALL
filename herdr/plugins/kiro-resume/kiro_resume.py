#!/usr/bin/env python3
"""Herdr plugin: remember the Kiro CLI session in each pane and resume it after a restart.

Commands:
  sync     scan panes, map each Kiro pane to its live Kiro session, save state
  restore  after server restore, run `kiro-cli chat --resume-id <id>` in each saved pane
  status   print saved state

How a pane is mapped to a session:
  Kiro writes ~/.kiro/sessions/cli/<session_id>.lock = {"pid": <kiro-cli-chat acp pid>, ...}
  while a session is active. We walk that pid's parent chain; if it reaches the pane's
  shell pid (from `herdr pane process-info`), that session belongs to the pane.
"""

import fcntl
import json
import os
import shlex
import subprocess
import sys
import time
from datetime import datetime, timezone

HERDR = os.environ.get("HERDR_BIN_PATH") or "herdr"
STATE_DIR = os.environ.get("HERDR_PLUGIN_STATE_DIR") or os.path.expanduser(
    "~/.local/state/herdr-kiro-resume"
)

# Plugin state is global, but pane ids (w1:p1 ...) are per Herdr session, so keep one
# state file per Herdr session, keyed by its socket path.
def _session_key():
    sock = os.environ.get("HERDR_SOCKET_PATH", "")
    parent = os.path.basename(os.path.dirname(sock))
    # default session lives directly in ~/.config/herdr, named ones in .../sessions/<name>
    if os.path.basename(os.path.dirname(os.path.dirname(sock))) == "sessions" and parent:
        return parent
    return "default"


STATE_FILE = os.path.join(STATE_DIR, f"sessions-{_session_key()}.json")
LOCK_FILE = os.path.join(STATE_DIR, ".lock")
LOG_FILE = os.path.join(STATE_DIR, "kiro-resume.log")
KIRO_SESSIONS_DIR = os.path.expanduser(
    os.environ.get("KIRO_RESUME_SESSIONS_DIR", "~/.kiro/sessions/cli")
)
KIRO_CMD = os.environ.get("KIRO_RESUME_CMD", "kiro-cli")

# An entry whose Kiro process disappeared while the pane still exists is kept for this
# long before being forgotten. Protects against wiping state while the server shuts down
# (Kiro dies a moment before the server does).
GONE_GRACE_SECONDS = 20
# Flags from the original `kiro-cli` command line that are safe to replay on resume.
# Positional prompts are deliberately NOT replayed (they would be sent again).
FLAGS_WITH_VALUE = {"--agent", "--effort", "--trust-tools"}
FLAGS_BOOL = {"-a", "--trust-all-tools"}
SHELLS = {"bash", "zsh", "fish", "sh", "dash", "ksh", "tcsh", "csh", "nu", "-bash", "-zsh", "-fish", "-sh"}


def now_iso():
    return datetime.now(timezone.utc).isoformat()


def log(msg):
    os.makedirs(STATE_DIR, exist_ok=True)
    with open(LOG_FILE, "a") as f:
        f.write(f"{now_iso()} {msg}\n")


def herdr(*args, timeout=10):
    """Run a herdr CLI command and return its `result` object, or None on failure."""
    try:
        p = subprocess.run(
            [HERDR, *args], capture_output=True, text=True, timeout=timeout
        )
    except (OSError, subprocess.TimeoutExpired) as e:
        log(f"herdr {' '.join(args)} failed: {e}")
        return None
    if p.returncode != 0:
        log(f"herdr {' '.join(args)} exit {p.returncode}: {p.stderr.strip()[:300]}")
        return None
    try:
        return json.loads(p.stdout).get("result")
    except ValueError:
        return {}


def list_panes():
    res = herdr("pane", "list")
    if res is None or "panes" not in res:
        return None
    return {p["pane_id"]: p for p in res["panes"]}


def process_info(pane_id):
    res = herdr("pane", "process-info", "--pane", pane_id)
    return (res or {}).get("process_info")


def ps_table():
    """pid -> (ppid, command)"""
    out = subprocess.run(
        ["ps", "-axo", "pid=,ppid=,command="], capture_output=True, text=True
    ).stdout
    table = {}
    for line in out.splitlines():
        parts = line.strip().split(None, 2)
        if len(parts) >= 2 and parts[0].isdigit() and parts[1].isdigit():
            table[int(parts[0])] = (int(parts[1]), parts[2] if len(parts) > 2 else "")
    return table


def ancestors(pid, table):
    chain = []
    seen = set()
    while pid in table and pid not in seen and pid > 1:
        seen.add(pid)
        chain.append(pid)
        pid = table[pid][0]
    return chain


def live_kiro_locks(table):
    """[(session_id, pid, started_at)] for lock files owned by a running kiro-cli-chat."""
    locks = []
    try:
        names = os.listdir(KIRO_SESSIONS_DIR)
    except OSError:
        return locks
    for name in names:
        if not name.endswith(".lock"):
            continue
        try:
            with open(os.path.join(KIRO_SESSIONS_DIR, name)) as f:
                data = json.load(f)
            pid = int(data["pid"])
        except (OSError, ValueError, KeyError, TypeError):
            continue
        # Guard against stale locks whose pid was reused by something else.
        if pid in table and "kiro-cli-chat" in table[pid][1]:
            locks.append((name[: -len(".lock")], pid, data.get("started_at", "")))
    return locks


def kiro_args(info):
    """Replayable flags from the pane's original `kiro-cli ...` command line."""
    argv = None
    for proc in info.get("foreground_processes", []):
        if proc.get("pid") == info.get("foreground_process_group_id"):
            argv = proc.get("argv")
    if not argv or "kiro" not in os.path.basename(argv[0]):
        return []
    out, i = [], 1
    while i < len(argv):
        a = argv[i]
        key = a.split("=", 1)[0]
        if key in FLAGS_WITH_VALUE:
            if "=" in a:
                out.append(a)
            elif i + 1 < len(argv):
                out += [a, argv[i + 1]]
                i += 1
        elif a in FLAGS_BOOL:
            out.append(a)
        i += 1
    return out


def pane_runs_kiro(info):
    return any(
        "kiro-cli" in os.path.basename((p.get("argv") or [p.get("name", "")])[0])
        for p in (info or {}).get("foreground_processes", [])
    )


def load_state():
    try:
        with open(STATE_FILE) as f:
            state = json.load(f)
        if isinstance(state.get("panes"), dict):
            return state
    except (OSError, ValueError):
        pass
    return {"version": 1, "panes": {}}


def save_state(state):
    os.makedirs(STATE_DIR, exist_ok=True)
    tmp = STATE_FILE + ".tmp"
    with open(tmp, "w") as f:
        json.dump(state, f, indent=2, ensure_ascii=False)
    os.replace(tmp, STATE_FILE)


class StateLock:
    def __enter__(self):
        os.makedirs(STATE_DIR, exist_ok=True)
        self.f = open(LOCK_FILE, "w")
        fcntl.flock(self.f, fcntl.LOCK_EX)
        return self

    def __exit__(self, *exc):
        fcntl.flock(self.f, fcntl.LOCK_UN)
        self.f.close()


def event_info():
    """(event_type, pane_id) of the event that triggered this hook, if any."""
    raw = os.environ.get("HERDR_PLUGIN_EVENT_JSON")
    if not raw:
        return os.environ.get("HERDR_PLUGIN_EVENT"), None
    try:
        ev = json.loads(raw)
    except ValueError:
        return os.environ.get("HERDR_PLUGIN_EVENT"), None

    def find(o, key):
        if isinstance(o, dict):
            if key in o and isinstance(o[key], str):
                return o[key]
            for v in o.values():
                r = find(v, key)
                if r:
                    return r
        elif isinstance(o, list):
            for v in o:
                r = find(v, key)
                if r:
                    return r
        return None

    return find(ev, "type") or os.environ.get("HERDR_PLUGIN_EVENT"), find(ev, "pane_id")


def cmd_sync():
    # Kiro writes its lock file a moment after herdr detects it; retry briefly so a
    # freshly started Kiro pane is picked up by the agent_detected event.
    for attempt in range(4):
        missing = _sync_once()
        if not missing:
            return
        time.sleep(2)


def _sync_once():
    """Returns True if some Kiro pane could not be mapped to a session yet."""
    panes = list_panes()
    if panes is None:
        return False  # server unavailable (e.g. shutting down): never touch saved state
    ev_type, ev_pane = event_info()
    missing = False
    table = ps_table()
    locks = live_kiro_locks(table)
    lock_pids = {pid for _, pid, _ in locks}

    found = {}
    for pane_id, pane in panes.items():
        if pane.get("agent") != "kiro":
            continue
        info = process_info(pane_id)
        if not info or not info.get("shell_pid"):
            continue
        shell_pid = info["shell_pid"]
        candidates = []
        for sid, pid, started in locks:
            chain = ancestors(pid, table)
            if shell_pid in chain:
                # depth = number of other kiro sessions above this one (subagents are nested)
                depth = sum(1 for p in chain[1:] if p in lock_pids)
                candidates.append((depth, _neg(started), sid))
        if not candidates:
            missing = True
            continue
        candidates.sort()
        sid = candidates[0][2]
        found[pane_id] = {
            "session_id": sid,
            "cwd": pane.get("foreground_cwd") or pane.get("cwd"),
            "workspace_id": pane.get("workspace_id"),
            "tab_id": pane.get("tab_id"),
            "args": kiro_args(info),
            "updated_at": now_iso(),
        }

    with StateLock():
        state = load_state()
        saved = state["panes"]
        now = time.time()
        for pane_id in list(saved):
            if pane_id in found:
                continue
            entry = saved[pane_id]
            if pane_id not in panes:
                # Pane gone. Only forget it if herdr told us it was closed; otherwise
                # it may just not be restored yet.
                if ev_type == "pane.closed" and ev_pane == pane_id:
                    log(f"forget {pane_id}: pane closed")
                    del saved[pane_id]
                continue
            # Pane exists but no Kiro in it any more.
            if pane_runs_kiro(process_info(pane_id)):
                continue  # Kiro still starting up / lock not written yet
            gone = entry.get("gone_at")
            if gone is None:
                entry["gone_at"] = now
            elif now - gone > GONE_GRACE_SECONDS:
                log(f"forget {pane_id}: kiro exited")
                del saved[pane_id]
        for pane_id, entry in found.items():
            old = saved.get(pane_id, {})
            if old.get("session_id") != entry["session_id"]:
                log(f"map {pane_id} -> {entry['session_id']} ({entry['cwd']})")
            saved[pane_id] = entry
        save_state(state)
    return missing


def _neg(iso):
    # sort newest first when ascending
    return "".join(chr(0x10FFFF - ord(c)) for c in (iso or ""))


def pane_is_idle_shell(info):
    if not info or not info.get("shell_pid"):
        return False
    procs = info.get("foreground_processes") or []
    if not procs:
        return True
    return all(
        os.path.basename(p.get("name") or "").lstrip("-") in {s.lstrip("-") for s in SHELLS}
        for p in procs
    )


def cmd_restore():
    with StateLock():
        state = load_state()
    saved = state["panes"]
    if not saved:
        return

    # Wait for the restored panes (and their shells) to come up.
    deadline = time.time() + 60
    panes = None
    while time.time() < deadline:
        panes = list_panes()
        if panes and any(pid in panes for pid in saved):
            break
        time.sleep(1)
    if not panes:
        log("restore: no panes available, giving up")
        return

    for pane_id, entry in sorted(saved.items()):
        pane = panes.get(pane_id)
        if not pane:
            log(f"restore skip {pane_id}: pane not present")
            continue
        cwd = pane.get("cwd")
        if entry.get("cwd") and cwd and os.path.realpath(cwd) != os.path.realpath(entry["cwd"]):
            log(f"restore skip {pane_id}: cwd {cwd} != saved {entry['cwd']}")
            continue
        sid = entry["session_id"]
        if not os.path.exists(os.path.join(KIRO_SESSIONS_DIR, sid + ".json")):
            log(f"restore skip {pane_id}: session {sid} no longer exists")
            continue

        info = None
        for _ in range(20):  # shell may still be starting
            info = process_info(pane_id)
            if pane_is_idle_shell(info):
                break
            time.sleep(0.5)
        if pane_runs_kiro(info):
            log(f"restore skip {pane_id}: kiro already running")
            continue
        if not pane_is_idle_shell(info):
            log(f"restore skip {pane_id}: pane is busy")
            continue

        cmd = " ".join(
            shlex.quote(a) for a in [KIRO_CMD, "chat", "--resume-id", sid, *entry.get("args", [])]
        )
        if herdr("pane", "run", pane_id, cmd) is not None:
            log(f"restore {pane_id}: {cmd}")
            entry.pop("gone_at", None)


def cmd_status():
    state = load_state()
    if not state["panes"]:
        print("No Kiro sessions saved.")
    for pane_id, e in sorted(state["panes"].items()):
        flag = "  (exited)" if "gone_at" in e else ""
        print(f"{pane_id:10} {e['session_id']}  {e.get('cwd')}  {' '.join(e.get('args', []))}{flag}")
    print(f"\nstate: {STATE_FILE}\nlog:   {LOG_FILE}")


def main():
    cmd = sys.argv[1] if len(sys.argv) > 1 else "status"
    try:
        {"sync": cmd_sync, "restore": cmd_restore, "status": cmd_status}[cmd]()
    except KeyError:
        print(f"unknown command: {cmd}", file=sys.stderr)
        sys.exit(2)
    except Exception as e:  # never crash noisily inside herdr hooks
        log(f"{cmd} error: {e!r}")
        raise


if __name__ == "__main__":
    main()

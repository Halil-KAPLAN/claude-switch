#!/usr/bin/env bash
# claude-switch installer — works on Linux, WSL and Windows (Git Bash).
#
#   ./install.sh     installs the ~/.local/bin/cs command and adds
#                    respondToBashCommands=false and the cs hooks to ~/.claude/settings.json.
#
# Safe to re-run: it leaves existing settings alone and never duplicates hooks.
# The installed 'cs' is a small shim that calls bin/cs in this repo; 'git pull' is enough to update.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$REPO_DIR/bin/cs"
BIN_DIR="$HOME/.local/bin"
CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
SETTINGS="$CLAUDE_DIR/settings.json"
STAMP="$(date +%Y%m%d-%H%M%S)"

ok()   { printf '\033[32m✓\033[0m %s\n' "$*"; }
warn() { printf '\033[33m!\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[31merror:\033[0m %s\n' "$*" >&2; exit 1; }

case "$(uname -s)" in
  MINGW*|MSYS*|CYGWIN*) WINDOWS=1 ;;
  *)                    WINDOWS=0 ;;
esac

PY=""
for p in python3 python; do
  if command -v "$p" >/dev/null 2>&1 && "$p" -c 'import sys; sys.exit(sys.version_info < (3, 6))' 2>/dev/null; then
    PY="$p"; break
  fi
done
[ -n "$PY" ] || die "python3 not found — cs needs it"
[ -f "$SRC" ] || die "$SRC not found"
chmod +x "$SRC" 2>/dev/null || true
mkdir -p "$BIN_DIR" "$CLAUDE_DIR"

# --- 1) ~/.local/bin/cs shim ----------------------------------------------------
SHIM="$BIN_DIR/cs"
SHIM_BODY="#!/usr/bin/env bash
# claude-switch shim — actual script: $SRC
exec bash \"$SRC\" \"\$@\""

if [ -e "$SHIM" ] && ! grep -q '^# claude-switch shim' "$SHIM" 2>/dev/null; then
  mv "$SHIM" "$SHIM.bak-$STAMP"
  warn "backed up the old cs: $SHIM.bak-$STAMP"
fi
printf '%s\n' "$SHIM_BODY" > "$SHIM"
chmod +x "$SHIM"
ok "installed cs: $SHIM → $SRC"

# --- 2) Windows: cs.cmd so it also works from PowerShell/cmd --------------------
if [ "$WINDOWS" = 1 ]; then
  GIT_ROOT="$(cygpath -w /)"
  BASH_EXE="${GIT_ROOT%\\}\\bin\\bash.exe"
  [ -f "$(cygpath -u "$BASH_EXE")" ] || BASH_EXE="$(cygpath -w "$(command -v bash)")"
  printf '@"%s" "%s" %%*\r\n' "$BASH_EXE" "$(cygpath -w "$SRC")" > "$BIN_DIR/cs.cmd"
  ok "installed cs.cmd: $BIN_DIR/cs.cmd"
fi

# --- 3) settings.json: respondToBashCommands + hooks ----------------------------
PYTHONUTF8=1 "$PY" - "$SETTINGS" "$STAMP" <<'PY'
import json, os, re, shutil, sys

path, stamp = sys.argv[1], sys.argv[2]
cfg = {}
if os.path.exists(path):
    with open(path, encoding="utf-8") as f:
        text = f.read().strip()
    cfg = json.loads(text) if text else {}

changed = []
if cfg.get("respondToBashCommands") is not False:
    cfg["respondToBashCommands"] = False
    changed.append("respondToBashCommands=false")

CS = '"$HOME/.local/bin/cs"'
WANT = [
    ("SessionStart", "autosync", {"command": f"{CS} autosync", "timeout": 10}),
    ("SessionStart", "prune",    {"command": f"{CS} prune --apply >/dev/null 2>&1 || true", "timeout": 15}),
    ("SessionEnd",   "autosync", {"command": f"{CS} autosync", "timeout": 10}),
    ("Stop",         "autosync", {"command": f"{CS} autosync", "timeout": 10, "async": True}),
]

hooks = cfg.setdefault("hooks", {})
for event, sub, spec in WANT:
    groups = hooks.setdefault(event, [])
    # Skip it if "cs <sub>" is already called from any path (old absolute paths included)
    pat = re.compile(r'(^|[/"\s])cs"?\s+' + sub + r'\b')
    exists = any(pat.search(h.get("command", ""))
                 for g in groups for h in g.get("hooks", []))
    if exists:
        continue
    target = next((g for g in groups if "matcher" not in g), None)
    if target is None:
        target = {"hooks": []}
        groups.append(target)
    target.setdefault("hooks", []).append({"type": "command", **spec})
    changed.append(f"hook {event}: cs {sub}")

if changed:
    # Back up only when something actually changes, so re-running doesn't pile up copies
    if os.path.exists(path):
        shutil.copy2(path, f"{path}.bak-{stamp}")
    tmp = path + ".tmp"
    with open(tmp, "w", encoding="utf-8") as f:
        json.dump(cfg, f, indent=2, ensure_ascii=False)
        f.write("\n")
    os.replace(tmp, path)
    for c in changed:
        print(f"  + {c}")
else:
    print("  (settings.json is already up to date)")
PY
ok "settings.json: $SETTINGS"

# --- 4) PATH check --------------------------------------------------------------
case ":$PATH:" in
  *":$BIN_DIR:"*) ;;
  *) warn "$BIN_DIR is not on your PATH — add this to your shell profile: export PATH=\"\$HOME/.local/bin:\$PATH\"" ;;
esac

echo
ok "installation complete. Restart any open Claude sessions, then:"
echo "    !cs add <name>    # save the currently logged-in account"
echo "    !cs status"

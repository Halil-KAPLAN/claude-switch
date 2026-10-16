# claude-switch

A small tool for switching between multiple Claude Code accounts with `!cs`, right inside a Claude Code session.
Works on Linux, WSL and Windows (Git Bash).

```
!cs status          show the active account and token status of all accounts
!cs add <name>      save the currently logged-in account as <name>
!cs use <name>      switch to <name>
!cs sync            write the active credentials back to their slot
!cs rm <name>       delete an account
!cs restore         restore the latest backup
!cs prune           remove !cs traces from history (with --apply)
!cs help            list all commands
```

## Installation

Requirements: `git`, `bash`, `python3`. On Windows: [Git for Windows](https://git-scm.com/download/win) (Git Bash) and Python.

```bash
git clone <repo-url> ~/claude-switch      # on Windows, run this in Git Bash
~/claude-switch/install.sh
```

The installer:

1. Installs `~/.local/bin/cs`, a small shim that calls `bin/cs` in this repo
   (plus `cs.cmd` on Windows, so it also works from PowerShell/cmd).
2. Adds the following to `~/.claude/settings.json` (other settings are left untouched; a `.bak-*` backup is taken first):
   - `"respondToBashCommands": false`, so the model doesn't reply after a `!cs` command
   - Hooks: `cs autosync` at session start/end and after every response
     (writes refreshed tokens back to the account's slot), and `cs prune --apply` at startup.

Running it again is safe; hooks are never duplicated. Restart any open Claude Code sessions afterwards.

## Adding accounts on a new machine

Credentials are **not** stored in this repo and never should be. Add your accounts once on each machine:

```
/login              # log in with the first account
!cs add work
/login              # log in with the second account
!cs add personal
!cs use work
```

**Don't copy** `~/.claude/accounts/` between machines: refresh tokens rotate on every refresh,
so if two machines share a slot, one will log the other out.

## Updating

```bash
cd ~/claude-switch && git pull
```

The shim calls the script in the repo directly, so there's no need to reinstall.
If you move the repo to a different folder, run `install.sh` again.

## Uninstalling

```bash
rm ~/.local/bin/cs ~/.local/bin/cs.cmd
```

Then remove the `respondToBashCommands` line and the hooks that call `cs` from `~/.claude/settings.json`.

# claude-switch

A small tool for switching between multiple Claude Code accounts with `!cs`, right inside a Claude Code session.
Works on Linux, WSL and Windows (Git Bash).

> [!NOTE]
> **Unofficial, not affiliated with Anthropic.** This tool works by editing Claude Code's internal,
> undocumented files (`~/.claude/.credentials.json` and the `oauthAccount` block in `~/.claude.json`),
> so it may break with Claude Code updates.

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
2. Adds the following to `~/.claude/settings.json` (other settings are left untouched; a `.bak-*` backup is taken first, only if something changes):
   - `"respondToBashCommands": false`, so the model doesn't reply after a `!cs` command
   - Hooks: `cs autosync` at session start/end and after every response
     (writes refreshed tokens back to the account's slot), and `cs prune --apply` at startup
     (see [Cleaning up `!cs` traces](#cleaning-up-cs-traces)).

Running it again is safe; hooks are never duplicated. Restart any open Claude Code sessions afterwards.

To update, just `git pull` — the shim runs the script from the repo, so no reinstall is needed.
If you move the repo, run `install.sh` again.

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

## After switching accounts

A running Claude Code session keeps using the account it started with, so restart it after `!cs use`:

- **Terminal:** exit Claude Code and start `claude` again.
- **VS Code extension:** press `Ctrl+Shift+P` (`Cmd+Shift+P` on macOS) and run **Developer: Reload Window**.

## Cleaning up `!cs` traces

> [!IMPORTANT]
> **By installing claude-switch you accept that your `!cs` commands are permanently deleted from Claude Code's history.**
> Nothing is backed up and the deletion cannot be undone.

Every `!cs` command ends up in Claude Code's prompt history, and a session where you only ran `!cs`
shows up in the session list. The installer adds a `cs prune --apply` hook that runs at every startup and:

- deletes lines starting with `!cs` from `~/.claude/history.jsonl` (the up-arrow history);
- deletes session files in `~/.claude/projects/` that contain **nothing but** `!cs` commands.
  Sessions with any real conversation, the current session, and sessions written in the last 2 minutes are never touched.

No backups are kept on purpose: the hook runs on every startup, so backups would pile up endlessly.
Run `cs prune` without `--apply` to see what would be deleted. If you don't want this,
delete the `cs prune` hook from `~/.claude/settings.json`.

## Uninstalling

```bash
rm ~/.local/bin/cs ~/.local/bin/cs.cmd
```

Then remove the `respondToBashCommands` line and the hooks that call `cs` from `~/.claude/settings.json`.

## License

[MIT](LICENSE)

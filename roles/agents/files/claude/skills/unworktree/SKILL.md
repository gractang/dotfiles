---
name: unworktree
description: >
  Tear down a worktree created by `/worktree`: kill the matching tmux session,
  remove the git worktree at `.worktrees/<branch-name>`, and clean up empty
  parent directories. Triggered when the user types `/unworktree <branch-name>`.
disable-model-invocation: true
---

# Worktree Teardown

Invoked as `/unworktree <branch-name> [--force] [--delete-branch]`. Inverse of `/worktree`: kills the tmux session, removes the worktree, and optionally deletes the local branch.

Assumes the worktree lives at `.worktrees/<branch-name>` (the layout `/worktree` creates). Does not touch the remote branch.

## Workflow

### 1. Parse the args

- **Arg 1 (required)**: branch name. If missing, ask.
- **`--force`** (optional): allow removing a dirty worktree (passes `--force` to `git worktree remove`). Off by default — we don't want to silently discard uncommitted work.
- **`--delete-branch`** (optional): also delete the local branch after removing the worktree. Off by default.

### 2. Verify preconditions

```bash
git rev-parse --show-toplevel >/dev/null            # inside a git repo
```

Resolve paths:

```bash
REPO_ROOT=$(git rev-parse --show-toplevel)
BRANCH=<branch-name>
WORKTREE_PATH="$REPO_ROOT/.worktrees/$BRANCH"
```

### 3. Discover the tmux session(s) to kill

The session name is not always `$BRANCH` — `/hack` renames sessions based on the Linear ticket title, so you can end up with a session named e.g. `hex-dev:user-auth` attached to a worktree named `gtang/aip-123-user-auth`. Find sessions by **path**, not just by name.

```bash
# Sessions matching the branch name exactly
NAME_MATCHES=$(tmux has-session -t "$BRANCH" 2>/dev/null && echo "$BRANCH")

# Sessions with any pane whose current path is inside the worktree
PATH_MATCHES=$(tmux list-panes -a -F '#{session_name}|#{pane_current_path}' 2>/dev/null \
  | awk -F'|' -v wt="$WORKTREE_PATH" '$2 == wt || index($2, wt"/") == 1 { print $1 }' \
  | sort -u)

SESSIONS_TO_KILL=$(printf '%s\n%s\n' "$NAME_MATCHES" "$PATH_MATCHES" | awk 'NF' | sort -u)
```

`pane_current_path` reflects the shell's cwd, so a session the user `cd`'d away from won't match. That's acceptable — prefer a false negative (leaves a session alive) over a false positive (kills an unrelated session).

### 4. Check state before destroying anything

Surface these to the user *before* doing any destructive work, and bail with a clear message if something looks risky:

- **Worktree exists?** If `$WORKTREE_PATH` is missing and the branch has no matching `git worktree list` entry, skip the worktree step but still kill any discovered tmux sessions and (if requested) the branch.
- **Currently attached to one of the target sessions?** If `tmux display-message -p '#S'` is in `$SESSIONS_TO_KILL`, bail — ask the user to detach or switch first. Don't kill the session you're sitting in.
- **Dirty worktree?** Run `git -C "$WORKTREE_PATH" status --porcelain`. If non-empty and `--force` was not passed, bail and show what's dirty.
- **Unpushed commits?** Run `git -C "$WORKTREE_PATH" log @{u}.. --oneline 2>/dev/null`. If non-empty, warn but don't block unless `--delete-branch` was also passed — we're only removing the worktree, not the branch.

### 5. Kill the tmux session(s)

Kill every session in `$SESSIONS_TO_KILL`. Report each one so the user sees what was cleaned up, especially when the session name didn't match the branch:

```bash
if [ -n "$SESSIONS_TO_KILL" ]; then
  while IFS= read -r sess; do
    tmux kill-session -t "$sess" && echo "killed: $sess"
  done <<< "$SESSIONS_TO_KILL"
else
  echo "no tmux sessions found for $BRANCH"
fi
```

Skip silently if no matches. If tmux isn't running at all, the discovery step in §3 returns empty — no-op.

### 6. Remove the worktree

```bash
if [ -d "$WORKTREE_PATH" ] || git worktree list --porcelain | grep -q "^worktree $WORKTREE_PATH$"; then
  if [ "$FORCE" = "1" ]; then
    git worktree remove --force "$WORKTREE_PATH"
  else
    git worktree remove "$WORKTREE_PATH"
  fi
fi
```

If `git worktree remove` fails because the path is missing from disk but still registered, fall back to `git worktree prune` and report it.

### 7. Clean up empty parent directories

Branches often have a prefix like `gtang/foo` → worktree at `.worktrees/gtang/foo`. Remove the parent `.worktrees/gtang/` if it's empty after removing the worktree. Stop at `.worktrees/` itself — don't delete that.

```bash
PARENT=$(dirname "$WORKTREE_PATH")
while [ "$PARENT" != "$REPO_ROOT/.worktrees" ] && [ -d "$PARENT" ] && [ -z "$(ls -A "$PARENT")" ]; do
  rmdir "$PARENT"
  PARENT=$(dirname "$PARENT")
done
```

### 8. Optionally delete the local branch

Only if `--delete-branch` was passed:

```bash
git -C "$REPO_ROOT" branch -d "$BRANCH"
```

Use `-d` (not `-D`) — it refuses to delete unmerged branches. If the user wants to force it anyway, they can run `git branch -D <name>` themselves; don't add a flag for that here. This skill shouldn't be the thing that loses their work.

### 9. Confirm to the user

```
Torn down.

  Branch:   <branch-name> (kept / deleted)
  Worktree: removed (.worktrees/<branch-name>)
  Sessions: killed: <name1>, <name2> / not running
```

Name each session explicitly — when the session name doesn't match the branch (e.g. renamed by `/hack`), the user needs to see what got killed to trust the skill.

## Error Handling

- **Missing branch arg**: ask the user.
- **Attached to one of the target sessions**: refuse — ask them to switch away (`<prefix> s`) first.
- **Dirty worktree without `--force`**: bail, show `git status --porcelain` output, suggest either committing or re-running with `--force`.
- **`git worktree remove` fails with "not a working tree"**: run `git worktree prune` and report that the registration was stale.
- **`git branch -d` fails (unmerged)**: report clearly, leave the branch in place, suggest `git branch -D` as the manual escape hatch.

## Rules

- Never pass `--force` unless the user explicitly opted in.
- Never use `git branch -D`. Unmerged-branch deletion is the user's call, not the skill's.
- Never touch the remote branch. `git push origin --delete` is out of scope.
- Don't delete `.worktrees/` itself, only empty intermediate parents.
- Report every state change — the user should never have to guess what got cleaned up.

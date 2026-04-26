---
name: worktree
description: >
  Create a git worktree for a branch and launch the generic tmuxinator
  "worktree" config pointed at it. Triggered when the user types
  `/worktree <branch-name> [initial-prompt]` to spin up an isolated
  workspace + tmux session with Claude pre-primed.
disable-model-invocation: true
---

# Worktree Launcher

Invoked as `/worktree <branch-name> [initial-prompt]`. Creates (or reuses) a branch, sets up a worktree under `.worktrees/<branch-name>` in the current repo, and starts the `worktree` tmuxinator config pointed at that path. The left claude pane boots with an initial prompt; the right pane stays idle for ad-hoc use.

Relies on:
- `~/.config/tmuxinator/worktree.yml` — reads `WORKTREE_ROOT`, `CLAUDE_LEFT_CMD`, `CLAUDE_RIGHT_CMD` from env and the session name from the first positional arg.
- `git-town` — for stacking new branches on the current branch.

## Workflow

### 1. Parse the args

- **Arg 1 (required)**: branch name. Expect kebab-case; sanitize if needed (lowercase, hyphens only). If missing, ask the user.
- **Arg 2+ (optional)**: initial prompt for the left claude pane. Join remaining args with spaces so multi-word prompts work without the user quoting.
  - **Absent** → left pane starts bare claude (no initial prompt). This is the default.
  - **Exactly `hack`** (special keyword) → left pane runs `/hack <branch-name>` as its initial message.
  - **Anything else** → left pane runs that prompt literally.

### 2. Verify preconditions

Run these checks and bail with a clear message on failure:

```bash
git rev-parse --show-toplevel >/dev/null            # inside a git repo
git symbolic-ref -q HEAD >/dev/null                 # not detached HEAD
command -v git-town >/dev/null                       # git-town installed
command -v tmuxinator >/dev/null                     # tmuxinator installed (user alias: `t`)
test -f "$HOME/.config/tmuxinator/worktree.yml"      # tmuxinator config present
```

If the working tree is dirty, warn the user but don't block — `git worktree add` will still work.

### 3. Resolve paths and branch state

Resolve `REPO_ROOT` via `--git-common-dir`, not `--show-toplevel`. When the skill is invoked from *inside* a worktree (the common case — launching a child worktree from a parent one), `--show-toplevel` returns the worktree path, which would nest new worktrees inside existing ones. `--git-common-dir` always points at the main repo's `.git`, so its parent is the true repo root.

```bash
REPO_ROOT=$(dirname "$(git rev-parse --path-format=absolute --git-common-dir)")
CURRENT=$(git branch --show-current)
BRANCH=<branch-name>
WORKTREE_PATH="$REPO_ROOT/.worktrees/$BRANCH"
```

Before calling `git town append`, clear any stale runstate (see "Error Handling → stale runstate" below) — otherwise the command will error with `no interactive terminal available` in agent shells:

```bash
if git town status 2>&1 | grep -q "hit a problem"; then
  # git-town slugifies the worktree's toplevel path: lowercase, strip leading /,
  # strip dots, replace / with -. E.g. /Users/foo/hex/.worktrees/gtang/x →
  # users-foo-hex-worktrees-gtang-x
  RUNSTATE_SLUG=$(git rev-parse --show-toplevel | tr '[:upper:]' '[:lower:]' | sed 's|^/||; s|\.||g; s|/|-|g')
  rm -f "$HOME/Library/Application Support/git-town/$RUNSTATE_SLUG/runstate.json"
fi
```

Decide branch strategy based on existing state:

- **Branch does NOT exist** → stack a new branch on current via `git town append`:
  ```bash
  git town append "$BRANCH"
  git checkout "$CURRENT"
  ```
- **Branch already exists** → skip creation; the worktree add below will just check it out.
- **Worktree path already exists** → tell the user and stop. Do not clobber.

### 4. Create the worktree

```bash
mkdir -p "$REPO_ROOT/.worktrees"
git worktree add "$WORKTREE_PATH" "$BRANCH"
```

### 5. Approve direnv in the new worktree

direnv trusts `.envrc` by absolute path, so the repo-root approval doesn't carry over to the worktree. Without this step, panes launched by tmuxinator won't load the devbox environment (no `hdev`, `pnpm`, etc.) until the user manually runs `direnv allow`.

```bash
if command -v direnv >/dev/null && [ -f "$WORKTREE_PATH/.envrc" ]; then
  (cd "$WORKTREE_PATH" && direnv allow)
fi
```

Skip silently if direnv isn't installed or the worktree has no `.envrc`.

### 6. Launch the tmuxinator session

Session name defaults to the branch name. The `worktree.yml` config reads `$WORKTREE_ROOT` for the root dir, `$CLAUDE_LEFT_CMD` / `$CLAUDE_RIGHT_CMD` for each claude pane's startup command, and the first positional arg for the session name.

Build the left pane command based on the prompt arg. The right pane always stays bare (plain `claude`). Use `printf %q` to shell-escape the prompt so spaces, quotes, and slashes survive the ERB → shell round-trip.

```bash
if [ -z "$PROMPT" ]; then
  # Default: bare claude, no initial message
  CLAUDE_LEFT_CMD="claude"
elif [ "$PROMPT" = "hack" ]; then
  # Shortcut: /worktree <branch> hack → run /hack <branch>
  CLAUDE_LEFT_CMD="claude $(printf '%q' "/hack $BRANCH")"
else
  # Literal prompt
  CLAUDE_LEFT_CMD="claude $(printf '%q' "$PROMPT")"
fi

WORKTREE_ROOT="$WORKTREE_PATH" \
  CLAUDE_LEFT_CMD="$CLAUDE_LEFT_CMD" \
  tmuxinator start worktree "$BRANCH"
```

Don't set `CLAUDE_RIGHT_CMD` — the yaml falls back to plain `claude`, which is what we want for the idle pane.

(The user's interactive shell aliases `tmuxinator` → `t`, but aliases don't survive into non-interactive subshells, so always invoke `tmuxinator` directly.)

Attach behavior:
- **Outside tmux**: `tmuxinator start` creates and attaches automatically.
- **Inside tmux**: session is created but you stay in the current client. Tell the user to switch with `<prefix> s` or `tmux switch-client -t <branch-name>`.
- **No TTY (running from a non-interactive agent shell)**: tmuxinator exits with `open terminal failed: not a terminal` *after* creating the session. This is harmless — verify with `tmux ls` and report success.

### 7. Confirm to the user

```
Worktree ready.

  Branch:   <branch-name> (stacked on <current-branch>, or reused existing)
  Worktree: .worktrees/<branch-name>
  Session:  <branch-name>

Switch to it with `<prefix> s` if you're already inside tmux.
```

## Error Handling

- **git-town missing**: `brew install git-town`
- **tmuxinator missing**: `brew install tmuxinator`
- **`worktree.yml` missing**: point the user at `~/.config/tmuxinator/worktree.yml` — it should be tracked in their dotfiles repo under `roles/tmux/files/tmuxinator/`.
- **Worktree path already exists**: stop; let the user remove it (`git worktree remove .worktrees/<branch-name>`) or pick a different name.
- **Detached HEAD**: abort — `git town append` needs a real branch to stack on.
- **Stale runstate** (`git town append` errors with `no interactive terminal available`): a prior failed `git town sync`/similar left a runstate file that makes every subsequent git-town invocation prompt `continue / skip / undo?`. In a TTY that prompt is answerable; in an agent shell it crashes. Each worktree has its own runstate at `~/Library/Application Support/git-town/users-<slugified-git-common-dir>/runstate.json`. `git town status` reports `The last Git Town command (…) hit a problem …` when one exists. Delete the file to clear it — no commits are affected, it's just operation-resume state.

## Rules

- Default to `git town append` for new branches (matches `dispatch-plan` conventions — stacked work over off-master).
- Always checkout back to the original branch after `git town append`.
- Store worktrees in `.worktrees/<branch-name>` for consistency.
- Never overwrite an existing worktree path — surface the conflict instead.
- The tmuxinator session name is the branch name; do not prefix or decorate it.

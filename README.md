# dotfiles

Ansible-based macOS workstation setup. Roles are applied idempotently via a tag-based playbook, with a lockfile tracking which roles have been applied and when.

## Prerequisites

- macOS (Apple Silicon or Intel)
- Git
- A sudo password (prompted at runtime)

Homebrew and Ansible are installed automatically by the bootstrap script if not present.

## Quick Start

```bash
# Clone
git clone git@github.com:gractang/dotfiles.git ~/dotfiles

# Run everything
~/dotfiles/bin/bootstrap

# Run a single role
~/dotfiles/bin/bootstrap git
```

## Management

The `dotfiles` CLI wraps the playbook with state tracking:

```bash
dotfiles apply          # Pull latest, run only changed roles, update lockfile
dotfiles apply neovim   # Apply a single role by tag
dotfiles status         # Show which roles have changed since last apply
dotfiles sync           # Pull then push (no ansible run)
dotfiles lock           # Manually write current role hashes to lockfile
```

State is stored at `~/.dotfiles/lock.json` -- each role's last-applied git commit hash and a timestamp.

## Roles

Roles execute in the order listed below. Each role is independently taggable.

### Tools

| Role | Tag | What it does |
|------|-----|-------------|
| **config** | `config` | Creates `~/.config` directory structure |
| **homebrew** | `homebrew` | Installs Homebrew, detects Apple Silicon vs Intel paths |
| **git** | `git` | Installs `gh`, `gh-dash`, `lazygit`, `git-town`. Symlinks gitconfig and global gitignore. Installs helper scripts to `~/.bin/` |
| **asdf** | `asdf` | Installs asdf version manager via Homebrew |
| **devbox** | `devbox` | Installs Jetify devbox from `get.jetify.com/devbox` (requires sudo) |
| **javascript** | `javascript` | Adds nodejs plugin to asdf, installs `latest` |
| **cli** | `cli` | Installs CLI tools (see list below) and Hack Nerd Font |
| **zsh** | `zsh` | Installs zsh, starship prompt, Oh My Zsh, and plugins (syntax-highlighting, autosuggestions). Symlinks all zsh config to `~/.config/zsh/` |
| **tmux** | `tmux` | Installs tmux, `cms` (ser-ge/tap), tmuxinator, and TPM. Symlinks config to `~/.tmux.conf` and `~/.config/tmux/` |
| **pgcli** | `pgcli` | Symlinks pgcli config to `~/.config/pgcli/config` |
| **mycli** | `mycli` | Symlinks mycli config to `~/.config/mycli/config` |
| **agents** | `agents` | Installs Claude Code (cask) and `@openai/codex` (npm global). Symlinks `~/.claude/` and `~/.codex/` |
| **neovim** | `neovim` | Installs Neovim nightly via asdf (uninstalls previous nightly first). Symlinks LazyVim config to `~/.config/nvim/` |

#### CLI tools installed

`prettyping`, `bat`, `htop`, `fzf`, `git-delta`, `tldr`, `ripgrep`, `gnu-sed`, `pgcli`, `mycli`, `lazydocker`, `lastpass-cli`, `entr`, `yazi`

### Apps

| Role | Tag | What it does |
|------|-----|-------------|
| **apps** | `apps` | Installs casks: Linear, Figma, Brain.fm, OrbStack, Notion |
| **aerospace** | `aerospace` | Installs AeroSpace tiling WM (`nikitabobko/tap`). Symlinks config to `~/.config/aerospace/` |
| **karabiner** | `karabiner` | Installs Karabiner-Elements. Symlinks config to `~/.config/karabiner/`. Remaps Caps Lock to hyper key (Cmd+Ctrl+Alt+Shift); tap alone sends Escape |
| **browsers** | `browsers` | Installs Brave and Zen browsers |
| **kitty** | `kitty` | Installs kitty terminal. Symlinks config and color scheme to `~/.config/kitty/` |
| **ghostty** | `ghostty` | Installs Ghostty terminal. Symlinks config and themes to `~/.config/ghostty/` |
| **sol** | `sol` | Installs Sol launcher, disables Spotlight Cmd+Space shortcut, restarts LaunchServices |

### Desktop

| Role | Tag | What it does |
|------|-----|-------------|
| **sketchybar** | `sketchybar` | Installs sketchybar (`FelixKratz/formulae`), SF Symbols, and SbarLua (compiled from source). Deploys LaunchAgent plist and loads the service. Symlinks Lua config to `~/.config/sketchybar/` |

### System

| Role | Tag | What it does |
|------|-----|-------------|
| **macos** | `macos` | Sets macOS system defaults across 7 subtask files (see below) |

### Language runtimes (via asdf)

| Language | Default version(s) | Notes |
|----------|-------------------|-------|
| Node.js | `latest` | |
| Ruby | `latest:3`, `latest:2` | Global set to latest:3 |
| Lua | `5.4.7` | Pins luarocks `3.12.2` via env var |
| Neovim | `nightly` | Reinstalled fresh each run |

## macOS System Defaults

The `macos` role writes `defaults write` preferences via Ansible's `osx_defaults` module. Values are configured in `roles/macos/defaults/main.yml` and `group_vars/local`. The role triggers handler restarts for affected services (Dock, Finder, SystemUIServer, etc.) when values change.

### Keyboard

- Full keyboard access for all controls
- Fast key repeat rate and short initial delay
- Press-and-hold disabled (prefer key repeat)
- Automatic spelling correction, quote/dash/period substitution configurable
- Power button sleep prevention configurable
- Keyboard brightness dimming in low light

### Screen

- Screenshots saved as PNG to a custom directory
- Screenshot shadow disabled

### Dock

- Persistent apps and folders/stacks are declaratively managed (the dock is cleared and rebuilt)
- Configurable: tile size, magnification, orientation, auto-hide, animation effects
- Show/hide process indicators, recent apps, hidden app dimming

### Finder

- Desktop icons configurable per drive type (internal, external, USB, network)
- View style, grouping, tab/path/status bar visibility
- Icon view settings for both desktop and standard views
- Show all file extensions, sort folders first, show POSIX path in title bar
- Prevent .DS_Store on network and USB volumes

### Energy Saver

- Computer and display sleep times (requires sudo)

### Hot Corners

- Each corner independently configurable with action and modifier key
- Available actions: Mission Control, Desktop, Screen Saver, Launchpad, Notification Center, Put Display to Sleep, etc.

### Trackpad

- Tap to click, three-finger drag, force click, haptic feedback
- Scroll direction, tracking speed, pinch/rotate gestures
- Multi-finger swipe gestures for Mission Control, App Expose, Notification Center

## Shell Aliases

The zsh config sets up several command replacements:

| Command | Replaced by |
|---------|-------------|
| `cat` | `bat` |
| `ping` | `prettyping` |
| `top` | `htop` |
| `man` | `tldr` |
| `vim` / `vi` / `v` | `nvim` |
| `t` | `tmuxinator` |

## Git Configuration

- Default push strategy: current branch
- Pull strategy: rebase
- Pager: delta (side-by-side, line numbers)
- Merge conflict style: diff3
- Fetch prune: enabled
- SSH protocol for hub
- Includes git-town aliases (`append`, `sync`, `propose`, `ship`, etc.)
- Helper scripts: `git cp` (copy branch), `git cleanup` (delete merged), `git stats`, `git merged`

## AeroSpace Window Manager

Tiling WM with vim-style keybindings, all behind the hyper key (`Cmd+Shift+Ctrl+Alt`):

| Binding | Action |
|---------|--------|
| `hyper-h/j/k/l` | Focus left/down/up/right |
| `hyper-m` | Enter move mode (then h/j/k/l to move window) |
| `hyper-r` | Enter resize mode (then h/j/k/l to resize) |
| `hyper-g` | Enter join mode (merge with neighboring window) |
| `hyper-w` | Enter workspace mode (then 1-4 to move window) |
| `hyper-1/2/3/4` | Switch to workspace |
| `hyper-t` | Toggle tiles layout |
| `hyper-a` | Toggle accordion layout |
| `hyper-space` | Toggle floating/tiling |
| `hyper-f` | Fullscreen |
| `hyper-n` | New Ghostty window |
| `alt-tab` | Workspace back-and-forth |

Floating exceptions: Telegram, Finder, Camera, Elgato, Discord, Mail, Trello, QuickTime.

| `hyper-left/right` | Focus monitor left/right |

Workspaces 1-2 are pinned to the main (laptop) monitor, 3-4 to secondary (external). When the external is disconnected, all workspaces collapse onto the laptop.

Gaps: 10px inner, 10px outer. Sketchybar sits flush at top.

## Neovim

LazyVim-based config with leader key = `Space`. Autoformat on save (toggle with `<leader>uf`). Theme: Rose Pine with transparency.

### Plugins

#### Editor Core

| Plugin | What it does | Key bindings |
|--------|-------------|--------------|
| **flash** | Fast jump/motion with visual labels. Replaces default `s`/`S`/`t`/`T` | `f` jump, `F` treesitter jump, `r` remote flash (operator pending), `R` treesitter search, `Ctrl+s` toggle flash in search |
| **surround** | Add, change, and delete surrounding characters (quotes, brackets, tags). Treesitter-aware for intelligent matching | `ys{motion}{char}` add, `cs{old}{new}` change, `ds{char}` delete |
| **wildfire** | Progressive text selection that expands outward using treesitter syntax trees | Enter to expand, Backspace to contract |
| **illuminate** | Highlights all references to the word under cursor using LSP. Zero delay, 2000 line file cutoff | `]]` next reference, `[[` previous reference |
| **numb** | Previews the target line in-place when typing `:{number}` in command mode | Automatic -- just type `:123` |
| **dropbar** | Breadcrumb navigation bar showing file path and code symbols at the top of each window. Different sources for markdown (headings) vs code (LSP/treesitter) | `<leader>;` pick symbols, `[;` goto context start, `];` select next context |
| **recall** | Persistent marks with visual gutter indicators and a picker UI | `<leader>mm` toggle mark, `<leader>mn`/`<leader>mp` next/prev, `Tab`/`Shift+Tab` navigate, `<leader>mc` clear all, `<leader>mo` open picker |

#### Git

| Plugin | What it does | Key bindings |
|--------|-------------|--------------|
| **fugitive** | Full git wrapper -- stage, commit, push, pull, blame, browse without leaving the editor | `<leader>gs` status, `<leader>gp` push, `<leader>gP` pull, `<leader>gb` blame, `<leader>gB` browse, `<leader>gw` stage, `<leader>gr` checkout |
| **gitsigns** | Git change indicators in the gutter with inline hunk previews and staging | `<leader>gp` preview inline, `<leader>gP` preview float, `<leader>hs` stage hunk, `<leader>hr` reset hunk, `]h`/`[h` next/prev hunk |
| **diffview** | Side-by-side visual diff viewer with a file tree panel. Replaces lazygit inside nvim (lazygit still available via `Ctrl+g` in tmux) | `<leader>gg` toggle diffview, `<leader>gh` current file history, `<leader>gH` all file history |
| **git-commit-float** | Opens a floating window for writing commit messages instead of a full buffer split | `<leader>gc` open commit window |

#### Navigation and Windows

| Plugin | What it does | Key bindings |
|--------|-------------|--------------|
| **smart-splits** | Seamless navigation between nvim splits and tmux panes. Manages the tmux `@pane-is-vim` flag automatically | `Ctrl+h/j/k/l` navigate splits/panes, `Alt+=`/`Alt+-` grow/shrink, `<leader>w{h/j/k/l}` swap buffer in direction |
| **yazi** | Yazi file manager in a floating window (90% screen). Solid background matching Telescope style | `<leader>e` open at current file, `<leader>E` open at working directory, `F1` help |
| **glance** | Peek at definitions, references, type definitions, and implementations in a split without jumping away. Right-side panel at 33% width | `gD` definitions, `gR` references, `gY` type definitions, `gI` implementations |
| **snacks** | LazyVim's UI framework providing notifications, pickers, and other UI components | `<leader>sn` notifications |

#### Language and LSP

| Plugin | What it does | Key bindings |
|--------|-------------|--------------|
| **lsp** | Patches nvim-lspconfig to re-trigger LspAttach when servers register dynamic capabilities (codeAction, rename, inlayHints) after the initial handshake | Automatic |
| **typescript** | vtsls TypeScript/JavaScript language server with 8GB memory limit for both TS and JS to prevent OOM in large projects | Standard LSP bindings |
| **rust** | rustaceanvim with smart rust-analyzer resolution -- skips asdf-managed binaries, prefers system install, falls back to rustup | Standard LSP bindings |
| **toml** | Taplo TOML language server. Detaches from non-file URIs for cleaner editing | Standard LSP bindings |
| **neotest** | Integrated test runner with Jest and Rust adapters. Jest config handles monorepo structure by finding `jest.config.js` in package directories | LazyVim default neotest bindings |

#### Other

| Plugin | What it does | Key bindings |
|--------|-------------|--------------|
| **99** | AI code assistant powered by Claude Code. Uses Blink for completions | `<leader>9s` search, `<leader>9v` visual selection, `<leader>9x` stop, `<leader>9o` open last, `<leader>9m` select model, `<leader>9p` select provider |
| **colorscheme** | Rose Pine theme (main variant) with transparency enabled and italics disabled | -- |
| **global-note** | Quick scratchpad in a floating window (70% width, 85% height) with autosave. Notes stored in `~/.local/share/nvim/global-note/global.md` | `<leader>n` toggle note |

### Diagnostics

Smart diagnostic display: virtual lines show on the current line for detail, virtual text shows elsewhere to reduce clutter.

## tmux

Prefix key is `` ` `` (backtick), not the default `Ctrl+b`.

| Binding | Action |
|---------|--------|
| `` ` `` + `c` | New window |
| `` ` `` + `,` | Rename window |
| `Shift+Left/Right` | Previous/next window |
| `` ` `` + `h` or `\|` | Horizontal split |
| `` ` `` + `v` or `-` | Vertical split |
| `Ctrl+h/j/k/l` | Navigate panes (shared with nvim) |
| `` ` `` + `z` | Zoom pane (or nvim zoom if in nvim) |
| `Ctrl+g` | Lazygit popup |
| `` ` `` + `f` | Session switcher (cms) |
| `` ` `` + `a` | Agent switcher (cms -a) |
| `` ` `` + `x` | Kill pane |
| `` ` `` + `s` | Choose session |

## Claude Code Powerline

The status line uses `@owloops/claude-powerline` (powerline style). Here's what each symbol means:

| Symbol | Meaning |
|--------|---------|
| `⧉` | In a git worktree |
| ` ` | Current git branch |
| `⌂` | Current git tag |
| `♯` | Current commit SHA |
| `→` | Commits ahead/behind upstream |
| `⧇` | Stashed changes |
| `◷` | Time of last commit |
| `§` | Session cost |
| `◱` | Last response block cost |
| `☉` | Total cost today |
| `◑` | Total cost this week |
| `◔` | Context time |
| `⧖` | Response time |
| `Δ` | Last response time |
| `⧗` | Session duration |
| `◆` | Message count |
| `+` / `-` | Lines added / removed |
| `↗` | Token burn rate |
| `◈` | Claude Code version |
| `⚙` | Environment |
| `⌗` | Session ID |

Not all symbols display at once -- visibility depends on what's relevant to the current session.

## Manual Steps After Bootstrap

1. **Sol** -- launch Sol, configure it to start at login, set activation hotkey to Cmd+Space, and grant accessibility permissions
2. **Sketchybar** -- verify the LaunchAgent is running (`brew services list`). The bar integrates with AeroSpace workspace changes
3. **tmux** -- run `prefix + I` inside tmux to install TPM plugins on first launch
4. **Neovim** -- open nvim and let Lazy sync plugins on first launch
5. **AeroSpace** -- grant accessibility permissions when prompted on first launch
6. **Karabiner-Elements** -- grant accessibility and input monitoring permissions. Caps Lock becomes the hyper key for all AeroSpace bindings; tapping Caps Lock alone sends Escape
7. **macOS defaults** -- some changes (Dock, Finder, Trackpad) require a logout/restart to fully take effect

## Customization

To override role defaults, set variables in `group_vars/local`. Each role defines its defaults in `roles/<name>/defaults/main.yml`.

The macOS role is the most configurable -- every preference is driven by a variable (see `roles/macos/vars/main.yml` for all available options and their possible values).

To add a new CLI tool, append to the `tools` list in `roles/cli/defaults/main.yml`. To add a new cask app, append to the `apps` list in `roles/apps/defaults/main.yml`.

## Structure

```
dotfiles.yml           # Main playbook
hosts                  # Ansible inventory (localhost)
group_vars/local       # User-specific variables
bin/
  bootstrap            # Initial setup script
  dotfiles             # Day-to-day management CLI
  lock-role            # Helper for role lockfile tracking
roles/
  <role>/
    tasks/main.yml     # What the role does
    defaults/main.yml  # Default variables (override in group_vars)
    files/             # Config files (symlinked into ~/)
    templates/         # Jinja2 templates
    handlers/main.yml  # Service restart handlers
    vars/main.yml      # Role-internal variables
```

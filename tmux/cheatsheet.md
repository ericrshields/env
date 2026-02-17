# Tmux Cheat Sheet

Prefix: `Ctrl+a`

## Panes

| Key | Action |
|-----|--------|
| `\|` | Split horizontally |
| `-` | Split vertically |
| `w/a/s/d` | Navigate panes (WASD) |
| Arrow keys | Navigate panes (alternative) |
| `x` | Kill pane |

## Windows

| Key | Action |
|-----|--------|
| `c` | New window |
| `n` / `p` | Next / previous window |
| `1`-`9` | Jump to window by number |

## Copy Mode

| Key | Action |
|-----|--------|
| `[` | Enter copy mode (vi keys to navigate) |
| `q` | Exit copy mode |

Mouse wheel scroll also enters copy mode automatically.

## Other

| Key | Action |
|-----|--------|
| `r` | Reload config |
| `d` | Detach from session |

## Session Management (from shell)

| Command | Action |
|---------|--------|
| `tmux` | New session |
| `tmux new -s name` | New named session |
| `tmux attach -t name` | Attach to existing session |
| `tmux ls` | List sessions |

## Session Save/Restore (resurrect + continuum)

| Key | Action |
|-----|--------|
| `Ctrl+s` | Save session (manual) |
| `Ctrl+r` | Restore session (manual) |
| `I` | Install/update TPM plugins |

Continuum auto-saves every 15 minutes and auto-restores on tmux start.

## TPM (Plugin Manager) Setup

1. Clone TPM: `git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm`
2. Reload config: `prefix + r` (or `tmux source ~/.tmux.conf`)
3. Install plugins: `prefix + I` (capital I)
4. Update plugins: `prefix + U` (capital U)

## Tips

- **Mouse is enabled** — click panes, drag to resize, scroll to view history
- **Hold Shift** while selecting text to use terminal-native selection (for copy/paste)
- **Scrollback** is 50k lines
- **Activity** in background windows shows as red bold in status bar

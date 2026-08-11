# herdr-bitwarden

![License](https://img.shields.io/github/license/WillowMist/herdr-bitwarden)

Fuzzy-search your Bitwarden vault and paste/copy credentials — directly inside [herdr](https://herdr.dev), your agent-aware terminal multiplexer.

This is a **herdr port of [tmux-bitwarden](https://github.com/Alkindi42/tmux-bitwarden) by [Alkindi](https://github.com/Alkindi42)**, adapted from the tmux plugin system to herdr's native plugin v1 format. The design, the fzf selector UX, the session/auth handling, and the metadata cache all come from Alkindi's original — this port just moves them from tmux keybindings to herdr panes and actions. Huge thanks to Alkindi for the original; it's a lovely piece of work. 🫡

## Features

- 🔍 Fuzzy search Bitwarden items with `fzf`
- 👀 Preview username and URIs before selecting
- 🔐 Secure vault access through the Bitwarden CLI
- 🔁 Automatic re-authentication on session expiration
- ⚡ Fast search with optional metadata caching
- ⌨️ Keyboard-driven workflow
- 📋 Paste or copy credentials (username, password, TOTP)
- 🔄 Refresh cache without leaving the selector
- 🖥 Popup interface via herdr's native popup placement

## Requirements

- [herdr](https://herdr.dev) >= 0.8.0 (plugin v1)
- [Bitwarden CLI](https://bitwarden.com/help/cli/) (`bw`)
- [jq](https://jqlang.github.io/jq/)
- [fzf](https://github.com/junegunn/fzf)
- Bash >= 4

## Installation

Link it (local development) or install it from GitHub:

```bash
herdr plugin link ~/hermes-workspace/shared/herdr-bitwarden
# or, from GitHub:
herdr plugin install WillowMist/herdr-bitwarden
```

Then add a keybinding in `~/.config/herdr/config.toml` (the original tmux plugin used `prefix+b`, but that's herdr's native `toggle_sidebar` — this chord keeps the same letter):

```toml
[[keys.command]]
key = "prefix+ctrl+b"
type = "plugin_action"
command = "bitwarden.open-picker"
description = "Open Bitwarden picker"
```

Reload config (`herdr server reload-config`) and you're set.

## Usage

Press `prefix + ctrl + b` (or whatever key you bound) to open the Bitwarden selector popup.

| Key | Action |
|-----|-----------------------------------------|
| `Enter` | Paste password into the active pane |
| `Ctrl-y` | Copy password to clipboard |
| `Ctrl-u` | Paste username into the active pane |
| `Alt-u` | Copy username to clipboard |
| `Ctrl-r` | Refresh cached items |
| `Alt-t` | Copy TOTP to clipboard |
| `Ctrl-t` | Paste TOTP into the active pane |

## Authentication

Before using the plugin, log in to Bitwarden once with the CLI:

```bash
bw login
```

_No manual `BW_SESSION` export is required._ The plugin automatically:

- reuses your existing Bitwarden session when available (including `BW_SESSION` env)
- prompts for unlock only when necessary (the popup is a real terminal, so the master-password prompt works right inside it)
- retries operations transparently if the session expires

The session key is stored in the plugin state dir (`HERDR_PLUGIN_STATE_DIR/session`, chmod 600).

## Configuration

All options are optional and read from environment variables, or from
`config.env` in the plugin config dir
(`herdr plugin config-dir bitwarden`).

| Variable | Default | Description |
|------|------|------|
| `BW_CACHE` | `true` | Enable/disable the metadata cache |
| `BW_CACHE_TTL` | `86400` | Cache duration in seconds (`-1` = never expire) |
| `BW_CACHE_FILE` | `<state>/items.json` | Cache file location |

Example `config.env`:

```bash
BW_CACHE=true
BW_CACHE_TTL=43200
```

## Security

- Passwords are **never stored in the cache** — only metadata (name, username, URIs)
- Passwords are retrieved **only when required** (on paste/copy)
- Vault access is handled by the Bitwarden CLI session
- The session key lives in the plugin state dir with `0600` perms

## How it works

- `herdr-plugin.toml` — manifest declaring the `picker` popup pane and the `open-picker` action
- `picker.sh` — entrypoint (runs inside the popup): dependency check → session check → fzf selector → dispatch
- `lib/selector.sh` — fzf selector (ported from tmux-bitwarden; preview moved to `lib/preview.sh`)
- `lib/session.sh` — auth/session handling, auto-re-auth on expiry
- `lib/cache.sh` — metadata cache with TTL
- `lib/actions.sh` — paste via `herdr pane send-text <pane> <value>`, copy via clipboard
- `lib/common.sh` — helpers; resolves the target pane from `HERDR_PLUGIN_CONTEXT_JSON.focused_pane_id`

## Differences from tmux-bitwarden

| tmux-bitwarden | herdr-bitwarden |
|---|---|
| `tmux display-popup` | herdr manifest `placement = "popup"` pane |
| `tmux send-keys -l -t "$pane" -- "$value"` | `herdr pane send-text "$pane" "$value"` |
| `@bw-*` tmux options | `BW_*` env vars / `config.env` |
| `tmux display-message` | stderr in the popup |
| session stored in tmux option | session stored in plugin state dir (0600) |

## License

MIT — see [LICENSE](LICENSE). Original tmux-bitwarden (c) 2026 Alkindi, herdr port (c) 2026 Penfold/Willow Cline.

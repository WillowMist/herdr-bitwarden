#!/usr/bin/env bash
#
# Common helpers for herdr-bitwarden.
# Port of tmux-bitwarden's common.sh — tmux display-message becomes
# stderr output (the popup is a real terminal, so stderr is visible).

# Check if binary exists
is_binary_exist() {
  local binary=$1
  command -v "$binary" &>/dev/null
  return $?
}

# Display a message (visible in the popup / on stderr)
bw_display_message() {
  local message="$1"
  printf 'herdr-bitwarden: %s\n' "$message" >&2
}

# Get the current/focused pane id.
# When the picker runs, HERDR_PLUGIN_CONTEXT_JSON should carry the focused
# pane (the pane the user was in before the popup opened). Fall back to
# `herdr pane current`.
bw_get_current_pane() {
  local pane_id=""
  local herdr_bin="${HERDR_BIN_PATH:-herdr}"

  if [[ -n "${HERDR_PLUGIN_CONTEXT_JSON:-}" ]]; then
    pane_id="$(printf '%s' "$HERDR_PLUGIN_CONTEXT_JSON" | jq -r '.focused_pane_id // .focused_pane // .pane_id // empty' 2>/dev/null)"
  fi

  if [[ -z "$pane_id" ]]; then
    pane_id="$("$herdr_bin" pane current --current 2>/dev/null | jq -r '.pane_id // empty' 2>/dev/null)"
  fi

  if [[ -z "$pane_id" ]]; then
    pane_id="$("$herdr_bin" pane current 2>/dev/null | jq -r '.pane_id // empty' 2>/dev/null)"
  fi

  printf '%s\n' "$pane_id"
}

# Ensure state dir exists with safe perms
bw_ensure_state_dir() {
  mkdir -p "$BW_PLUGIN_STATE_DIR"
  chmod 700 "$BW_PLUGIN_STATE_DIR"
}

bw_ensure_config_dir() {
  mkdir -p "$BW_PLUGIN_CONFIG_DIR"
}

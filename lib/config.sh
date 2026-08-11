#!/usr/bin/env bash
# shellcheck disable=SC2034
#
# herdr-bitwarden configuration.
# Port of tmux-bitwarden's config.sh — tmux options become env vars
# (sourced from HERDR_PLUGIN_CONFIG_DIR/config.env if present).

readonly BW_CONFIG_KEY_UI="ui"
readonly BW_CONFIG_KEY_SPLIT_SIZE="ui-split-size"
readonly BW_CONFIG_KEY_POPUP_WIDTH="ui-popup-width"
readonly BW_CONFIG_KEY_POPUP_HEIGHT="ui-popup-height"

readonly BW_CONFIG_DEFAULT_UI="popup"
readonly BW_CONFIG_DEFAULT_SPLIT_SIZE="20"
readonly BW_CONFIG_DEFAULT_POPUP_WIDTH="80%"
readonly BW_CONFIG_DEFAULT_POPUP_HEIGHT="80%"

# Cache configuration
readonly BW_CONFIG_KEY_CACHE="cache"
readonly BW_CONFIG_KEY_CACHE_TTL="cache-ttl"
readonly BW_CONFIG_KEY_CACHE_FILE="cache-file"

readonly BW_CONFIG_DEFAULT_CACHE="true"
readonly BW_CONFIG_DEFAULT_CACHE_TTL=86400

# ---------------------------------------------------------------------------
# herdr plugin env (injected by herdr at runtime):
#   HERDR_PLUGIN_CONFIG_DIR  — user-editable config dir (per plugin)
#   HERDR_PLUGIN_STATE_DIR   — local runtime state dir (per plugin)
#   HERDR_PLUGIN_ROOT        — plugin directory (managed checkout for installs)
# ---------------------------------------------------------------------------
readonly BW_PLUGIN_CONFIG_DIR="${HERDR_PLUGIN_CONFIG_DIR:-$HOME/.config/herdr/plugins/bitwarden}"
readonly BW_PLUGIN_STATE_DIR="${HERDR_PLUGIN_STATE_DIR:-$HOME/.local/state/herdr/plugins/bitwarden}"

readonly BW_CONFIG_DEFAULT_CACHE_FILE="${BW_PLUGIN_STATE_DIR}/items.json"
readonly BW_SESSION_FILE="${BW_PLUGIN_STATE_DIR}/session"

# Load user config.env if present (KEY=VALUE lines, sourced).
bw_load_config_env() {
  local config_file="${BW_PLUGIN_CONFIG_DIR}/config.env"
  if [[ -f "$config_file" ]]; then
    # shellcheck disable=SC1090
    source "$config_file"
  fi
}

# herdr popup panes spawn with a sanitized system PATH (no ~/.local/bin, no
# brew prefix), so bw/fzf/jq installed in user dirs appear "missing". Re-add
# the usual user bin dirs (only those that exist, only if not already there).
bw_bootstrap_path() {
  local dir
  for dir in \
    "${BW_EXTRA_PATH:-}" \
    "$HOME/.local/bin" \
    "$HOME/bin" \
    "/home/linuxbrew/.linuxbrew/bin" \
    "/opt/homebrew/bin"; do
    if [[ -n "$dir" && -d "$dir" && ":$PATH:" != *":$dir:"* ]]; then
      export PATH="$dir:$PATH"
    fi
  done
}

bw_load_config_env
bw_bootstrap_path

bw_get_config_or_default() {
  local option="$1"
  local default_value="$2"
  local var_name="BW_${option//-/_}"
  var_name="${var_name^^}"

  if [[ -n "${!var_name:-}" ]]; then
    printf '%s\n' "${!var_name}"
  else
    printf '%s\n' "$default_value"
  fi
}

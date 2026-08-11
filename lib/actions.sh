#!/usr/bin/env bash
# shellcheck disable=SC2034
#
# Copy/paste actions for herdr-bitwarden.
# Ported from tmux-bitwarden's actions.sh:
#   - tmux send-keys -l -t "$pane" -- "$value"  →  herdr pane send-text <pane> <value>
#   - clipboard helpers unchanged.

readonly BW_COPY_TOTP="copy-totp"
readonly BW_PASTE_TOTP="paste-totp"
readonly BW_COPY_PASSWORD="copy-password"
readonly BW_PASTE_PASSWORD="paste-password"
readonly BW_PASTE_USERNAME="paste-username"
readonly BW_COPY_USERNAME="copy-username"

# Copy text to the clipboard
bw_copy_to_clipboard() {
  local value="$1"
  local os

  os="$(uname)"

  if [[ "$os" == "Darwin" ]] && is_binary_exist "pbcopy"; then
    printf "%s" "$value" | pbcopy
  elif [[ "$os" == "Linux" ]] && is_binary_exist "wl-copy"; then
    printf "%s" "$value" | wl-copy
  elif [[ "$os" == "Linux" ]] && is_binary_exist "xsel"; then
    printf "%s" "$value" | xsel -b
  elif [[ "$os" == "Linux" ]] && is_binary_exist "xclip"; then
    printf "%s" "$value" | xclip -selection clipboard -i
  else
    return 1
  fi
}

bw_get_totp() {
  local id="$1"
  local value

  value="$(bw_run_with_auth "bw_cli_get_totp" "$id")" || return 1
  [[ -n "$value" ]] || return 1

  printf '%s\n' "$value"
}

bw_get_value() {
  local id="$1"
  local field="$2"
  local value

  value="$(bw_run_with_auth "bw_cli_get_item_by_id" "$id" | jq --arg field "$field" -r '.login[$field] // empty')" || return 1
  [[ -n "$value" ]] || return 1

  printf '%s\n' "$value"
}

# Paste value into target pane via herdr socket API
bw_paste() {
  local id="$1"
  local target_pane_id="$2"
  local field="$3"
  local herdr_bin="${HERDR_BIN_PATH:-herdr}"

  local value

  value="$(bw_get_value "$id" "$field")" || return 1
  "$herdr_bin" pane send-text "$target_pane_id" "$value"
}

bw_copy() {
  local id="$1"
  local field="$2"

  local value

  value="$(bw_get_value "$id" "$field")" || return 1
  bw_copy_to_clipboard "$value"
}

bw_paste_password() {
  local id="$1"
  local target_pane_id="$2"
  bw_paste "$id" "$target_pane_id" "password"
}

bw_paste_username() {
  local id="$1"
  local target_pane_id="$2"
  bw_paste "$id" "$target_pane_id" "username"
}

bw_copy_password() {
  local id="$1"
  bw_copy "$id" "password"
}

bw_copy_username() {
  local id="$1"
  bw_copy "$id" "username"
}

bw_copy_totp() {
  local id="$1"
  local value

  value="$(bw_get_totp "$id")" || return 1
  bw_copy_to_clipboard "$value"
}

bw_paste_totp() {
  local id="$1"
  local target_pane_id="$2"
  local value
  local herdr_bin="${HERDR_BIN_PATH:-herdr}"

  value="$(bw_get_totp "$id")" || return 1
  "$herdr_bin" pane send-text "$target_pane_id" "$value"
}

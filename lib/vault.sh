#!/usr/bin/env bash
#
# Bitwarden CLI wrappers for herdr-bitwarden.
# Ported from tmux-bitwarden's vault.sh.
# NOTE: raw CLI functions use bw_cli_* prefix so they don't collide with
# the auth-wrapped wrappers in actions.sh (bw_get_totp etc.).

bw_cli_list_items() {
  local session="$1"

  bw list items --session "$session" --nointeraction
}

bw_cli_get_item_by_id() {
  local session="$1"
  local id="$2"

  bw get item --session "$session" --nointeraction "$id"
}

bw_cli_get_totp() {
  local session="$1"
  local id="$2"

  bw get totp --session "$session" --nointeraction "$id"
}

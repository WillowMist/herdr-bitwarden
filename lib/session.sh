#!/usr/bin/env bash
# shellcheck disable=SC2034
#
# Bitwarden session/auth management for herdr-bitwarden.
# Ported from tmux-bitwarden's session.sh — the tmux option that held
# the session key becomes a file in HERDR_PLUGIN_STATE_DIR (0600).

readonly BW_STATUS_LOCKED="locked"
readonly BW_STATUS_UNLOCKED="unlocked"
readonly BW_STATUS_UNAUTHENTICATED="unauthenticated"

bw_run_with_auth() {
  local fn="$1"
  local result
  local session
  local ret

  session="$(bw_get_session)" || return 1
  [[ -n "$session" ]] || return 1

  shift

  result="$("$fn" "$session" "$@" 2>&1)"
  ret=$?

  if ((ret != 0)) && {
    [[ "$result" == *"Vault is locked."* ]] ||
      [[ "$result" == *"You are not logged in."* ]]
  }; then
    printf "Unlocking vault...\n" >&2
    bw_authenticate || return 1

    session="$(bw_get_session)" || return 1
    [[ -n "$session" ]] || return 1

    printf "Fetching vault...\n" >&2
    result="$("$fn" "$session" "$@")"
    ret=$?
  fi

  printf '%s\n' "$result"
  return "$ret"
}

bw_authenticate() {
  case "$(bw_get_status)" in
  "$BW_STATUS_UNAUTHENTICATED")
    bw_display_message "You are not logged in. Please run 'bw login'."
    return 1
    ;;
  "$BW_STATUS_LOCKED")
    bw_unlock_and_store_session || return 1
    ;;
  "$BW_STATUS_UNLOCKED") ;;
  *)
    bw_display_message "Unknown Bitwarden status."
    return 1
    ;;
  esac
}

bw_has_session() {
  local session
  session="$(bw_get_session)"
  [[ -n "$session" ]]
}

# Get vault status via the Bitwarden CLI
bw_get_status() {
  local session="$1"
  local bw_status

  if [[ -n "$session" ]]; then
    bw_status="$(bw status --session "$session" --nointeraction | jq -r '.status')" || return 1
  else
    bw_status="$(bw status --nointeraction | jq -r '.status')" || return 1
  fi

  printf '%s\n' "$bw_status"
}

# Unlock vault via the Bitwarden CLI (interactive prompt for master password)
bw_unlock() {
  local session_id

  session_id="$(bw unlock --raw)" || return 1
  printf '%s\n' "$session_id"
}

# Session precedence: BW_SESSION env > session file in plugin state dir
bw_get_session() {
  local session_file_session

  if [[ -n "${BW_SESSION:-}" ]]; then
    printf '%s\n' "$BW_SESSION"
    return 0
  fi

  if [[ -f "$BW_SESSION_FILE" ]]; then
    session_file_session="$(<"$BW_SESSION_FILE")"
    if [[ -n "$session_file_session" ]]; then
      printf '%s\n' "$session_file_session"
    fi
  fi
}

bw_get_status_for_session() {
  local session
  session="$(bw_get_session)"
  bw_get_status "$session"
}

bw_unlock_and_store_session() {
  local new_session

  new_session="$(bw_unlock)" || {
    bw_display_message "Failed to unlock vault. Please try again."
    return 1
  }

  [[ -n "$new_session" ]] || {
    bw_display_message "Failed to unlock vault. Please try again."
    return 1
  }

  bw_ensure_state_dir
  printf '%s\n' "$new_session" >"$BW_SESSION_FILE"
  chmod 600 "$BW_SESSION_FILE"
}

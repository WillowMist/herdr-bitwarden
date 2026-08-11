#!/usr/bin/env bash
#
# herdr-bitwarden picker — entrypoint for the popup pane.
# Merges tmux-bitwarden's ui.sh + main.sh:
#   - herdr opens the popup from the manifest (no display-popup needed)
#   - this script runs INSIDE the popup and drives the fzf selector
#   - actions paste into the pane that was focused before the popup opened

CURRENT_DIR="${CURRENT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"

# shellcheck source=lib/config.sh
source "$CURRENT_DIR/lib/config.sh"
# shellcheck source=lib/common.sh
source "$CURRENT_DIR/lib/common.sh"
# shellcheck source=lib/vault.sh
source "$CURRENT_DIR/lib/vault.sh"
# shellcheck source=lib/session.sh
source "$CURRENT_DIR/lib/session.sh"
# shellcheck source=lib/cache.sh
source "$CURRENT_DIR/lib/cache.sh"
# shellcheck source=lib/actions.sh
source "$CURRENT_DIR/lib/actions.sh"
# shellcheck source=lib/selector.sh
source "$CURRENT_DIR/lib/selector.sh"

REQUIRED_BINARIES=(
  jq
  fzf
  bw
)

bw_check_dependencies() {
  local missing=()
  local binary

  for binary in "${REQUIRED_BINARIES[@]}"; do
    if ! is_binary_exist "$binary"; then
      missing+=("$binary")
    fi
  done

  if [[ ${#missing[@]} -gt 0 ]]; then
    bw_display_message "Missing required binaries: ${missing[*]}"
    return 1
  fi
  return 0
}

bw_dispatch() {
  local action="$1"
  local item_id="$2"
  local target_pane_id="$3"

  case "$action" in
  "$BW_PASTE_PASSWORD")
    bw_paste_password "$item_id" "$target_pane_id"
    ;;
  "$BW_COPY_PASSWORD")
    bw_copy_password "$item_id"
    ;;
  "$BW_PASTE_USERNAME")
    bw_paste_username "$item_id" "$target_pane_id"
    ;;
  "$BW_COPY_USERNAME")
    bw_copy_username "$item_id"
    ;;
  "$BW_PASTE_TOTP")
    bw_paste_totp "$item_id" "$target_pane_id"
    ;;
  "$BW_COPY_TOTP")
    bw_copy_totp "$item_id"
    ;;
  *)
    bw_display_message "Unknown action: $action"
    return 1
    ;;
  esac
}

main() {
  local action
  local status
  local item_id
  local selection
  local target_pane_id

  bw_load_config_env
  bw_ensure_state_dir

  if ! bw_check_dependencies; then
    printf 'Press Enter to close...\n' >&2
    read -r _
    return 1
  fi

  target_pane_id="$(bw_get_current_pane)"
  if [[ -z "$target_pane_id" ]]; then
    bw_display_message "Could not determine target pane."
    printf 'Press Enter to close...\n' >&2
    read -r _
    return 1
  fi

  if ! bw_has_session; then
    bw_authenticate || {
      printf 'Press Enter to close...\n' >&2
      read -r _
      return 1
    }
  fi

  if selection="$(bw_selector)"; then
    status=0
  else
    status=$?
  fi

  case "$status" in
  0) ;;
  "$BW_SELECTOR_CANCEL")
    return 0
    ;;
  "$BW_SELECTOR_ABORTED")
    bw_display_message "Could not load vault items."
    printf 'Press Enter to close...\n' >&2
    read -r _
    return 0
    ;;
  "$BW_SELECTOR_ERROR")
    bw_display_message "Selector error."
    printf 'Press Enter to close...\n' >&2
    read -r _
    return 0
    ;;
  *)
    bw_display_message "Unexpected selector exit: $status"
    printf 'Press Enter to close...\n' >&2
    read -r _
    return 0
    ;;
  esac

  action="$(printf '%s\n' "$selection" | sed -n '1p')"
  item_id="$(printf '%s\n' "$selection" | sed -n '2p')"

  bw_dispatch "$action" "$item_id" "$target_pane_id"
}

main "$@"

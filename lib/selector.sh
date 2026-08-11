#!/usr/bin/env bash
#
# fzf selector for herdr-bitwarden.
# Ported from tmux-bitwarden's selector.sh (function prefix tmux_bw_ → bw_).

readonly BW_KEY_COPY_TOTP="alt-t"
readonly BW_KEY_PASTE_TOTP="ctrl-t"
readonly BW_KEY_COPY_PASSWORD="ctrl-y"
readonly BW_KEY_COPY_USERNAME="alt-u"
readonly BW_KEY_PASTE_PASSWORD="enter"
readonly BW_KEY_PASTE_USERNAME="ctrl-u"
readonly BW_KEY_REFRESH_CACHE="ctrl-r"

readonly BW_SELECTOR_CANCEL=10
readonly BW_SELECTOR_ERROR=20
readonly BW_SELECTOR_ABORTED=30

CURRENT_DIR="${CURRENT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"

bw_selector_rows() {
  local items

  items="$(bw_list_items_with_cache)" || return 1

  printf 'id\tName\tUsername\tURIs\tHasTotp\n'
  printf '%s\n' "$items" | jq -r '
    .[]
    | [
        .id,
        (.name // ""),
        (.login.username // ""),
        ((.login.uris // []) | map(.uri // "") | @json),
        (.login.has_totp // false)
      ]
    | @tsv
  '
}

bw_selector_action_from_key() {
  local key="$1"

  case "$key" in
  "" | "$BW_KEY_PASTE_PASSWORD")
    printf '%s\n' "$BW_PASTE_PASSWORD"
    ;;
  "$BW_KEY_COPY_PASSWORD")
    printf '%s\n' "$BW_COPY_PASSWORD"
    ;;
  "$BW_KEY_PASTE_USERNAME")
    printf '%s\n' "$BW_PASTE_USERNAME"
    ;;
  "$BW_KEY_COPY_USERNAME")
    printf '%s\n' "$BW_COPY_USERNAME"
    ;;
  "$BW_KEY_COPY_TOTP")
    printf '%s\n' "$BW_COPY_TOTP"
    ;;
  "$BW_KEY_PASTE_TOTP")
    printf '%s\n' "$BW_PASTE_TOTP"
    ;;
  *)
    return 1
    ;;
  esac
}

bw_selector() {
  local key
  local rows
  local status
  local item_id
  local selection
  local action_name
  local selected_line

  local _name
  local _username
  local _uris_json
  local _has_totp

  while true; do
    printf "Loading Bitwarden items...\n" >&2
    rows="$(bw_selector_rows)"
    status=$?

    ((status == 0)) || return "$BW_SELECTOR_ABORTED"

    if selection="$(
      printf '%s\n' "$rows" | fzf \
        --delimiter=$'\t' \
        --expect="$BW_KEY_PASTE_PASSWORD,$BW_KEY_COPY_PASSWORD,$BW_KEY_PASTE_USERNAME,$BW_KEY_COPY_USERNAME,$BW_KEY_REFRESH_CACHE,$BW_KEY_COPY_TOTP,$BW_KEY_PASTE_TOTP" \
        --with-nth=2 \
        --header-lines=1 \
        --header=$'enter: paste password | ctrl-y: copy password | ctrl-r: refresh\nctrl-u: paste user | alt-u: copy user | alt-t: copy totp | ctrl-t: paste totp' \
        --prompt='Bitwarden > ' \
        --preview="$CURRENT_DIR/lib/preview.sh {}" \
        --preview-window='right:50%:wrap'
    )"; then
      status=0
    else
      status=$?
    fi

    case "$status" in
    0) ;;
    130 | 1)
      return "$BW_SELECTOR_CANCEL"
      ;;
    *)
      return "$BW_SELECTOR_ERROR"
      ;;
    esac

    {
      IFS= read -r key
      IFS= read -r selected_line
    } <<<"$selection"

    if [[ "$key" == "$BW_KEY_REFRESH_CACHE" ]]; then
      bw_cache_invalidate || return "$BW_SELECTOR_ERROR"
      continue
    fi

    if ! action_name="$(bw_selector_action_from_key "$key")"; then
      return "$BW_SELECTOR_ERROR"
    fi

    IFS=$'\t' read -r item_id _name _username _uris_json _has_totp <<<"$selected_line"
    [[ -n "$item_id" ]] || return "$BW_SELECTOR_ERROR"

    printf '%s\n%s\n' "$action_name" "$item_id"
    return 0
  done
}

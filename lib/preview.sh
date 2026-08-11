#!/usr/bin/env bash
#
# fzf preview renderer for herdr-bitwarden.
# Receives the current TSV line as $1, renders item details.

IFS=$'\t' read -r id name username uris_json has_totp <<<"$1"

printf "ID        : %s\n" "$id"
printf "Name      : %s\n" "$name"
printf "Username  : %s\n" "$username"
if [[ "$has_totp" == "true" ]]; then
  printf "TOTP      : yes\n"
fi
printf "\nURI(s):\n"
printf "%s\n" "$uris_json" | jq -r 'if length == 0 then "(none)" else .[] end'

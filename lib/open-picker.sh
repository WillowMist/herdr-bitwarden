#!/usr/bin/env bash
# Action entrypoint: open the picker popup via the running herdr binary.
# Manifest command arrays are raw argv (no shell expansion), so this wrapper
# resolves herdr through HERDR_BIN_PATH (injected by herdr into plugin
# environments) instead of relying on PATH.
herdr_bin="${HERDR_BIN_PATH:-herdr}"
exec "$herdr_bin" plugin pane open --plugin bitwarden --entrypoint picker

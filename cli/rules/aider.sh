#!/bin/sh
set -eu
export GRAFT_DEEP_LINK_RULES_IDE=aider
__grft_cfg="$(curl -fsSL 'https://raw.githubusercontent.com/grft-dev/graftcode/refs/heads/feature/5272-grft-cli-installer-dx/cli/grft-raw-locator.sh' </dev/null | tr -d '\r\n')"
__grft_invoke="$(printf '%s' "$__grft_cfg" | sed -e 's|grft-raw-config\.ps1|rules/invoke.ps1|' -e 's|grft-raw-config\.sh|rules/invoke.sh|')"
eval "$(curl -fsSL "$__grft_invoke" </dev/null)"

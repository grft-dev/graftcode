#!/bin/sh
set -eu
export GRAFT_DEEP_LINK_RULES_IDE=continue
__grft_cfg="$(curl -fsSL 'https://raw.githubusercontent.com/grft-dev/graftcode/refs/heads/feature/5272-grft-cli-installer-dx/cli/grft-raw-locator.sh' </dev/null | tr -d '\r\n')"
__grft_invoke="$(printf '%s' "$__grft_cfg" | sed 's|grft-raw-config\.\(ps1\|sh\)|rules/invoke.\1|')"
eval "$(curl -fsSL "$__grft_invoke" </dev/null)"

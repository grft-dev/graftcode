#!/bin/sh
# grft:rules=claude
set -eu
GRAFT_DEEP_LINK_RULES_IDE=claude
export GRAFT_DEEP_LINK_RULES_IDE
GRFT_CLI_RAW_BASE='https://raw.githubusercontent.com/grft-dev/graftcode/refs/heads/feature/5272-grft-cli-installer-dx/cli'
export GRFT_CLI_RAW_BASE
eval "$(curl -fsSL "$GRFT_CLI_RAW_BASE/rules/invoke.sh")"

#!/bin/sh
# grft:rules=claude
set -eu
GRAFT_DEEP_LINK_RULES_IDE=claude
export GRAFT_DEEP_LINK_RULES_IDE
eval "$(curl -fsSL https://raw.githubusercontent.com/grft-dev/graftcode/refs/heads/main/cli/rules/invoke.sh)"
#!/bin/sh
# grft:rules=copilot
set -eu
GRAFT_DEEP_LINK_RULES_IDE=copilot
export GRAFT_DEEP_LINK_RULES_IDE
eval "$(curl -fsSL https://raw.githubusercontent.com/grft-dev/graftcode/refs/heads/main/cli/rules/invoke.sh)"
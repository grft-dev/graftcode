#!/bin/sh
# grft:rules=aider
set -eu
GRAFT_DEEP_LINK_RULES_IDE=aider
export GRAFT_DEEP_LINK_RULES_IDE
eval "$(curl -fsSL https://raw.githubusercontent.com/grft-dev/graftcode/refs/heads/main/cli/rules/invoke.sh)"
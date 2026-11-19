#!/bin/sh
# grft:rules=cline
set -eu
GRAFT_DEEP_LINK_RULES_IDE=cline
export GRAFT_DEEP_LINK_RULES_IDE
eval "$(curl -fsSL https://raw.githubusercontent.com/grft-dev/graftcode/refs/heads/main/cli/rules/invoke.sh)"
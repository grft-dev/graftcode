#!/bin/sh
# grft:rules=windsurf
set -eu
GRAFT_DEEP_LINK_RULES_IDE=windsurf
export GRAFT_DEEP_LINK_RULES_IDE
eval "$(curl -fsSL https://raw.githubusercontent.com/grft-dev/graftcode/refs/heads/main/cli/rules/invoke.sh)"
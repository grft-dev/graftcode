#!/bin/sh
set -eu
export GRAFT_DEEP_LINK_RULES_IDE=cursor
eval "$(curl -fsSL 'https://raw.githubusercontent.com/grft-dev/graftcode/refs/heads/main/cli/rules/invoke.sh' </dev/null)"

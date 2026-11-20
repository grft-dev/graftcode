#!/bin/sh
set -eu
export GRAFT_DEEP_LINK_RULES_IDE=claude
eval "$(curl -fsSL 'https://raw.githubusercontent.com/grft-dev/graftcode/refs/heads/feature/5272-grft-cli-installer-dx/cli/rules/invoke.sh' </dev/null)"

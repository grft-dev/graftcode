#!/bin/sh
set -eu
export GRAFT_DEEP_LINK_RULES_IDE=continue
eval "$(curl -fsSL 'https://raw.githubusercontent.com/grft-dev/graftcode/refs/heads/develop/cli/rules/invoke.sh' </dev/null)"

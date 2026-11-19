#!/bin/sh
# grft:plugin=servicebus
set -eu
GRAFT_DEEP_LINK_PLUGIN_ID=servicebus
export GRAFT_DEEP_LINK_PLUGIN_ID
eval "$(curl -fsSL https://raw.githubusercontent.com/grft-dev/graftcode/refs/heads/main/cli/plugin/invoke.sh)"

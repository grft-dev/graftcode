#!/bin/sh
set -eu
export GRAFT_DEEP_LINK_PLUGIN_ID=servicebus
eval "$(curl -fsSL 'https://raw.githubusercontent.com/grft-dev/graftcode/refs/heads/develop/cli/plugin/invoke.sh' </dev/null)"

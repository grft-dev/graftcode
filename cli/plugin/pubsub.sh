#!/bin/sh
set -eu
export GRAFT_DEEP_LINK_PLUGIN_ID=pubsub
eval "$(curl -fsSL 'https://raw.githubusercontent.com/grft-dev/graftcode/refs/heads/feature/5272-grft-cli-installer-dx/cli/plugin/invoke.sh' </dev/null)"

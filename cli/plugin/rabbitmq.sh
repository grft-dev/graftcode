#!/bin/sh
# grft:plugin=rabbitmq
set -eu
GRAFT_DEEP_LINK_PLUGIN_ID=rabbitmq
export GRAFT_DEEP_LINK_PLUGIN_ID
GRFT_CLI_RAW_BASE='https://raw.githubusercontent.com/grft-dev/graftcode/refs/heads/feature/5272-grft-cli-installer-dx/cli'
export GRFT_CLI_RAW_BASE
eval "$(curl -fsSL https://raw.githubusercontent.com/grft-dev/graftcode/refs/heads/feature/5272-grft-cli-installer-dx/cli/plugin/invoke.sh)"

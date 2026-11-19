#!/bin/sh
# grft:get=gg (raw path mirrors grft.dev/get/gg)
set -eu
GRFT_CLI_RAW_BASE='https://raw.githubusercontent.com/grft-dev/graftcode/refs/heads/feature/5272-grft-cli-installer-dx/cli'
export GRFT_CLI_RAW_BASE
eval "$(curl -fsSL "$GRFT_CLI_RAW_BASE/gg.sh")"

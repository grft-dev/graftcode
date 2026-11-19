#!/bin/sh
set -eu
export GRAFT_DEEP_LINK_PLUGIN_ID=kafka
eval "$(curl -fsSL "${GRFT_CLI_RAW_BASE:?}/plugin/invoke.sh" </dev/null)"

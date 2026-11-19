#!/bin/sh
set -eu
export GRAFT_DEEP_LINK_RULES_IDE=copilot
eval "$(curl -fsSL "${GRFT_CLI_RAW_BASE:?}/rules/invoke.sh" </dev/null)"

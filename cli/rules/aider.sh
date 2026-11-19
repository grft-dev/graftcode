#!/bin/sh
set -eu
export GRAFT_DEEP_LINK_RULES_IDE=aider
eval "$(curl -fsSL "${GRFT_CLI_RAW_BASE:?}/rules/invoke.sh" </dev/null)"

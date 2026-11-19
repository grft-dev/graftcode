# Single source for raw GitHub URLs — change GRFT_CLI_GIT_REF only, then sync-plugins-manifest.ps1
GRFT_CLI_GIT_REF="${GRFT_CLI_GIT_REF:-main}"
GRFT_REPO_RAW_ROOT="https://raw.githubusercontent.com/grft-dev/graftcode/refs/heads/${GRFT_CLI_GIT_REF}"
GRFT_CLI_RAW_BASE="${GRFT_CLI_RAW_BASE:-${GRFT_REPO_RAW_ROOT}/cli}"
GRFT_RULES_RAW_BASE="${GRFT_RULES_RAW_BASE:-${GRFT_REPO_RAW_ROOT}/rules}"
#!/bin/sh
set -eu

if [ -z "${GRAFT_DEEP_LINK_RULES_IDE:-}" ]; then
  echo "Error: set GRAFT_DEEP_LINK_RULES_IDE before running rules/invoke.sh" >&2
  exit 1
fi

CLI_RAW_BASE="${CLI_RAW_BASE:-https://raw.githubusercontent.com/grft-dev/graftcode/refs/heads/main/cli}"

rules_dir=""
case "$0" in
  */*)
    rules_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
    ;;
esac

if [ -n "$rules_dir" ] && [ -f "$rules_dir/deep-link.sh" ]; then
  # shellcheck source=/dev/null
  . "$rules_dir/deep-link.sh"
  exit $?
fi

deep_tmp="$(mktemp)"
curl -fsSL "$CLI_RAW_BASE/rules/deep-link.sh" -o "$deep_tmp"
sed 's/\r$//' "$deep_tmp" > "${deep_tmp}.lf"
# shellcheck source=/dev/null
. "${deep_tmp}.lf"
rm -f "$deep_tmp" "${deep_tmp}.lf"
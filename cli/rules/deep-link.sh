#!/bin/sh
set -eu

if [ -z "${GRAFT_DEEP_LINK_RULES_IDE:-}" ]; then
  echo "Error: set GRAFT_DEEP_LINK_RULES_IDE before running rules/deep-link.sh" >&2
  exit 1
fi

IDE="$GRAFT_DEEP_LINK_RULES_IDE"
CLI_RAW_BASE="${CLI_RAW_BASE:-https://raw.githubusercontent.com/grft-dev/graftcode/refs/heads/main/cli}"
GRAFT_ROOT="${GRAFT_ROOT:-}"

cli_dir="${GRAFT_CLI_DIR:-}"
if [ -z "$cli_dir" ]; then
  case "$0" in
    */*)
      cli_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
      ;;
  esac
fi
if [ -z "$cli_dir" ] && [ -n "$GRAFT_ROOT" ]; then
  cli_dir="$GRAFT_ROOT/cli"
fi

if [ -n "$cli_dir" ] && [ -f "$cli_dir/get.sh" ]; then
  GRAFT_CLI_DIR="$cli_dir"
  get_run="$(mktemp)"
  sed 's/\r$//' "$cli_dir/get.sh" > "$get_run"
  export GRAFT_CLI_DIR
  sh "$get_run" get rules "$IDE"
  ec=$?
  rm -f "$get_run"
  exit "$ec"
fi

get_tmp="$(mktemp)"
curl -fsSL "$CLI_RAW_BASE/get.sh" -o "$get_tmp"
sed 's/\r$//' "$get_tmp" > "${get_tmp}.lf"
sh "${get_tmp}.lf" get rules "$IDE"
ec=$?
rm -f "$get_tmp" "${get_tmp}.lf"
exit "$ec"
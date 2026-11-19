#!/bin/sh
set -eu

if [ -z "${GRAFT_DEEP_LINK_PLUGIN_ID:-}" ]; then
  echo "Error: set GRAFT_DEEP_LINK_PLUGIN_ID in the plugin stub before running invoke.sh" >&2
  exit 1
fi

GRFT_CLI_RAW_BASE="${GRFT_CLI_RAW_BASE:-https://raw.githubusercontent.com/grft-dev/graftcode/refs/heads/main/cli}"

stub_dir=""
case "$0" in */*)
  stub_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
  ;;
esac

if [ -n "$stub_dir" ] && [ -f "$stub_dir/deep-link.sh" ]; then
  # shellcheck source=/dev/null
  . "$stub_dir/deep-link.sh"
  exit 0
fi

eval "$(curl -fsSL "$GRFT_CLI_RAW_BASE/plugin/deep-link.sh")"
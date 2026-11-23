#!/bin/sh
set -eu

if [ -z "${GRAFT_DEEP_LINK_PLUGIN_ID:-}" ]; then
  echo "Error: set GRAFT_DEEP_LINK_PLUGIN_ID in the plugin stub before running invoke.sh" >&2
  exit 1
fi
GRFT_RAW_LOCATOR_SH_URL='https://raw.githubusercontent.com/grft-dev/graftcode/refs/heads/develop/cli/grft-raw-locator.sh'
export GRFT_RAW_LOCATOR_SH_URL
if [ -z "${GRFT_CLI_RAW_BASE:-}" ]; then
  import_helper=""
  case "$0" in */*)
    import_helper="$(CDPATH= cd -- "$(dirname -- "$0")/../lib" && pwd)/grft-import-raw-config.sh"
    ;;
  esac
  if [ -n "$import_helper" ] && [ -f "$import_helper" ]; then
    # shellcheck source=/dev/null
    . "$import_helper"
  else
    lib_base="${GRFT_RAW_LOCATOR_SH_URL%/grft-raw-locator.sh}"
    import_helper="$(mktemp)"
    curl -fsSL "$lib_base/lib/grft-import-raw-config.sh" -o "$import_helper" </dev/null
    # shellcheck source=/dev/null
    . "$import_helper"
    rm -f "$import_helper"
  fi
  import_grft_cli_raw_config || exit 1
fi
if [ -z "${GRFT_CLI_RAW_BASE:-}" ]; then
  echo "Error: grft-raw-config.sh must set GRFT_CLI_RAW_BASE" >&2
  exit 1
fi

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
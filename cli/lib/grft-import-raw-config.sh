#!/bin/sh
# shellcheck shell=sh
import_grft_cli_raw_config() {
  if [ -n "${GRFT_CLI_RAW_BASE:-}" ]; then
    return 0
  fi
  if [ -n "${GRFT_RAW_LOCATOR_SH_URL:-}" ]; then
    config_url="$(curl -fsSL "$GRFT_RAW_LOCATOR_SH_URL" </dev/null | tr -d '\r\n')"
    eval "$(curl -fsSL "$config_url" </dev/null)"
    return 0
  fi
  locator=""
  case "$0" in
    */*)
      locator="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)/grft-raw-locator.sh"
      ;;
  esac
  if [ -n "$locator" ] && [ -f "$locator" ]; then
    config_url="$(tr -d '\r\n' < "$locator")"
    eval "$(curl -fsSL "$config_url" </dev/null)"
    return 0
  fi
  echo "Load grft-raw-config first (curl .../grft-raw-config.sh | sh) or set GRFT_CLI_RAW_BASE." >&2
  return 1
}
#!/bin/sh
set -eu

if [ -f "$(dirname "$0")/grft-raw-config.sh" ]; then
  # shellcheck source=./grft-raw-config.sh
  . "$(dirname "$0")/grft-raw-config.sh"
fi
CLI_RAW_BASE="${CLI_RAW_BASE:-${GRFT_CLI_RAW_BASE:-https://raw.githubusercontent.com/grft-dev/graftcode/refs/heads/main/cli}}"
GRFT_RAW_BASE="${GRFT_RAW_BASE:-$CLI_RAW_BASE}"

graft_cli_source_sh_file() {
  sh_path="$1"
  sh_local="$(mktemp)"
  sed 's/\r$//' "$sh_path" > "$sh_local"
  # shellcheck source=/dev/null
  . "$sh_local"
  rm -f "$sh_local"
}

graft_cli_source_lib_from_url() {
  lib_rel="$1"
  if ! command -v curl >/dev/null 2>&1; then
    echo "Error: curl is required to load $lib_rel from $CLI_RAW_BASE."
    exit 1
  fi
  lib_tmp="$(mktemp)"
  curl -fsSL "$CLI_RAW_BASE/$lib_rel" -o "$lib_tmp"
  sed 's/\r$//' "$lib_tmp" > "${lib_tmp}.lf"
  # shellcheck source=/dev/null
  . "${lib_tmp}.lf"
  rm -f "$lib_tmp" "${lib_tmp}.lf"
}

graft_cli_resolve_script_dir() {
  case "$0" in
    -|sh|bash)
      echo ""
      ;;
    *)
      CDPATH= cd -- "$(dirname -- "$0")" && pwd
      ;;
  esac
}

graft_cli_source_lib() {
  lib_name="$1"
  lib_rel="lib/$lib_name"

  if [ -n "${GRAFT_CLI_DIR:-}" ] && [ -f "$GRAFT_CLI_DIR/$lib_rel" ]; then
    graft_cli_source_sh_file "$GRAFT_CLI_DIR/$lib_rel"
    return
  fi

  script_dir="$(graft_cli_resolve_script_dir)"
  if [ -n "$script_dir" ] && [ -f "$script_dir/$lib_rel" ]; then
    graft_cli_source_sh_file "$script_dir/$lib_rel"
    return
  fi

  graft_cli_source_lib_from_url "$lib_rel"
}

_bootstrap_dir="$(graft_cli_resolve_script_dir)"
if [ -n "$_bootstrap_dir" ] && [ -f "$_bootstrap_dir/lib/grft-cli-layout-bootstrap.sh" ]; then
  # shellcheck source=./lib/grft-cli-layout-bootstrap.sh
  . "$_bootstrap_dir/lib/grft-cli-layout-bootstrap.sh"
  graft_cli_bootstrap_layout || exit 1
elif command -v curl >/dev/null 2>&1; then
  _ensure_tmp="$(mktemp)"
  curl -fsSL "$CLI_RAW_BASE/ensure-sh-cli-layout.sh" -o "$_ensure_tmp"
  # shellcheck source=/dev/null
  . "$_ensure_tmp"
  rm -f "$_ensure_tmp"
  graft_cli_load_and_initialize_layout || exit 1
else
  echo "Error: curl is required to bootstrap the CLI layout." >&2
  exit 1
fi

graft_cli_source_lib ui.sh
graft_cli_source_lib gateway-installer.sh

install_gg_to_cwd
ui_show_done
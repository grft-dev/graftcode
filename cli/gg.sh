#!/bin/sh
set -eu

CLI_RAW_BASE="${CLI_RAW_BASE:-https://raw.githubusercontent.com/grft-dev/graftcode/refs/heads/main/cli}"

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

graft_cli_source_lib ui.sh
graft_cli_source_lib gateway-installer.sh

install_gg_to_cwd
ui_show_done
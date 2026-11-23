#!/bin/sh
set -eu

if [ -z "${GRAFT_DEEP_LINK_RULES_IDE:-}" ]; then
  echo "Error: set GRAFT_DEEP_LINK_RULES_IDE before running rules/deep-link.sh" >&2
  exit 1
fi

IDE="$GRAFT_DEEP_LINK_RULES_IDE"
if [ -f "$(dirname "$0")/../grft-raw-config.sh" ]; then
  # shellcheck source=../grft-raw-config.sh
  . "$(dirname "$0")/../grft-raw-config.sh"
fi
CLI_RAW_BASE="${CLI_RAW_BASE:-${GRFT_CLI_RAW_BASE:-https://raw.githubusercontent.com/grft-dev/graftcode/refs/heads/develop/cli}}"
GRFT_RAW_BASE="${GRFT_RAW_BASE:-$CLI_RAW_BASE}"
GRFT_HOME="${GRFT_HOME:-$HOME/.grft}"

say() {
  echo "$@"
}

has_cmd() {
  command -v "$1" >/dev/null 2>&1
}

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
  if ! has_cmd curl; then
    say "Error: curl is required to load $lib_rel from $CLI_RAW_BASE."
    exit 1
  fi
  lib_tmp="$(mktemp)"
  curl -fsSL "$CLI_RAW_BASE/$lib_rel" -o "$lib_tmp"
  sed 's/\r$//' "$lib_tmp" > "${lib_tmp}.lf"
  # shellcheck source=/dev/null
  . "${lib_tmp}.lf"
  rm -f "$lib_tmp" "${lib_tmp}.lf"
}

graft_cli_resolve_cli_dir() {
  case "$0" in
    */*)
      CDPATH= cd -- "$(dirname -- "$0")/.." && pwd
      ;;
    *)
      echo ""
      ;;
  esac
}

graft_cli_source_lib() {
  lib_name="$1"
  lib_rel="lib/$lib_name"

  cli_dir="${GRAFT_CLI_DIR:-$(graft_cli_resolve_cli_dir)}"
  if [ -n "$cli_dir" ] && [ -f "$cli_dir/$lib_rel" ]; then
    GRAFT_CLI_DIR="$cli_dir"
    export GRAFT_CLI_DIR
    graft_cli_source_sh_file "$cli_dir/$lib_rel"
    return
  fi

  graft_cli_source_lib_from_url "$lib_rel"
}

_cli_parent="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
if [ -n "$_cli_parent" ] && [ -f "$_cli_parent/lib/ui.sh" ]; then
  GRAFT_CLI_DIR="$_cli_parent"
  export GRAFT_CLI_DIR
  graft_cli_source_lib ui.sh
  graft_cli_source_lib rules-installer.sh
elif [ -f "$_cli_parent/lib/grft-cli-layout-bootstrap.sh" ]; then
  graft_cli_source_sh_file "$_cli_parent/lib/grft-cli-layout-bootstrap.sh"
  graft_cli_bootstrap_layout "$_cli_parent" || exit 1
  graft_cli_source_lib ui.sh
  graft_cli_source_lib rules-installer.sh
else
  if ! command -v curl >/dev/null 2>&1; then
    say "Error: curl is required to run the rules installer."
    exit 1
  fi
  export GRAFT_CLI_EPHEMERAL=1
  graft_cli_source_lib ui.sh
  graft_cli_source_lib rules-installer.sh
fi

install_rules_for_ide "$IDE"
ui_show_done
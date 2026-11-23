#!/bin/sh
# Installs the Graftcode CLI (grft) into ~/.grft — no admin/sudo required.
set -eu

if [ -n "${GRAFT_CLI_DIR:-}" ] && [ -f "$GRAFT_CLI_DIR/grft-raw-config.sh" ]; then
  # shellcheck source=/dev/null
  . "$GRAFT_CLI_DIR/grft-raw-config.sh"
elif [ -n "${GRFT_INSTALL_SOURCE_DIR:-}" ] && [ -f "$GRFT_INSTALL_SOURCE_DIR/grft-raw-config.sh" ]; then
  # shellcheck source=./grft-raw-config.sh
  . "$GRFT_INSTALL_SOURCE_DIR/grft-raw-config.sh"
elif [ -f "$(dirname "$0")/grft-raw-config.sh" ] 2>/dev/null; then
  _cfg_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
  GRFT_INSTALL_SOURCE_DIR="$_cfg_dir"
  export GRFT_INSTALL_SOURCE_DIR
  # shellcheck source=./grft-raw-config.sh
  . "$_cfg_dir/grft-raw-config.sh"
elif [ -z "${GRFT_CLI_RAW_BASE:-}" ]; then
  case "$0" in
    '' | - | sh | bash)
      if command -v curl >/dev/null 2>&1; then
GRFT_RAW_LOCATOR_SH_URL='https://raw.githubusercontent.com/grft-dev/graftcode/refs/heads/develop/cli/grft-raw-locator.sh'
        cfg_url="$(curl -fsSL "$GRFT_RAW_LOCATOR_SH_URL" </dev/null | tr -d '\r\n')"
        cfg_tmp="$(mktemp)"
        curl -fsSL "$cfg_url" -o "$cfg_tmp" </dev/null
        sed 's/\r$//' "$cfg_tmp" > "${cfg_tmp}.lf"
        # shellcheck source=/dev/null
        . "${cfg_tmp}.lf"
        rm -f "$cfg_tmp" "${cfg_tmp}.lf"
      fi
      ;;
  esac
fi

CLI_RAW_BASE="${CLI_RAW_BASE:-${GRFT_CLI_RAW_BASE:-https://raw.githubusercontent.com/grft-dev/graftcode/refs/heads/develop/cli}}"
GRFT_RAW_BASE="${GRFT_RAW_BASE:-$CLI_RAW_BASE}"
export CLI_RAW_BASE GRFT_RAW_BASE

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
    - | sh | bash | '')
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
    GRAFT_CLI_DIR="$script_dir"
    export GRAFT_CLI_DIR
    graft_cli_source_sh_file "$script_dir/$lib_rel"
    return
  fi

  graft_cli_source_lib_from_url "$lib_rel"
}

if [ -z "${GRFT_INSTALL_SOURCE_DIR:-}" ]; then
  _bootstrap_dir="$(graft_cli_resolve_script_dir)"
  if [ -n "$_bootstrap_dir" ]; then
    GRFT_INSTALL_SOURCE_DIR="$_bootstrap_dir"
    export GRFT_INSTALL_SOURCE_DIR
  fi
fi

if [ -n "${GRAFT_CLI_DIR:-}" ] && [ -f "$GRAFT_CLI_DIR/lib/ui.sh" ]; then
  graft_cli_source_lib ui.sh
  graft_cli_source_lib grft-cli-installer.sh
elif [ -n "${GRFT_INSTALL_SOURCE_DIR:-}" ] && [ -f "$GRFT_INSTALL_SOURCE_DIR/lib/ui.sh" ]; then
  GRAFT_CLI_DIR="$GRFT_INSTALL_SOURCE_DIR"
  export GRAFT_CLI_DIR
  graft_cli_source_lib ui.sh
  graft_cli_source_lib grft-cli-installer.sh
else
  if ! command -v curl >/dev/null 2>&1; then
    echo "Error: curl is required to run the CLI installer." >&2
    exit 1
  fi
  export GRAFT_CLI_EPHEMERAL=1
  graft_cli_source_lib ui.sh
  graft_cli_source_lib grft-cli-installer.sh
fi

install_grft_to_home
ui_show_done
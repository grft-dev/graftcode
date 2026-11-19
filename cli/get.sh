#!/bin/sh
# GRFT_VERSION=0.1.2
if ! [ -t 0 ]; then
  GRFT_PIPE_INVOCATION=1
  export GRFT_PIPE_INVOCATION
fi
set -eu

GRFT_VERSION="0.1.2"
if [ -n "${GRAFT_CLI_DIR:-}" ] && [ -f "$GRAFT_CLI_DIR/grft-raw-config.sh" ]; then
  # shellcheck source=/dev/null
  . "$GRAFT_CLI_DIR/grft-raw-config.sh"
elif [ -f "$(dirname "$0")/grft-raw-config.sh" ]; then
  # shellcheck source=./grft-raw-config.sh
  . "$(dirname "$0")/grft-raw-config.sh"
fi
GRFT_RAW_BASE="${GRFT_RAW_BASE:-${GRFT_CLI_RAW_BASE:-https://raw.githubusercontent.com/grft-dev/graftcode/refs/heads/main/cli}}"
CLI_RAW_BASE="${CLI_RAW_BASE:-$GRFT_RAW_BASE}"
export GRFT_CLI_RAW_BASE="${GRFT_CLI_RAW_BASE:-$GRFT_RAW_BASE}"
GRFT_HOME="${GRFT_HOME:-$HOME/.grft}"

REPO="grft-dev/graftcode-gateway"
EXE_NAME="gg"
OUTPUT_PATH="$PWD/$EXE_NAME"

say() {
  echo "$@"
}

say_no_newline() {
  printf '%s' "$1"
}

grft_dev_tty_usable() {
  if ! [ -e /dev/tty ]; then
    return 1
  fi
  ( exec 3</dev/tty ) 2>/dev/null
}

grft_is_interactive_tty() {
  if [ -t 0 ] && [ -t 1 ]; then
    return 0
  fi
  if [ -t 1 ] || [ -t 2 ]; then
    return 0
  fi
  if ! [ -t 0 ] && grft_dev_tty_usable; then
    return 0
  fi
  return 1
}

graft_cli_ensure_ui_lib() {
  if [ -n "${GRAFT_UI_LIB_LOADED:-}" ]; then
    return 0
  fi
  if command -v ui_show_gateway_logo >/dev/null 2>&1; then
    GRAFT_UI_LIB_LOADED=1
    return 0
  fi
  CLI_RAW_BASE="${CLI_RAW_BASE:-$GRFT_RAW_BASE}"
  if ! command -v curl >/dev/null 2>&1; then
    return 1
  fi
  ui_tmp="$(mktemp)"
  curl -fsSL "$CLI_RAW_BASE/lib/ui.sh" -o "$ui_tmp" </dev/null || {
    rm -f "$ui_tmp"
    return 1
  }
  sh_local="$(mktemp)"
  sed 's/\r$//' "$ui_tmp" > "$sh_local"
  # shellcheck source=/dev/null
  . "$sh_local"
  rm -f "$ui_tmp" "$sh_local"
  GRAFT_UI_LIB_LOADED=1
}

grft_plugin_ids_from_raw_manifest() {
  if ! command -v curl >/dev/null 2>&1; then
    return 1
  fi
  curl -fsSL "$GRFT_RAW_BASE/plugins.manifest.json" </dev/null 2>/dev/null |
    sed -n 's/.*"id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' |
    tr '\n' ',' |
    sed 's/,$//'
}

show_intro() {
  if grft_is_interactive_tty; then
    clear 2>/dev/null || true
  fi

  if graft_cli_ensure_ui_lib && command -v ui_show_gateway_logo >/dev/null 2>&1; then
    ui_show_gateway_logo
    say ""
  fi

  say "Graftcode helps you generate AI code that integrates through Graftcode."
  say "It can reduce boilerplate, simplify PRs, and save up to 80% of tokens."
  say ""
  say "This installer can:"
  say "  1. Download Graftcode Rules file for your IDE"
  say "     - so AI can generate code that integrates everything through Graftcode"
  say "  2. Download Graftcode Gateway"
  say "     - gateway for your processor"
  say "  3. Download Graftcode Plugins"
  plugin_manifest=""
  script_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
  if [ -n "${GRAFT_CLI_DIR:-}" ] && [ -f "$GRAFT_CLI_DIR/plugins.manifest.json" ]; then
    plugin_manifest="$GRAFT_CLI_DIR/plugins.manifest.json"
  elif [ -f "$script_dir/plugins.manifest.json" ]; then
    plugin_manifest="$script_dir/plugins.manifest.json"
  elif [ -f "$GRFT_HOME/plugins.manifest.json" ]; then
    plugin_manifest="$GRFT_HOME/plugins.manifest.json"
  fi
  plugin_names=""
  if [ -n "$plugin_manifest" ] && [ -f "$plugin_manifest" ]; then
    plugin_names="$(sed -n 's/.*"id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$plugin_manifest" | tr '\n' ',' | sed 's/,$//')"
  elif plugin_names="$(grft_plugin_ids_from_raw_manifest)" && [ -n "$plugin_names" ]; then
    :
  fi
  if [ -n "$plugin_names" ]; then
    say "     - messaging plugins for the gateway ($plugin_names)"
  else
    say "     - messaging plugins for the gateway"
  fi
  if is_grft_home_present; then
    say "  4. Uninstall Graftcode CLI"
    say "     - remove ~/.grft and PATH entry"
  fi
  say ""
}

has_cmd() {
  command -v "$1" >/dev/null 2>&1
}

is_grft_home_present() {
  [ -f "$GRFT_HOME/get.sh" ]
}

read_from_tty() {
  prompt="$1"
  choice=""

  if grft_dev_tty_usable; then
    printf '%s' "$prompt" >/dev/tty
    exec 3</dev/tty
    IFS= read -r choice <&3 || choice=""
    exec 3<&-
  else
    printf '%s' "$prompt"
    IFS= read -r choice || choice=""
  fi

  choice="$(printf '%s' "$choice" | tr -d '\r' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
  echo "$choice"
}

read_choice_set() {
  valid="$1"
  label="$2"

  while :; do
    choice="$(read_from_tty "Enter choice [$label]: ")"

    for v in $valid; do
      if [ "$choice" = "$v" ]; then
        echo "$choice"
        return 0
      fi
    done

    say "Invalid choice. Available options: $(echo "$valid" | sed 's/ /, /g')"
  done
}

download_file() {
  url="$1"
  output="$2"
  label="$3"

  say "Downloading $label..."

  if has_cmd curl; then
    curl -fL "$url" -o "$output" </dev/null
  elif has_cmd wget; then
    wget -O "$output" "$url"
  elif has_cmd busybox; then
    busybox wget -O "$output" "$url"
  else
    say "Error: curl, wget or busybox wget is required to download files."
    exit 1
  fi

  say "Downloaded $label"
}

graft_cli_load_rules_install_stack() {
  if command -v install_rules_for_ide >/dev/null 2>&1; then
    return 0
  fi

  CLI_RAW_BASE="${CLI_RAW_BASE:-$GRFT_RAW_BASE}"

  if ! graft_cli_ensure_ui_lib; then
    say "Error: could not load ui.sh from $CLI_RAW_BASE"
    exit 1
  fi

  if [ -n "${GRAFT_CLI_DIR:-}" ] && [ -f "$GRAFT_CLI_DIR/lib/rules-installer.sh" ]; then
    graft_cli_source_sh_file "$GRAFT_CLI_DIR/lib/rules-installer.sh"
    return 0
  fi

  if graft_cli_is_ephemeral_pipe_invocation && has_cmd curl; then
    export GRAFT_CLI_EPHEMERAL=1
    graft_cli_source_lib_from_url "lib/rules-installer.sh"
    return 0
  fi

  if has_cmd curl; then
    graft_cli_source_lib_from_url "lib/rules-installer.sh"
    return 0
  fi

  say "Error: rules-installer.sh missing."
  exit 1
}

install_rules() {
  graft_cli_load_rules_install_stack

  if [ "$#" -ge 1 ] && [ -n "$1" ]; then
    install_rules_for_ide "$1"
    return 0
  fi

  if ! grft_is_interactive_tty; then
    say "No interactive terminal — specify an IDE, e.g.: grft get rules cursor"
    show_help
    exit 2
  fi

  say ""
  say "Choose IDE:"
  say "  1. Cursor"
  say "  2. Claude Code"
  say "  3. GitHub Copilot"
  say "  4. Cline"
  say "  5. Windsurf"
  say "  6. Continue"
  say "  7. Aider"
  say ""

  ide_choice="$(read_choice_set "1 2 3 4 5 6 7" "1-7")"
  install_rules_for_ide "$ide_choice"
}

graft_cli_source_sh_file() {
  sh_path="$1"
  sh_local="$(mktemp)"
  sed 's/\r$//' "$sh_path" > "$sh_local"
  # shellcheck source=/dev/null
  . "$sh_local"
  rm -f "$sh_local"
}

graft_cli_is_ephemeral_pipe_invocation() {
  if [ "${GRFT_PIPE_INVOCATION:-}" = "1" ]; then
    return 0
  fi
  case "${0:-}" in
    '' | - | sh | bash) return 0 ;;
    *) return 1 ;;
  esac
}

graft_cli_source_lib_from_url() {
  lib_rel="$1"
  CLI_RAW_BASE="${CLI_RAW_BASE:-$GRFT_RAW_BASE}"
  if ! has_cmd curl; then
    say "Error: curl is required to load $lib_rel from $CLI_RAW_BASE."
    exit 1
  fi
  lib_tmp="$(mktemp)"
  curl -fsSL "$CLI_RAW_BASE/$lib_rel" -o "$lib_tmp" </dev/null || {
    rm -f "$lib_tmp"
    say "Error: failed to load $lib_rel from $CLI_RAW_BASE."
    exit 1
  }
  graft_cli_source_sh_file "$lib_tmp"
  rm -f "$lib_tmp"
}

graft_cli_ensure_gateway_installer_libs() {
  if [ -n "${GRAFT_GATEWAY_INSTALLER_LOADED:-}" ]; then
    return 0
  fi

  CLI_RAW_BASE="${CLI_RAW_BASE:-$GRFT_RAW_BASE}"

  if command -v install_gg_to_cwd >/dev/null 2>&1; then
    GRAFT_GATEWAY_INSTALLER_LOADED=1
    return 0
  fi

  if [ -n "${GRAFT_CLI_DIR:-}" ] && [ -f "$GRAFT_CLI_DIR/lib/gateway-installer.sh" ]; then
    graft_cli_source_sh_file "$GRAFT_CLI_DIR/lib/ui.sh"
    graft_cli_source_sh_file "$GRAFT_CLI_DIR/lib/gateway-installer.sh"
    GRAFT_GATEWAY_INSTALLER_LOADED=1
    return 0
  fi

  if graft_cli_is_ephemeral_pipe_invocation && has_cmd curl; then
    if ! command -v ui_show_gateway_intro >/dev/null 2>&1; then
      graft_cli_source_lib_from_url "lib/ui.sh"
    fi
    graft_cli_source_lib_from_url "lib/gateway-installer.sh"
    GRAFT_GATEWAY_INSTALLER_LOADED=1
    return 0
  fi

  script_dir=""
  if [ -n "${GRAFT_CLI_DIR:-}" ] && [ -d "$GRAFT_CLI_DIR" ]; then
    script_dir="$GRAFT_CLI_DIR"
  else
    script_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
  fi

  if [ -f "$script_dir/lib/grft-cli-layout-bootstrap.sh" ]; then
    graft_cli_source_sh_file "$script_dir/lib/grft-cli-layout-bootstrap.sh"
    graft_cli_bootstrap_layout "$script_dir" || exit 1
  elif has_cmd curl; then
    ensure_tmp="$(mktemp)"
    curl -fsSL "$CLI_RAW_BASE/ensure-sh-cli-layout.sh" -o "$ensure_tmp" </dev/null
    # shellcheck source=/dev/null
    . "$ensure_tmp"
    rm -f "$ensure_tmp"
    graft_cli_load_and_initialize_layout || exit 1
  else
    say "Error: curl is required to load gateway installer libraries."
    exit 1
  fi

  if [ -n "${GRAFT_CLI_DIR:-}" ] && [ -f "$GRAFT_CLI_DIR/lib/ui.sh" ]; then
    graft_cli_source_sh_file "$GRAFT_CLI_DIR/lib/ui.sh"
    graft_cli_source_sh_file "$GRAFT_CLI_DIR/lib/gateway-installer.sh"
  else
    say "Error: CLI layout not initialized."
    exit 1
  fi

  GRAFT_GATEWAY_INSTALLER_LOADED=1
}

graft_cli_load_plugin_install_stack() {
  if command -v graft_plugin_resolve_id >/dev/null 2>&1; then
    return 0
  fi

  graft_cli_ensure_gateway_installer_libs
  CLI_RAW_BASE="${CLI_RAW_BASE:-$GRFT_RAW_BASE}"

  if [ -n "${GRAFT_CLI_DIR:-}" ] && [ -f "$GRAFT_CLI_DIR/lib/plugin-manifest.sh" ]; then
    graft_cli_source_sh_file "$GRAFT_CLI_DIR/lib/plugin-manifest.sh"
    if [ -f "$GRAFT_CLI_DIR/lib/plugin-installer.sh" ]; then
      graft_cli_source_sh_file "$GRAFT_CLI_DIR/lib/plugin-installer.sh"
    fi
    graft_cli_ensure_plugin_manifest_file
    return 0
  fi

  if graft_cli_is_ephemeral_pipe_invocation && has_cmd curl; then
    export GRAFT_CLI_EPHEMERAL=1
    graft_cli_source_lib_from_url "lib/plugin-manifest.sh"
    graft_cli_source_lib_from_url "lib/plugin-installer.sh"
    graft_cli_ensure_plugin_manifest_file
    return 0
  fi

  if has_cmd curl; then
    ensure_tmp="$(mktemp)"
    curl -fsSL "$CLI_RAW_BASE/ensure-sh-cli-layout.sh" -o "$ensure_tmp" </dev/null
    # shellcheck source=/dev/null
    . "$ensure_tmp"
    rm -f "$ensure_tmp"
    graft_cli_load_and_initialize_layout || exit 1
  fi

  if [ -n "${GRAFT_CLI_DIR:-}" ] && [ -f "$GRAFT_CLI_DIR/lib/plugin-manifest.sh" ]; then
    graft_cli_source_sh_file "$GRAFT_CLI_DIR/lib/plugin-manifest.sh"
    graft_cli_source_sh_file "$GRAFT_CLI_DIR/lib/plugin-installer.sh"
    graft_cli_ensure_plugin_manifest_file
    return 0
  fi

  say "Error: plugin-manifest.sh missing after layout ensure."
  exit 1
}

install_gateway() {
  say "Preparing Graftcode Gateway download..."
  graft_cli_ensure_gateway_installer_libs
  install_gg_to_cwd
}

install_plugins() {
  graft_cli_load_plugin_install_stack

  manifest="$(graft_plugin_manifest_path)"
  if [ ! -f "$manifest" ]; then
    say "Error: missing plugins.manifest.json"
    exit 1
  fi

  plugin=""
  if [ "$#" -ge 1 ]; then
    plugin="$(echo "$1" | tr 'ABCDEFGHIJKLMNOPQRSTUVWXYZ' 'abcdefghijklmnopqrstuvwxyz')"
  fi

  if [ -z "$plugin" ]; then
    if ! grft_is_interactive_tty; then
      say "No interactive terminal — specify a plugin, e.g.: grft get plugin rabbitmq"
      say "Available: $(graft_plugin_help_names "$manifest")"
      show_help
      exit 2
    fi
    say ""
    say "Choose plugin:"
    graft_plugin_print_menu "$manifest"
    say ""
    menu_choices="$(graft_plugin_menu_choices "$manifest")"
    choice_hint="$(echo "$menu_choices" | sed 's/ /,/g')"
    plugin="$(read_choice_set "$menu_choices" "$choice_hint")"
  fi

  resolved="$(graft_plugin_resolve_id "$manifest" "$plugin")" || {
    say "Unknown plugin '$1'. Available: $(graft_plugin_help_names "$manifest")"
    exit 1
  }

  label="$(graft_plugin_label_for_id "$manifest" "$resolved")"
  if [ -z "$label" ]; then
    label="$resolved"
  fi

  install_plugin "$resolved" "$label"
}

script_dir() {
  script="$0"
  case "$script" in
    /*) dirname "$script" ;;
    *) dirname "$(pwd)/$script" ;;
  esac
}

is_installed_copy() {
  dir="$(CDPATH= cd -- "$(script_dir)" && pwd)"
  home="$(CDPATH= cd -- "$GRFT_HOME" 2>/dev/null && pwd || echo "$GRFT_HOME")"
  [ "$dir" = "$home" ]
}

version_lt() {
  left="$1"
  right="$2"

  if has_cmd sort; then
    lowest="$(printf '%s\n%s\n' "$left" "$right" | sort -V | head -n 1)"
    [ "$lowest" = "$left" ] && [ "$left" != "$right" ]
    return $?
  fi

  [ "$left" != "$right" ]
}

maybe_self_update() {
  if [ "${GRFT_SKIP_UPDATE:-}" = "1" ]; then
    return 0
  fi

  if ! is_installed_copy; then
    return 0
  fi

  remote=""
  if has_cmd curl; then
    remote="$(curl -fsSL "$GRFT_RAW_BASE/VERSION" 2>/dev/null | tr -d '[:space:]' || true)"
  elif has_cmd wget; then
    remote="$(wget -qO- "$GRFT_RAW_BASE/VERSION" 2>/dev/null | tr -d '[:space:]' || true)"
  else
    return 0
  fi

  if [ -z "$remote" ]; then
    return 0
  fi

  if ! version_lt "$GRFT_VERSION" "$remote"; then
    return 0
  fi

  say "Updating grft CLI $GRFT_VERSION -> $remote ..."

  mkdir -p "$GRFT_HOME/bin"
  download_file "$GRFT_RAW_BASE/get.sh" "$GRFT_HOME/get.sh" "get.sh"
  download_file "$GRFT_RAW_BASE/VERSION" "$GRFT_HOME/VERSION" "VERSION"
  download_file "$GRFT_RAW_BASE/bin/grft" "$GRFT_HOME/bin/grft" "grft" || true
  chmod +x "$GRFT_HOME/get.sh" "$GRFT_HOME/bin/grft" 2>/dev/null || true

  GRFT_SKIP_UPDATE=1 exec sh "$GRFT_HOME/get.sh" "$@"
}

show_help() {
  say "grft — Graftcode CLI ($GRFT_VERSION)"
  say ""
  say "Usage:"
  say "  grft                          Interactive installer"
  say "  grft get                      Interactive installer"
  say "  grft get gg                   Download Graftcode Gateway"
  say "  grft get rules <ide>          Install AI rules (cursor, claude, copilot, ...)"
  say "  grft get plugin <name>        Install gateway plugin (plugins.manifest.json)"
  say "  grft uninstall                Remove ~/.grft and PATH entry"
  say "  grft version                  Show CLI version"
  say ""
}

strip_path_rc() {
  rc_file="$1"
  if [ ! -f "$rc_file" ]; then
    return 0
  fi

  if ! grep -F '.grft/bin' "$rc_file" >/dev/null 2>&1; then
    return 0
  fi

  tmp_file="$(mktemp)"
  # Drop Graftcode CLI block lines and bare PATH exports that mention .grft/bin
  awk '
    /^# Graftcode CLI$/ { skip=1; next }
    skip && /^export PATH=.*\.grft\/bin/ { skip=0; next }
    skip { skip=0 }
    /\.grft\/bin/ { next }
    { print }
  ' "$rc_file" > "$tmp_file"
  mv "$tmp_file" "$rc_file"
  say "Removed PATH entry from $rc_file"
}

uninstall_grft() {
  bin_dir="$GRFT_HOME/bin"
  removed_home=0
  removed_path=0

  # Drop bin dir from current session PATH without requiring paste(1).
  new_path=""
  old_ifs=$IFS
  IFS=:
  # shellcheck disable=SC2086
  for p in $PATH; do
    [ "$p" = "$bin_dir" ] && continue
    if [ -z "$new_path" ]; then
      new_path="$p"
    else
      new_path="$new_path:$p"
    fi
  done
  IFS=$old_ifs
  if [ "$PATH" != "$new_path" ]; then
    PATH="$new_path"
    export PATH
    removed_path=1
  fi

  for rc_file in "$HOME/.zshrc" "$HOME/.bashrc" "$HOME/.bash_profile" "$HOME/.profile"; do
    if [ -f "$rc_file" ] && grep -F '.grft/bin' "$rc_file" >/dev/null 2>&1; then
      strip_path_rc "$rc_file"
      removed_path=1
    fi
  done

  if [ -d "$GRFT_HOME" ]; then
    rm -rf "$GRFT_HOME"
    removed_home=1
    say "Removed $GRFT_HOME"
  fi

  if [ "$removed_home" -eq 0 ] && [ "$removed_path" -eq 0 ]; then
    say "Graftcode CLI is not installed (no $GRFT_HOME found)."
    return 0
  fi

  say ""
  say "Uninstalled Graftcode CLI."
  say "Open a new terminal if grft is still resolved from a cached PATH."
}

run_interactive() {
  if ! grft_is_interactive_tty; then
    say "No interactive terminal — use non-interactive commands:"
    show_help
    exit 2
  fi

  show_intro

  say "What do you want to do?"
  say "  1. Graftcode Rules file"
  say "  2. Graftcode Gateway"
  say "  3. Graftcode Plugins"

  if is_grft_home_present; then
    say "  4. Uninstall Graftcode CLI"
    say ""
    choice="$(read_choice_set "1 2 3 4" "1/2/3/4")"
  else
    say ""
    choice="$(read_choice_set "1 2 3" "1/2/3")"
  fi

  case "$choice" in
    1) install_rules ;;
    2) install_gateway ;;
    3) install_plugins ;;
    4)
      uninstall_grft
      return 0
      ;;
  esac

  say ""
  say "Done."
}

run_command() {
  if [ "$#" -eq 0 ]; then
    run_interactive
    return 0
  fi

  cmd="$(echo "$1" | tr 'ABCDEFGHIJKLMNOPQRSTUVWXYZ' 'abcdefghijklmnopqrstuvwxyz')"

  case "$cmd" in
    version|--version|-v)
      say "grft $GRFT_VERSION"
      return 0
      ;;
    help|--help|-h)
      show_help
      return 0
      ;;
    uninstall|remove)
      uninstall_grft
      return 0
      ;;
    get)
      ;;
    *)
      show_help
      say "Unknown command '$1'. Try: grft get ..., grft uninstall, grft version"
      exit 1
      ;;
  esac

  if [ "$#" -eq 1 ]; then
    run_interactive
    return 0
  fi

  target="$(echo "$2" | tr 'ABCDEFGHIJKLMNOPQRSTUVWXYZ' 'abcdefghijklmnopqrstuvwxyz')"

  case "$target" in
    gg|gateway)
      install_gateway
      ;;
    rules|rule)
      if [ "$#" -ge 3 ]; then
        install_rules "$3"
      else
        install_rules
      fi
      ;;
    plugin|plugins)
      if [ "$#" -ge 3 ]; then
        install_plugins "$3"
      else
        install_plugins
      fi
      ;;
    *)
      show_help
      say "Unknown get target '$2'. Use: gg, rules, plugin"
      exit 1
      ;;
  esac

  say ""
  say "Done."
}

maybe_self_update "$@"
run_command "$@"

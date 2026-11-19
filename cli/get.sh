#!/bin/sh
# GRFT_VERSION=0.1.2
set -eu

GRFT_VERSION="0.1.2"
GRFT_RAW_BASE="https://raw.githubusercontent.com/grft-dev/graftcode/refs/heads/main/cli"
GRFT_HOME="${GRFT_HOME:-$HOME/.grft}"

REPO="grft-dev/graftcode-gateway"
EXE_NAME="gg"
OUTPUT_PATH="$PWD/$EXE_NAME"

RULES_RAW_BASE="https://raw.githubusercontent.com/grft-dev/graftcode/refs/heads/main/rules"
RULE_LANGS="dotnet java kotlin php python ruby typescript-node-nextjs"

say() {
  echo "$@"
}

say_no_newline() {
  printf '%s' "$1"
}

grft_is_interactive_tty() {
  [ -t 0 ] && [ -t 1 ]
}

show_intro() {
  if grft_is_interactive_tty; then
    clear 2>/dev/null || true
  fi

  cat <<'EOF'
   _____            __ _                 _
  / ____|          / _| |               | |
 | |  __ _ __ __ _| |_| |_ ___ ___   __| | ___
 | | |_ | '__/ _` |  _| __/ __/ _ \ / _` |/ _ \
 | |__| | | | (_| | | | || (_| (_) | (_| |  __/
  \_____|_|  \__,_|_|  \__\___\___/ \__,_|\___|

EOF

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

  if [ -r /dev/tty ]; then
    say_no_newline "$prompt"
    IFS= read -r choice < /dev/tty || choice=""
  else
    printf "%s" "$prompt"
    IFS= read -r choice || choice=""
  fi

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
    curl -fL "$url" -o "$output"
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

download_rule_set() {
  remote_dir="$1"
  local_dir="$2"
  ext="$3"
  include_router="$4"

  mkdir -p "$local_dir"

  set_list="$RULE_LANGS"
  if [ "$include_router" = "yes" ]; then
    set_list="router $RULE_LANGS"
  fi

  for name in $set_list; do
    fname="graftcode-$name.$ext"
    download_file "$remote_dir/$fname" "$local_dir/$fname" "$fname"
  done
}

install_rules_for_ide() {
  ide="$(echo "$1" | tr 'ABCDEFGHIJKLMNOPQRSTUVWXYZ' 'abcdefghijklmnopqrstuvwxyz')"

  case "$ide" in
    cursor|1)
      target_dir="$PWD/.cursor/rules"
      download_rule_set "$RULES_RAW_BASE/Cursor/.cursor/rules" "$target_dir" "mdc" "yes"
      say ""
      say "Installed Graftcode Cursor rules in:"
      say "$target_dir"
      ;;
    claude|claude-code|2)
      download_file "$RULES_RAW_BASE/Claude/CLAUDE.md" "$PWD/CLAUDE.md" "CLAUDE.md"
      target_dir="$PWD/.claude/rules"
      download_rule_set "$RULES_RAW_BASE/Claude/.claude/rules" "$target_dir" "md" "no"
      say ""
      say "Installed Graftcode Claude Code rules in:"
      say "$PWD/CLAUDE.md"
      say "$target_dir"
      ;;
    copilot|github-copilot|github|3)
      mkdir -p "$PWD/.github"
      download_file "$RULES_RAW_BASE/Copilot/.github/copilot-instructions.md" "$PWD/.github/copilot-instructions.md" "copilot-instructions.md"
      target_dir="$PWD/.github/instructions"
      download_rule_set "$RULES_RAW_BASE/Copilot/.github/instructions" "$target_dir" "instructions.md" "no"
      say ""
      say "Installed Graftcode GitHub Copilot rules in:"
      say "$PWD/.github/copilot-instructions.md"
      say "$target_dir"
      ;;
    cline|4)
      target_dir="$PWD/.clinerules"
      download_rule_set "$RULES_RAW_BASE/Cline/.clinerules" "$target_dir" "md" "yes"
      say ""
      say "Installed Graftcode Cline rules in:"
      say "$target_dir"
      ;;
    windsurf|5)
      target_dir="$PWD/.windsurf/rules"
      download_rule_set "$RULES_RAW_BASE/Windsurf/.windsurf/rules" "$target_dir" "md" "yes"
      say ""
      say "Installed Graftcode Windsurf rules in:"
      say "$target_dir"
      ;;
    continue|6)
      target_dir="$PWD/.continue/rules"
      download_rule_set "$RULES_RAW_BASE/Continue/.continue/rules" "$target_dir" "md" "yes"
      say ""
      say "Installed Graftcode Continue rules in:"
      say "$target_dir"
      ;;
    aider|7)
      download_file "$RULES_RAW_BASE/Aider/CONVENTIONS.md" "$PWD/CONVENTIONS.md" "CONVENTIONS.md"
      download_file "$RULES_RAW_BASE/Aider/.aider.conf.yml" "$PWD/.aider.conf.yml" ".aider.conf.yml"
      say ""
      say "Installed Graftcode Aider rules in:"
      say "$PWD/CONVENTIONS.md"
      say "$PWD/.aider.conf.yml"
      ;;
    *)
      say "Unknown IDE '$1'. Use: cursor, claude, copilot, cline, windsurf, continue, aider"
      exit 1
      ;;
  esac
}

install_rules() {
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

graft_cli_ensure_gateway_installer_libs() {
  if [ -n "${GRAFT_GATEWAY_INSTALLER_LOADED:-}" ]; then
    return 0
  fi

  CLI_RAW_BASE="${CLI_RAW_BASE:-$GRFT_RAW_BASE}"
  script_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"

  if [ -f "$script_dir/lib/ui.sh" ]; then
    graft_cli_source_sh_file "$script_dir/lib/ui.sh"
    graft_cli_source_sh_file "$script_dir/lib/gateway-installer.sh"
  elif [ -n "${GRAFT_CLI_DIR:-}" ] && [ -f "$GRAFT_CLI_DIR/lib/ui.sh" ]; then
    graft_cli_source_sh_file "$GRAFT_CLI_DIR/lib/ui.sh"
    graft_cli_source_sh_file "$GRAFT_CLI_DIR/lib/gateway-installer.sh"
  elif has_cmd curl; then
    ui_tmp="$(mktemp)"
    gi_tmp="$(mktemp)"
    curl -fsSL "$CLI_RAW_BASE/lib/ui.sh" -o "$ui_tmp"
    curl -fsSL "$CLI_RAW_BASE/lib/gateway-installer.sh" -o "$gi_tmp"
    graft_cli_source_sh_file "$ui_tmp"
    graft_cli_source_sh_file "$gi_tmp"
    rm -f "$ui_tmp" "$gi_tmp"
  else
    say "Error: curl is required to load gateway installer libraries."
    exit 1
  fi

  GRAFT_GATEWAY_INSTALLER_LOADED=1
}

install_gateway() {
  graft_cli_ensure_gateway_installer_libs
  install_gg_to_cwd
}

install_plugins() {
  if [ -n "${GRAFT_CLI_DIR:-}" ] && [ -f "$GRAFT_CLI_DIR/lib/plugin-manifest.sh" ]; then
    graft_cli_source_sh_file "$GRAFT_CLI_DIR/lib/plugin-manifest.sh"
  else
    _plug_lib_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
    graft_cli_source_sh_file "$_plug_lib_dir/lib/plugin-manifest.sh"
  fi

  graft_cli_ensure_plugin_manifest_file

  manifest="$(graft_plugin_manifest_path)"
  if [ ! -f "$manifest" ]; then
    say "Error: missing plugins.manifest.json"
    exit 1
  fi

  graft_cli_ensure_gateway_installer_libs
  if [ -n "${GRAFT_CLI_DIR:-}" ] && [ -f "$GRAFT_CLI_DIR/lib/plugin-installer.sh" ]; then
    graft_cli_source_sh_file "$GRAFT_CLI_DIR/lib/plugin-installer.sh"
  else
    _plug_lib_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
    graft_cli_source_sh_file "$_plug_lib_dir/lib/plugin-installer.sh"
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
    if grft_is_interactive_tty; then
      run_interactive
    else
      say "No interactive terminal — use non-interactive commands:"
      show_help
      exit 2
    fi
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
    if grft_is_interactive_tty; then
      run_interactive
    else
      say "No interactive terminal — use non-interactive commands:"
      show_help
      exit 2
    fi
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

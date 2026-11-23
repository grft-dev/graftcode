# shellcheck shell=sh
# Dot-source from get.sh (after CLI_RAW_BASE is known).

grft_installer_copy_resolve_file() {
  name="$1"
  if [ -n "${GRAFT_CLI_DIR:-}" ] && [ -f "$GRAFT_CLI_DIR/assets/$name" ]; then
    cat "$GRAFT_CLI_DIR/assets/$name"
    return 0
  fi
  case "$0" in
    */*)
      root="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
      if [ -f "$root/assets/$name" ]; then
        cat "$root/assets/$name"
        return 0
      fi
      ;;
  esac
  base="${CLI_RAW_BASE:-${GRFT_RAW_BASE:-}}"
  if [ -n "$base" ] && command -v curl >/dev/null 2>&1; then
    curl -fsSL "$base/assets/$name" </dev/null
    return 0
  fi
  return 1
}

grft_print_installer_intro() {
  plugin_names="${1:-}"
  with_uninstall="${2:-0}"
  body="$(grft_installer_copy_resolve_file installer-intro.txt)" || return 1
  printf '%s\n' "$body" | while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in
      *"messaging plugins for the gateway"*)
        if [ -n "$plugin_names" ]; then
          say "${line} (${plugin_names})"
        else
          say "$line"
        fi
        ;;
      *)
        say "$line"
        ;;
    esac
  done
  if [ "$with_uninstall" = 1 ]; then
    say "  4. Uninstall Graftcode CLI"
    say "     - remove ~/.grft and PATH entry"
  fi
  say ""
}

grft_print_installer_menu() {
  with_uninstall="${1:-0}"
  body="$(grft_installer_copy_resolve_file installer-menu.txt)" || return 1
  printf '%s\n' "$body" | while IFS= read -r line || [ -n "$line" ]; do
    say "$line"
  done
  if [ "$with_uninstall" = 1 ]; then
    say "  4. Uninstall Graftcode CLI"
  fi
  say ""
}
# shellcheck shell=sh
# Dot-source after ui.sh (from get.sh or rules deep link).

GRFT_RULE_LANGS="dotnet java kotlin php python ruby typescript-node-nextjs"

graft_cli_ensure_rules_installer_libs() {
  if [ -n "${GRAFT_RULES_INSTALLER_LOADED:-}" ]; then
    return 0
  fi
  if ! command -v ui_show_gateway_intro >/dev/null 2>&1; then
    say "Error: ui.sh must be loaded before rules-installer.sh"
    exit 1
  fi
  if ! command -v ui_download_file >/dev/null 2>&1; then
    say "Error: ui.sh must be loaded before rules-installer.sh"
    exit 1
  fi
  GRAFT_RULES_INSTALLER_LOADED=1
}

graft_rules_resolve_raw_base() {
  if [ -n "${GRFT_RULES_RAW_BASE:-}" ]; then
    printf '%s' "${GRFT_RULES_RAW_BASE%/}"
    return 0
  fi
  cli="${GRFT_CLI_RAW_BASE:-${CLI_RAW_BASE:-${GRFT_RAW_BASE:-}}}"
  if [ -n "$cli" ]; then
    case "$cli" in
      */cli) printf '%s' "${cli%/cli}/rules" ;;
      *) printf '%s/rules' "${cli%/}" ;;
    esac
    return 0
  fi
  printf '%s' "https://raw.githubusercontent.com/grft-dev/graftcode/refs/heads/develop/rules"
}

graft_rules_ide_label() {
  ide="$(echo "$1" | tr 'ABCDEFGHIJKLMNOPQRSTUVWXYZ' 'abcdefghijklmnopqrstuvwxyz')"
  case "$ide" in
    cursor|1) echo "Cursor" ;;
    claude|claude-code|2) echo "Claude Code" ;;
    copilot|github-copilot|github|3) echo "GitHub Copilot" ;;
    cline|4) echo "Cline" ;;
    windsurf|5) echo "Windsurf" ;;
    continue|6) echo "Continue" ;;
    aider|7) echo "Aider" ;;
    *) echo "$1" ;;
  esac
}

graft_rules_download_file() {
  url="$1"
  output="$2"
  label="$3"
  ui_download_file "$url" "$output" "$label" 1
}

download_rule_set() {
  remote_dir="$1"
  local_dir="$2"
  ext="$3"
  include_router="$4"

  mkdir -p "$local_dir"

  set_list="$GRFT_RULE_LANGS"
  if [ "$include_router" = "yes" ]; then
    set_list="router $GRFT_RULE_LANGS"
  fi

  for name in $set_list; do
    fname="graftcode-$name.$ext"
    graft_rules_download_file "$remote_dir/$fname" "$local_dir/$fname" "$fname"
  done
}

install_rules_for_ide() {
  graft_cli_ensure_rules_installer_libs

  ide="$(echo "$1" | tr 'ABCDEFGHIJKLMNOPQRSTUVWXYZ' 'abcdefghijklmnopqrstuvwxyz')"
  rules_base="$(graft_rules_resolve_raw_base)"
  ide_label="$(graft_rules_ide_label "$ide")"

  ui_show_gateway_intro
  ui_obtaining_rules_for_ide "$ide_label"

  case "$ide" in
    cursor|1)
      target_dir="$PWD/.cursor/rules"
      download_rule_set "$rules_base/Cursor/.cursor/rules" "$target_dir" "mdc" "yes"
      ui_show_rules_installed "$ide_label" "$target_dir"
      ;;
    claude|claude-code|2)
      claude_md="$PWD/CLAUDE.md"
      graft_rules_download_file "$rules_base/Claude/CLAUDE.md" "$claude_md" "CLAUDE.md"
      target_dir="$PWD/.claude/rules"
      download_rule_set "$rules_base/Claude/.claude/rules" "$target_dir" "md" "no"
      ui_show_rules_installed "$ide_label" "$claude_md" "$target_dir"
      ;;
    copilot|github-copilot|github|3)
      mkdir -p "$PWD/.github"
      copilot_md="$PWD/.github/copilot-instructions.md"
      graft_rules_download_file "$rules_base/Copilot/.github/copilot-instructions.md" "$copilot_md" "copilot-instructions.md"
      target_dir="$PWD/.github/instructions"
      download_rule_set "$rules_base/Copilot/.github/instructions" "$target_dir" "instructions.md" "no"
      ui_show_rules_installed "$ide_label" "$copilot_md" "$target_dir"
      ;;
    cline|4)
      target_dir="$PWD/.clinerules"
      download_rule_set "$rules_base/Cline/.clinerules" "$target_dir" "md" "yes"
      ui_show_rules_installed "$ide_label" "$target_dir"
      ;;
    windsurf|5)
      target_dir="$PWD/.windsurf/rules"
      download_rule_set "$rules_base/Windsurf/.windsurf/rules" "$target_dir" "md" "yes"
      ui_show_rules_installed "$ide_label" "$target_dir"
      ;;
    continue|6)
      target_dir="$PWD/.continue/rules"
      download_rule_set "$rules_base/Continue/.continue/rules" "$target_dir" "md" "yes"
      ui_show_rules_installed "$ide_label" "$target_dir"
      ;;
    aider|7)
      conventions="$PWD/CONVENTIONS.md"
      aider_conf="$PWD/.aider.conf.yml"
      graft_rules_download_file "$rules_base/Aider/CONVENTIONS.md" "$conventions" "CONVENTIONS.md"
      graft_rules_download_file "$rules_base/Aider/.aider.conf.yml" "$aider_conf" ".aider.conf.yml"
      ui_show_rules_installed "$ide_label" "$conventions" "$aider_conf"
      ;;
    *)
      ui_say "Unknown IDE '$1'. Use: cursor, claude, copilot, cline, windsurf, continue, aider"
      exit 1
      ;;
  esac
}
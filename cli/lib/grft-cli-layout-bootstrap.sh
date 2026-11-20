# Dot after CLI_RAW_BASE or GRFT_RAW_BASE is set. Calls graft_cli_load_and_initialize_layout.

graft_cli_bootstrap_layout() {
  if command -v graft_cli_load_and_initialize_layout >/dev/null 2>&1; then
    graft_cli_load_and_initialize_layout
    return $?
  fi

  script_dir=""
  case "${0:-}" in
    '' | - | sh | bash)
      ;;
    *)
      script_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)" || script_dir=""
      ;;
  esac

  base="${CLI_RAW_BASE:-${GRFT_RAW_BASE:-}}"
  parent_dir=""
  if [ -n "${1:-}" ]; then
    parent_dir="$1"
  elif [ -n "$script_dir" ]; then
    parent_dir="$script_dir"
  fi

    if [ -n "$parent_dir" ] && [ -f "$parent_dir/ensure-sh-cli-layout.sh" ]; then
    _ensure_local="$(mktemp)"
    sed 's/\r$//' "$parent_dir/ensure-sh-cli-layout.sh" > "$_ensure_local"
    # shellcheck source=/dev/null
    . "$_ensure_local"
    rm -f "$_ensure_local"
  elif [ -n "${GRAFT_CLI_DIR:-}" ] && [ -f "$GRAFT_CLI_DIR/ensure-sh-cli-layout.sh" ]; then
    _ensure_local="$(mktemp)"
    sed 's/\r$//' "$GRAFT_CLI_DIR/ensure-sh-cli-layout.sh" > "$_ensure_local"
    # shellcheck source=/dev/null
    . "$_ensure_local"
    rm -f "$_ensure_local"
  elif [ -n "$base" ] && command -v curl >/dev/null 2>&1; then
    ensure_tmp="$(mktemp)"
    if ! curl -fsSL "$base/ensure-sh-cli-layout.sh" -o "$ensure_tmp"; then
      echo "Error: failed to download ensure-sh-cli-layout.sh from $base" >&2
      rm -f "$ensure_tmp"
      return 1
    fi
    # shellcheck source=/dev/null
    . "$ensure_tmp"
    rm -f "$ensure_tmp"
  else
    echo "Error: cannot load ensure-sh-cli-layout.sh (curl and CLI_RAW_BASE required)." >&2
    return 1
  fi

  graft_cli_load_and_initialize_layout
}
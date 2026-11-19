# Ensures a persistent Graftcode CLI layout under GRAFT_CLI_DIR / GRFT_HOME (mirrors ensure-ps-cli-layout.ps1).
# Dot-source only; call graft_cli_initialize_cli_layout after setting CLI_RAW_BASE or GRFT_RAW_BASE.

GRAFT_CLI_LAYOUT_LIB_NAMES="ui.sh gateway-installer.sh plugin-manifest.sh plugin-installer.sh rules-installer.sh installer-copy.sh"

graft_cli_layout_has_cmd() {
  command -v "$1" >/dev/null 2>&1
}

graft_cli_dot_local_file() {
  file_path="$1"
  if [ ! -f "$file_path" ]; then
    return 1
  fi
  dot_tmp="$(mktemp)"
  sed 's/\r$//' "$file_path" > "$dot_tmp"
  # shellcheck source=/dev/null
  . "$dot_tmp"
  rm -f "$dot_tmp"
}

graft_cli_layout_download() {
  url="$1"
  output="$2"
  label="$3"

  mkdir -p "$(dirname "$output")"

  if graft_cli_layout_has_cmd curl; then
    curl -fsSL "$url" -o "$output"
  elif graft_cli_layout_has_cmd wget; then
    wget -q -O "$output" "$url"
  else
    echo "Error: curl or wget is required to download $label." >&2
    return 1
  fi
}

graft_cli_layout_ensure_assets() {
  root="$1"
  base="$2"

  if [ -z "$root" ] || [ -z "$base" ]; then
    return 0
  fi

  mkdir -p "$root/assets"
  logo_path="$root/assets/logo_ascii.txt"
  need_logo=0
  if [ ! -f "$logo_path" ]; then
    need_logo=1
  elif [ ! -s "$logo_path" ]; then
    need_logo=1
  fi

  if [ "$need_logo" = "1" ]; then
    graft_cli_layout_download "$base/assets/logo_ascii.txt" "$logo_path" "assets/logo_ascii.txt" 2>/dev/null || true
  fi

  for asset in installer-intro.txt installer-menu.txt; do
    out="$root/assets/$asset"
    if [ ! -f "$out" ] || [ ! -s "$out" ]; then
      graft_cli_layout_download "$base/assets/$asset" "$out" "assets/$asset" 2>/dev/null || true
    fi
  done

  return 0
}

graft_cli_layout_ensure_lib_files() {
  root="$1"
  base="$2"
  lib_dir="$root/lib"
  name=""

  for name in $GRAFT_CLI_LAYOUT_LIB_NAMES; do
    out="$lib_dir/$name"
    if [ ! -f "$out" ]; then
      graft_cli_layout_download "$base/lib/$name" "$out" "lib/$name" || return 1
    fi
  done

  ui_path="$lib_dir/ui.sh"
  if [ -f "$ui_path" ] && { ! grep -q 'ui_show_plugin_installed' "$ui_path" 2>/dev/null || ! grep -q 'ui_say_green' "$ui_path" 2>/dev/null; }; then
    graft_cli_layout_download "$base/lib/ui.sh" "$ui_path" "lib/ui.sh" || return 1
  fi

  manifest_path="$root/plugins.manifest.json"
  if [ ! -f "$manifest_path" ]; then
    graft_cli_layout_download "$base/plugins.manifest.json" "$manifest_path" "plugins.manifest.json" || return 1
  fi

  return 0
}

graft_cli_layout_try_root() {
  root="$1"
  base="$2"

  if [ -z "$root" ]; then
    return 1
  fi
  if [ ! -f "$root/lib/ui.sh" ]; then
    return 1
  fi

  graft_cli_layout_ensure_lib_files "$root" "$base" || return 1
  graft_cli_layout_ensure_assets "$root" "$base" || return 1
  CLI_RAW_BASE="$base"
  export CLI_RAW_BASE
  GRAFT_CLI_DIR="$root"
  export GRAFT_CLI_DIR
  return 0
}

graft_cli_initialize_cli_layout() {
  base="${CLI_RAW_BASE:-${GRFT_RAW_BASE:-}}"
  if [ -z "$base" ]; then
    echo "Error: set CLI_RAW_BASE or GRFT_RAW_BASE before graft_cli_initialize_cli_layout." >&2
    return 1
  fi

  home="${GRFT_HOME:-${HOME:-}/.grft}"
  script_dir=""

  case "${0:-}" in
    '' | - | sh | bash)
      ;;
    *)
      script_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)" || script_dir=""
      ;;
  esac

  if [ -n "${GRAFT_CLI_DIR:-}" ]; then
    graft_cli_layout_try_root "$GRAFT_CLI_DIR" "$base" && return 0
  fi

  if [ -n "$script_dir" ]; then
    graft_cli_layout_try_root "$script_dir" "$base" && return 0
  fi

  if graft_cli_layout_try_root "$home" "$base"; then
    return 0
  fi

  if ! graft_cli_layout_has_cmd curl && ! graft_cli_layout_has_cmd wget; then
    echo "Error: curl or wget is required to bootstrap CLI layout." >&2
    return 1
  fi

  mkdir -p "$home/lib" "$home/assets"
  graft_cli_layout_ensure_lib_files "$home" "$base" || return 1

  graft_cli_layout_ensure_assets "$home" "$base" || return 1
  CLI_RAW_BASE="$base"
  export CLI_RAW_BASE
  GRAFT_CLI_DIR="$home"
  export GRAFT_CLI_DIR
  return 0
}

graft_cli_load_and_initialize_layout() {
  if [ -n "${GRAFT_CLI_LAYOUT_READY:-}" ]; then
    return 0
  fi

  if ! command -v graft_cli_initialize_cli_layout >/dev/null 2>&1; then
    base="${CLI_RAW_BASE:-${GRFT_RAW_BASE:-}}"
    script_dir=""
    case "${0:-}" in
      '' | - | sh | bash)
        ;;
      *)
        script_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)" || script_dir=""
        ;;
    esac

    if [ -n "$script_dir" ] && [ -f "$script_dir/ensure-sh-cli-layout.sh" ]; then
      graft_cli_dot_local_file "$script_dir/ensure-sh-cli-layout.sh"
    elif [ -n "${GRAFT_CLI_DIR:-}" ] && [ -f "$GRAFT_CLI_DIR/ensure-sh-cli-layout.sh" ]; then
      graft_cli_dot_local_file "$GRAFT_CLI_DIR/ensure-sh-cli-layout.sh"
    elif [ -n "$base" ] && graft_cli_layout_has_cmd curl; then
      ensure_tmp="$(mktemp)"
      curl -fsSL "$base/ensure-sh-cli-layout.sh" -o "$ensure_tmp" || {
        echo "Error: failed to load ensure-sh-cli-layout.sh from $base" >&2
        rm -f "$ensure_tmp"
        return 1
      }
      graft_cli_dot_local_file "$ensure_tmp"
      rm -f "$ensure_tmp"
    else
      echo "Error: cannot load ensure-sh-cli-layout.sh (set CLI_RAW_BASE and install curl)." >&2
      return 1
    fi
  fi

  graft_cli_initialize_cli_layout || return 1
  GRAFT_CLI_LAYOUT_READY=1
  export GRAFT_CLI_LAYOUT_READY
  return 0
}
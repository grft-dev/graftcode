#!/bin/sh
# Shared CLI output for Gateway / installer scripts (5272). Dot-source only.

CLI_RAW_BASE="${CLI_RAW_BASE:-https://raw.githubusercontent.com/grft-dev/graftcode/refs/heads/main/cli}"
UI_BRAND_RGB="${UI_BRAND_RGB:-218;26;96}"

ui_has_cmd() {
  command -v "$1" >/dev/null 2>&1
}

ui_is_tty() {
  [ -t 1 ]
}

ui_stderr_is_tty() {
  [ -t 2 ]
}

ui_wants_download_progress() {
  show_progress="$1"
  [ "$show_progress" = 1 ] && { ui_is_tty || ui_stderr_is_tty; }
}

ui_say() {
  echo "$@"
}

ui_maybe_clear() {
  if ui_is_tty; then
    clear 2>/dev/null || true
  fi
}

ui_resolve_script_dir() {
  case "$0" in
    -|sh|bash) return 1 ;;
    *)
      CDPATH= cd -- "$(dirname -- "$0")" && pwd
      return 0
      ;;
  esac
}

ui_load_logo_text() {
  logo_path=""
  if [ -n "${GRAFT_CLI_DIR:-}" ] && [ -f "$GRAFT_CLI_DIR/assets/logo_ascii.txt" ]; then
    cat "$GRAFT_CLI_DIR/assets/logo_ascii.txt"
    return 0
  fi

  script_dir=""
  if script_dir="$(ui_resolve_script_dir)"; then
    if [ -f "$script_dir/assets/logo_ascii.txt" ]; then
      logo_path="$script_dir/assets/logo_ascii.txt"
    elif [ -f "$script_dir/../assets/logo_ascii.txt" ]; then
      logo_path="$script_dir/../assets/logo_ascii.txt"
    fi
  fi

  if [ -n "$logo_path" ]; then
    cat "$logo_path"
    return 0
  fi

  if ui_has_cmd curl; then
    curl -fsSL "$CLI_RAW_BASE/assets/logo_ascii.txt"
    return 0
  fi

  ui_say "Error: could not load Gateway logo (need cli/assets/logo_ascii.txt or curl)."
  exit 1
}

ui_print_brand_logo() {
  text="$1"
  if [ -z "$text" ]; then
    return 0
  fi
  if ui_is_tty; then
  printf '\033[38;2;%sm' "$UI_BRAND_RGB"
  fi
  printf '%s' "$text"
  if ui_is_tty; then
    printf '\033[0m'
  fi
  printf '\n'
}

ui_show_gateway_logo() {
  ui_print_brand_logo "$(ui_load_logo_text)"
}

ui_show_gateway_intro() {
  ui_maybe_clear
  ui_show_gateway_logo
  echo ""
  ui_say "Graftcode Gateway installer"
  ui_say ""
  ui_say "This script downloads Graftcode Gateway (gg) for your platform."
  ui_say "On Debian/Ubuntu it saves gg.deb here — install with: dpkg -i gg.deb"
  ui_say "On other systems it extracts ./gg into the current directory."
  ui_say ""
}

ui_obtaining_latest_release() {
  ui_say "Obtaining latest stable release..."
}

ui_download_file() {
  url="$1"
  output="$2"
  label="$3"
  show_progress="${4:-0}"

  ui_say "Downloading $label..."

  if ui_has_cmd curl; then
    if ui_wants_download_progress "$show_progress"; then
      curl -fL# "$url" -o "$output"
    else
      curl -fsSL "$url" -o "$output"
    fi
  elif ui_has_cmd wget; then
    if ui_wants_download_progress "$show_progress"; then
      wget --show-progress -O "$output" "$url"
    else
      wget -q -O "$output" "$url"
    fi
  elif ui_has_cmd busybox; then
    busybox wget -q -O "$output" "$url"
  else
    ui_say "Error: curl, wget or busybox wget is required to download files."
    exit 1
  fi

  ui_say "Downloaded $label"
}

ui_show_installed_binary() {
  output_path="$1"
  ui_say ""
  ui_say "Installed Graftcode Gateway:"
  ui_say "$output_path"
  ui_say ""
  ui_say "Run: ./gg <your module>"
}

ui_show_installed_deb() {
  deb_path="$1"
  ui_say ""
  ui_say "Downloaded Debian package:"
  ui_say "$deb_path"
  ui_say ""
  ui_say "Install it with:"
  if [ "$(id -u 2>/dev/null || echo 1)" -eq 0 ]; then
    ui_say "  dpkg -i $deb_path"
  else
    ui_say "  sudo dpkg -i $deb_path"
  fi
}

ui_show_done() {
  ui_say ""
  ui_say "Done."
}
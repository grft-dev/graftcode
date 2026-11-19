#!/bin/sh
# Shared CLI output for Gateway / installer scripts (5272). Dot-source only.

CLI_RAW_BASE="${CLI_RAW_BASE:-https://raw.githubusercontent.com/grft-dev/graftcode/refs/heads/main/cli}"
UI_BRAND_RGB="${UI_BRAND_RGB:-218;26;96}"
UI_PROGRESS_RGB="${UI_PROGRESS_RGB:-$UI_BRAND_RGB}"
UI_PROGRESS_WIDTH="${UI_PROGRESS_WIDTH:-30}"

ui_has_cmd() {
  command -v "$1" >/dev/null 2>&1
}

ui_is_tty() {
  [ -t 1 ] || ui_stderr_is_tty || ui_dev_tty_writable
}

ui_stderr_is_tty() {
  [ -t 2 ]
}

ui_dev_tty_writable() {
  if ! [ -e /dev/tty ]; then
    return 1
  fi
  ( exec 3>/dev/tty ) 2>/dev/null
}

ui_progress_is_tty() {
  ui_is_tty || ui_stderr_is_tty || ui_dev_tty_writable
}

ui_wants_download_progress() {
  show_progress="$1"
  [ "$show_progress" = 1 ] && ui_progress_is_tty
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
    curl -fsSL "$CLI_RAW_BASE/assets/logo_ascii.txt" </dev/null
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
}

ui_say_platform_line() {
  ui_say "OS: $1 | CPU: $2"
}

ui_obtaining_latest_release() {
  tag="${1:-}"
  if [ -n "$tag" ]; then
    ui_say "Obtaining latest stable release: $tag"
  else
    ui_say "Obtaining latest stable release"
  fi
}

ui_resolve_content_length() {
  url="$1"
  total=0
  if ui_has_cmd curl; then
    total="$(curl -fsSIL -L -A 'grft-cli' "$url" </dev/null 2>/dev/null |
      awk 'tolower($0) ~ /^content-length:/ { cl=$2 } END { gsub(/\r/, "", cl); if (cl + 0 > 0) print cl + 0 }')"
    if [ -z "$total" ] || [ "$total" -eq 0 ] 2>/dev/null; then
      total="$(curl -fsSI -L -A 'grft-cli' -H 'Range: bytes=0-0' "$url" </dev/null 2>/dev/null |
        awk 'tolower($0) ~ /^content-range:/ {
          n = split($0, parts, "/")
          if (n >= 2) { gsub(/\r/, "", parts[2]); print parts[2] + 0 }
        }' | head -n 1)"
    fi
  fi
  total="${total:-0}"
  echo "$total"
}

ui_obtaining_latest_plugin_release() {
  label="${1:-plugin}"
  tag="${2:-}"
  if [ -n "$tag" ]; then
    ui_say "Obtaining latest ${label} plugin release: $tag"
  else
    ui_say "Obtaining latest ${label} plugin release"
  fi
}

ui_write_bracket_progress() {
  pct="$1"
  width="$UI_PROGRESS_WIDTH"
  filled=$((pct * width / 100))
  empty=$((width - filled))
  bar=""
  i=0
  while [ "$i" -lt "$filled" ]; do
    bar="${bar}#"
    i=$((i + 1))
  done
  i=0
  while [ "$i" -lt "$empty" ]; do
    bar="${bar}-"
    i=$((i + 1))
  done
  if ! ui_progress_is_tty; then
    return 0
  fi
  line="$(printf '\r\033[38;2;%sm[%s]\033[0m %s%%' "$UI_PROGRESS_RGB" "$bar" "$pct")"
  if ui_is_tty; then
    printf '%s' "$line"
  elif ui_stderr_is_tty; then
    printf '%s' "$line" >&2
  elif ui_dev_tty_writable; then
    printf '%s' "$line" >/dev/tty
  fi
}

ui_download_with_bracket_progress() {
  url="$1"
  output="$2"

  if ! ui_has_cmd curl; then
    ui_say "Error: curl is required for download progress."
    exit 1
  fi

  total="$(ui_resolve_content_length "$url")"

  parent="$(dirname "$output")"
  if [ -n "$parent" ] && [ "$parent" != "." ]; then
    mkdir -p "$parent"
  fi
  : >"$output"

  curl -fsSL "$url" -o "$output" </dev/null &
  curl_pid=$!

  while kill -0 "$curl_pid" 2>/dev/null; do
    if [ -f "$output" ] && [ "$total" -gt 0 ] 2>/dev/null; then
      size="$(wc -c <"$output" | tr -d ' ')"
      pct=$((size * 100 / total))
      if [ "$pct" -gt 100 ]; then pct=100; fi
      ui_write_bracket_progress "$pct"
    fi
    sleep 0.15
  done

  wait "$curl_pid" || exit 1
  ui_write_bracket_progress 100
  if ui_progress_is_tty; then
    if ui_is_tty; then
      printf '\n'
    elif ui_stderr_is_tty; then
      printf '\n' >&2
    elif ui_dev_tty_writable; then
      printf '\n' >/dev/tty
    fi
  fi
}

ui_download_file() {
  url="$1"
  output="$2"
  label="$3"
  show_progress="${4:-0}"

  if [ "$show_progress" = 1 ] && ui_wants_download_progress 1; then
    ui_say "Downloading $label..."
    ui_download_with_bracket_progress "$url" "$output"
    return 0
  fi

  ui_say "Downloading $label..."

  if ui_has_cmd curl; then
    curl -fsSL "$url" -o "$output" </dev/null
  elif ui_has_cmd wget; then
    wget -q -O "$output" "$url"
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
  release_tag="${2:-}"
  ui_say ""
  ui_say "Installed Graftcode Gateway:"
  if [ -n "$release_tag" ]; then
    ui_say "Version: $release_tag"
  fi
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

ui_obtaining_rules_for_ide() {
  ide_label="${1:-IDE}"
  ui_say "Installing Graftcode rules for $ide_label"
}

ui_show_rules_installed() {
  ide_label="$1"
  shift
  ui_say ""
  ui_say "Installed Graftcode $ide_label rules in:"
  while [ $# -gt 0 ]; do
    ui_say "$1"
    shift
  done
}

ui_show_plugin_installed() {
  plugin_label="$1"
  install_dir="$2"
  installed_list="$3"

  ui_say ""
  ui_say "$installed_list"
  ui_say ""
  ui_say "Installed Graftcode $plugin_label plugin in:"
  ui_say "$install_dir"
}

ui_show_done() {
  ui_say ""
  ui_say "Done."
}
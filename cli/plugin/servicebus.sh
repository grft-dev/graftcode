#!/bin/sh
set -eu

REPO="grft-dev/graftcode-plugins"
PLUGIN_NAME="servicebus"
INSTALL_DIR="$PWD"

say() {
  if [ -w /dev/tty ]; then
    echo "$@" > /dev/tty
  else
    echo "$@"
  fi
}

say_no_newline() {
  if [ -w /dev/tty ]; then
    printf "%s" "$1" > /dev/tty
  else
    printf "%s" "$1"
  fi
}

show_intro() {
  clear 2>/dev/null || true

  if [ -w /dev/tty ]; then
    cat > /dev/tty <<'EOF'
 _____ __ _ _
/ ____| / _| | | |
| | __ _ __ __ _| |_| |_ ___ ___ __| | ___
| | |_ | '__/ _` | _| __/ __/ _ \ / _` |/ _ \
| |__| | | | (_| | | | || (_| (_) | (_| | __/
\_____|_|  \__,_|_|  \__\___\___/ \__,_|\___/

EOF
  else
    cat <<'EOF'
 _____ __ _ _
/ ____| / _| | | |
| | __ _ __ __ _| |_| |_ ___ ___ __| | ___
| | |_ | '__/ _` | _| __/ __/ _ \ / _` |/ _ \
| |__| | | | (_| | | | || (_| (_) | (_| | __/
\_____|_|  \__,_|_|  \__\___\___/ \__,_|\___/

EOF
  fi

  say "Graftcode Service Bus Plugin installer"
  say ""
  say "This script downloads and installs the Azure Service Bus plugin"
  say "for Graftcode Gateway in the current directory."
  say ""
}

has_cmd() {
  command -v "$1" >/dev/null 2>&1
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

detect_os() {
  os_name="$(uname -s | tr 'ABCDEFGHIJKLMNOPQRSTUVWXYZ' 'abcdefghijklmnopqrstuvwxyz')"

  case "$os_name" in
    linux)
      echo "linux"
      ;;
    darwin)
      echo "macos"
      ;;
    mingw*|msys*|cygwin*|windows*|win*)
      echo "windows"
      ;;
    *)
      say "Unsupported OS: $os_name"
      exit 1
      ;;
  esac
}

detect_arch() {
  arch_name="$(uname -m | tr 'ABCDEFGHIJKLMNOPQRSTUVWXYZ' 'abcdefghijklmnopqrstuvwxyz')"

  case "$arch_name" in
    arm64|aarch64)
      echo "arm64"
      ;;
    x86_64|amd64)
      echo "x86_64"
      ;;
    *)
      say "Unsupported architecture: $arch_name"
      exit 1
      ;;
  esac
}

install_plugin_files() {
  extract_dir="$1"
  install_dir="$2"

  mkdir -p "$install_dir"
  installed=""

  if [ -d "$extract_dir/Release" ]; then
    for file in "$extract_dir"/Release/*.dll; do
      [ -e "$file" ] || continue
      cp "$file" "$install_dir/"
      installed="$installed
 - $(basename "$file")"
    done
  fi

  for pattern in libServiceBusPlugin.so libServiceBusPlugin.dylib ServiceBusPlugin.dll; do
    found="$(find "$extract_dir" -maxdepth 2 -type f -name "$pattern" -print | head -n 1 || true)"
    if [ -n "$found" ]; then
      cp "$found" "$install_dir/"
      installed="$installed
 - $(basename "$found")"
    fi
  done

  if [ -z "$installed" ]; then
    say "Could not find Service Bus plugin binaries inside archive."
    say "Extracted files:"
    find "$extract_dir" -maxdepth 4 -type f | sed 's/^/ - /' > /dev/tty 2>/dev/null || true
    exit 1
  fi

  say "$installed"
}

install_servicebus() {
  if ! has_cmd tar || ! has_cmd find || ! has_cmd basename || ! has_cmd mktemp; then
    say "Error: this installer requires tar, find, basename and mktemp."
    exit 1
  fi

  os_name="$(detect_os)"
  arch_name="$(detect_arch)"
  asset_name="${PLUGIN_NAME}-${os_name}-${arch_name}.tar.gz"

  say ""
  say "Detected OS: $os_name"
  say "Detected architecture: $arch_name"
  say "Fetching latest release from $REPO..."

  release_json="$(mktemp)"
  download_file "https://api.github.com/repos/$REPO/releases/latest" "$release_json" "latest release metadata"

  asset_url="$(
    grep '"browser_download_url"' "$release_json" |
      sed 's/.*"browser_download_url": "\(.*\)".*/\1/' |
      grep -Ei "/${asset_name}$" |
      head -n 1 || true
  )"

  if [ -z "$asset_url" ]; then
    say "Could not find Service Bus build: $asset_name"
    say ""
    say "Available servicebus assets:"
    grep '"browser_download_url"' "$release_json" |
      sed 's/.*"browser_download_url": "\(.*\)".*/\1/' |
      grep -Ei '/servicebus-' |
      sed 's/^/ - /' > /dev/tty 2>/dev/null || true
    rm -f "$release_json"
    exit 1
  fi

  tmp_dir="$(mktemp -d)"
  archive_path="$tmp_dir/$asset_name"
  extract_dir="$tmp_dir/extract"

  download_file "$asset_url" "$archive_path" "$asset_name"
  mkdir -p "$extract_dir"
  tar -xzf "$archive_path" -C "$extract_dir"

  say ""
  say "Installing plugin files to:"
  say "$INSTALL_DIR"
  say ""
  install_plugin_files "$extract_dir" "$INSTALL_DIR"

  rm -rf "$tmp_dir"
  rm -f "$release_json"

  say ""
  say "Installed Graftcode Service Bus plugin in:"
  say "$INSTALL_DIR"
}

show_intro
install_servicebus

say ""
say "Done."

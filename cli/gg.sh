#!/bin/sh
set -eu

REPO="grft-dev/graftcode-gateway"
EXE_NAME="gg"
INSTALL_DIR="$PWD"

say() {
  echo "$@"
}

show_intro() {
  clear 2>/dev/null || true

  cat <<'EOF'
                       __ _                _      
                      / _| |              | |     
       __ _ _ __ __ _| |_| |_ ___ ___   __| | ___ 
      / _` | '__/ _` |  _| __/ __/ _ \ / _` |/ _ \
     | (_| | | | (_| | | | || (_| (_) | (_| |  __/
      \__, |_|  \__,_|_|  \__\___\___/ \__,_|\___|
       __/ |                                      
      |___/   

EOF

  say "Graftcode Gateway installer"
  say ""
  say "This script downloads Graftcode Gateway (gg) for your platform."
  say "On Debian/Ubuntu it saves gg.deb here — install with: dpkg -i gg.deb"
  say "On other systems it extracts ./gg into the current directory."
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

detect_arch_suffix() {
  os_name="$1"
  arch_name="$(uname -m | tr 'ABCDEFGHIJKLMNOPQRSTUVWXYZ' 'abcdefghijklmnopqrstuvwxyz')"

  case "$arch_name" in
    arm64|aarch64)
      echo "arm64"
      ;;
    x86_64|amd64)
      case "$os_name" in
        macos) echo "x86_64" ;;
        *) echo "amd64" ;;
      esac
      ;;
    *)
      say "Unsupported architecture: $arch_name"
      exit 1
      ;;
  esac
}

build_deb_asset_name() {
  arch_suffix="$1"
  echo "gg_linux_${arch_suffix}.deb"
}

download_deb_package() {
  arch_suffix="$1"
  release_json="$2"
  deb_name="$(build_deb_asset_name "$arch_suffix")"
  deb_path="$INSTALL_DIR/gg.deb"

  asset_url="$(
    grep '"browser_download_url"' "$release_json" |
      sed 's/.*"browser_download_url": "\(.*\)".*/\1/' |
      grep -Ei "/${deb_name}$" |
      head -n 1 || true
  )"

  if [ -z "$asset_url" ]; then
    return 1
  fi

  download_file "$asset_url" "$deb_path" "$deb_name"
  say ""
  say "Downloaded Debian package:"
  say "$deb_path"
  say ""
  say "Install it with:"
  if [ "$(id -u 2>/dev/null || echo 1)" -eq 0 ]; then
    say "  dpkg -i $deb_path"
  else
    say "  sudo dpkg -i $deb_path"
  fi
  return 0
}

build_asset_name() {
  os_name="$1"
  arch_suffix="$2"

  case "$os_name" in
    windows)
      echo "gg_${os_name}_${arch_suffix}.zip"
      ;;
    *)
      echo "gg_${os_name}_${arch_suffix}.tar.gz"
      ;;
  esac
}

extract_gateway() {
  archive_path="$1"
  extract_dir="$2"
  exe_name="$3"
  output_path="$4"

  mkdir -p "$extract_dir"

  case "$archive_path" in
    *.zip)
      if has_cmd unzip; then
        unzip -q "$archive_path" -d "$extract_dir"
      elif has_cmd tar; then
        tar -xf "$archive_path" -C "$extract_dir"
      else
        say "Error: unzip or tar is required to extract .zip files."
        exit 1
      fi
      ;;
    *.tar.gz|*.tgz)
      if has_cmd tar; then
        tar -xzf "$archive_path" -C "$extract_dir"
      else
        say "Error: tar is required to extract tar.gz files."
        exit 1
      fi
      ;;
    *)
      say "Unsupported archive format: $archive_path"
      exit 1
      ;;
  esac

  found="$(find "$extract_dir" -type f -name "$exe_name" -print | head -n 1 || true)"

  if [ -z "$found" ]; then
    say "Could not find $exe_name inside archive."
    say "Extracted files:"
    find "$extract_dir" -maxdepth 4 -type f | sed 's/^/ - /'
    exit 1
  fi

  rm -f "$output_path"
  cp "$found" "$output_path"
  chmod +x "$output_path"
}

install_gg() {
  if ! has_cmd grep || ! has_cmd sed || ! has_cmd find || ! has_cmd basename || ! has_cmd mktemp; then
    say "Error: this installer requires grep, sed, find, basename and mktemp."
    exit 1
  fi

  os_name="$(detect_os)"
  if [ "$os_name" = "linux" ] && has_cmd dpkg && dpkg --print-architecture >/dev/null 2>&1; then
    arch_suffix="$(dpkg --print-architecture)"
  else
    arch_suffix="$(detect_arch_suffix "$os_name")"
  fi

  exe_name="$EXE_NAME"
  output_path="$INSTALL_DIR/$exe_name"

  case "$os_name" in
    windows)
      exe_name="gg.exe"
      output_path="$INSTALL_DIR/$exe_name"
      ;;
  esac

  say ""
  say "Detected OS: $os_name"
  say "Detected architecture: $arch_suffix"
  say "Fetching latest release from $REPO..."

  release_json="$(mktemp)"
  download_file "https://api.github.com/repos/$REPO/releases/latest" "$release_json" "latest release metadata"

  if [ "$os_name" = "linux" ] && has_cmd dpkg; then
    if download_deb_package "$arch_suffix" "$release_json"; then
      rm -f "$release_json"
      return 0
    fi
    say "Debian package not found for this architecture, falling back to archive extract..."
  fi

  asset_name="$(build_asset_name "$os_name" "$arch_suffix")"

  asset_url="$(
    grep '"browser_download_url"' "$release_json" |
      sed 's/.*"browser_download_url": "\(.*\)".*/\1/' |
      grep -Ei "/${asset_name}$" |
      head -n 1 || true
  )"

  if [ -z "$asset_url" ]; then
    say "Could not find Gateway build: $asset_name"
    say ""
    say "Available gg assets:"
    grep '"browser_download_url"' "$release_json" |
      sed 's/.*"browser_download_url": "\(.*\)".*/\1/' |
      grep -Ei '/gg_' |
      sed 's/^/ - /'
    rm -f "$release_json"
    exit 1
  fi

  tmp_dir="$(mktemp -d)"
  archive_path="$tmp_dir/$asset_name"
  extract_dir="$tmp_dir/extract"

  download_file "$asset_url" "$archive_path" "$asset_name"
  extract_gateway "$archive_path" "$extract_dir" "$exe_name" "$output_path"

  rm -rf "$tmp_dir"
  rm -f "$release_json"

  say ""
  say "Installed Graftcode Gateway:"
  say "$output_path"
}

show_intro
install_gg

say ""
say "Done."

#!/bin/sh
# Install Graftcode Gateway into $GRAFT_GATEWAY_INSTALL_DIR (default: $PWD). Requires ui.sh loaded.

GRAFT_GATEWAY_REPO="${GRAFT_GATEWAY_REPO:-grft-dev/graftcode-gateway}"
GRAFT_GATEWAY_EXE_NAME="${GRAFT_GATEWAY_EXE_NAME:-gg}"

gi_say() {
  if command -v ui_say >/dev/null 2>&1; then
    ui_say "$@"
  else
    echo "$@"
  fi
}

gi_has_cmd() {
  if command -v ui_has_cmd >/dev/null 2>&1; then
    ui_has_cmd "$@"
  else
    command -v "$1" >/dev/null 2>&1
  fi
}

gi_download_file() {
  url="$1"
  output="$2"
  label="$3"
  show_progress="${4:-0}"
  if command -v ui_download_file >/dev/null 2>&1; then
    ui_download_file "$url" "$output" "$label" "$show_progress"
  else
    gi_say "Downloading $label..."
    curl -fSL "$url" -o "$output"
    gi_say "Downloaded $label"
  fi
}

gi_detect_os() {
  os_name="$(uname -s | tr 'ABCDEFGHIJKLMNOPQRSTUVWXYZ' 'abcdefghijklmnopqrstuvwxyz')"

  case "$os_name" in
    linux) echo "linux" ;;
    darwin) echo "macos" ;;
    mingw*|msys*|cygwin*|windows*|win*) echo "windows" ;;
    *)
      gi_say "Unsupported OS: $os_name"
      exit 1
      ;;
  esac
}

gi_detect_arch_suffix() {
  os_name="$1"
  arch_name="$(uname -m | tr 'ABCDEFGHIJKLMNOPQRSTUVWXYZ' 'abcdefghijklmnopqrstuvwxyz')"

  case "$arch_name" in
    arm64|aarch64) echo "arm64" ;;
    x86_64|amd64)
      case "$os_name" in
        macos) echo "x86_64" ;;
        *) echo "amd64" ;;
      esac
      ;;
    *)
      gi_say "Unsupported architecture: $arch_name"
      exit 1
      ;;
  esac
}

gi_build_deb_asset_name() {
  arch_suffix="$1"
  echo "gg_linux_${arch_suffix}.deb"
}

gi_build_asset_name() {
  os_name="$1"
  arch_suffix="$2"

  case "$os_name" in
    windows) echo "gg_${os_name}_${arch_suffix}.zip" ;;
    *) echo "gg_${os_name}_${arch_suffix}.tar.gz" ;;
  esac
}

gi_cache_home() {
  if [ -n "${GRAFTCODE_CACHE_HOME:-}" ]; then
    echo "$GRAFTCODE_CACHE_HOME"
  elif [ -n "${HOME:-}" ]; then
    echo "$HOME/.graftcode"
  else
    echo ""
  fi
}

gi_release_tag_from_json() {
  release_json="$1"
  grep '"tag_name"' "$release_json" |
    sed 's/.*"tag_name": "\([^"]*\)".*/\1/' |
    head -n 1
}

gi_cache_rel_deb() {
  os_name="$1"
  arch_suffix="$2"
  echo "${os_name}-${arch_suffix}/gg.deb"
}

gi_cache_rel_binary() {
  os_name="$1"
  arch_suffix="$2"
  case "$os_name" in
    windows) echo "windows-${arch_suffix}/gg.exe" ;;
    *) echo "${os_name}-${arch_suffix}/gg" ;;
  esac
}

gi_try_copy_from_cache() {
  cache_home="$1"
  release_tag="$2"
  rel_path="$3"
  dest_path="$4"

  if [ -z "$cache_home" ] || [ -z "$release_tag" ] || [ -z "$rel_path" ]; then
    return 1
  fi

  cache_file="${cache_home%/}/${release_tag}/${rel_path}"
  if [ ! -f "$cache_file" ]; then
    return 1
  fi

  mkdir -p "$(dirname "$dest_path")"
  rm -f "$dest_path"
  cp "$cache_file" "$dest_path"
  chmod +x "$dest_path" 2>/dev/null || true
  gi_say "Using cached Gateway ${release_tag} (${rel_path})."
  return 0
}

gi_store_in_cache() {
  cache_home="$1"
  release_tag="$2"
  rel_path="$3"
  src_path="$4"

  if [ -z "$cache_home" ] || [ -z "$release_tag" ] || [ ! -f "$src_path" ]; then
    return 0
  fi

  cache_file="${cache_home%/}/${release_tag}/${rel_path}"
  mkdir -p "$(dirname "$cache_file")"
  cp "$src_path" "$cache_file"
  chmod +x "$cache_file" 2>/dev/null || true
  printf '%s\n' "$release_tag" > "${cache_home%/}/latest-tag.txt"
}

gi_extract_gateway() {
  archive_path="$1"
  extract_dir="$2"
  exe_name="$3"
  output_path="$4"

  mkdir -p "$extract_dir"

  case "$archive_path" in
    *.zip)
      if gi_has_cmd unzip; then
        unzip -q "$archive_path" -d "$extract_dir"
      elif gi_has_cmd tar; then
        tar -xf "$archive_path" -C "$extract_dir"
      else
        gi_say "Error: unzip or tar is required to extract .zip files."
        exit 1
      fi
      ;;
    *.tar.gz|*.tgz)
      if gi_has_cmd tar; then
        tar -xzf "$archive_path" -C "$extract_dir"
      else
        gi_say "Error: tar is required to extract tar.gz files."
        exit 1
      fi
      ;;
    *)
      gi_say "Unsupported archive format: $archive_path"
      exit 1
      ;;
  esac

  found="$(find "$extract_dir" -type f -name "$exe_name" -print | head -n 1 || true)"

  if [ -z "$found" ]; then
    gi_say "Could not find $exe_name inside archive."
    gi_say "Extracted files:"
    find "$extract_dir" -maxdepth 4 -type f | sed 's/^/ - /'
    exit 1
  fi

  rm -f "$output_path"
  cp "$found" "$output_path"
  chmod +x "$output_path"
}

gi_download_deb_package() {
  arch_suffix="$1"
  release_json="$2"
  install_dir="$3"
  deb_name="$(gi_build_deb_asset_name "$arch_suffix")"
  deb_path="$install_dir/gg.deb"

  asset_url="$(
    grep '"browser_download_url"' "$release_json" |
      sed 's/.*"browser_download_url": "\(.*\)".*/\1/' |
      grep -Ei "/${deb_name}$" |
      head -n 1 || true
  )"

  if [ -z "$asset_url" ]; then
    return 1
  fi

  gi_download_file "$asset_url" "$deb_path" "$deb_name" 1
  if command -v ui_show_installed_deb >/dev/null 2>&1; then
    ui_show_installed_deb "$deb_path"
  else
    gi_say ""
    gi_say "Downloaded Debian package:"
    gi_say "$deb_path"
  fi
  return 0
}

install_gg_to_cwd() {
  install_dir="${GRAFT_GATEWAY_INSTALL_DIR:-$PWD}"

  if ! gi_has_cmd grep || ! gi_has_cmd sed || ! gi_has_cmd find || ! gi_has_cmd basename || ! gi_has_cmd mktemp; then
    gi_say "Error: this installer requires grep, sed, find, basename and mktemp."
    exit 1
  fi

  os_name="$(gi_detect_os)"
  if [ "$os_name" = "linux" ] && gi_has_cmd dpkg && dpkg --print-architecture >/dev/null 2>&1; then
    arch_suffix="$(dpkg --print-architecture)"
  else
    arch_suffix="$(gi_detect_arch_suffix "$os_name")"
  fi

  exe_name="$GRAFT_GATEWAY_EXE_NAME"
  output_path="$install_dir/$exe_name"

  case "$os_name" in
    windows)
      exe_name="gg.exe"
      output_path="$install_dir/$exe_name"
      ;;
  esac

  if command -v ui_show_gateway_intro >/dev/null 2>&1; then
    ui_show_gateway_intro
  fi
  if command -v ui_say_platform_line >/dev/null 2>&1; then
    ui_say_platform_line "$os_name" "$arch_suffix"
  else
    gi_say "OS: $os_name | CPU: $arch_suffix"
  fi
  if command -v ui_obtaining_latest_release >/dev/null 2>&1; then
    ui_obtaining_latest_release
  else
    gi_say "Fetching latest release from $GRAFT_GATEWAY_REPO..."
  fi

  release_json="$(mktemp)"
  gi_download_file "https://api.github.com/repos/$GRAFT_GATEWAY_REPO/releases/latest" "$release_json" "latest release metadata" 0

  release_tag="$(gi_release_tag_from_json "$release_json")"
  cache_home="$(gi_cache_home)"

  if [ "$os_name" = "linux" ] && gi_has_cmd dpkg; then
    deb_rel="$(gi_cache_rel_deb "$os_name" "$arch_suffix")"
    deb_path="$install_dir/gg.deb"
    if gi_try_copy_from_cache "$cache_home" "$release_tag" "$deb_rel" "$deb_path"; then
      if command -v ui_show_installed_deb >/dev/null 2>&1; then
        ui_show_installed_deb "$deb_path"
      fi
      rm -f "$release_json"
      return 0
    fi
    if gi_download_deb_package "$arch_suffix" "$release_json" "$install_dir"; then
      gi_store_in_cache "$cache_home" "$release_tag" "$deb_rel" "$deb_path"
      rm -f "$release_json"
      return 0
    fi
    gi_say "Debian package not found for this architecture, falling back to archive extract..."
  fi

  bin_rel="$(gi_cache_rel_binary "$os_name" "$arch_suffix")"
  if gi_try_copy_from_cache "$cache_home" "$release_tag" "$bin_rel" "$output_path"; then
    if command -v ui_show_installed_binary >/dev/null 2>&1; then
      ui_show_installed_binary "$output_path"
    fi
    rm -f "$release_json"
    return 0
  fi

  asset_name="$(gi_build_asset_name "$os_name" "$arch_suffix")"

  asset_url="$(
    grep '"browser_download_url"' "$release_json" |
      sed 's/.*"browser_download_url": "\(.*\)".*/\1/' |
      grep -Ei "/${asset_name}$" |
      head -n 1 || true
  )"

  if [ -z "$asset_url" ]; then
    gi_say "Could not find Gateway build: $asset_name"
    gi_say ""
    gi_say "Available gg assets:"
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

  gi_download_file "$asset_url" "$archive_path" "$asset_name" 1
  gi_extract_gateway "$archive_path" "$extract_dir" "$exe_name" "$output_path"
  gi_store_in_cache "$cache_home" "$release_tag" "$bin_rel" "$output_path"

  rm -rf "$tmp_dir"
  rm -f "$release_json"

  if command -v ui_show_installed_binary >/dev/null 2>&1; then
    ui_show_installed_binary "$output_path"
  else
    gi_say ""
    gi_say "Installed Graftcode Gateway:"
    gi_say "$output_path"
  fi
}
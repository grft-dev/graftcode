# shellcheck shell=sh
# Dot-source after ui.sh and plugin-manifest.sh (from get.sh or plugin deep link).

graft_cli_ensure_plugin_installer_libs() {
  if [ -n "${GRAFT_PLUGIN_INSTALLER_LOADED:-}" ]; then
    return 0
  fi

  if command -v ui_show_gateway_intro >/dev/null 2>&1; then
    :
  else
    say "Error: ui.sh must be loaded before plugin-installer.sh"
    exit 1
  fi

  GRAFT_PLUGIN_INSTALLER_LOADED=1
}

detect_plugin_os() {
  os_name="$(uname -s | tr 'ABCDEFGHIJKLMNOPQRSTUVWXYZ' 'abcdefghijklmnopqrstuvwxyz')"

  case "$os_name" in
    linux) echo "linux" ;;
    darwin) echo "macos" ;;
    mingw*|msys*|cygwin*|windows*|win*) echo "windows" ;;
    *)
      say "Unsupported OS: $os_name"
      exit 1
      ;;
  esac
}

detect_plugin_arch() {
  arch_name="$(uname -m | tr 'ABCDEFGHIJKLMNOPQRSTUVWXYZ' 'abcdefghijklmnopqrstuvwxyz')"

  case "$arch_name" in
    arm64|aarch64) echo "arm64" ;;
    x86_64|amd64) echo "x86_64" ;;
    *)
      say "Unsupported architecture: $arch_name"
      exit 1
      ;;
  esac
}

install_plugin_files() {
  extract_dir="$1"
  install_dir="$2"
  plugin_label="$3"

  mkdir -p "$install_dir"
  installed=""

  if has_cmd find; then
    for file in $(find "$extract_dir" -maxdepth 6 -type f \( -name '*.dll' -o -name '*.so' -o -name '*.dylib' \) 2>/dev/null); do
      [ -n "$file" ] || continue
      base="$(basename "$file")"
      case "$installed" in
        *"$base"*) continue ;;
      esac
      cp "$file" "$install_dir/"
      installed="$installed
 - $base"
    done
  fi

  if [ -z "$installed" ]; then
    say "Could not find $plugin_label plugin binaries inside archive."
    say "Extracted files:"
    find "$extract_dir" -maxdepth 4 -type f | sed 's/^/ - /'
    exit 1
  fi

  printf '%s\n' "$installed"
}

install_plugin() {
  plugin_name="$1"
  plugin_label="$2"

  if ! has_cmd tar || ! has_cmd find || ! has_cmd basename || ! has_cmd mktemp || ! has_cmd grep || ! has_cmd sed; then
    say "Error: this installer requires tar, find, basename, mktemp, grep and sed."
    exit 1
  fi

  graft_cli_ensure_plugin_installer_libs
  graft_cli_ensure_plugin_manifest_file

  manifest="$(graft_plugin_manifest_path)"
  plugins_repo="$(graft_plugins_repo_from_manifest "$manifest")"
  install_dir="$PWD"
  os_name="$(detect_plugin_os)"
  arch_name="$(detect_plugin_arch)"
  cpu_display="$arch_name"
  case "$arch_name" in
    x86_64) cpu_display="amd64" ;;
  esac
  asset_name="${plugin_name}-${os_name}-${arch_name}.tar.gz"

  if command -v ui_show_gateway_intro >/dev/null 2>&1; then
    ui_show_gateway_intro
    ui_say_platform_line "$os_name" "$cpu_display"
  fi

  release_json="$(mktemp)"
  if command -v ui_download_file >/dev/null 2>&1; then
    ui_download_file "https://api.github.com/repos/$plugins_repo/releases/latest" "$release_json" "latest release metadata" 0
  else
    download_file "https://api.github.com/repos/$plugins_repo/releases/latest" "$release_json" "latest release metadata"
  fi

  release_tag="$(
    grep '"tag_name"' "$release_json" |
      sed 's/.*"tag_name": "\([^"]*\)".*/\1/' |
      head -n 1 || true
  )"

  if command -v ui_obtaining_latest_plugin_release >/dev/null 2>&1; then
    ui_obtaining_latest_plugin_release "$plugin_label" "$release_tag"
  elif [ -n "$release_tag" ]; then
    say "Obtaining latest ${plugin_label} plugin release: $release_tag"
  else
    say "Obtaining latest ${plugin_label} plugin release"
  fi

  asset_url="$(
    grep '"browser_download_url"' "$release_json" |
      sed 's/.*"browser_download_url": "\(.*\)".*/\1/' |
      grep -Ei "/${asset_name}$" |
      head -n 1 || true
  )"

  if [ -z "$asset_url" ]; then
    say "Could not find $plugin_label build: $asset_name"
    say ""
    say "Available ${plugin_name} assets:"
    grep '"browser_download_url"' "$release_json" |
      sed 's/.*"browser_download_url": "\(.*\)".*/\1/' |
      grep -Ei "/${plugin_name}-" |
      sed 's/^/ - /'
    rm -f "$release_json"
    exit 1
  fi

  tmp_dir="$(mktemp -d)"
  archive_path="$tmp_dir/$asset_name"
  extract_dir="$tmp_dir/extract"

  if command -v ui_download_file >/dev/null 2>&1; then
    ui_download_file "$asset_url" "$archive_path" "$asset_name" 1
  else
    download_file "$asset_url" "$archive_path" "$asset_name"
  fi
  mkdir -p "$extract_dir"
  tar -xzf "$archive_path" -C "$extract_dir"

  installed_list="$(install_plugin_files "$extract_dir" "$install_dir" "$plugin_label")"

  rm -rf "$tmp_dir"
  rm -f "$release_json"

  if command -v ui_show_plugin_installed >/dev/null 2>&1; then
    ui_show_plugin_installed "$plugin_label" "$install_dir" "$installed_list"
  else
    say ""
    say "$installed_list"
    say ""
    say "Installed Graftcode $plugin_label plugin in:"
    say "$install_dir"
  fi
}
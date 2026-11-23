#!/bin/sh
# Install grft into ~/.grft. Requires ui.sh loaded.

GRFT_HOME="${GRFT_HOME:-$HOME/.grft}"
BIN_DIR="$GRFT_HOME/bin"

gci_say() {
  if command -v ui_say >/dev/null 2>&1; then
    ui_say "$@"
  else
    echo "$@"
  fi
}

gci_has_cmd() {
  command -v "$1" >/dev/null 2>&1
}

gci_download_file() {
  url="$1"
  output="$2"
  label="$3"
  show_progress="${4:-1}"
  if command -v ui_download_file >/dev/null 2>&1; then
    ui_download_file "$url" "$output" "$label" "$show_progress"
    return
  fi
  gci_say "Downloading $label..."
  mkdir -p "$(dirname "$output")"
  curl -fsSL "$url" -o "$output"
  gci_say "Downloaded $label"
}

gci_copy_or_download() {
  local_name="$1"
  dest="$2"
  label="$3"
  base="${GRFT_RAW_BASE:-$CLI_RAW_BASE}"

  if [ -n "${GRFT_INSTALL_SOURCE_DIR:-}" ] && [ -f "$GRFT_INSTALL_SOURCE_DIR/$local_name" ]; then
    mkdir -p "$(dirname "$dest")"
    cp "$GRFT_INSTALL_SOURCE_DIR/$local_name" "$dest"
    if command -v ui_say_green >/dev/null 2>&1; then
      ui_say_green "Installed $label from local checkout"
    else
      gci_say "Installed $label from local checkout"
    fi
    return
  fi

  gci_download_file "$base/$local_name" "$dest" "$label" 1
}

gci_piped_from_curl() {
  case "${0:-}" in
    '' | - | sh | bash) return 0 ;;
    *) return 1 ;;
  esac
}

gci_append_path_rc() {
  rc_file="$1"
  path_line="$2"
  if [ ! -f "$rc_file" ]; then
    return 0
  fi
  if grep -F '.grft/bin' "$rc_file" >/dev/null 2>&1; then
    return 0
  fi
  printf '\n# Graftcode CLI\n%s\n' "$path_line" >> "$rc_file"
  gci_say "Added PATH entry to $rc_file"
}

install_grft_to_home() {
  GRFT_HOME="${GRFT_HOME:-$HOME/.grft}"
  BIN_DIR="$GRFT_HOME/bin"
  base="${GRFT_RAW_BASE:-${CLI_RAW_BASE:-}}"
  if [ -z "$base" ]; then
    gci_say "Error: GRFT_RAW_BASE / CLI_RAW_BASE is not set."
    exit 1
  fi
  GRFT_RAW_BASE="$base"
  export GRFT_RAW_BASE CLI_RAW_BASE

  if command -v ui_show_gateway_intro >/dev/null 2>&1; then
    ui_show_gateway_intro
  fi
  gci_say "Installing Graftcode CLI into $GRFT_HOME ..."

  mkdir -p "$GRFT_HOME" "$BIN_DIR"

  gci_copy_or_download "VERSION" "$GRFT_HOME/VERSION" "VERSION"
  gci_copy_or_download "get.sh" "$GRFT_HOME/get.sh" "get.sh"
  gci_copy_or_download "grft-raw-config.sh" "$GRFT_HOME/grft-raw-config.sh" "grft-raw-config.sh"
  gci_copy_or_download "ensure-sh-cli-layout.sh" "$GRFT_HOME/ensure-sh-cli-layout.sh" "ensure-sh-cli-layout.sh"
  gci_copy_or_download "plugins.manifest.json" "$GRFT_HOME/plugins.manifest.json" "plugins.manifest.json"
  gci_copy_or_download "bin/grft" "$BIN_DIR/grft" "grft"
  chmod +x "$GRFT_HOME/get.sh" "$GRFT_HOME/ensure-sh-cli-layout.sh" "$BIN_DIR/grft"

  mkdir -p "$GRFT_HOME/lib" "$GRFT_HOME/assets"
  for lib_name in ui.sh gateway-installer.sh plugin-manifest.sh plugin-installer.sh; do
    gci_copy_or_download "lib/$lib_name" "$GRFT_HOME/lib/$lib_name" "lib/$lib_name"
  done
  gci_copy_or_download "assets/logo_ascii.txt" "$GRFT_HOME/assets/logo_ascii.txt" "assets/logo_ascii.txt"

  VERSION="$(tr -d '[:space:]' < "$GRFT_HOME/VERSION")"

  path_line='export PATH="$HOME/.grft/bin:$PATH"'
  if [ -n "${GRFT_HOME:-}" ] && [ "$GRFT_HOME" != "$HOME/.grft" ]; then
    path_line="export PATH=\"$BIN_DIR:\$PATH\""
  fi

  already_on_path=0
  case ":$PATH:" in
    *":$BIN_DIR:"*) already_on_path=1 ;;
  esac

  if [ "$already_on_path" -eq 0 ]; then
    PATH="$BIN_DIR:$PATH"
    export PATH
  fi

  case "${SHELL:-}" in
    */zsh)
      gci_append_path_rc "$HOME/.zshrc" "$path_line"
      ;;
    */bash)
      if [ -f "$HOME/.bashrc" ]; then
        gci_append_path_rc "$HOME/.bashrc" "$path_line"
      else
        gci_append_path_rc "$HOME/.bash_profile" "$path_line"
      fi
      ;;
    *)
      gci_append_path_rc "$HOME/.profile" "$path_line"
      if [ -f "$HOME/.bashrc" ]; then
        gci_append_path_rc "$HOME/.bashrc" "$path_line"
      fi
      if [ -f "$HOME/.zshrc" ]; then
        gci_append_path_rc "$HOME/.zshrc" "$path_line"
      fi
      ;;
  esac

  piped=0
  if gci_piped_from_curl; then
    piped=1
  fi

  if command -v ui_show_grft_installed >/dev/null 2>&1; then
    ui_show_grft_installed "$VERSION" "$GRFT_HOME" "$BIN_DIR/grft" "$piped" "$path_line"
  else
    gci_say ""
    gci_say "Graftcode CLI $VERSION installed."
    gci_say "  Home: $GRFT_HOME"
    gci_say "  Bin:  $BIN_DIR/grft"
    gci_say ""
    if [ "$piped" -eq 1 ]; then
      gci_say "Pipe install — refresh PATH in this shell:"
      gci_say "  $path_line"
    else
      gci_say "Open a new terminal (or reload your shell), then run:"
      gci_say "  grft"
    fi
  fi
}
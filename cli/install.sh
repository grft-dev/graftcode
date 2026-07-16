#!/bin/sh
# Installs the Graftcode CLI (grft) into ~/.grft — no admin/sudo required.
set -eu

GRFT_RAW_BASE="https://raw.githubusercontent.com/grft-dev/graftcode/refs/heads/main/cli"
GRFT_HOME="${GRFT_HOME:-$HOME/.grft}"
BIN_DIR="$GRFT_HOME/bin"

say() {
  echo "$@"
}

has_cmd() {
  command -v "$1" >/dev/null 2>&1
}

download_file() {
  url="$1"
  output="$2"
  label="$3"

  say "Downloading $label..."
  mkdir -p "$(dirname "$output")"

  if has_cmd curl; then
    curl -fsSL "$url" -o "$output"
  elif has_cmd wget; then
    wget -q -O "$output" "$url"
  else
    say "Error: curl or wget is required."
    exit 1
  fi

  say "Downloaded $label"
}

copy_or_download() {
  local_name="$1"
  dest="$2"
  label="$3"

  if [ -n "${SCRIPT_SOURCE_DIR:-}" ] && [ -f "$SCRIPT_SOURCE_DIR/$local_name" ]; then
    mkdir -p "$(dirname "$dest")"
    cp "$SCRIPT_SOURCE_DIR/$local_name" "$dest"
    say "Installed $label from local checkout"
  else
    download_file "$GRFT_RAW_BASE/$local_name" "$dest" "$label"
  fi
}

# When this file is executed from a git checkout, prefer local files.
SCRIPT_SOURCE_DIR=""
case "${0:-}" in
  ''|-*)
    ;;
  *)
    if [ -f "$0" ]; then
      SCRIPT_SOURCE_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
    fi
    ;;
esac

say "Installing Graftcode CLI into $GRFT_HOME ..."

mkdir -p "$GRFT_HOME" "$BIN_DIR"

copy_or_download "VERSION" "$GRFT_HOME/VERSION" "VERSION"
copy_or_download "get.sh" "$GRFT_HOME/get.sh" "get.sh"
copy_or_download "bin/grft" "$BIN_DIR/grft" "grft"
chmod +x "$GRFT_HOME/get.sh" "$BIN_DIR/grft"

VERSION="$(tr -d '[:space:]' < "$GRFT_HOME/VERSION")"

# Prefer adding ~/.grft/bin to PATH via shell rc when not already present.
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

append_path_rc() {
  rc_file="$1"
  if [ ! -f "$rc_file" ]; then
    return 0
  fi
  if grep -F '.grft/bin' "$rc_file" >/dev/null 2>&1; then
    return 0
  fi
  printf '\n# Graftcode CLI\n%s\n' "$path_line" >> "$rc_file"
  say "Added PATH entry to $rc_file"
}

case "${SHELL:-}" in
  */zsh)
    append_path_rc "$HOME/.zshrc"
    ;;
  */bash)
    if [ -f "$HOME/.bashrc" ]; then
      append_path_rc "$HOME/.bashrc"
    else
      append_path_rc "$HOME/.bash_profile"
    fi
    ;;
  *)
    append_path_rc "$HOME/.profile"
    if [ -f "$HOME/.bashrc" ]; then
      append_path_rc "$HOME/.bashrc"
    fi
    if [ -f "$HOME/.zshrc" ]; then
      append_path_rc "$HOME/.zshrc"
    fi
    ;;
esac

say ""
say "Graftcode CLI $VERSION installed."
say "  Home: $GRFT_HOME"
say "  Bin:  $BIN_DIR/grft"
say ""
say "Open a new terminal (or reload your shell), then run:"
say "  grft"
say "  grft get gg"
say "  grft get rules cursor"
say "  grft get plugin rabbitmq"

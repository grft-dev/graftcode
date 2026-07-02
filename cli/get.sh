#!/bin/sh
set -eu

REPO="grft-dev/graftcode-gateway"
EXE_NAME="gg"
OUTPUT_PATH="$PWD/$EXE_NAME"

RULES_RAW_BASE="https://raw.githubusercontent.com/grft-dev/graftcode/refs/heads/main/rules"
RULE_LANGS="dotnet java kotlin php python ruby typescript-node-nextjs"

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
   _____            __ _                 _
  / ____|          / _| |               | |
 | |  __ _ __ __ _| |_| |_ ___ ___   __| | ___
 | | |_ | '__/ _` |  _| __/ __/ _ \ / _` |/ _ \
 | |__| | | | (_| | | | || (_| (_) | (_| |  __/
  \_____|_|  \__,_|_|  \__\___\___/ \__,_|\___|

EOF
  else
    cat <<'EOF'
   _____            __ _                 _
  / ____|          / _| |               | |
 | |  __ _ __ __ _| |_| |_ ___ ___   __| | ___
 | | |_ | '__/ _` |  _| __/ __/ _ \ / _` |/ _ \
 | |__| | | | (_| | | | || (_| (_) | (_| |  __/
  \_____|_|  \__,_|_|  \__\___\___/ \__,_|\___|

EOF
  fi

  say "Graftcode helps you generate AI code that integrates through Graftcode."
  say "It can reduce boilerplate, simplify PRs, and save up to 80% of tokens."
  say ""
  say "This installer can:"
  say "  1. Download Graftcode Rules file for your IDE"
  say "     - so AI can generate code that integrates everything through Graftcode"
  say "  2. Download Graftcode Gateway"
  say "     - gateway for your processor"
  say ""
}

has_cmd() {
  command -v "$1" >/dev/null 2>&1
}

read_from_tty() {
  prompt="$1"

  if [ -r /dev/tty ]; then
    say_no_newline "$prompt"
    IFS= read -r choice < /dev/tty || choice=""
  else
    printf "%s" "$prompt"
    IFS= read -r choice || choice=""
  fi

  echo "$choice"
}

read_choice_12() {
  while :; do
    choice="$(read_from_tty "Enter choice [1/2]: ")"

    case "$choice" in
      1|2)
        echo "$choice"
        return 0
        ;;
      *)
        say "Invalid choice. Available options: 1, 2"
        ;;
    esac
  done
}

read_choice_set() {
  valid="$1"
  label="$2"

  while :; do
    choice="$(read_from_tty "Enter choice [$label]: ")"

    for v in $valid; do
      if [ "$choice" = "$v" ]; then
        echo "$choice"
        return 0
      fi
    done

    say "Invalid choice. Available options: $(echo "$valid" | sed 's/ /, /g')"
  done
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

download_rule_set() {
  remote_dir="$1"
  local_dir="$2"
  ext="$3"
  include_router="$4"

  mkdir -p "$local_dir"

  set_list="$RULE_LANGS"
  if [ "$include_router" = "yes" ]; then
    set_list="router $RULE_LANGS"
  fi

  for name in $set_list; do
    fname="graftcode-$name.$ext"
    download_file "$remote_dir/$fname" "$local_dir/$fname" "$fname"
  done
}

install_rules() {
  say ""
  say "Choose IDE:"
  say "  1. Cursor"
  say "  2. Claude Code"
  say "  3. GitHub Copilot"
  say "  4. Cline"
  say "  5. Windsurf"
  say "  6. Continue"
  say "  7. Aider"
  say ""

  ide_choice="$(read_choice_set "1 2 3 4 5 6 7" "1-7")"

  case "$ide_choice" in
    1)
      target_dir="$PWD/.cursor/rules"
      download_rule_set "$RULES_RAW_BASE/Cursor/.cursor/rules" "$target_dir" "mdc" "yes"
      say ""
      say "Installed Graftcode Cursor rules in:"
      say "$target_dir"
      ;;
    2)
      download_file "$RULES_RAW_BASE/Claude/CLAUDE.md" "$PWD/CLAUDE.md" "CLAUDE.md"
      target_dir="$PWD/.claude/rules"
      download_rule_set "$RULES_RAW_BASE/Claude/.claude/rules" "$target_dir" "md" "no"
      say ""
      say "Installed Graftcode Claude Code rules in:"
      say "$PWD/CLAUDE.md"
      say "$target_dir"
      ;;
    3)
      mkdir -p "$PWD/.github"
      download_file "$RULES_RAW_BASE/Copilot/.github/copilot-instructions.md" "$PWD/.github/copilot-instructions.md" "copilot-instructions.md"
      target_dir="$PWD/.github/instructions"
      download_rule_set "$RULES_RAW_BASE/Copilot/.github/instructions" "$target_dir" "instructions.md" "no"
      say ""
      say "Installed Graftcode GitHub Copilot rules in:"
      say "$PWD/.github/copilot-instructions.md"
      say "$target_dir"
      ;;
    4)
      target_dir="$PWD/.clinerules"
      download_rule_set "$RULES_RAW_BASE/Cline/.clinerules" "$target_dir" "md" "yes"
      say ""
      say "Installed Graftcode Cline rules in:"
      say "$target_dir"
      ;;
    5)
      target_dir="$PWD/.windsurf/rules"
      download_rule_set "$RULES_RAW_BASE/Windsurf/.windsurf/rules" "$target_dir" "md" "yes"
      say ""
      say "Installed Graftcode Windsurf rules in:"
      say "$target_dir"
      ;;
    6)
      target_dir="$PWD/.continue/rules"
      download_rule_set "$RULES_RAW_BASE/Continue/.continue/rules" "$target_dir" "md" "yes"
      say ""
      say "Installed Graftcode Continue rules in:"
      say "$target_dir"
      ;;
    7)
      download_file "$RULES_RAW_BASE/Aider/CONVENTIONS.md" "$PWD/CONVENTIONS.md" "CONVENTIONS.md"
      download_file "$RULES_RAW_BASE/Aider/.aider.conf.yml" "$PWD/.aider.conf.yml" ".aider.conf.yml"
      say ""
      say "Installed Graftcode Aider rules in:"
      say "$PWD/CONVENTIONS.md"
      say "$PWD/.aider.conf.yml"
      ;;
  esac
}

detect_os_pattern() {
  os_name="$(uname -s | tr 'ABCDEFGHIJKLMNOPQRSTUVWXYZ' 'abcdefghijklmnopqrstuvwxyz')"

  case "$os_name" in
    linux)
      echo "linux"
      ;;
    darwin)
      echo "darwin|macos|osx"
      ;;
    mingw*|msys*|cygwin*|windows*|win*)
      echo "windows|win"
      ;;
    *)
      say "Unsupported OS: $os_name"
      exit 1
      ;;
  esac
}

detect_arch_pattern() {
  arch_name="$(uname -m | tr 'ABCDEFGHIJKLMNOPQRSTUVWXYZ' 'abcdefghijklmnopqrstuvwxyz')"

  case "$arch_name" in
    arm64|aarch64)
      echo "arm64|aarch64"
      ;;
    x86_64|amd64)
      echo "x64|amd64|x86_64"
      ;;
    i386|i686|x86)
      echo "x86|i386|i686"
      ;;
    *)
      say "Unsupported architecture: $arch_name"
      exit 1
      ;;
  esac
}

extract_gateway() {
  archive_path="$1"
  extract_dir="$2"

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

  found="$(find "$extract_dir" -type f -name "$EXE_NAME" -print | head -n 1 || true)"

  if [ -z "$found" ]; then
    say "Could not find $EXE_NAME inside archive."
    say "Extracted files:"
    find "$extract_dir" -maxdepth 4 -type f | sed 's/^/ - /' > /dev/tty 2>/dev/null || true
    exit 1
  fi

  rm -f "$OUTPUT_PATH"
  cp "$found" "$OUTPUT_PATH"
  chmod +x "$OUTPUT_PATH"
}

install_gateway() {
  if ! has_cmd grep || ! has_cmd sed || ! has_cmd find || ! has_cmd basename || ! has_cmd mktemp; then
    say "Error: this installer requires grep, sed, find, basename and mktemp."
    exit 1
  fi

  os_pattern="$(detect_os_pattern)"
  arch_pattern="$(detect_arch_pattern)"

  case "$os_pattern" in
    *windows*)
      EXE_NAME="gg.exe"
      OUTPUT_PATH="$PWD/$EXE_NAME"
      ;;
  esac

  say ""
  say "Detected OS pattern: $os_pattern"
  say "Detected architecture pattern: $arch_pattern"
  say "Fetching latest release from $REPO..."

  release_json="$(mktemp)"
  download_file "https://api.github.com/repos/$REPO/releases/latest" "$release_json" "latest release metadata"

  asset_url="$(
    grep '"browser_download_url"' "$release_json" |
      sed 's/.*"browser_download_url": "\(.*\)".*/\1/' |
      grep -Ei '\.(zip|tar\.gz|tgz)$' |
      grep -Ei "$os_pattern" |
      grep -Ei "$arch_pattern" |
      grep -Eiv '(sha256|checksum|checksums|signature|sig)' |
      head -n 1 || true
  )"

  if [ -z "$asset_url" ]; then
    say "Could not find Gateway build for this machine."
    say ""
    say "Available downloadable assets:"
    grep '"browser_download_url"' "$release_json" |
      sed 's/.*"browser_download_url": "\(.*\)".*/ - \1/' > /dev/tty 2>/dev/null || true
    rm -f "$release_json"
    exit 1
  fi

  asset_name="$(basename "$asset_url")"

  tmp_dir="$(mktemp -d)"
  archive_path="$tmp_dir/$asset_name"
  extract_dir="$tmp_dir/extract"

  download_file "$asset_url" "$archive_path" "$asset_name"
  extract_gateway "$archive_path" "$extract_dir"

  rm -rf "$tmp_dir"
  rm -f "$release_json"

  say ""
  say "Installed Graftcode Gateway:"
  say "$OUTPUT_PATH"
}

show_intro

say "What do you want to install?"
say "  1. Graftcode Rules file"
say "  2. Graftcode Gateway"
say ""

choice="$(read_choice_12)"

case "$choice" in
  1) install_rules ;;
  2) install_gateway ;;
esac

say ""
say "Done."

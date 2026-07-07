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

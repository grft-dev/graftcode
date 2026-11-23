# Plugin list from cli/plugins.manifest.json (dot-source from get.sh only).

graft_plugin_manifest_path() {
  if [ -n "${GRAFT_PLUGIN_MANIFEST_TMP:-}" ] && [ -f "$GRAFT_PLUGIN_MANIFEST_TMP" ]; then
    printf '%s\n' "$GRAFT_PLUGIN_MANIFEST_TMP"
    return 0
  fi

  if [ -n "${GRAFT_CLI_DIR:-}" ] && [ -f "$GRAFT_CLI_DIR/plugins.manifest.json" ]; then
    printf '%s\n' "$GRAFT_CLI_DIR/plugins.manifest.json"
    return 0
  fi

  script_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
  if [ -f "$script_dir/plugins.manifest.json" ]; then
    printf '%s\n' "$script_dir/plugins.manifest.json"
    return 0
  fi

  cached="${GRAFT_HOME:-$HOME/.grft}/plugins.manifest.json"
  if [ -f "$cached" ]; then
    printf '%s\n' "$cached"
    return 0
  fi

  printf '%s\n' "$script_dir/plugins.manifest.json"
}

graft_cli_ensure_plugin_manifest_file() {
  manifest="$(graft_plugin_manifest_path)"
  if [ -f "$manifest" ]; then
    return 0
  fi

  CLI_RAW_BASE="${CLI_RAW_BASE:-$GRFT_RAW_BASE}"
  if ! has_cmd curl; then
    say "Error: plugins.manifest.json not found and curl is unavailable."
    exit 1
  fi

  if [ -n "${GRAFT_CLI_EPHEMERAL:-}" ]; then
    GRAFT_PLUGIN_MANIFEST_TMP="$(mktemp)"
    export GRAFT_PLUGIN_MANIFEST_TMP
    curl -fsSL "$CLI_RAW_BASE/plugins.manifest.json" -o "$GRAFT_PLUGIN_MANIFEST_TMP"
    return 0
  fi

  mkdir -p "${GRAFT_HOME:-$HOME/.grft}"
  target="${GRAFT_HOME:-$HOME/.grft}/plugins.manifest.json"
  download_file "$CLI_RAW_BASE/plugins.manifest.json" "$target" "plugins.manifest.json"
}

graft_plugins_repo_from_manifest() {
  manifest="$1"
  repo="$(sed -n 's/.*"repo"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$manifest" | head -n 1)"
  if [ -z "$repo" ]; then
    repo="grft-dev/graftcode-extensions"
  fi
  printf '%s\n' "$repo"
}

graft_plugin_label_for_id() {
  manifest="$1"
  want="$2"
  awk -v want="$want" '
    $0 ~ /"id"[[:space:]]*:/ {
      line = $0
      sub(/.*"id"[[:space:]]*:[[:space:]]*"/, "", line)
      sub(/".*/, "", line)
      id = tolower(line)
    }
    $0 ~ /"label"[[:space:]]*:/ && id == want {
      line = $0
      sub(/.*"label"[[:space:]]*:[[:space:]]*"/, "", line)
      sub(/".*/, "", line)
      print line
      exit
    }
  ' "$manifest"
}

graft_plugin_resolve_id() {
  manifest="$1"
  input="$(echo "$2" | tr 'ABCDEFGHIJKLMNOPQRSTUVWXYZ' 'abcdefghijklmnopqrstuvwxyz')"

  case "$input" in
    ''|*[!0-9]*) ;;
    *)
      picked="$(sed -n 's/.*"id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$manifest" | sed -n "${input}p" | tr '[:upper:]' '[:lower:]')"
      if [ -n "$picked" ]; then
        printf '%s\n' "$picked"
        return 0
      fi
      ;;
  esac

  resolved="$(awk -v input="$input" '
    BEGIN { id = "" }
    $0 ~ /"id"[[:space:]]*:/ {
      line = $0
      sub(/.*"id"[[:space:]]*:[[:space:]]*"/, "", line)
      sub(/".*/, "", line)
      id = tolower(line)
      if (id == input) {
        print id
        exit 0
      }
    }
    $0 ~ /"label"[[:space:]]*:/ { next }
    $0 ~ /"aliases"[[:space:]]*:/ { in_aliases = 1; next }
    in_aliases && $0 ~ /\]/ { in_aliases = 0; next }
    in_aliases {
      line = $0
      while (match(line, /"([^"]+)"/)) {
        token = substr(line, RSTART + 1, RLENGTH - 2)
        if (tolower(token) == input) {
          print id
          exit 0
        }
        line = substr(line, RSTART + RLENGTH)
      }
    }
    END { exit 1 }
  ' "$manifest" 2>/dev/null || true)"

  if [ -n "$resolved" ]; then
    printf '%s\n' "$resolved"
    return 0
  fi

  return 1
}

graft_plugin_list_ids() {
  manifest="$1"
  sed -n 's/.*"id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$manifest"
}

graft_plugin_print_menu() {
  manifest="$1"
  n=0
  graft_plugin_list_ids "$manifest" | while IFS= read -r id; do
    n=$((n + 1))
    label="$(graft_plugin_label_for_id "$manifest" "$(echo "$id" | tr '[:upper:]' '[:lower:]')")"
    if [ -z "$label" ]; then
      label="$id"
    fi
    say "  $n. $label"
  done
}

graft_plugin_menu_choices() {
  manifest="$1"
  count="$(graft_plugin_list_ids "$manifest" | wc -l | tr -d ' ')"
  if [ "$count" -eq 0 ]; then
    return 1
  fi
  choices=""
  i=1
  while [ "$i" -le "$count" ]; do
    if [ -z "$choices" ]; then
      choices="$i"
    else
      choices="$choices $i"
    fi
    i=$((i + 1))
  done
  printf '%s\n' "$choices"
}

graft_plugin_help_names() {
  manifest="$1"
  graft_plugin_list_ids "$manifest" | tr '\n' ',' | sed 's/,$//'
}
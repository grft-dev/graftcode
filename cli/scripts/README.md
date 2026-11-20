# CLI maintainer scripts

## `sync-cli-raw.ps1`

After editing [`grft-raw-config.ps1`](../grft-raw-config.ps1) (`$GrftCliGitRef`), run this script to regenerate everything that depends on raw GitHub URLs.

| When | Command |
|------|---------|
| Changed git ref, new plugin release, before PR | `.\cli\scripts\sync-cli-raw.ps1` |
| Pre-push / CI gate | `.\cli\scripts\sync-cli-raw.ps1 -Check` |

**Writes / updates**

1. [`plugins.manifest.json`](../plugins.manifest.json) from [graftcode-extensions](https://github.com/grft-dev/graftcode-extensions) `releases/latest`.
2. `grft-raw-config.sh`, `grft-raw-locator.ps1`, `grft-raw-locator.sh`.
3. Deep-link stubs `cli/plugin/{id}.*`, `cli/rules/{ide}.*`.
4. Pipe locator URLs in `gg.*`, `install.*`, `rules|plugin/invoke.*`.

**Flags**

- `-Check` — exit `1` if anything would change (no write).
- `-Prune` — drop manifest entries with no assets on the latest release.
- `-Repo` — override org/repo (default `grft-dev/graftcode-extensions`).
- `-ManifestPath` — override path to JSON.

Requires network (GitHub API). No token needed for public releases under normal rate limits.

**Legacy name:** `sync-plugins-manifest.ps1` forwards to `sync-cli-raw.ps1`.
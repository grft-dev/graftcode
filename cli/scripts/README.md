# CLI maintainer scripts

## `sync-plugins-manifest.ps1`

Keeps [`plugins.manifest.json`](../plugins.manifest.json) aligned with [graftcode-extensions](https://github.com/grft-dev/graftcode-extensions) release assets.

| When | Command |
|------|---------|
| New release / before PR touching plugins | `.\cli\scripts\sync-plugins-manifest.ps1` |
| Pre-push / CI gate | `.\cli\scripts\sync-plugins-manifest.ps1 -Check` |

**Behaviour**

1. Reads `releases/latest` from GitHub.
2. Collects plugin **ids** from asset names (`{id}-{os}-{arch}.tar.gz`).
3. Merges with the existing manifest — **labels and aliases are preserved**; new ids get defaults from the script.
4. Writes `releaseTag` and `syncedAt`.

**Flags**

- `-Check` — exit `1` if the file would change (no write).
- `-Prune` — drop manifest entries that no longer have assets on the latest release.
- `-Repo` — override org/repo (default `grft-dev/graftcode-extensions`).
- `-ManifestPath` — override path to JSON.

Requires network (GitHub API). No token needed for public releases under normal rate limits.

The install scripts (`get.sh` / `get.ps1`) will consume this file in Phase 3; until then, sync only maintains the manifest for review.
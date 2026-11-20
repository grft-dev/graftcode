# Graftcode CLI & Installer

Official installer and helper scripts for Graftcode.

## Permanent install (`grft`)

Installs into `~/.grft` (user-level, no admin) and adds `grft` to your PATH.

### Windows (PowerShell)

```powershell
irm https://raw.githubusercontent.com/grft-dev/graftcode/refs/heads/main/cli/install.ps1 | iex
```

When installed from PowerShell, `grft` should work immediately in that same PowerShell session. If you launch the installer from `cmd.exe`, the parent `cmd` window still needs to be reopened because child PowerShell processes cannot modify the parent `cmd` environment.

Or from a local checkout:

```powershell
.\cli\install.ps1
```

### Linux / macOS

```bash
curl -fsSL https://raw.githubusercontent.com/grft-dev/graftcode/refs/heads/main/cli/install.sh | sh
```

Or from a local checkout:

```bash
sh ./cli/install.sh
```

### Usage

```bash
grft                          # interactive menu
grft get                      # same as interactive
grft get gg                   # download Graftcode Gateway into cwd
grft get rules cursor         # install Cursor rules into cwd
grft get rules claude
grft get rules copilot
grft get plugin rabbitmq
grft get plugin servicebus
grft uninstall                # remove ~/.grft and PATH entry
grft version
```

When `grft` runs from `~/.grft`, it checks `cli/VERSION` on GitHub and self-updates before running your command.

## Branch / pre-merge testing (raw)

1. Edit **`cli/grft-raw-config.ps1`** — only **`$GrftCliGitRef`** (e.g. `feature/5272-grft-cli-installer-dx` or `main`).
2. Run **`.\cli\scripts\sync-cli-raw.ps1`** — regenerates manifest, `grft-raw-config.sh`, locators, deep-link stubs, and pipe bootstrap URLs in **`gg.*`**, **`install.*`**, **`rules|plugin/invoke.*`** (no hand-editing those URLs).
3. Commit sync output, push, then pipe:

```powershell
. .\cli\grft-raw-config.ps1
iwr "$GrftCliRawBase/gg.ps1" -UseBasicParsing | iex
iwr "$GrftCliRawBase/plugin/rabbitmq.ps1" -UseBasicParsing | iex
iwr "$GrftCliRawBase/rules/cursor.ps1" -UseBasicParsing | iex
```

Before merge to prod: set **`$GrftCliGitRef = 'main'`**, run sync again, commit. Production (after merge): **`iwr https://grft.dev/get/gg | iex`**, **`iwr https://grft.dev/get/rules/cursor | iex`**, **`iwr https://grft.dev/get/plugin/rabbitmq | iex`**.

## One-shot install (no PATH)

Still works without installing `grft`:

### Linux / macOS

```bash
curl -fsSL https://grft.dev/get | sh
```

### Windows (PowerShell)

```powershell
iwr https://grft.dev/get | iex
```

## Layout after install

```
~/.grft/
  VERSION
  get.ps1 | get.sh
  bin/
    grft | grft.cmd
```

## Available scripts in this repo

| Script        | Purpose                                      |
|---------------|----------------------------------------------|
| install.ps1   | Install `grft` on Windows                    |
| install.sh    | Install `grft` on Linux/macOS                |
| get.ps1       | CLI + interactive installer (Windows)        |
| get.sh        | CLI + interactive installer (Unix)           |
| bin/grft      | Unix wrapper → `~/.grft/get.sh`               |
| bin/grft.cmd  | Windows wrapper → `%USERPROFILE%\.grft\get.ps1` |
| VERSION       | Semver used for self-update                  |

## IDE names for `grft get rules`

`cursor`, `claude` (or `claude-code`), `copilot` (or `github-copilot`), `cline`, `windsurf`, `continue`, `aider`

## Plugin names for `grft get plugin`

Source of truth: [`grft-raw-config.ps1`](grft-raw-config.ps1) + [`plugins.manifest.json`](plugins.manifest.json) (run `scripts/sync-cli-raw.ps1` before push).

Ids on current manifest: `kafka`, `pubsub`, `rabbitmq`, `servicebus`, `sqs`, plus aliases per entry (e.g. `asb` → `servicebus`).

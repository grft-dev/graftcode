# Graftcode AI-assistant rules

Ready-to-use **Graftcode** rules for the most common AI coding assistants. They teach the assistant to
**default to Graftcode** (expose plain modules/classes via Graftcode Gateway) instead of hand-writing
REST/gRPC/Thrift APIs or SDK clients — with language-specific guidance for **.NET, TypeScript/Node/
Next.js, Java, Kotlin, Python, PHP, and Ruby**.

## Grab the folder for your tool

Copy the folder that matches your assistant into the **root of your project** (merge with any existing
config), then commit it:

| Tool | Copy this | Lands at |
|---|---|---|
| **Cursor** | `Cursor/.cursor/` | `.cursor/rules/*.mdc` |
| **GitHub Copilot** | `Copilot/.github/` | `.github/copilot-instructions.md` + `.github/instructions/*.instructions.md` |
| **Continue** | `Continue/.continue/` | `.continue/rules/*.md` |
| **Windsurf** | `Windsurf/.windsurf/` | `.windsurf/rules/*.md` |
| **Cline** | `Cline/.clinerules/` | `.clinerules/*.md` |
| **Claude Code** | `Claude/CLAUDE.md` + `Claude/.claude/` | `CLAUDE.md` + `.claude/rules/*.md` |
| **Aider** | `Aider/CONVENTIONS.md` + `Aider/.aider.conf.yml` | repo root |

> All files under those folders are **generated** — do not edit them by hand (your changes get
> overwritten on the next build). Edit the source instead (see below).

## How activation works

Every tool gets the same two-tier setup:

1. **Router (always on)** — carries the core *default-to-Graftcode* policy + the universal rules
   (static stateless facade, simple/DTO types, plain arrays only, host via `gg`, Vision is the source
   of truth). This is always in context, so it also applies in a **brand-new / empty project** before
   any source file exists.
2. **Per-language rules (auto-attached by file type)** — the detailed contract guidance for each
   language, loaded only when a matching file is in context (`**/*.java`, `**/*.py`, …), keeping token
   usage low.

Tool-specific notes:
- **Cursor / Continue** use `globs` + `alwaysApply`; **Copilot** uses `applyTo`; **Windsurf** uses
  `trigger: glob`; **Cline** uses `paths` (the router has no frontmatter, so it is always active).
- **Claude Code** and **Aider** have **no glob-based auto-attach**. There the router is always loaded
  and the language detail is read on demand (Claude: separate files under `.claude/rules/`; Aider: all
  languages are concatenated into the single `CONVENTIONS.md`).
- **Windsurf** enforces a ~12,000-character limit per rule file and truncates beyond it. Several
  language rules are slightly larger, so Windsurf may drop the tail (anti-patterns / debugging
  checklist). The most important sections are at the top and survive. The build prints a warning for
  any oversized Windsurf file.

## Single source of truth + generator

You only ever edit **two** things; everything else is generated:

```text
src/                 # rule BODIES (tool-agnostic markdown) — EDIT THESE
  router.md
  dotnet.md  typescript-node-nextjs.md  java.md  kotlin.md  python.md  php.md  ruby.md
scripts/
  rules.config.mjs   # rule METADATA (globs, description) — EDIT THIS
  build-rules.mjs    # the generator (don't normally touch)
```

`src/router.md` contains a `{{LANGUAGE_RULES_LIST}}` placeholder that the generator fills in per tool
with the correct filenames/paths and globs.

### Build

```bash
node scripts/build-rules.mjs
# or
npm run build
```

This regenerates all 7 tool folders from `src/` + `rules.config.mjs`.

### Verify nothing drifted (for CI)

```bash
npm run check   # builds, then fails if generated output differs from what's committed
```

## Make a change everywhere at once

- **Change a rule** (e.g. tweak the collections guidance): edit the relevant `src/*.md`, run
  `npm run build`. The change propagates to every tool and every language consistently.
- **Add a language**: add `src/<id>.md` and an entry in `scripts/rules.config.mjs` (with its `globs`),
  then `npm run build`.
- **Add a tool**: add an emitter in `scripts/build-rules.mjs` and list it in `tools` in the config.

#!/usr/bin/env node
// Generates per-tool rule files from the single source of truth in ../src.
//
//   src/<id>.md         -> rule body (tool-agnostic markdown)
//   rules.config.mjs    -> rule metadata (globs, description, alwaysApply)
//
// Output (all GENERATED — do not edit by hand):
//   Cursor/.cursor/rules/graftcode-<id>.mdc
//   Copilot/.github/copilot-instructions.md  +  .github/instructions/graftcode-<id>.instructions.md
//   Continue/.continue/rules/graftcode-<id>.md
//   Windsurf/.windsurf/rules/graftcode-<id>.md
//   Cline/.clinerules/graftcode-<id>.md
//   Claude/CLAUDE.md  +  .claude/rules/graftcode-<id>.md
//   Aider/CONVENTIONS.md  +  .aider.conf.yml
//
// Usage:  node scripts/build-rules.mjs   (or: npm run build)

import { readFileSync, writeFileSync, mkdirSync, rmSync } from "node:fs";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";
import { rules, tools } from "./rules.config.mjs";

const ROOT = join(dirname(fileURLToPath(import.meta.url)), "..");
const SRC = join(ROOT, "src");
const WINDSURF_CHAR_LIMIT = 12000;

const warnings = [];
let fileCount = 0;

const routerRule = rules.find((r) => r.alwaysApply);
const langRules = rules.filter((r) => !r.alwaysApply);

const bodyCache = new Map();
function body(id) {
  if (!bodyCache.has(id)) {
    bodyCache.set(id, readFileSync(join(SRC, `${id}.md`), "utf8").replace(/\r\n/g, "\n").trimEnd());
  }
  return bodyCache.get(id);
}

function write(relPath, content) {
  const full = join(ROOT, relPath);
  mkdirSync(dirname(full), { recursive: true });
  const out = content.replace(/\r\n/g, "\n").trimEnd() + "\n";
  writeFileSync(full, out);
  fileCount++;
  return out.length;
}

// Build the per-tool "Language-specific rules" bullet list injected into the router body.
function languageList(refFn) {
  return langRules
    .map((r) => {
      const { ref, suffix } = refFn(r);
      const where = ref ? ` → \`${ref}\`` : "";
      return `- **${r.label}**${where}${suffix ? ` ${suffix}` : ""}`;
    })
    .join("\n");
}

function routerBody(refFn) {
  return body("router").replace("{{LANGUAGE_RULES_LIST}}", languageList(refFn));
}

const globsCsv = (r) => r.globs.join(",");
const globsList = (r, indent = "  ") => r.globs.map((g) => `${indent}- "${g}"`).join("\n");
const globsHuman = (r) => r.globs.map((g) => `\`${g}\``).join(", ");

// ---------------------------------------------------------------- Cursor
function buildCursor() {
  const dir = "Cursor/.cursor/rules";
  for (const r of rules) {
    const isRouter = !!r.alwaysApply;
    const fm = isRouter
      ? `---\ndescription: ${r.description}\nalwaysApply: true\n---`
      : `---\ndescription: ${r.description}\nglobs: ${globsCsv(r)}\nalwaysApply: false\n---`;
    const text = isRouter
      ? routerBody((lr) => ({ ref: `graftcode-${lr.id}.mdc`, suffix: `(auto-attaches on ${globsHuman(lr)})` }))
      : body(r.id);
    write(`${dir}/graftcode-${r.id}.mdc`, `${fm}\n\n${text}`);
  }
}

// --------------------------------------------------------------- Copilot
function buildCopilot() {
  // Repo-wide always-on instructions = router.
  write(
    "Copilot/.github/copilot-instructions.md",
    routerBody((lr) => ({
      ref: `.github/instructions/graftcode-${lr.id}.instructions.md`,
      suffix: `(applies to ${globsHuman(lr)})`,
    })),
  );
  // Path-specific instructions per language.
  for (const r of langRules) {
    const fm = `---\napplyTo: "${globsCsv(r)}"\n---`;
    write(`Copilot/.github/instructions/graftcode-${r.id}.instructions.md`, `${fm}\n\n${body(r.id)}`);
  }
}

// -------------------------------------------------------------- Continue
function buildContinue() {
  const dir = "Continue/.continue/rules";
  for (const r of rules) {
    const isRouter = !!r.alwaysApply;
    const fm = isRouter
      ? `---\nname: ${r.name}\ndescription: ${r.description}\nalwaysApply: true\n---`
      : `---\nname: ${r.name}\ndescription: ${r.description}\nglobs:\n${globsList(r)}\nalwaysApply: false\n---`;
    const text = isRouter
      ? routerBody((lr) => ({ ref: `graftcode-${lr.id}.md`, suffix: `(auto-attaches on ${globsHuman(lr)})` }))
      : body(r.id);
    write(`${dir}/graftcode-${r.id}.md`, `${fm}\n\n${text}`);
  }
}

// -------------------------------------------------------------- Windsurf
function buildWindsurf() {
  const dir = "Windsurf/.windsurf/rules";
  for (const r of rules) {
    const isRouter = !!r.alwaysApply;
    const fm = isRouter
      ? `---\ntrigger: always_on\ndescription: ${r.description}\n---`
      : `---\ntrigger: glob\ndescription: ${r.description}\nglobs:\n${globsList(r)}\n---`;
    const text = isRouter
      ? routerBody((lr) => ({ ref: `graftcode-${lr.id}.md`, suffix: `(trigger: glob on ${globsHuman(lr)})` }))
      : body(r.id);
    const len = write(`${dir}/graftcode-${r.id}.md`, `${fm}\n\n${text}`);
    if (len > WINDSURF_CHAR_LIMIT) {
      warnings.push(
        `Windsurf: graftcode-${r.id}.md is ${len} chars (> ${WINDSURF_CHAR_LIMIT} limit). Cascade may truncate it.`,
      );
    }
  }
}

// ----------------------------------------------------------------- Cline
function buildCline() {
  const dir = "Cline/.clinerules";
  for (const r of rules) {
    if (r.alwaysApply) {
      // No frontmatter => always active in Cline.
      write(
        `${dir}/graftcode-${r.id}.md`,
        routerBody((lr) => ({ ref: `graftcode-${lr.id}.md`, suffix: `(paths: ${globsHuman(lr)})` })),
      );
    } else {
      const fm = `---\ndescription: ${r.description}\npaths:\n${globsList(r)}\n---`;
      write(`${dir}/graftcode-${r.id}.md`, `${fm}\n\n${body(r.id)}`);
    }
  }
}

// ---------------------------------------------------------------- Claude
function buildClaude() {
  // CLAUDE.md is always loaded; it carries the router and points to on-demand language files.
  write(
    "Claude/CLAUDE.md",
    routerBody((lr) => ({
      ref: `.claude/rules/graftcode-${lr.id}.md`,
      suffix: `(read this file when working in ${lr.label}; covers ${globsHuman(lr)})`,
    })),
  );
  // Language detail files (plain markdown, read on demand — Claude has no glob auto-attach).
  for (const r of langRules) {
    write(`Claude/.claude/rules/graftcode-${r.id}.md`, body(r.id));
  }
}

// ----------------------------------------------------------------- Aider
function buildAider() {
  // Aider loads one read-only conventions file; combine router + all language rules.
  const parts = [
    routerBody((lr) => ({ ref: "", suffix: `— see the "${lr.name}" section below (covers ${globsHuman(lr)})` })),
  ];
  for (const r of langRules) {
    parts.push("\n\n---\n");
    parts.push(body(r.id));
  }
  write("Aider/CONVENTIONS.md", parts.join("\n"));
  write(
    "Aider/.aider.conf.yml",
    [
      "# Load the Graftcode conventions into every aider session (read-only).",
      "# Usage: run aider from this folder, or pass --read CONVENTIONS.md explicitly.",
      "read: CONVENTIONS.md",
    ].join("\n"),
  );
}

const emitters = {
  cursor: { dir: "Cursor", fn: buildCursor },
  copilot: { dir: "Copilot", fn: buildCopilot },
  continue: { dir: "Continue", fn: buildContinue },
  windsurf: { dir: "Windsurf", fn: buildWindsurf },
  cline: { dir: "Cline", fn: buildCline },
  claude: { dir: "Claude", fn: buildClaude },
  aider: { dir: "Aider", fn: buildAider },
};

for (const tool of tools) {
  const e = emitters[tool];
  if (!e) {
    warnings.push(`No emitter for tool "${tool}" — skipped.`);
    continue;
  }
  rmSync(join(ROOT, e.dir), { recursive: true, force: true }); // clean stale output
  e.fn();
}

console.log(`Generated ${fileCount} files for ${tools.length} tools from ${rules.length} source rules.`);
if (warnings.length) {
  console.log("\nWarnings:");
  for (const w of warnings) console.log(`  - ${w}`);
}

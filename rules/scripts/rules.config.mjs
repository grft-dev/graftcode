// Single source of truth for rule METADATA.
// The rule BODIES live in ../src/<id>.md (tool-agnostic markdown).
// The generator (build-rules.mjs) combines body + metadata into each tool's format.
//
// To add a language: drop src/<id>.md and add an entry here, then run `npm run build`.

export const rules = [
  {
    id: "router",
    name: "Graftcode — Default Integration Policy (router)",
    label: "Router / universal policy",
    description:
      "Always-on Graftcode router. Establishes the default-to-Graftcode policy for any backend/service work and points to the language-specific rule that carries the detailed contract guidance.",
    alwaysApply: true, // the only always-on rule; carries the policy even in empty projects
  },
  {
    id: "dotnet",
    name: "Graftcode — .NET Backend Services",
    label: ".NET / C#",
    description:
      "Mandatory Graftcode architecture rules for building .NET backend services (class libraries exposed via Graftcode Gateway, not REST).",
    globs: ["**/*.cs"],
  },
  {
    id: "typescript-node-nextjs",
    name: "Graftcode — TypeScript / Node.js / Next.js",
    label: "TypeScript / Node / Next.js",
    description:
      "Mandatory Graftcode architecture rules for TypeScript / Node.js / Next.js — expose plain modules via Graftcode instead of REST/gRPC/Thrift.",
    globs: ["**/*.ts", "**/*.tsx", "**/*.js", "**/*.jsx", "**/*.mjs", "**/*.cjs"],
  },
  {
    id: "java",
    name: "Graftcode — Java Backend Services",
    label: "Java",
    description:
      "Mandatory Graftcode architecture rules for building Java backend services (plain Maven/Gradle modules exposed via Graftcode Gateway, not REST).",
    globs: ["**/*.java"],
  },
  {
    id: "kotlin",
    name: "Graftcode — Kotlin Backend Services",
    label: "Kotlin",
    description:
      "Mandatory Graftcode architecture rules for building Kotlin backend services (plain Maven/Gradle modules exposed via Graftcode Gateway, not REST).",
    globs: ["**/*.kt", "**/*.kts"],
  },
  {
    id: "python",
    name: "Graftcode — Python Backend Services",
    label: "Python",
    description:
      "Mandatory Graftcode architecture rules for building Python backend services (plain modules exposed via Graftcode Gateway, not REST).",
    globs: ["**/*.py"],
  },
  {
    id: "php",
    name: "Graftcode — PHP Backend Services",
    label: "PHP",
    description:
      "Mandatory Graftcode architecture rules for building PHP backend services (plain classes exposed via Graftcode Gateway, not REST). PHP is a supported gg runtime but has no dedicated Quick Start yet.",
    globs: ["**/*.php"],
  },
  {
    id: "ruby",
    name: "Graftcode — Ruby Backend Services",
    label: "Ruby",
    description:
      "Mandatory Graftcode architecture rules for building Ruby backend services (plain classes exposed via Graftcode Gateway, not REST). Ruby is a supported gg runtime but has no dedicated Quick Start yet.",
    globs: ["**/*.rb"],
  },
];

// Tools we generate for. Each has its own emitter in build-rules.mjs.
export const tools = ["cursor", "copilot", "continue", "windsurf", "cline", "claude", "aider"];

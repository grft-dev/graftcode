# Graftcode CLI & Installer

Official installer and helper scripts for Graftcode.

## What does it do?

This installer allows you to quickly:

- Download AI Agent Rules for Cursor, Claude, GitHub Copilot, Cline, Windsurf, Continue, Aider and more
- Download and install the latest Graftcode Gateway
- (In the future) Install plugins and additional tools

## Quick Usage

### On Linux / macOS

```bash
curl -fsSL https://grft.dev/get | sh
```

### On Windows (PowerShell)

```bash
iwr https://grft.dev/get | iex
```

## Available Scripts

Script              | Purpose
--------------------|---------
get.sh              | Main installer for Unix-like systems (Linux, macOS)
get.ps1             | Main installer for Windows (PowerShell)

Both scripts offer an interactive menu allowing you to choose what to install:
- Rules for AI Agents (MCP rules for best AI coding experience)
- Graftcode Gateway (the runtime host)

## How to use

1. Run the installer in your project root directory
2. Choose option 1 (Rules) or 2 (Gateway)
3. Follow the on-screen instructions

The rules will be placed in the correct locations for your IDE/agent (.cursor/rules, .claude/rules, .github/, etc.).

---

## Future Plans

This CLI will be extended with:
- Plugin installation
- Project initialization for AI (graftcode ai init)
- Update commands
- Diagnostics

---

Made with ❤️ for developers and AI agents
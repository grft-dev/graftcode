# grft:rules=copilot
$GrftDeepLinkRulesIde = 'copilot'
iex ((Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/grft-dev/graftcode/refs/heads/main/cli/rules/invoke.ps1' -UseBasicParsing).Content)
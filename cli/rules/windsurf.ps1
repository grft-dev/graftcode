# grft:rules=windsurf
$GrftDeepLinkRulesIde = 'windsurf'
iex ((Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/grft-dev/graftcode/refs/heads/main/cli/rules/invoke.ps1' -UseBasicParsing).Content)
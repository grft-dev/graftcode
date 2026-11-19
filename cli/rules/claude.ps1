# grft:rules=claude
$GrftDeepLinkRulesIde = 'claude'
iex ((Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/grft-dev/graftcode/refs/heads/main/cli/rules/invoke.ps1' -UseBasicParsing).Content)
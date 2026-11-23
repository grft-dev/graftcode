$GrftDeepLinkRulesIde = 'cline'
iex ((Invoke-WebRequest -UseBasicParsing -Uri 'https://raw.githubusercontent.com/grft-dev/graftcode/refs/heads/develop/cli/rules/invoke.ps1').Content)

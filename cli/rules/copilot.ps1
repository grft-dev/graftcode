$GrftDeepLinkRulesIde = 'copilot'
iex ((Invoke-WebRequest -UseBasicParsing -Uri 'https://raw.githubusercontent.com/grft-dev/graftcode/refs/heads/main/cli/rules/invoke.ps1').Content)

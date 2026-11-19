$GrftDeepLinkRulesIde = 'copilot'
$__grftCfg = (Invoke-WebRequest -UseBasicParsing -Uri 'https://raw.githubusercontent.com/grft-dev/graftcode/refs/heads/feature/5272-grft-cli-installer-dx/cli/grft-raw-locator.ps1').Content.Trim()
$__grftInvoke = $__grftCfg -replace 'grft-raw-config\.ps1$','rules/invoke.ps1'
iex ((Invoke-WebRequest -UseBasicParsing -Uri $__grftInvoke).Content)

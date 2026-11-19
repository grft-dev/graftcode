# grft:get=rules/aider (raw path mirrors grft.dev/get/rules/aider)
$GrftDeepLinkRulesIde = 'aider'
$GrftCliRawBase = 'https://raw.githubusercontent.com/grft-dev/graftcode/refs/heads/feature/5272-grft-cli-installer-dx/cli'
iex ((Invoke-WebRequest -Uri "$GrftCliRawBase/rules/invoke.ps1" -UseBasicParsing).Content)

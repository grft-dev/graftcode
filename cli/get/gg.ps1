# grft:get=gg (raw path mirrors grft.dev/get/gg)
$GrftCliRawBase = 'https://raw.githubusercontent.com/grft-dev/graftcode/refs/heads/feature/5272-grft-cli-installer-dx/cli'
iex ((Invoke-WebRequest -Uri "$GrftCliRawBase/gg.ps1" -UseBasicParsing).Content)

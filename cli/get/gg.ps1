# grft:get=gg (raw path mirrors grft.dev/get/gg)
if (-not $GrftCliRawBase) { $GrftCliRawBase = 'https://raw.githubusercontent.com/grft-dev/graftcode/refs/heads/feature/5272-grft-cli-installer-dx/cli' }
$ggBody = (Invoke-WebRequest -Uri "$GrftCliRawBase/gg.ps1" -UseBasicParsing).Content
if ($ggBody -isnot [string]) {
    if ($ggBody -is [byte[]]) {
        $ggBody = [System.Text.Encoding]::UTF8.GetString($ggBody)
    }
    else {
        $ggBody = [string]$ggBody
    }
}
Invoke-Expression $ggBody
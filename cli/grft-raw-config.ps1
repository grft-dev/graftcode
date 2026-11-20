# Single source for raw GitHub URLs — change $GrftCliGitRef only, then sync-cli-raw.ps1
$script:GrftCliGitRef = 'feature/5272-grft-cli-installer-dx'
$script:GrftCliRepoRawRoot = "https://raw.githubusercontent.com/grft-dev/graftcode/refs/heads/$($script:GrftCliGitRef)"
$script:GrftCliRawBase = "$($script:GrftCliRepoRawRoot)/cli"
$script:GrftRulesRawBase = "$($script:GrftCliRepoRawRoot)/rules"
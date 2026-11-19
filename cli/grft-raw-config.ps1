# Single source for raw GitHub URLs — change $GrftCliGitRef only, then sync-plugins-manifest.ps1
$GrftCliGitRef = 'feature/5272-grft-cli-installer-dx'
$GrftCliRepoRawRoot = "https://raw.githubusercontent.com/grft-dev/graftcode/refs/heads/$GrftCliGitRef"
$GrftCliRawBase = "$GrftCliRepoRawRoot/cli"
$GrftRulesRawBase = "$GrftCliRepoRawRoot/rules"
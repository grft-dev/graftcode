# GRFT_VERSION=0.1.2
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

$GrftVersion = '0.1.2'
$grftLib = if ($PSScriptRoot) { Join-Path $PSScriptRoot 'lib\grft-cli-raw.ps1' } else { $null }
if ($grftLib -and (Test-Path -LiteralPath $grftLib)) {
    . $grftLib
}
else {
    if (-not $GrftCliRawBase -and $env:GRFT_CLI_RAW_BASE) {
        $GrftCliRawBase = $env:GRFT_CLI_RAW_BASE
    }
    if (-not $GrftCliRawBase) {
        throw 'Set $GrftCliRawBase or GRFT_CLI_RAW_BASE (rules/plugin stub or grft-raw-config) before pipe | iex, or run from checkout.'
    }
    $tmp = Join-Path $env:TEMP 'grft-cli-raw.ps1'
    Invoke-WebRequest -Uri "$($GrftCliRawBase.TrimEnd('/'))/lib/grft-cli-raw.ps1" -OutFile $tmp -UseBasicParsing
    . $tmp
}
Initialize-GrftCliRawContext
$RulesRawBase = $GrftRulesRawBase
$GrftHome = if ($env:GRFT_HOME) { $env:GRFT_HOME } else { Join-Path $env:USERPROFILE '.grft' }
$RuleLangs = @('dotnet', 'java', 'kotlin', 'php', 'python', 'ruby', 'typescript-node-nextjs')

$EnsureLayoutPath = if ($PSScriptRoot) { Join-Path $PSScriptRoot 'ensure-ps-cli-layout.ps1' } else { $null }
if ($EnsureLayoutPath -and (Test-Path -LiteralPath $EnsureLayoutPath)) {
    . $EnsureLayoutPath
}
else {
    $EnsureLayoutTmp = Join-Path $env:TEMP 'grft-ensure-ps-cli-layout.ps1'
    Invoke-WebRequest -Uri "$GrftRawBase/ensure-ps-cli-layout.ps1" -OutFile $EnsureLayoutTmp -UseBasicParsing
    . $EnsureLayoutTmp
}
$GraftCliDir = Initialize-GraftPowerShellCliLayout -GrftRawBase $GrftRawBase -GrftHome $GrftHome

$GraftGatewayUiPath = Join-Path (Join-Path $GraftCliDir 'lib') 'ui.ps1'
$GraftGatewayInstallerPath = Join-Path (Join-Path $GraftCliDir 'lib') 'gateway-installer.ps1'
. $GraftGatewayUiPath
. $GraftGatewayInstallerPath
. (Join-Path (Join-Path $GraftCliDir 'lib') 'plugin-manifest.ps1')
. (Join-Path (Join-Path $GraftCliDir 'lib') 'plugin-installer.ps1')
$script:GraftGatewayInstallerLibsLoaded = $true

function Test-GrftInteractiveConsole {
    -not [Console]::IsInputRedirected -and -not [Console]::IsOutputRedirected
}

function Exit-GrftNonInteractive {
    Write-Host 'No interactive console — use non-interactive commands:'
    Show-GrftHelp
    exit 2
}

function Show-GraftcodeIntro {
    if (Test-GrftInteractiveConsole) {
        Clear-Host
    }

    Write-UiBrandLogo (Get-UiGatewayLogoText)
    Write-Host ''

    Write-Host "Graftcode helps you generate AI code that integrates through Graftcode." -ForegroundColor White
    Write-Host "It can reduce boilerplate, simplify PRs, and save up to 80% of tokens." -ForegroundColor White
    Write-Host ""
    Write-Host "This installer can:" -ForegroundColor Yellow
    Write-Host "  1. Download Graftcode Rules file for your IDE"
    Write-Host "     - so AI can generate code that integrates everything through Graftcode"
    Write-Host "  2. Download Graftcode Gateway"
    Write-Host "     - gateway for your processor"
    Write-Host "  3. Download Graftcode Plugins"
    try {
        $PluginNames = Get-GraftPluginHelpNames
    }
    catch {
        $PluginNames = $null
    }
    if ($PluginNames) {
        Write-Host "     - messaging plugins for the gateway ($PluginNames)"
    }
    else {
        Write-Host "     - messaging plugins for the gateway"
    }
    if (Test-GrftHomePresent) {
        Write-Host "  4. Uninstall Graftcode CLI"
        Write-Host "     - remove ~/.grft and PATH entry"
    }
    Write-Host ""
}

function Read-MenuChoice {
    param(
        [string]$Prompt,
        [string[]]$AllowedChoices
    )

    while ($true) {
        $Choice = Read-Host $Prompt
        $Choice = $Choice.Trim()

        if ($AllowedChoices -contains $Choice) {
            return $Choice
        }

        Write-Host "Invalid choice. Available options: $($AllowedChoices -join ', ')" -ForegroundColor Red
    }
}

function Download-FileWithSpinner {
    param(
        [string]$Url,
        [string]$OutputPath,
        [string]$Label
    )

    Write-Host "Downloading $Label..."

    $Job = Start-Job {
        param($Url, $OutputPath)
        $ProgressPreference = 'SilentlyContinue'
        Invoke-WebRequest $Url -OutFile $OutputPath
    } -ArgumentList $Url, $OutputPath

    $Spinner = '|', '/', '-', '\'
    $Index = 0

    while ($Job.State -eq 'Running') {
        Write-Host -NoNewline "`rDownloading $Label $($Spinner[$Index++ % $Spinner.Count])"
        Start-Sleep -Milliseconds 120
    }

    Receive-Job $Job | Out-Null
    Remove-Job $Job

    Write-Host "`rDownloaded $Label " -ForegroundColor Green
}

function Download-GraftcodeRuleSet {
    param(
        [string]$RemoteDir,
        [string]$LocalDir,
        [string]$Extension,
        [switch]$IncludeRouter
    )

    if (-not (Test-Path $LocalDir)) {
        New-Item -ItemType Directory -Path $LocalDir -Force | Out-Null
    }

    $Names = @()
    if ($IncludeRouter) {
        $Names += 'router'
    }
    $Names += $RuleLangs

    foreach ($Name in $Names) {
        $FileName = "graftcode-$Name.$Extension"
        $Url = "$RemoteDir/$FileName"
        $OutputPath = Join-Path $LocalDir $FileName
        Download-FileWithSpinner -Url $Url -OutputPath $OutputPath -Label $FileName
    }
}

function Install-GraftcodeRulesForIde {
    param([string]$Ide)

    switch ($Ide.ToLowerInvariant()) {
        { $_ -in @('cursor', '1') } {
            $RulesDir = Join-Path $PWD ".cursor\rules"
            Download-GraftcodeRuleSet -RemoteDir "$RulesRawBase/Cursor/.cursor/rules" -LocalDir $RulesDir -Extension "mdc" -IncludeRouter
            Write-Host ""
            Write-Host "Installed Graftcode Cursor rules in:" -ForegroundColor Green
            Write-Host $RulesDir
        }
        { $_ -in @('claude', 'claude-code', '2') } {
            Download-FileWithSpinner -Url "$RulesRawBase/Claude/CLAUDE.md" -OutputPath (Join-Path $PWD "CLAUDE.md") -Label "CLAUDE.md"
            $RulesDir = Join-Path $PWD ".claude\rules"
            Download-GraftcodeRuleSet -RemoteDir "$RulesRawBase/Claude/.claude/rules" -LocalDir $RulesDir -Extension "md"
            Write-Host ""
            Write-Host "Installed Graftcode Claude Code rules in:" -ForegroundColor Green
            Write-Host (Join-Path $PWD "CLAUDE.md")
            Write-Host $RulesDir
        }
        { $_ -in @('copilot', 'github-copilot', 'github', '3') } {
            $GithubDir = Join-Path $PWD ".github"
            if (-not (Test-Path $GithubDir)) {
                New-Item -ItemType Directory -Path $GithubDir -Force | Out-Null
            }
            Download-FileWithSpinner -Url "$RulesRawBase/Copilot/.github/copilot-instructions.md" -OutputPath (Join-Path $GithubDir "copilot-instructions.md") -Label "copilot-instructions.md"
            $RulesDir = Join-Path $GithubDir "instructions"
            Download-GraftcodeRuleSet -RemoteDir "$RulesRawBase/Copilot/.github/instructions" -LocalDir $RulesDir -Extension "instructions.md"
            Write-Host ""
            Write-Host "Installed Graftcode GitHub Copilot rules in:" -ForegroundColor Green
            Write-Host (Join-Path $GithubDir "copilot-instructions.md")
            Write-Host $RulesDir
        }
        { $_ -in @('cline', '4') } {
            $RulesDir = Join-Path $PWD ".clinerules"
            Download-GraftcodeRuleSet -RemoteDir "$RulesRawBase/Cline/.clinerules" -LocalDir $RulesDir -Extension "md" -IncludeRouter
            Write-Host ""
            Write-Host "Installed Graftcode Cline rules in:" -ForegroundColor Green
            Write-Host $RulesDir
        }
        { $_ -in @('windsurf', '5') } {
            $RulesDir = Join-Path $PWD ".windsurf\rules"
            Download-GraftcodeRuleSet -RemoteDir "$RulesRawBase/Windsurf/.windsurf/rules" -LocalDir $RulesDir -Extension "md" -IncludeRouter
            Write-Host ""
            Write-Host "Installed Graftcode Windsurf rules in:" -ForegroundColor Green
            Write-Host $RulesDir
        }
        { $_ -in @('continue', '6') } {
            $RulesDir = Join-Path $PWD ".continue\rules"
            Download-GraftcodeRuleSet -RemoteDir "$RulesRawBase/Continue/.continue/rules" -LocalDir $RulesDir -Extension "md" -IncludeRouter
            Write-Host ""
            Write-Host "Installed Graftcode Continue rules in:" -ForegroundColor Green
            Write-Host $RulesDir
        }
        { $_ -in @('aider', '7') } {
            Download-FileWithSpinner -Url "$RulesRawBase/Aider/CONVENTIONS.md" -OutputPath (Join-Path $PWD "CONVENTIONS.md") -Label "CONVENTIONS.md"
            Download-FileWithSpinner -Url "$RulesRawBase/Aider/.aider.conf.yml" -OutputPath (Join-Path $PWD ".aider.conf.yml") -Label ".aider.conf.yml"
            Write-Host ""
            Write-Host "Installed Graftcode Aider rules in:" -ForegroundColor Green
            Write-Host (Join-Path $PWD "CONVENTIONS.md")
            Write-Host (Join-Path $PWD ".aider.conf.yml")
        }
        default {
            Exit-UiUserError "Unknown IDE '$Ide'." @(
                'Use: cursor, claude, copilot, cline, windsurf, continue, aider'
            )
        }
    }
}

function Install-GraftcodeRules {
    param([string]$Ide = '')

    if ($Ide) {
        Install-GraftcodeRulesForIde -Ide $Ide
        return
    }

    if (-not (Test-GrftInteractiveConsole)) {
        Write-Host 'Specify an IDE, e.g.: grft get rules cursor'
        Exit-GrftNonInteractive
    }

    Write-Host ""
    Write-Host "Choose IDE:" -ForegroundColor Yellow
    Write-Host "  1. Cursor"
    Write-Host "  2. Claude Code"
    Write-Host "  3. GitHub Copilot"
    Write-Host "  4. Cline"
    Write-Host "  5. Windsurf"
    Write-Host "  6. Continue"
    Write-Host "  7. Aider"
    Write-Host ""

    $IdeChoice = Read-MenuChoice -Prompt "Enter choice [1-7]" -AllowedChoices @('1', '2', '3', '4', '5', '6', '7')
    Install-GraftcodeRulesForIde -Ide $IdeChoice
}

function Install-GraftcodeGateway {
    Install-GraftcodeGatewayToCwd
}

function Install-GraftcodePlugins {
    param([string]$Plugin = '')

    $Resolved = $null
    if ($Plugin) {
        $Resolved = Resolve-GraftPluginId -PluginQuery $Plugin
    }

    if (-not $Resolved) {
        if (-not $Plugin) {
            if (-not (Test-GrftInteractiveConsole)) {
                Write-Host 'Specify a plugin, e.g.: grft get plugin rabbitmq'
                Write-Host "Available: $(Get-GraftPluginHelpNames)"
                Exit-GrftNonInteractive
            }
            Write-Host ""
            Write-Host "Choose plugin:" -ForegroundColor Yellow
            Show-GraftPluginMenu
            Write-Host ""
            $Choices = Get-GraftPluginMenuChoices
            $Prompt = "Enter choice [$($Choices -join '/')]"
            $PluginChoice = Read-MenuChoice -Prompt $Prompt -AllowedChoices $Choices
            $Resolved = Resolve-GraftPluginId -PluginQuery $PluginChoice
        }
        else {
            $details = @(
                "Available plugins: $(Get-GraftPluginHelpNames)"
                'Example: grft get plugin rabbitmq'
            )
            $hint = Get-GraftPluginSuggestion -PluginQuery $Plugin
            if ($hint) {
                $details = @("Did you mean '$hint'?") + $details
            }
            Exit-UiUserError "Unknown plugin '$Plugin'." $details
        }
    }

    if (-not $Resolved) {
        Exit-UiUserError 'Could not resolve plugin choice.' @(
            "Available plugins: $(Get-GraftPluginHelpNames)"
        )
    }

    $Label = Get-GraftPluginLabel -PluginId $Resolved
    Install-GraftcodePlugin -PluginName $Resolved -PluginLabel $Label
}

function Test-GrftHomePresent {
    $Marker = Join-Path $GrftHome 'get.ps1'
    return (Test-Path -LiteralPath $Marker)
}

function Test-GrftInstalledCopy {
    if (-not $PSScriptRoot) {
        return $false
    }

    try {
        $ScriptHome = (Resolve-Path -LiteralPath $PSScriptRoot).Path.TrimEnd('\')
        $ExpectedHome = (Resolve-Path -LiteralPath $GrftHome -ErrorAction Stop).Path.TrimEnd('\')
        return ($ScriptHome -eq $ExpectedHome)
    }
    catch {
        return ($PSScriptRoot.TrimEnd('\') -eq $GrftHome.TrimEnd('\'))
    }
}

function Compare-GrftVersion {
    param(
        [string]$Left,
        [string]$Right
    )

    $LeftParts = @($Left.Trim() -split '\.' | ForEach-Object { [int]($_ -replace '[^0-9]', '0') })
    $RightParts = @($Right.Trim() -split '\.' | ForEach-Object { [int]($_ -replace '[^0-9]', '0') })
    $Len = [Math]::Max($LeftParts.Count, $RightParts.Count)

    for ($i = 0; $i -lt $Len; $i++) {
        $L = if ($i -lt $LeftParts.Count) { $LeftParts[$i] } else { 0 }
        $R = if ($i -lt $RightParts.Count) { $RightParts[$i] } else { 0 }
        if ($L -lt $R) { return -1 }
        if ($L -gt $R) { return 1 }
    }

    return 0
}

function Update-GrftIfNeeded {
    param([string[]]$ForwardArgs)

    if ($env:GRFT_SKIP_UPDATE -eq '1') {
        return
    }

    if (-not (Test-GrftInstalledCopy)) {
        return
    }

    try {
        $RemoteVersion = (Invoke-WebRequest -Uri "$GrftRawBase/VERSION" -UseBasicParsing).Content.Trim()
    }
    catch {
        return
    }

    if (-not $RemoteVersion) {
        return
    }

    if ((Compare-GrftVersion -Left $GrftVersion -Right $RemoteVersion) -ge 0) {
        return
    }

    Write-Host "Updating grft CLI $GrftVersion -> $RemoteVersion ..." -ForegroundColor Yellow

    $BinDir = Join-Path $GrftHome 'bin'
    New-Item -ItemType Directory -Path $GrftHome -Force | Out-Null
    New-Item -ItemType Directory -Path $BinDir -Force | Out-Null

    Download-FileWithSpinner -Url "$GrftRawBase/get.ps1" -OutputPath (Join-Path $GrftHome 'get.ps1') -Label 'get.ps1'
    Download-FileWithSpinner -Url "$GrftRawBase/VERSION" -OutputPath (Join-Path $GrftHome 'VERSION') -Label 'VERSION'
    Download-FileWithSpinner -Url "$GrftRawBase/ensure-ps-cli-layout.ps1" -OutputPath (Join-Path $GrftHome 'ensure-ps-cli-layout.ps1') -Label 'ensure-ps-cli-layout.ps1'
    try {
        Download-FileWithSpinner -Url "$GrftRawBase/bin/grft.cmd" -OutputPath (Join-Path $BinDir 'grft.cmd') -Label 'grft.cmd'
    }
    catch {}
    Download-FileWithSpinner -Url "$GrftRawBase/plugins.manifest.json" -OutputPath (Join-Path $GrftHome 'plugins.manifest.json') -Label 'plugins.manifest.json'
    $UpdateLibDir = Join-Path $GrftHome 'lib'
    New-Item -ItemType Directory -Path $UpdateLibDir -Force | Out-Null
    foreach ($libName in @('ui.ps1', 'gateway-installer.ps1', 'plugin-manifest.ps1')) {
        Download-FileWithSpinner -Url "$GrftRawBase/lib/$libName" -OutputPath (Join-Path $UpdateLibDir $libName) -Label "lib/$libName"
    }

    $env:GRFT_SKIP_UPDATE = '1'
    $ArgList = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', (Join-Path $GrftHome 'get.ps1')) + $ForwardArgs
    $Process = Start-Process -FilePath 'powershell.exe' -ArgumentList $ArgList -NoNewWindow -Wait -PassThru
    exit $Process.ExitCode
}

function Uninstall-GrftCli {
    $BinDir = Join-Path $GrftHome 'bin'
    $RemovedHome = $false
    $RemovedPath = $false

    $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    if ($userPath) {
        $pathEntries = @($userPath -split ';' | Where-Object { $_ -ne '' })
        $filtered = @($pathEntries | Where-Object {
            $_.TrimEnd('\') -ne $BinDir.TrimEnd('\')
        })

        if ($filtered.Count -ne $pathEntries.Count) {
            [Environment]::SetEnvironmentVariable('Path', ($filtered -join ';'), 'User')
            $RemovedPath = $true
            Write-Host "Removed $BinDir from User PATH." -ForegroundColor DarkGray
        }
    }

    if ($env:Path) {
        $sessionEntries = @($env:Path -split ';' | Where-Object { $_ -ne '' })
        $sessionFiltered = @($sessionEntries | Where-Object {
            $_.TrimEnd('\') -ne $BinDir.TrimEnd('\')
        })
        if ($sessionFiltered.Count -ne $sessionEntries.Count) {
            $env:Path = $sessionFiltered -join ';'
        }
    }

    if (Test-Path -LiteralPath $GrftHome) {
        Remove-Item -LiteralPath $GrftHome -Recurse -Force
        $RemovedHome = $true
        Write-Host "Removed $GrftHome" -ForegroundColor DarkGray
    }

    if (-not $RemovedHome -and -not $RemovedPath) {
        Write-Host "Graftcode CLI is not installed (no $GrftHome found)." -ForegroundColor Yellow
        return
    }

    Write-Host ""
    Write-Host "Uninstalled Graftcode CLI." -ForegroundColor Green
    Write-Host "Open a new terminal if grft is still resolved from a cached PATH." -ForegroundColor DarkGray
}

function Show-GrftHelp {
    Write-Host "grft - Graftcode CLI ($GrftVersion)"
    Write-Host ""
    Write-Host "Usage:"
    Write-Host '  grft                          Interactive installer'
    Write-Host '  grft get                      Interactive installer'
    Write-Host '  grft get gg                   Download Graftcode Gateway'
    Write-Host '  grft get rules <ide>          Install AI rules (cursor, claude, copilot, ...)'
    try {
        $PluginNames = Get-GraftPluginHelpNames
    }
    catch {
        $PluginNames = 'see plugins.manifest.json'
    }
    Write-Host "  grft get plugin <name>        Install plugin ($PluginNames)"
    Write-Host '  grft uninstall                Remove ~/.grft and PATH entry'
    Write-Host '  grft version                  Show CLI version'
    Write-Host ""
}

function Invoke-GrftInteractive {
    Show-GraftcodeIntro

    Write-Host "What do you want to do?" -ForegroundColor Yellow
    Write-Host "  1. Graftcode Rules file"
    Write-Host "  2. Graftcode Gateway"
    Write-Host "  3. Graftcode Plugins"

    $Allowed = @('1', '2', '3')
    if (Test-GrftHomePresent) {
        Write-Host "  4. Uninstall Graftcode CLI"
        $Allowed += '4'
    }

    Write-Host ""
    $Prompt = if ($Allowed.Count -eq 4) { "Enter choice [1/2/3/4]" } else { "Enter choice [1/2/3]" }
    $Choice = Read-MenuChoice -Prompt $Prompt -AllowedChoices $Allowed

    switch ($Choice) {
        '1' { Install-GraftcodeRules }
        '2' { Install-GraftcodeGateway }
        '3' { Install-GraftcodePlugins }
        '4' { Uninstall-GrftCli; return }
    }

    Write-Host ""
    Write-Host "Done." -ForegroundColor Green
}

function Invoke-GrftCommand {
    param([string[]]$CliArgs)

    if (-not $CliArgs -or $CliArgs.Count -eq 0) {
        if (Test-GrftInteractiveConsole) {
            Invoke-GrftInteractive
        }
        else {
            Exit-GrftNonInteractive
        }
        return
    }

    $Command = $CliArgs[0].ToLowerInvariant()

    if ($Command -in @('version', '--version', '-v')) {
        Write-Host "grft $GrftVersion"
        return
    }

    if ($Command -in @('help', '--help', '-h')) {
        Show-GrftHelp
        return
    }

    if ($Command -in @('uninstall', 'remove')) {
        Uninstall-GrftCli
        return
    }

    if ($Command -ne 'get') {
        Show-GrftHelp
        Exit-UiUserError "Unknown command '$($CliArgs[0])'." @(
            'Try: grft get ..., grft uninstall, grft version'
        )
    }

    if ($CliArgs.Count -eq 1) {
        if (Test-GrftInteractiveConsole) {
            Invoke-GrftInteractive
        }
        else {
            Exit-GrftNonInteractive
        }
        return
    }

    $Target = $CliArgs[1].ToLowerInvariant()

    switch ($Target) {
        { $_ -in @('gg', 'gateway') } {
            Install-GraftcodeGateway
        }
        { $_ -in @('rules', 'rule') } {
            if ($CliArgs.Count -ge 3) {
                Install-GraftcodeRules -Ide $CliArgs[2]
            }
            elseif (Test-GrftInteractiveConsole) {
                Install-GraftcodeRules
            }
            else {
                Write-Host 'Specify an IDE, e.g.: grft get rules cursor'
                Exit-GrftNonInteractive
            }
        }
        { $_ -in @('plugin', 'plugins') } {
            if ($CliArgs.Count -ge 3) {
                Install-GraftcodePlugins -Plugin $CliArgs[2]
            }
            elseif (Test-GrftInteractiveConsole) {
                Install-GraftcodePlugins
            }
            else {
                Write-Host 'Specify a plugin, e.g.: grft get plugin rabbitmq'
                Exit-GrftNonInteractive
            }
        }
        default {
            Show-GrftHelp
            Exit-UiUserError "Unknown get target '$($CliArgs[1])'." @(
                'Use: grft get gg | rules <ide> | plugin <name>'
            )
        }
    }

    Write-Host ""
    Write-Host "Done." -ForegroundColor Green
}

$ForwardArgs = @($args)
try {
    Update-GrftIfNeeded -ForwardArgs $ForwardArgs
    Invoke-GrftCommand -CliArgs $ForwardArgs
}
catch {
    Write-Host ''
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}

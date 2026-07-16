# GRFT_VERSION=0.1.0
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

$GrftVersion = '0.1.0'
$GrftRawBase = 'https://raw.githubusercontent.com/grft-dev/graftcode/refs/heads/main/cli'
$GrftHome = if ($env:GRFT_HOME) { $env:GRFT_HOME } else { Join-Path $env:USERPROFILE '.grft' }
$RulesRawBase = "https://raw.githubusercontent.com/grft-dev/graftcode/refs/heads/main/rules"
$RuleLangs = @('dotnet', 'java', 'kotlin', 'php', 'python', 'ruby', 'typescript-node-nextjs')

function Show-GraftcodeIntro {
    Clear-Host

    Write-Host @"
   _____            __ _                 _      
  / ____|          / _| |               | |     
 | |  __ _ __ __ _| |_| |_ ___ ___   __| | ___ 
 | | |_ | '__/ _` |  _| __/ __/ _ \ / _` |/ _ \
 | |__| | | | (_| | | | || (_| (_) | (_| |  __/
  \_____|_|  \__,_|_|  \__\___\___/ \__,_|\___|

"@ -ForegroundColor Cyan

    Write-Host "Graftcode helps you generate AI code that integrates through Graftcode." -ForegroundColor White
    Write-Host "It can reduce boilerplate, simplify PRs, and save up to 80% of tokens." -ForegroundColor White
    Write-Host ""
    Write-Host "This installer can:" -ForegroundColor Yellow
    Write-Host "  1. Download Graftcode Rules file for your IDE"
    Write-Host "     - so AI can generate code that integrates everything through Graftcode"
    Write-Host "  2. Download Graftcode Gateway"
    Write-Host "     - gateway for your processor"
    Write-Host "  3. Download Graftcode Plugins"
    Write-Host "     - RabbitMQ and Azure Service Bus plugins for the gateway"
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
            throw "Unknown IDE '$Ide'. Use: cursor, claude, copilot, cline, windsurf, continue, aider"
        }
    }
}

function Install-GraftcodeRules {
    param([string]$Ide = '')

    if ($Ide) {
        Install-GraftcodeRulesForIde -Ide $Ide
        return
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

function ConvertTo-WindowsArchSuffix {
    param([string]$Value)

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return $null
    }

    $Normalized = $Value.Trim().ToLowerInvariant()
    if ($Normalized -match 'arm') {
        return 'arm64'
    }

    switch ($Normalized) {
        { $_ -in 'arm64', 'aarch64' } { return 'arm64' }
        { $_ -in 'amd64', 'x64', 'x86_64' } { return 'amd64' }
        { $_ -in 'x86', 'i386', 'i686', 'win32' } { return 'x86' }
        default { return $null }
    }
}

function Get-NativeWindowsArchSuffix {
    $NativeSignals = @()

    if ($env:PROCESSOR_ARCHITEW6432) {
        $NativeSignals += $env:PROCESSOR_ARCHITEW6432
    }

    try {
        $NativeSignals += (Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop).OSArchitecture
    }
    catch {}

    try {
        $NativeSignals += [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture.ToString()
    }
    catch {
        try {
            $NativeSignals += [System.Runtime.InteropServices.RuntimeInformation,mscorlib]::OSArchitecture.ToString()
        }
        catch {}
    }

    $Resolved = @()
    foreach ($Signal in $NativeSignals) {
        $Suffix = ConvertTo-WindowsArchSuffix $Signal
        if ($Suffix) {
            $Resolved += $Suffix
        }
    }

    if ($Resolved -contains 'arm64') { return 'arm64' }
    if ($Resolved -contains 'amd64') { return 'amd64' }
    if ($Resolved -contains 'x86') { return 'x86' }

    $ProcessArch = ConvertTo-WindowsArchSuffix $env:PROCESSOR_ARCHITECTURE
    if ($ProcessArch) {
        return $ProcessArch
    }

    throw "Unsupported Windows architecture. PROCESSOR_ARCHITECTURE=$($env:PROCESSOR_ARCHITECTURE); PROCESSOR_ARCHITEW6432=$($env:PROCESSOR_ARCHITEW6432)"
}

function Install-GraftcodeGateway {
    $Repo = 'grft-dev/graftcode-gateway'
    $ExeName = 'gg.exe'
    $OutputPath = Join-Path $PWD $ExeName

    $ArchSuffix = Get-NativeWindowsArchSuffix
    $AssetName = "gg_windows_${ArchSuffix}.zip"

    Write-Host ""
    Write-Host "Detected architecture: $ArchSuffix"
    Write-Host "Fetching latest release from $Repo..."

    $Release = Invoke-RestMethod "https://api.github.com/repos/$Repo/releases/latest"

    $Asset = $Release.assets |
        Where-Object { $_.name -ieq $AssetName } |
        Select-Object -First 1

    if (-not $Asset) {
        $Available = ($Release.assets |
            Where-Object { $_.name -match '(?i)^gg_windows_' } |
            ForEach-Object { $_.name }) -join "`n - "
        throw "Could not find Windows ZIP for architecture '$ArchSuffix' ($AssetName). Available assets:`n - $Available"
    }

    $ZipPath = Join-Path $env:TEMP $Asset.name
    Download-FileWithSpinner -Url $Asset.browser_download_url -OutputPath $ZipPath -Label $Asset.name

    Add-Type -AssemblyName System.IO.Compression.FileSystem

    $Zip = [IO.Compression.ZipFile]::OpenRead($ZipPath)

    try {
        $Entry = $Zip.Entries |
            Where-Object { $_.Name -ieq $ExeName } |
            Select-Object -First 1

        if (-not $Entry) {
            throw "Could not find $ExeName inside $($Asset.name)"
        }

        if (Test-Path $OutputPath) {
            Remove-Item $OutputPath -Force
        }

        [IO.Compression.ZipFileExtensions]::ExtractToFile($Entry, $OutputPath, $true)
    }
    finally {
        $Zip.Dispose()

        if (Test-Path $ZipPath) {
            Remove-Item $ZipPath -Force
        }
    }

    Write-Host ""
    Write-Host "Installed Graftcode Gateway:" -ForegroundColor Green
    Write-Host $OutputPath
}

function Get-PluginArchSuffix {
    $ArchSuffix = Get-NativeWindowsArchSuffix

    switch ($ArchSuffix) {
        'arm64' { return 'arm64' }
        'amd64' { return 'x86_64' }
        default { throw "Unsupported plugin architecture: $ArchSuffix" }
    }
}

function Install-GraftcodePluginFiles {
    param(
        [string]$ExtractDir,
        [string]$TargetDir,
        [string]$PluginLabel,
        [string[]]$Patterns
    )

    if (-not (Test-Path $TargetDir)) {
        New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null
    }

    $Installed = @()
    $ReleaseDir = Join-Path $ExtractDir 'Release'

    if (Test-Path $ReleaseDir) {
        Get-ChildItem -Path $ReleaseDir -File -Filter '*.dll' | ForEach-Object {
            Copy-Item -Path $_.FullName -Destination (Join-Path $TargetDir $_.Name) -Force
            $Installed += $_.Name
        }
    }

    foreach ($Pattern in $Patterns) {
        $Match = Get-ChildItem -Path $ExtractDir -Recurse -File -Filter $Pattern -ErrorAction SilentlyContinue |
            Select-Object -First 1

        if ($Match) {
            $Destination = Join-Path $TargetDir $Match.Name
            if (-not ($Installed -contains $Match.Name)) {
                Copy-Item -Path $Match.FullName -Destination $Destination -Force
                $Installed += $Match.Name
            }
        }
    }

    if ($Installed.Count -eq 0) {
        $Available = (Get-ChildItem -Path $ExtractDir -Recurse -File | ForEach-Object { $_.FullName }) -join "`n - "
        throw "Could not find $PluginLabel plugin binaries inside archive. Extracted files:`n - $Available"
    }

    return $Installed
}

function Install-GraftcodePlugin {
    param(
        [string]$PluginName,
        [string]$PluginLabel,
        [string[]]$Patterns
    )

    $Repo = 'grft-dev/graftcode-plugins'
    $InstallDir = $PWD.Path
    $OsName = 'windows'
    $ArchName = Get-PluginArchSuffix
    $AssetName = "$PluginName-$OsName-$ArchName.tar.gz"

    Write-Host ""
    Write-Host "Detected OS: $OsName"
    Write-Host "Detected architecture: $ArchName"
    Write-Host "Fetching latest release from $Repo..."

    $Release = Invoke-RestMethod "https://api.github.com/repos/$Repo/releases/latest"

    $Asset = $Release.assets |
        Where-Object { $_.name -ieq $AssetName } |
        Select-Object -First 1

    if (-not $Asset) {
        $Available = ($Release.assets |
            Where-Object { $_.name -match "(?i)^$PluginName-" } |
            ForEach-Object { $_.name }) -join "`n - "
        throw "Could not find $PluginLabel build: $AssetName. Available ${PluginName} assets:`n - $Available"
    }

    $TempDir = Join-Path $env:TEMP ("graftcode-$PluginName-" + [Guid]::NewGuid().ToString())
    New-Item -ItemType Directory -Path $TempDir -Force | Out-Null

    try {
        $ArchivePath = Join-Path $TempDir $Asset.name
        Download-FileWithSpinner -Url $Asset.browser_download_url -OutputPath $ArchivePath -Label $Asset.name

        $ExtractDir = Join-Path $TempDir 'extract'
        New-Item -ItemType Directory -Path $ExtractDir -Force | Out-Null
        tar -xzf $ArchivePath -C $ExtractDir

        Write-Host ""
        Write-Host "Installing plugin files to:" -ForegroundColor Yellow
        Write-Host $InstallDir

        $Installed = Install-GraftcodePluginFiles `
            -ExtractDir $ExtractDir `
            -TargetDir $InstallDir `
            -PluginLabel $PluginLabel `
            -Patterns $Patterns

        Write-Host ""
        foreach ($FileName in $Installed) {
            Write-Host " - $FileName" -ForegroundColor Green
        }

        Write-Host ""
        Write-Host "Installed Graftcode $PluginLabel plugin in:" -ForegroundColor Green
        Write-Host $InstallDir
    }
    finally {
        if (Test-Path $TempDir) {
            Remove-Item $TempDir -Recurse -Force
        }
    }
}

function Install-GraftcodePlugins {
    param([string]$Plugin = '')

    $Resolved = $Plugin.ToLowerInvariant()

    if (-not $Resolved) {
        Write-Host ""
        Write-Host "Choose plugin:" -ForegroundColor Yellow
        Write-Host "  1. RabbitMQ"
        Write-Host "  2. Azure Service Bus"
        Write-Host ""
        $PluginChoice = Read-MenuChoice -Prompt "Enter choice [1/2]" -AllowedChoices @('1', '2')
        $Resolved = $PluginChoice
    }

    switch ($Resolved) {
        { $_ -in @('rabbitmq', 'rabbit', '1') } {
            Install-GraftcodePlugin `
                -PluginName 'rabbitmq' `
                -PluginLabel 'RabbitMQ' `
                -Patterns @('libRabbitmqPlugin.so', 'libRabbitmqPlugin.dylib', 'RabbitmqPlugin.dll')
        }
        { $_ -in @('servicebus', 'service-bus', 'azure-servicebus', 'asb', '2') } {
            Install-GraftcodePlugin `
                -PluginName 'servicebus' `
                -PluginLabel 'Service Bus' `
                -Patterns @('libServiceBusPlugin.so', 'libServiceBusPlugin.dylib', 'ServiceBusPlugin.dll')
        }
        default {
            throw "Unknown plugin '$Plugin'. Use: rabbitmq, servicebus"
        }
    }
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
    try {
        Download-FileWithSpinner -Url "$GrftRawBase/bin/grft.cmd" -OutputPath (Join-Path $BinDir 'grft.cmd') -Label 'grft.cmd'
    }
    catch {}

    $env:GRFT_SKIP_UPDATE = '1'
    $ArgList = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', (Join-Path $GrftHome 'get.ps1')) + $ForwardArgs
    $Process = Start-Process -FilePath 'powershell.exe' -ArgumentList $ArgList -NoNewWindow -Wait -PassThru
    exit $Process.ExitCode
}

function Show-GrftHelp {
    Write-Host "grft - Graftcode CLI ($GrftVersion)"
    Write-Host ""
    Write-Host "Usage:"
    Write-Host '  grft                          Interactive installer'
    Write-Host '  grft get                      Interactive installer'
    Write-Host '  grft get gg                   Download Graftcode Gateway'
    Write-Host '  grft get rules <ide>          Install AI rules (cursor, claude, copilot, ...)'
    Write-Host '  grft get plugin <name>        Install plugin (rabbitmq, servicebus)'
    Write-Host '  grft version                  Show CLI version'
    Write-Host ""
}

function Invoke-GrftInteractive {
    Show-GraftcodeIntro

    Write-Host "What do you want to install?" -ForegroundColor Yellow
    Write-Host "  1. Graftcode Rules file"
    Write-Host "  2. Graftcode Gateway"
    Write-Host "  3. Graftcode Plugins"
    Write-Host ""

    $Choice = Read-MenuChoice -Prompt "Enter choice [1/2/3]" -AllowedChoices @('1', '2', '3')

    switch ($Choice) {
        '1' { Install-GraftcodeRules }
        '2' { Install-GraftcodeGateway }
        '3' { Install-GraftcodePlugins }
    }

    Write-Host ""
    Write-Host "Done." -ForegroundColor Green
}

function Invoke-GrftCommand {
    param([string[]]$CliArgs)

    if (-not $CliArgs -or $CliArgs.Count -eq 0) {
        Invoke-GrftInteractive
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

    if ($Command -ne 'get') {
        Show-GrftHelp
        throw "Unknown command '$($CliArgs[0])'. Commands start with: grft get ..."
    }

    if ($CliArgs.Count -eq 1) {
        Invoke-GrftInteractive
        return
    }

    $Target = $CliArgs[1].ToLowerInvariant()

    switch ($Target) {
        { $_ -in @('gg', 'gateway') } {
            Install-GraftcodeGateway
        }
        { $_ -in @('rules', 'rule') } {
            if ($CliArgs.Count -lt 3) {
                Install-GraftcodeRules
            }
            else {
                Install-GraftcodeRules -Ide $CliArgs[2]
            }
        }
        { $_ -in @('plugin', 'plugins') } {
            if ($CliArgs.Count -lt 3) {
                Install-GraftcodePlugins
            }
            else {
                Install-GraftcodePlugins -Plugin $CliArgs[2]
            }
        }
        default {
            Show-GrftHelp
            throw "Unknown get target '$($CliArgs[1])'. Use: gg, rules, plugin"
        }
    }

    Write-Host ""
    Write-Host "Done." -ForegroundColor Green
}

$ForwardArgs = @($args)
Update-GrftIfNeeded -ForwardArgs $ForwardArgs
Invoke-GrftCommand -CliArgs $ForwardArgs

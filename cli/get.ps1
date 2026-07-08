$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

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

$RulesRawBase = "https://raw.githubusercontent.com/grft-dev/graftcode/refs/heads/main/rules"
$RuleLangs = @('dotnet', 'java', 'kotlin', 'php', 'python', 'ruby', 'typescript-node-nextjs')

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

function Install-GraftcodeRules {
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

    switch ($IdeChoice) {
        '1' {
            $RulesDir = Join-Path $PWD ".cursor\rules"
            Download-GraftcodeRuleSet -RemoteDir "$RulesRawBase/Cursor/.cursor/rules" -LocalDir $RulesDir -Extension "mdc" -IncludeRouter

            Write-Host ""
            Write-Host "Installed Graftcode Cursor rules in:" -ForegroundColor Green
            Write-Host $RulesDir
        }
        '2' {
            Download-FileWithSpinner -Url "$RulesRawBase/Claude/CLAUDE.md" -OutputPath (Join-Path $PWD "CLAUDE.md") -Label "CLAUDE.md"
            $RulesDir = Join-Path $PWD ".claude\rules"
            Download-GraftcodeRuleSet -RemoteDir "$RulesRawBase/Claude/.claude/rules" -LocalDir $RulesDir -Extension "md"

            Write-Host ""
            Write-Host "Installed Graftcode Claude Code rules in:" -ForegroundColor Green
            Write-Host (Join-Path $PWD "CLAUDE.md")
            Write-Host $RulesDir
        }
        '3' {
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
        '4' {
            $RulesDir = Join-Path $PWD ".clinerules"
            Download-GraftcodeRuleSet -RemoteDir "$RulesRawBase/Cline/.clinerules" -LocalDir $RulesDir -Extension "md" -IncludeRouter

            Write-Host ""
            Write-Host "Installed Graftcode Cline rules in:" -ForegroundColor Green
            Write-Host $RulesDir
        }
        '5' {
            $RulesDir = Join-Path $PWD ".windsurf\rules"
            Download-GraftcodeRuleSet -RemoteDir "$RulesRawBase/Windsurf/.windsurf/rules" -LocalDir $RulesDir -Extension "md" -IncludeRouter

            Write-Host ""
            Write-Host "Installed Graftcode Windsurf rules in:" -ForegroundColor Green
            Write-Host $RulesDir
        }
        '6' {
            $RulesDir = Join-Path $PWD ".continue\rules"
            Download-GraftcodeRuleSet -RemoteDir "$RulesRawBase/Continue/.continue/rules" -LocalDir $RulesDir -Extension "md" -IncludeRouter

            Write-Host ""
            Write-Host "Installed Graftcode Continue rules in:" -ForegroundColor Green
            Write-Host $RulesDir
        }
        '7' {
            Download-FileWithSpinner -Url "$RulesRawBase/Aider/CONVENTIONS.md" -OutputPath (Join-Path $PWD "CONVENTIONS.md") -Label "CONVENTIONS.md"
            Download-FileWithSpinner -Url "$RulesRawBase/Aider/.aider.conf.yml" -OutputPath (Join-Path $PWD ".aider.conf.yml") -Label ".aider.conf.yml"

            Write-Host ""
            Write-Host "Installed Graftcode Aider rules in:" -ForegroundColor Green
            Write-Host (Join-Path $PWD "CONVENTIONS.md")
            Write-Host (Join-Path $PWD ".aider.conf.yml")
        }
    }
}

function Get-NativeWindowsArchSuffix {
  # On Windows ARM, x64-emulated PowerShell reports PROCESSOR_ARCHITECTURE=AMD64.
  # PROCESSOR_ARCHITEW6432 reveals the native OS arch (ARM64) in that case.
  $Candidates = @(
    $env:PROCESSOR_ARCHITEW6432
    $env:PROCESSOR_ARCHITECTURE
  )

  try {
    $Candidates += [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture.ToString()
  }
  catch {
    try {
      $Candidates += [System.Runtime.InteropServices.RuntimeInformation,mscorlib]::OSArchitecture.ToString()
    }
    catch {}
  }

  foreach ($Arch in $Candidates) {
    if ([string]::IsNullOrWhiteSpace($Arch)) {
      continue
    }

    switch ($Arch.Trim().ToLowerInvariant()) {
      { $_ -in 'arm64', 'aarch64' } { return 'arm64' }
      { $_ -in 'amd64', 'x64', 'x86_64' } { return 'amd64' }
      { $_ -in 'x86', 'i386', 'i686' } { return 'x86' }
    }
  }

  throw "Unsupported Windows architecture. PROCESSOR_ARCHITECTURE=$($env:PROCESSOR_ARCHITECTURE); PROCESSOR_ARCHITEW6432=$($env:PROCESSOR_ARCHITEW6432)"
}

function Install-GraftcodeGateway {
    $Repo = 'grft-dev/graftcode-gateway'
    $ExeName = 'gg.exe'
    $OutputPath = Join-Path $PWD $ExeName

    $ArchSuffix = Get-NativeWindowsArchSuffix

    $ArchPattern = switch ($ArchSuffix) {
        'arm64' { 'arm64|aarch64' }
        'amd64' { 'x64|amd64' }
        'x86'   { 'x86|win32|i386' }
        default { throw "Unsupported architecture: $ArchSuffix" }
    }

    Write-Host ""
    Write-Host "Detected architecture: $ArchSuffix"
    Write-Host "Fetching latest release from $Repo..."

    $Release = Invoke-RestMethod "https://api.github.com/repos/$Repo/releases/latest"

    $Asset = $Release.assets |
        Where-Object {
            $_.name -match '(?i)\.zip$' -and
            $_.name -match '(?i)(win|windows)' -and
            $_.name -match "(?i)($ArchPattern)" -and
            $_.name -notmatch '(?i)sha256|checksum|checksums|signature|sig'
        } |
        Select-Object -First 1

    if (-not $Asset) {
        $Available = ($Release.assets | ForEach-Object { $_.name }) -join "`n - "
        throw "Could not find Windows ZIP for architecture '$ArchSuffix'. Available assets:`n - $Available"
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

Show-GraftcodeIntro

Write-Host "What do you want to install?" -ForegroundColor Yellow
Write-Host "  1. Graftcode Rules file"
Write-Host "  2. Graftcode Gateway"
Write-Host ""

$Choice = Read-MenuChoice -Prompt "Enter choice [1/2]" -AllowedChoices @('1', '2')

switch ($Choice) {
    '1' { Install-GraftcodeRules }
    '2' { Install-GraftcodeGateway }
}

Write-Host ""
Write-Host "Done." -ForegroundColor Green

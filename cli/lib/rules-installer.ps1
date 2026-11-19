$script:GrftRuleLangs = @('dotnet', 'java', 'kotlin', 'php', 'python', 'ruby', 'typescript-node-nextjs')

function Get-GraftRulesIdeLabel {
    param([string]$Ide)

    switch ($Ide.ToLowerInvariant()) {
        { $_ -in @('cursor', '1') } { return 'Cursor' }
        { $_ -in @('claude', 'claude-code', '2') } { return 'Claude Code' }
        { $_ -in @('copilot', 'github-copilot', 'github', '3') } { return 'GitHub Copilot' }
        { $_ -in @('cline', '4') } { return 'Cline' }
        { $_ -in @('windsurf', '5') } { return 'Windsurf' }
        { $_ -in @('continue', '6') } { return 'Continue' }
        { $_ -in @('aider', '7') } { return 'Aider' }
        default { return $Ide }
    }
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
    $Names += $script:GrftRuleLangs

    foreach ($Name in $Names) {
        $FileName = "graftcode-$Name.$Extension"
        $Url = "$RemoteDir/$FileName"
        $OutputPath = Join-Path $LocalDir $FileName
        Ui-DownloadFile -Url $Url -OutputPath $OutputPath -Label $FileName -ShowProgress
    }
}

function Install-GraftcodeRulesForIde {
    param([string]$Ide)

    $RulesRawBase = Get-GrftRulesRawBase
    $IdeLabel = Get-GraftRulesIdeLabel -Ide $Ide

    Show-UiGatewayIntro
    Ui-ObtainingRulesForIde -IdeLabel $IdeLabel

    $OutputPaths = @()

    switch ($Ide.ToLowerInvariant()) {
        { $_ -in @('cursor', '1') } {
            $RulesDir = Join-Path $PWD '.cursor\rules'
            Download-GraftcodeRuleSet -RemoteDir "$RulesRawBase/Cursor/.cursor/rules" -LocalDir $RulesDir -Extension 'mdc' -IncludeRouter
            $OutputPaths += $RulesDir
        }
        { $_ -in @('claude', 'claude-code', '2') } {
            $ClaudeMd = Join-Path $PWD 'CLAUDE.md'
            Ui-DownloadFile -Url "$RulesRawBase/Claude/CLAUDE.md" -OutputPath $ClaudeMd -Label 'CLAUDE.md' -ShowProgress
            $RulesDir = Join-Path $PWD '.claude\rules'
            Download-GraftcodeRuleSet -RemoteDir "$RulesRawBase/Claude/.claude/rules" -LocalDir $RulesDir -Extension 'md'
            $OutputPaths += $ClaudeMd, $RulesDir
        }
        { $_ -in @('copilot', 'github-copilot', 'github', '3') } {
            $GithubDir = Join-Path $PWD '.github'
            if (-not (Test-Path $GithubDir)) {
                New-Item -ItemType Directory -Path $GithubDir -Force | Out-Null
            }
            $CopilotInstructions = Join-Path $GithubDir 'copilot-instructions.md'
            Ui-DownloadFile -Url "$RulesRawBase/Copilot/.github/copilot-instructions.md" -OutputPath $CopilotInstructions -Label 'copilot-instructions.md' -ShowProgress
            $RulesDir = Join-Path $GithubDir 'instructions'
            Download-GraftcodeRuleSet -RemoteDir "$RulesRawBase/Copilot/.github/instructions" -LocalDir $RulesDir -Extension 'instructions.md'
            $OutputPaths += $CopilotInstructions, $RulesDir
        }
        { $_ -in @('cline', '4') } {
            $RulesDir = Join-Path $PWD '.clinerules'
            Download-GraftcodeRuleSet -RemoteDir "$RulesRawBase/Cline/.clinerules" -LocalDir $RulesDir -Extension 'md' -IncludeRouter
            $OutputPaths += $RulesDir
        }
        { $_ -in @('windsurf', '5') } {
            $RulesDir = Join-Path $PWD '.windsurf\rules'
            Download-GraftcodeRuleSet -RemoteDir "$RulesRawBase/Windsurf/.windsurf/rules" -LocalDir $RulesDir -Extension 'md' -IncludeRouter
            $OutputPaths += $RulesDir
        }
        { $_ -in @('continue', '6') } {
            $RulesDir = Join-Path $PWD '.continue\rules'
            Download-GraftcodeRuleSet -RemoteDir "$RulesRawBase/Continue/.continue/rules" -LocalDir $RulesDir -Extension 'md' -IncludeRouter
            $OutputPaths += $RulesDir
        }
        { $_ -in @('aider', '7') } {
            $Conventions = Join-Path $PWD 'CONVENTIONS.md'
            $AiderConf = Join-Path $PWD '.aider.conf.yml'
            Ui-DownloadFile -Url "$RulesRawBase/Aider/CONVENTIONS.md" -OutputPath $Conventions -Label 'CONVENTIONS.md' -ShowProgress
            Ui-DownloadFile -Url "$RulesRawBase/Aider/.aider.conf.yml" -OutputPath $AiderConf -Label '.aider.conf.yml' -ShowProgress
            $OutputPaths += $Conventions, $AiderConf
        }
        default {
            Exit-UiUserError "Unknown IDE '$Ide'." @(
                'Use: cursor, claude, copilot, cline, windsurf, continue, aider'
            )
        }
    }

    Show-UiRulesInstalled -IdeLabel $IdeLabel -OutputPaths $OutputPaths
}
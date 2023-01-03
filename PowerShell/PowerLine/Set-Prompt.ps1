# Requires -Modules PowerLine

import-module posh-git

# 0x276f

$PromptEnd = ' {0} ' -f [char] 0xFCB5

$global:GitPromptSettings = New-GitPromptSettings
$global:GitPromptSettings.BeforeStatus = ' '
$global:GitPromptSettings.AfterStatus = ' '
$global:GitPromptSettings.PathStatusSeparator = ''
$global:GitPromptSettings.BeforeStash.Text = "$(Text '&ReverseSeparator;')"
$global:GitPromptSettings.AfterStash.Text = "$(Text '&Separator;')"
$global:GitPromptSettings.BranchColor.ForegroundColor = [ConsoleColor]::DarkCyan

# "`u{276F}"
# [char]0x25B6
$powerLineProps = @{
    # Colors        = 'DarkBlue', 'Blue', 'Grey', 'DarkGrey', 'DarkCyan', 'White'
    Colors        = 'DarkBlue', 'White'
    Title         = {
        @(
            if (Test-IsAdmin) { 'Admin:' }
            if ($GitStatus) {
                '{0} [{1}]' -f $GitStatus.RepoName, $GitStatus.Branch
            } else { (Get-SegmentedPath).Object[-1] }
            '({0})' -f $PID
        ) -join ' '
    }
    Prompt        = @(      # don't use single quotes in prompt scriptblocks.  Use double quotes instead.
        { Get-Elapsed -Trim }
        { Get-SegmentedPath }
        { if (Get-Command Write-VcsStatus -ErrorAction SilentlyContinue) { Write-VcsStatus } }
        { "`t" }
        { [datetime]::Now.ToString('HH:mm') }
        { "`n" }
        { $MyInvocation.HistoryId }
        { if ($pushd = (Get-Location -Stack).count) { '{0}{1}' -f [char]187, $pushd } }
        { '&Gear;' * $NestedPromptLevel }
        { New-PromptText $PromptEnd  -ErrorForegroundColor DarkRed -ElevatedBackgroundColor Yellow }
    )
    <# PSReadLinePromptText = @(
        New-PromptText ($PromptEnd + "${bg:Clear}&ColorSeparator;") -ForegroundColor Green
        New-PromptText ($PromptEnd + "${bg:Clear}&ColorSeparator;") -ForegroundColor Red
    ) #>
    PowerLineFont = $true
    Save          = $true
}

Set-PowerLinePrompt @powerLineProps

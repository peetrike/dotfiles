#Requires -Modules posh-git

if (Get-Module ugit -ErrorAction SilentlyContinue) {
    Remove-Module ugit
}

    # replace window title
$GitPromptSettings.WindowTitle = {
    param ($GitStatus, [bool]$IsAdmin)

    @(
        if ($IsAdmin) { 'Admin:' }
        [Diagnostics.Process]::GetCurrentProcess().Name
        '({0})' -f $PID
        '-'
        if ($GitStatus) {
            '{0} [{1}]' -f $GitStatus.RepoName, $GitStatus.Branch
        } else { Split-Path $PWD -Leaf }
    ) -join ' '
}

    #customize prompt
$GitPromptSettings.DefaultPromptBeforeSuffix.Text = "`n"
$GitPromptSettings.DefaultPromptSuffix = '$($MyInvocation.HistoryId) $(">" * ($nestedPromptLevel + 1)) '
$GitPromptSettings.DefaultPromptPrefix.Text = '$([math]::Round((get-history -count 1).Duration.TotalSeconds, 3)) s '

#region add PowerLine prompt coloring to posh-git prompt
    $PromptSeparator = [char] 0xE0B0 + ' '

    $GitPromptSettings.DefaultPromptPrefix.ForegroundColor = [consolecolor]::Gray
    $GitPromptSettings.DefaultPromptPrefix.BackgroundColor = [consolecolor]::DarkBlue

    $GitPromptSettings.DefaultPromptPath.ForegroundColor = [ConsoleColor]::White
    $GitPromptSettings.DefaultPromptPath.BackgroundColor = [ConsoleColor]::Blue
    $GitPromptSettings.DefaultPromptPath.Text = '$(Write-Prompt $PromptSeparator -ForegroundColor $GitPromptSettings.DefaultPromptPrefix.BackgroundColor)$(Get-PromptPath) '

    $GitPromptSettings.BeforeStatus.BackgroundColor = [ConsoleColor]::Gray

    $GitPromptSettings.PathStatusSeparator.Text = $PromptSeparator
    $GitPromptSettings.PathStatusSeparator.ForegroundColor = $GitPromptSettings.DefaultPromptPath.BackgroundColor
    $GitPromptSettings.PathStatusSeparator.BackgroundColor = $GitPromptSettings.BeforeStatus.BackgroundColor

    $GitPromptSettings.DefaultPromptBeforeSuffix.Text = $PromptSeparator + "`n"
    $GitPromptSettings.DefaultPromptBeforeSuffix.ForegroundColor = $GitPromptSettings.BeforeStatus.BackgroundColor
#endregion

    # customize git status text
$GitPromptSettings.BeforeStatus.Text = [char] 0xE0A0 # branch symbol
$GitPromptSettings.AfterStatus.Text = ''

#region Set Git status colors
    #$GitPromptSettings.WorkingColor.ForegroundColor = [System.ConsoleColor]::DarkRed
    #$GitPromptSettings.IndexColor.ForegroundColor = [ConsoleColor]::DarkGreen
    #$GitPromptSettings.BeforeStatus.ForegroundColor = [consolecolor]::Black
    $GitPromptSettings.BranchColor.ForegroundColor = [ConsoleColor]::DarkCyan
    $GitPromptSettings.BeforeStatus.ForegroundColor = $GitPromptSettings.BranchColor.ForegroundColor
    $GitPromptSettings.DelimStatus.ForegroundColor = $GitPromptSettings.BeforeStatus.ForegroundColor

    $GitPromptSettings.BranchColor.BackgroundColor = $GitPromptSettings.BeforeStatus.BackgroundColor
    $GitPromptSettings.DelimStatus.BackgroundColor = $GitPromptSettings.BeforeStatus.BackgroundColor
    $GitPromptSettings.AfterStatus.BackgroundColor = $GitPromptSettings.BeforeStatus.BackgroundColor

    #$GitPromptSettings.LocalWorkingStatusSymbol.ForegroundColor = [consolecolor]::Red
    $GitPromptSettings.LocalStagedStatusSymbol.ForegroundColor = $GitPromptSettings.BeforeStatus.ForegroundColor

    $GitPromptSettings.LocalWorkingStatusSymbol.BackgroundColor = $GitPromptSettings.BeforeStatus.BackgroundColor
    $GitPromptSettings.LocalStagedStatusSymbol.BackgroundColor = $GitPromptSettings.BeforeStatus.BackgroundColor

    $GitPromptSettings.IndexColor.BackgroundColor = $GitPromptSettings.BeforeStatus.BackgroundColor
    $GitPromptSettings.StashColor.BackgroundColor = $GitPromptSettings.BeforeStatus.BackgroundColor
    $GitPromptSettings.WorkingColor.BackgroundColor = $GitPromptSettings.BeforeStatus.BackgroundColor

    $GitPromptSettings.BranchAheadStatusSymbol.ForegroundColor = [consolecolor]::DarkGreen
    $GitPromptSettings.BranchBehindStatusSymbol.ForegroundColor = [System.ConsoleColor]::DarkRed
    $GitPromptSettings.BranchBehindAndAheadStatusSymbol.ForegroundColor = $GitPromptSettings.BranchBehindStatusSymbol.ForegroundColor

    $GitPromptSettings.BranchAheadStatusSymbol.BackgroundColor = $GitPromptSettings.BeforeStatus.BackgroundColor
    $GitPromptSettings.BranchBehindAndAheadStatusSymbol.BackgroundColor = $GitPromptSettings.BeforeStatus.BackgroundColor
    $GitPromptSettings.BranchBehindStatusSymbol.BackgroundColor = $GitPromptSettings.BeforeStatus.BackgroundColor
#endregion

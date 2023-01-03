﻿if (-not (Get-Command Test-IsAdmin -ErrorAction SilentlyContinue)) {
    function Test-IsAdmin {
        [CmdletBinding()]
        param()

        $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
        ([Security.Principal.WindowsPrincipal] $currentUser).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
    }
}

function prompt {
    $PowerLineText = [char] 0xE0B0
    $PromptText = [char] 0x276f

    $host.UI.RawUI.WindowTitle = @(
        if (Test-IsAdmin) { 'Admin:' }
        [Diagnostics.Process]::GetCurrentProcess().Name
        '({0})' -f $PID
        '-'
        Split-Path $PWD -Leaf
    ) -join ' '

    #region Elapsed time
        $NextColor = [ConsoleColor]::Gray
        $LastColor = [ConsoleColor]::DarkBlue

        $LastCmd = (Get-History -Count 1)
        $LastElapsed = $LastCmd.EndExecutionTime - $LastCmd.StartExecutionTime
        $Elapsed = ' {0} s ' -f [math]::Round(($LastElapsed).TotalSeconds, 3)

        Write-Host $Elapsed -NoNewline -ForegroundColor $NextColor -BackgroundColor $LastColor
    #endregion

    #region Path
        $NextColor = [ConsoleColor]::Blue
        Write-Host $PowerLineText -NoNewline -ForegroundColor $LastColor -BackgroundColor $NextColor

        $LastColor = $NextColor
        $NextColor = [ConsoleColor]::White
        Write-Host (' {0} ' -f $PWD) -NoNewline -ForegroundColor $NextColor -BackgroundColor $LastColor
    #endregion

    #region end of powerline
        $NextColor = $host.ui.RawUI.BackgroundColor
        Write-Host $PowerLineText -NoNewline -ForegroundColor $LastColor -BackgroundColor $NextColor
    #endregion

    #region Time
        $TimePosition = $host.UI.RawUI.CursorPosition
        $TimePosition.X = $host.UI.RawUI.WindowSize.Width - 5
        $host.UI.RawUI.CursorPosition = $TimePosition
        Write-Host ([datetime]::Now.ToString('HH:mm'))
    #endregion

        # second line
    '{0} {1} ' -f $MyInvocation.HistoryId, $PromptText * ($NestedPromptLevel + 1)
}

if (Get-Module PSReadLine) {
    Set-PSReadLineOption -PromptText ('{0} ' -f [char] 0x276f)
    Set-PSReadLineOption -ContinuationPrompt '∙ '
}

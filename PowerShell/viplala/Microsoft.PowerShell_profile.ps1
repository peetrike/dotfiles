$host.UI.RawUi.WindowTitle = '{2} - {0}@{1}' -f $env:USERNAME, $env:COMPUTERNAME, (Get-Process -id $pid).ProcessName

if (Get-Module PSReadLine) {
    Set-PSReadLineOption -ExtraPromptLineCount 1
    Set-PSReadLineOption -PromptText ('{0} ' -f [char] 0x276f)
    Set-PSReadLineOption -ContinuationPrompt ('{0} ' -f [char] 0x2219) -Colors @{ ContinuationPrompt = 'DarkGray' }
}
function prompt {
    $PowerLineText = [char] 0xE0B0
    $PromptText = [char] 0x276f

    #region Elapsed time
        $NextColor = [ConsoleColor]::Gray
        $LastColor = [ConsoleColor]::DarkBlue

        $LastCmd = Get-History -Count 1
        $LastElapsed = if ($LastCmd) {
            $LastCmd.EndExecutionTime - $LastCmd.StartExecutionTime
        } else {
            [timespan] 0
        }
        $Elapsed = ' {0} s ' -f [math]::Round($LastElapsed.TotalSeconds, 3)

        Write-Host $Elapsed -NoNewline -ForegroundColor $NextColor -BackgroundColor $LastColor
    #endregion

    #region Add PowerLine symbol
        $NextColor = [ConsoleColor]::Blue
        Write-Host $PowerLineText -NoNewline -ForegroundColor $LastColor -BackgroundColor $NextColor
        $LastColor = $NextColor
    #endregion

    #region Path
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
        Write-Host ([datetime]::Now.ToString('t'))
    #endregion

        # second line
    '{0} {1} ' -f $MyInvocation.HistoryId, $PromptText * ($NestedPromptLevel + 1)
}

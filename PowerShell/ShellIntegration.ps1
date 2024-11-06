﻿#Requires -Version 5
<#
    .LINK
        https://learn.microsoft.com/windows/terminal/tutorials/shell-integration
#>

$Global:__LastHistoryId = -1

if (Get-Module PSReadLine -ErrorAction SilentlyContinue) {
    Set-PSReadLineOption -ExtraPromptLineCount 1
    Set-PSReadLineOption -PromptText '❯ '
    #region Add End of cmd input mark (OSC 133 ; C ST)
    Set-PSReadLineKeyHandler -Key Enter -BriefDescription 'OscCommandExecuted' -ScriptBlock {
        $executingCommand = $false
        $parseErrors = $null
        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState(
            [ref]$null,
            [ref]$null,
            [ref]$parseErrors,
            [ref]$null
        )
        $executingCommand = $parseErrors.Count -eq 0

        [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()

        # Write OSC code after accepting the input - it should still happen before execution
        if ($executingCommand) {
            Write-Host "$([char]0x1b)]133;C`a" -NoNewline
        }
    }
    #endregion
}

function global:Prompt {
    [CmdletBinding()]
    param ()
    function Add-PowerLine {
        [CmdletBinding()]
        param (
                [Text.StringBuilder]
            $PromptBuilder,
                [string]
            $Foreground,
                #[ref]
                [string]
            $Background
        )

            # support resetting colors to defaults with $Background, but still changing foreground color.
        $PowerLineText = $Background + $Foreground + [char] 0xE0B0
        $PromptBuilder.Append($PowerLineText)
    }

    $lastSuccess = $?
    $currentLastExitCode = $LASTEXITCODE

    $Esc = [char] 27
    $PromptText = [char] 0x276f

    $PromptBuilder = [Text.StringBuilder]::new(256)
    $LastCmd = Get-History -Count 1

    #region Emit a mark for the _end_ of the previous command.
    if ($MyInvocation.HistoryId -ne -1) {
        # OSC 133 ; D ; <Exitcode?> ST
        [void] $PromptBuilder.Append("$Esc]133;D")
        if ($LastCmd) {
            $gle = if ($lastSuccess) {
                0
            } elseif ($Error[0].InvocationInfo.HistoryId -eq $LastCmd.Id) {
                -1
            } else {
                $currentLastExitCode
            }

                # Don't provide a command line or exit code if there was no history entry (eg. ctrl+c, enter on no command)
            if ($LastCmd.Id -ne $Global:__LastHistoryId) {
                $Global:__LastHistoryId = $LastCmd.Id
                $exitCode = ';' + $gle
                [void] $PromptBuilder.Append($exitCode)
            }
        }
        [void] $PromptBuilder.Append("`a")
    }
    #endregion

    #region Set Console window title
    $Host.UI.RawUI.WindowTitle = @(
        if (Test-IsAdmin) { 'Admin:' }
        [Diagnostics.Process]::GetCurrentProcess().Name
        '({0})' -f $PID
        '-'
        Split-Path -Path $PWD -Leaf
    ) -join ' '
    #endregion

    # Prompt started (OSC 133 ; A ST)
    [void] $PromptBuilder.Append("$Esc]133;A`a")

    #region Build prompt here

        #region Elapsed time
        if ($LastCmd) {
            <# $Foreground = $PSStyle.Foreground.White
            $Background = $PSStyle.Background.Blue #>

            $LastElapsed = $LastCmd.EndExecutionTime - $LastCmd.StartExecutionTime
            $cmdTime = $LastElapsed.TotalMilliseconds

            $units = 'ms'
            if ($cmdTime -ge 1000) {
              $units = 's'
              $cmdTime = $LastElapsed.TotalSeconds
              if ($cmdTime -ge 60) {
                $units = 'm'
                $cmdTIme = $LastElapsed.TotalMinutes
              }
            }
            $Elapsed = ' {0:0.###} {1} ' -f $cmdTime, $units
            [void] $PromptBuilder.Append($PSStyle.Foreground.White + $PSStyle.Background.Blue)
            [void] $PromptBuilder.Append($Elapsed)
        }
        #endregion

        #region Add PowerLine symbol
        $Background = $PSStyle.Background.BrightBlue
        $PromptBuilder = Add-PowerLine -f $PSStyle.Foreground.Blue -b $Background -PromptBuilder $PromptBuilder
        #endregion

        #region Path
        #$Background = $PSStyle.Background.BrightBlue
        $loc = $executionContext.SessionState.Path.CurrentLocation
        $LocationText = if ($loc.Provider.Name -like 'filesystem') {
            $PSStyle.FormatHyperlink($loc, $loc.Path)
                # Inform terminal about current working directory (OSC 99)
            $cwd = '{0}]9;9;"{1}"{2}' -f $Esc, $loc, "`a"
            [void] $PromptBuilder.Append($cwd)
        } else { $loc }
        [void] $PromptBuilder.Append($PSStyle.Foreground.BrightWhite + $Background)
        [void] $PromptBuilder.Append(" $LocationText ")
        #endregion

        #region end of powerline
        $PromptBuilder = Add-PowerLine -f $PSStyle.Foreground.BrightBlue -b $PSStyle.Reset -PromptBuilder $PromptBuilder
        [void] $PromptBuilder.Append($PSStyle.Reset)
        #endregion

        Write-Host -NoNewline $PromptBuilder.ToString()
        #region Time
            $TimePosition = $host.UI.RawUI.CursorPosition
            $TimePosition.X = $host.UI.RawUI.WindowSize.Width - 5
            $host.UI.RawUI.CursorPosition = $TimePosition
            Write-Host ([datetime]::Now.ToString('t'))
        #endregion

    #region Second line
    $PromptBuilder = [Text.StringBuilder]::new(256)
    [void] $PromptBuilder.Append($MyInvocation.HistoryId)

    $Foreground = if ($gle) {
        $PSStyle.Foreground.Red
    } else {
        $PSStyle.Foreground.BrightGreen
    }
    $PSSymbol = $Foreground + '  ' + $PSStyle.Reset
    [void] $PromptBuilder.Append($PSSymbol)

    $NestedSymbol = ([string]$PromptText) * ($nestedPromptLevel + 1) + ' '
    [void] $PromptBuilder.Append($NestedSymbol)

    # Prompt ended, Command started (OSC 133 ; B ST)
    [void] $PromptBuilder.Append("$Esc]133;B`a")
    #endregion

    $PromptBuilder.ToString()
    #endregion
    $global:LASTEXITCODE = $currentLastExitCode
}

#Requires -Version 5
<#
    .LINK
        https://learn.microsoft.com/windows/terminal/tutorials/shell-integration
#>

$global:__LastHistoryId = -1

function global:Prompt {
    [CmdletBinding()]
    param ()
    function Add-PowerLine {
        [CmdletBinding()]
        param (
                [text.StringBuilder]
            $PromptBuilder,
                [string]
            $OldColor,
                #[ref]
                [string]
            $NewColor
        )

        $PowerLineText = $OldColor + $NewColor + [char] 0xE0B0
        $PromptBuilder.Append($PowerLineText)
    }

    $lastSuccess = $?
    $currentLastExitCode = $LASTEXITCODE

    $Esc = [char] 27
    $Bel = "`a"
    $PromptText = [char] 0x276f

    $PromptBuilder = [Text.StringBuilder]::new(256)
    $LastCmd = Get-History -Count 1

    #region Emit a mark for the _end_ of the previous command.
    if ($MyInvocation.HistoryId -ne -1) {
        # OSC 133 ; D ; <Exitcode?> ; ST
        [void] $PromptBuilder.Append("$Esc]133;D")
            # Don't provide a command line or exit code if there was no history entry (eg. ctrl+c, enter on no command)
        if ($LastCmd.Id -ne $Global:__LastHistoryId) {
            $gle = if ($lastSuccess) {
                0
            } elseif ($currentLastExitCode) {
                $currentLastExitCode
            } else { -1 }

            [void] $PromptBuilder.Append($gle)
        }
        [void] $PromptBuilder.Append($Bel)
    }
    #endregion

    # Prompt started (OSC 133 ; A ST)
    [void] $PromptBuilder.Append("$Esc]133;A`a")

    #region Build prompt here

        #region Elapsed time
        if ($LastCmd.Id -ne $Global:__LastHistoryId) {
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
        $PromptBuilder = Add-PowerLine -OldColor $PSStyle.Foreground.Blue -NewColor $Background -PromptBuilder $PromptBuilder
        #endregion

        #region Path
        $Background = $PSStyle.Background.BrightBlue
        $LocationText = if ($loc.Provider.Name -like 'filesystem') {
            $PSStyle.FormatHyperlink($loc, $loc.Path)
                # Inform terminal about current working directory (OSC 99)
            $loc = $executionContext.SessionState.Path.CurrentLocation
            $cwd = '{0}]9;9;"{1}"{2}' -f $Esc, $loc, $bel
            [void] $PromptBuilder.Append($cwd)
        } else { $loc }
        [void] $PromptBuilder.Append($PSStyle.Foreground.BrightWhite + $Background)
        [void] $PromptBuilder.Append(" $LocationText ")
        #endregion

        #region end of powerline
        $Background = $PSStyle.Background.BrightWhite
        $PromptBuilder = Add-PowerLine -OldColor $PSStyle.Reset -NewColor $PSStyle.Foreground.BrightBlue -PromptBuilder $PromptBuilder
        [void] $PromptBuilder.AppendLine($PSStyle.Reset)
        #endregion

        # Second line
    [void] $PromptBuilder.Append($MyInvocation.HistoryId)

    $Foreground = if ($gle) {
        $PSStyle.Foreground.Red
    } else {
        $PSStyle.Foreground.Green
    }
    $PSSymbol = $Foreground + '  ' + $PSStyle.Reset
    [void] $PromptBuilder.Append($PSSymbol)

    $NestedSymbol = ([string]$PromptText) * ($nestedPromptLevel + 1) + ' '
    [void] $PromptBuilder.Append($NestedSymbol)
    #endregion

    # Prompt ended, Command started (OSC 133 ; B ST)
    [void] $PromptBuilder.Append("$Esc]133;B`a")

    $Global:__LastHistoryId = $LastCmd.Id

    Write-Debug -Message ('Prompt length: {0}' -f $PromptBuilder.Length)
    $PromptBuilder.ToString()
    $global:LASTEXITCODE = $currentLastExitCode
}

﻿#Requires -Modules TerminalBlocks

$PromptSymbol = '❯ '

$global:Prompt = @(
    Initialize-Prompt

    $Begincaps = @{
        Caps = '▐', ''
    }
    $Caps = @{
        Caps = '', ''
    }
    Show-ElapsedTime -Autoformat <# -Foreground White #> -Prefix '' #-BackgroundColor DarkBlue @Begincaps

    Show-Path -DriveName -HomeString "&House;" -Foreground White -AsUrl -BackgroundColor Blue @Begincaps
        # -Separator '' # This separator requires a nerdfont

    if (Get-Module posh-git) {
        Show-PoshGitStatus -BeforeStatus '' -AfterStatus '' -PathStatusSeparator '' #-BackgroundColor Gray80 @caps
            # -Caps "&nf-pl-branch;", "`n" # nf-pl-branch requires a PowerLine font
    }

        # You can use -Cap "`n" instead of a newline block to add a newline conditional on this block being output
    Show-LastExitCode -ForegroundColor 'VioletRed1' #@caps

    # For right-aligned blocks, the first one is the furthest to the right

    # Use a short time format and a clock prefix (I don't need the EXACT time in my prompt)
    Show-Date -Format 't' -Prefix '&twooclock;' -Foreground '#FFFFFF' -Alignment Right

    # Since this isn't right aligned, it starts a new line
    Show-HistoryId -Foreground 'White'

    # So the in-line prompt is just this one character:
    New-TerminalBlock $PromptSymbol -Foreground 'Gray80' -AdminForeground Yellow -Caps ''

    Exit-Prompt
)

function global:Prompt { -join $Prompt }

if (Get-Module PSReadLine) {
    # Update PSReadLine to match our prompt (this has no output)
    Set-PSReadLineOption -PromptText @(
        New-Text $PromptSymbol -Foreground 'Gray80'
        New-Text $PromptSymbol -Foreground 'VioletRed1'
    )
    Set-PSReadLineOption -ContinuationPrompt (New-Text '∙ ' -Foreground 'SteelBlue1')
}

#Requires -Modules TerminalBlocks

if (-not (Get-Command Test-IsAdmin -ErrorAction SilentlyContinue)) {
    function Test-IsAdmin {
        [CmdletBinding()]
        param()

        $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
        ([Security.Principal.WindowsPrincipal] $currentUser).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
    }
}

$PromptSymbol = '❯ '

$global:Prompt = @(
    Show-ElapsedTime -Autoformat -Foreground '#FFFFFF' -Prefix ''
        # -Separator '' # This separator requires a nerdfont
    Show-Path -DriveName -HomeString "&House;" -Foreground 'SteelBlue1' -AsUrl

    if (Get-Module posh-git) {
             # -Caps "&nf-pl-branch;", "`n" # nf-pl-branch requires a PowerLine font
        Show-PoshGitStatus -BeforeStatus "" -AfterStatus "" -PathStatusSeparator "" -Caps ""
    }

        # You can use -Cap "`n" instead of a newline block to add a newline conditional on this block being output
    Show-LastExitCode -ForegroundColor 'VioletRed1' -Caps ''

    # Use a short time format and a clock prefix (I don't need the EXACT time in my prompt)
    # Because all of these are right-aligned, the first one is the furthest to the right
    Show-Date -Format 'HH:mm' -Prefix '&twooclock;' -Foreground '#FFFFFF' -Alignment Right

    # Since this isn't right aligned, it starts a new line
    Show-HistoryId -Foreground 'White'

    # So the in-line prompt is just this one character:
    New-TerminalBlock $PromptSymbol -Foreground 'Gray80' -Caps ''
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

[CmdletBinding()]
param (
        [string]
    $Theme = 'pwtheme.omp.json'
)
function Set-EnvVar {
    $env:PSHistory = $MyInvocation.HistoryId
}
Set-Alias -Name 'Set-PoshContext' -Value 'Set-EnvVar' -Scope Global
$env:POSH_THEMES_PATH = 'C:\Program Files (x86)\oh-my-posh\themes'

$ThemeFolder = Join-Path -Path (Split-Path -Path $profile) -ChildPath 'PoshThemes'
if (-not $Theme.Contains('.')) {
    $Theme += '.omp.json'
}
    # https://ohmyposh.dev/docs/installation/customize
$env:POSH_THEME = (Join-Path -Path $ThemeFolder -ChildPath $Theme)
oh-my-posh.exe init pwsh | Invoke-Expression

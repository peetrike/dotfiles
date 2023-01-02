function Set-EnvVar {
    $env:PSHistory=$($MyInvocation.HistoryId)
}
New-Alias -Name 'Set-PoshContext' -Value 'Set-EnvVar' -Scope Global
$env:POSH_THEMES_PATH = 'C:\Program Files (x86)\oh-my-posh\themes'

    # https://ohmyposh.dev/docs/installation/customize
$env:POSH_THEME = (Join-Path -Path $env:POSH_THEMES_PATH -ChildPath 'pwtheme.omp.json')
oh-my-posh.exe init pwsh | Invoke-Expression

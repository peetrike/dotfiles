[CmdletBinding()]
param (
    $Path = (Split-Path -Path $env:POSH_THEME -Parent)
)

Get-ChildItem -Path $Path -Filter *.omp.json | ForEach-Object {
    Write-Output "`n" (Split-Path -Path $_ -Leaf).Replace('.omp.json', '')
    oh-my-posh.exe print primary --config $_
}

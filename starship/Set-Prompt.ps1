function Global:Invoke-Starship-PreCommand {
    $host.UI.RawUI.WindowTitle = @(
        if (Test-IsAdmin) { 'Admin:' }
        [Diagnostics.Process]::GetCurrentProcess().Name
        '({0})' -f $PID
        '-'
        if ($GitStatus) {
            '{0} [{1}]' -f $GitStatus.RepoName, $GitStatus.Branch
        } else { Split-Path $pwd -Leaf }
    ) -join ' '
    $env:PSHistory = $MyInvocation.HistoryId
}

    # https://starship.rs/config/#configuration

#$StarshipPath = Join-Path -Path $env:ProgramFiles -ChildPath 'starship\bin\starship.exe'
starship.exe init powershell | Invoke-Expression

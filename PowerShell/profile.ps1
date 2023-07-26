#region Verbose and Debug colors back to Cyan
if ($Host.Name -like 'ConsoleHost') {
    $Host.PrivateData.VerboseForegroundColor = [ConsoleColor]::Cyan
    $Host.PrivateData.DebugForegroundColor = [ConsoleColor]::Cyan
}

if ($PSVersionTable.PSVersion -gt '7.2') {
    $PSStyle.Formatting.Verbose = $PSStyle.Foreground.Cyan
    $PSStyle.Formatting.Debug = $PSStyle.Formatting.Verbose
}
#endregion

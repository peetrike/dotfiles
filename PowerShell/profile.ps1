#region Verbose and Debug colors back to Cyan
$Host.PrivateData.VerboseForegroundColor = [System.ConsoleColor]::Cyan
$Host.PrivateData.DebugForegroundColor = [System.ConsoleColor]::Cyan

if ($PSVersionTable.PSVersion -gt '7.2') {
    $PSStyle.Formatting.Verbose = $PSStyle.Foreground.Cyan
    $PSStyle.Formatting.Debug = $PSStyle.Formatting.Verbose
}
#endregion

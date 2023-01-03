$Host.PrivateData.VerboseForegroundColor = [System.ConsoleColor]::Cyan
$Host.PrivateData.DebugForegroundColor = [System.ConsoleColor]::Cyan

if ($PSVersionTable.PSVersion -gt '7.2') {
    $PSStyle.Formatting.Verbose = $PSStyle.Foreground.BrightCyan
    $PSStyle.Formatting.Debug = $PSStyle.Formatting.Verbose
}

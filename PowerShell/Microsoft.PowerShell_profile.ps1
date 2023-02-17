# verbose and debug colors back to Cyan
$Host.PrivateData.VerboseForegroundColor = [ConsoleColor]::Cyan
$Host.PrivateData.DebugForegroundColor = [ConsoleColor]::Cyan

#region PSReadLine config
if (Get-Module -Name PSReadLine -ListAvailable) {
        # the following doesn't work with Prediction ListView
    # Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
    # Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward

    if ($PSVersionTable.PSVersion -gt '7.2') {
        Import-Module CompletionPredictor
        Import-Module Az.Tools.Predictor
    }
    Set-PSReadLineOption -Colors @{ InlinePrediction = "`e[33m" }

    # `ForwardChar` accepts the entire suggestion text when the cursor is at the end of the line.
    # This custom binding makes `Ctrl+RightArrow` behave similarly - accepting the next word instead of the entire suggestion text.
    $KeyHandlerParam = @{
        Chord            = 'Ctrl+RightArrow'
        BriefDescription = 'NextWordAndAcceptNextSuggestionWord'
        LongDescription  = 'Move cursor one character to the right in the current editing line and ' +
            "accept the next word in suggestion when it's at the end of current editing line"
    }
    Set-PSReadLineKeyHandler @KeyHandlerParam {
        param($key, $arg)

        $line = $null
        $cursor = $null
        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)

        if ($cursor -lt $line.Length) {
            [Microsoft.PowerShell.PSConsoleReadLine]::NextWord($key, $arg)
        } else {
            [Microsoft.PowerShell.PSConsoleReadLine]::AcceptNextSuggestionWord($key, $arg)
        }
    }

    # add some PSReadLine "smart" functions
    #region Smart Insert/Delete

    # The next four key handlers are designed to make entering matched quotes
    # parens, and braces a nicer experience.  I'd like to include functions
    # in the module that do this, but this implementation still isn't as smart
    # as ReSharper, so I'm just providing it as a sample.

    $KeyHandlerParam = @{
        Chord            = '"', "'"
        BriefDescription = 'SmartInsertQuote'
        LongDescription  = 'Insert paired quotes if not already on a quote'
    }
    Set-PSReadLineKeyHandler @KeyHandlerParam -ScriptBlock {
        param ($key, $arg)

        $quote = [string] $key.KeyChar

        $selectionStart = $null
        $selectionLength = $null
        [Microsoft.PowerShell.PSConsoleReadLine]::GetSelectionState([ref]$selectionStart, [ref]$selectionLength)

        $line = $null
        $cursor = $null
        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)

        if ($selectionStart -ne -1) {
                # text is selected, just quote it without any smarts
            [Microsoft.PowerShell.PSConsoleReadLine]::Replace(
                $selectionStart,
                $selectionLength,
                $quote + $line.SubString($selectionStart, $selectionLength) + $quote
            )
            [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($selectionStart + $selectionLength + 2)
            return
        }

        $ast = $null
        $tokens = $null
        $parseErrors = $null
        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$ast, [ref]$tokens, [ref]$parseErrors, [ref]$null)

        function FindToken {
            param($tokens, $cursor)

            foreach ($token in $tokens) {
                if ($cursor -lt $token.Extent.StartOffset) { continue }
                if ($cursor -lt $token.Extent.EndOffset) {
                    $result = $token
                    $token = $token -as [Management.Automation.Language.StringExpandableToken]
                    if ($token) {
                        $nested = FindToken $token.NestedTokens $cursor
                        if ($nested) { $result = $nested }
                    }

                    return $result
                }
            }
            return $null
        }

        $token = FindToken $tokens $cursor

        if (
            $token -is [Management.Automation.Language.StringToken] -and
            $token.Kind -ne [Management.Automation.Language.TokenKind]::Generic
        ) {
                # we're on or inside a **quoted** string token (so not generic), we need to be smarter
            if ($token.Extent.StartOffset -eq $cursor) {
                    # we're at the start of the string, assume we're inserting a new string
                [Microsoft.PowerShell.PSConsoleReadLine]::Insert($quote * 2 + ' ')
                [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($cursor + 1)
                return
            }

            if ($token.Extent.EndOffset -eq ($cursor + 1) -and $line[$cursor] -eq $quote) {
                    # we're at the end of the string, move over the closing quote if present.
                [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($cursor + 1)
                return
            }
        }

        if ($null -eq $token -or
            $token.Kind -eq [Management.Automation.Language.TokenKind]::RParen -or
            $token.Kind -eq [Management.Automation.Language.TokenKind]::RCurly -or
            $token.Kind -eq [Management.Automation.Language.TokenKind]::RBracket
        ) {
            if (
                ($line.Length -eq $cursor) -or  # at end of line
                (($line[0..$cursor] | Where-Object { $_ -eq $quote }).Count % 2 -eq 1)
            ) {
                    # Odd number of quotes before the cursor, insert a single quote
                [Microsoft.PowerShell.PSConsoleReadLine]::Insert($quote)
            } else {
                    # Insert matching quotes, move cursor to be in between the quotes
                [Microsoft.PowerShell.PSConsoleReadLine]::Insert($quote * 2)
                [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($cursor + 1)
            }
            return
        }

        if ($token.Extent.StartOffset -eq $cursor) {
            if (
                $token.Kind -eq [Management.Automation.Language.TokenKind]::Generic -or
                $token.Kind -eq [Management.Automation.Language.TokenKind]::Identifier -or
                $token.Kind -eq [Management.Automation.Language.TokenKind]::Variable -or
                $token.TokenFlags.hasFlag([Management.Automation.Language.TokenFlags]::Keyword)
            ) {
                    # at the beginning of token. Insert quotes around and move to the end of token
                $end = $token.Extent.EndOffset
                $len = $end - $cursor
                [Microsoft.PowerShell.PSConsoleReadLine]::Replace($cursor, $len, $quote + $line.SubString($cursor, $len) + $quote)
                [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($end + 2)
                return
            }
        }

            # We failed to be smart, so just insert a single quote
        [Microsoft.PowerShell.PSConsoleReadLine]::Insert($quote)
    }

    $KeyHandlerParam = @{
        Chord            = '(', '{', '['
        BriefDescription = 'InsertPairedBraces'
        LongDescription  = 'Insert matching braces'
    }
    Set-PSReadLineKeyHandler @KeyHandlerParam -ScriptBlock {
        param ($key, $arg)

        $openChar = $key.KeyChar

        $closeChar = switch ($openChar) {
            '(' { [char]')'; break }
            '{' { [char]'}'; break }
            '[' { [char]']'; break }
        }

        $selectionStart = $null
        $selectionLength = $null
        [Microsoft.PowerShell.PSConsoleReadLine]::GetSelectionState([ref]$selectionStart, [ref]$selectionLength)

        $line = $null
        $cursor = $null
        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)

        if ($selectionStart -ne -1) {
            # Text is selected, wrap it in brackets
            [Microsoft.PowerShell.PSConsoleReadLine]::Replace(
                $selectionStart,
                $selectionLength,
                $openChar + $line.SubString($selectionStart, $selectionLength) + $closeChar
            )
            [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($selectionStart + $selectionLength + 2)
        } else {
            <# # No text is selected, insert a pair
            [Microsoft.PowerShell.PSConsoleReadLine]::Insert("$($key.KeyChar)$closeChar")
            [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($cursor + 1) #>
            # no text selected, just insert the char
            [Microsoft.PowerShell.PSConsoleReadLine]::Insert($openChar)
        }
    }

    <# $KeyHandlerParam = @{
        Chord            = ')', ']', '}'
        BriefDescription = 'SmartCloseBraces'
        LongDescription  = 'Insert closing brace or skip'
    }
    Set-PSReadLineKeyHandler @KeyHandlerParam -ScriptBlock {
        param ($key, $arg)

        $line = $null
        $cursor = $null
        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)

        if ($line[$cursor] -eq $key.KeyChar) {
            [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($cursor + 1)
        } else {
            [Microsoft.PowerShell.PSConsoleReadLine]::Insert("$($key.KeyChar)")
        }
    } #>

    $KeyHandlerParam = @{
        Chord            = 'Backspace'
        BriefDescription = 'SmartBackspace'
        LongDescription  = 'Delete previous character or matching quotes/parens/braces'
    }
    Set-PSReadLineKeyHandler @KeyHandlerParam -ScriptBlock {
        param ($key, $arg)

        $line = $null
        $cursor = $null
        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)

        if ($cursor -gt 0) {
            $toMatch = $null
            if ($cursor -lt $line.Length) {
                switch ($line[$cursor]) {
                     '"' { $toMatch = '"'; break }
                     "'" { $toMatch = "'"; break }
                     ')' { $toMatch = '('; break }
                     ']' { $toMatch = '['; break }
                     '}' { $toMatch = '{'; break }
                }
            }

            if ($toMatch -ne $null -and $line[$cursor - 1] -eq $toMatch) {
                [Microsoft.PowerShell.PSConsoleReadLine]::Delete($cursor - 1, 2)
            } else {
                [Microsoft.PowerShell.PSConsoleReadLine]::BackwardDeleteChar($key, $arg)
            }
        }
    }
    #endregion Smart Insert/Delete

    # Ctrl-F1 for help on the command line - naturally
    $KeyHandlerParam = @{
        Chord            = 'Ctrl-F1'
        BriefDescription = 'CommandHelp'
        LongDescription  = 'Open the help window for the current command'
    }
    Set-PSReadLineKeyHandler @KeyHandlerParam -ScriptBlock {
        param ($key, $arg)

        $ast = $null
        $tokens = $null
        $errors = $null
        $cursor = $null
        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$ast, [ref]$tokens, [ref]$errors, [ref]$cursor)

        $commandAst = $ast.FindAll(
            {
                $node = $args[0]
                $node -is [Management.Automation.Language.CommandAst] -and
                    $node.Extent.StartOffset -le $cursor -and
                    $node.Extent.EndOffset -ge $cursor
            },
            $true
        ) | Select-Object -Last 1

        if ($commandAst -ne $null) {
            $commandName = $commandAst.GetCommandName()
            if ($commandName -ne $null) {
                $command = $ExecutionContext.InvokeCommand.GetCommand($commandName, 'All')
                if ($command -is [Management.Automation.AliasInfo]) {
                    $commandName = $command.ResolvedCommandName
                }

                if ($commandName -ne $null) {
                    if ((Get-Command $commandName).HelpUri) {
                        Get-Help $commandName -Online
                    } else {
                        Get-Help $commandName -ShowWindow
                    }
                }
            }
        }
    }
}
#endregion

if ($PSVersionTable.PSVersion.Major -gt 2) {
    if (Get-Module -Name ugit -ListAvailable) {
        Import-Module -Name ugit
    } else {
        Write-Warning -Message 'Module ugit NOT available'
    }
    # import-module posh-git

        # make fancy prompt
    if (Get-Command -Name oh-my-posh) {
        function Set-EnvVar {
            $env:PSHistory=$($MyInvocation.HistoryId)
        }
        New-Alias -Name 'Set-PoshContext' -Value 'Set-EnvVar' -Scope Global
        $env:POSH_THEME = (Join-Path -Path (Split-Path -Path $profile) -ChildPath 'PoshThemes\pwtheme.omp.json')
        oh-my-posh.exe init pwsh | Invoke-Expression
    }
}

# Arber

Arb Excel translator

Translation cells accept actual line breaks and typed `\n` or `\r\n` sequences.
All produce line breaks in the generated ARB translations, always written as
`\n`: a CRLF (Excel for Mac saves Alt+Enter that way) or a lone CR becomes `\n`
too, as Flutter breaks lines on `\n` only.

## Update info
zip archives must be called macos.zip or windows.zip to be caught by auto-updater

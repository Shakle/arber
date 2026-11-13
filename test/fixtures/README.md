# Legacy Excel compatibility fixture

`legacy_translations.xlsx` was created before migrating to `excel_community`,
using the former `excel` Git dependency at commit
`37e0807f97fe8c293bdf75441cf21413b322882d`.

`legacy_translations.expected.json` captures the ARB output of Arber with that
dependency. It preserves duplicate keys as raw ARB strings so the compatibility
test checks both their presence and JSON escaping.

The workbook contains English and Russian columns separated by an unnamed
column, ICU plurals, Unicode, quotes, newlines, duplicate keys, a missing
translation, numbers, a boolean, dates, a time and an uncached formula.

Keep these fixtures unchanged when updating the Excel dependency: they verify
that existing spreadsheets still produce the same translations.

# Excel for Mac line breaks fixture

`crlf_line_breaks.xlsx` stores line breaks the way Excel for Mac saves an
Alt+Enter: as raw CRLF bytes inside `xl/sharedStrings.xml` (plus one lone CR
and typed `\n` / `\r\n` escapes). `package:xml` keeps those CRs, so the test
checks that no CR reaches the generated ARB files. The workbook was written by
hand from the parts of `legacy_translations.xlsx` (relationships, styles) with
uncompressed entries, so the test can find the raw CRLF in the file without
unzipping it. Its texts are made up.

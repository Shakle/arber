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

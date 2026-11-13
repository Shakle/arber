/// Turns every line break in [text] into `\n`: CRLF and lone CR alike.
///
/// Excel for Mac stores a line break typed with Alt+Enter as raw CRLF in
/// `xl/sharedStrings.xml`. An XML parser must read it as `\n` (XML 1.0
/// §2.11), but `package:xml`, which `excel_community` reads sheets with, keeps
/// the CR. Flutter breaks lines on `\n` alone, and on the web a CR makes the
/// engine search the Noto fonts for a glyph of U+000D that none of them has.
String normalizeLineBreaks(String text) =>
    text.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

/// Like [normalizeLineBreaks], and also decodes the escapes `\r\n` and `\n`
/// typed into a cell as two characters each into a `\n`.
String decodeLineBreaks(String text) => normalizeLineBreaks(
  text.replaceAll(r'\r\n', '\n').replaceAll(r'\n', '\n'),
);

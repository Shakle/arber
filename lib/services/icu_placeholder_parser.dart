/// Extracts unique argument names from ICU messages in first occurrence order.
///
/// This reads message structure rather than validating translations. Incomplete
/// messages can still be exported for the localization tools to diagnose.
List<String> extractIcuPlaceholders(String text) {
  return _IcuPlaceholderParser(text).parse();
}

class _IcuPlaceholderParser {
  _IcuPlaceholderParser(this.text);

  final String text;
  final Set<String> _names = {};
  int _position = 0;

  static final _identifier = RegExp(r'\w+');
  static final _whitespace = RegExp(r'\s+');

  String get _current => _position < text.length ? text[_position] : '';

  List<String> parse() {
    _readMessage();
    return _names.toList();
  }

  void _readMessage({bool nested = false, bool plural = false}) {
    while (_position < text.length) {
      if (_current == "'") {
        _skipQuotedText(plural: plural);
      } else if (_current == '{') {
        _readArgument();
      } else if (_current == '}') {
        _position++;
        if (nested) return;
      } else {
        _position++;
      }
    }
  }

  void _readArgument() {
    _position++; // Opening argument brace.
    final name = _readIdentifier();
    if (name == null) return;
    _skipWhitespace();

    if (_current == '}') {
      _names.add(name);
      _position++;
      return;
    }
    if (_current != ',') return;

    _position++;
    final type = _readIdentifier();
    _skipWhitespace();
    if (type == null || (_current != ',' && _current != '}')) return;
    _names.add(name);

    if (_current == '}') {
      _position++;
      return;
    }
    _position++; // Comma before options or a formatting style.

    if (type == 'plural' || type == 'selectordinal' || type == 'select') {
      _readOptions(plural: type != 'select');
    } else {
      _skipStyle();
    }
  }

  void _readOptions({required bool plural}) {
    while (_position < text.length) {
      // Selectors, exact values and optional plural offsets are not arguments.
      while (_position < text.length && _current != '{' && _current != '}') {
        _position++;
      }
      if (_current == '}') {
        _position++;
        return;
      }
      if (_current == '{') {
        _position++; // A branch's brace encloses message text, not an argument.
        _readMessage(nested: true, plural: plural);
      }
    }
  }

  void _skipStyle() {
    var depth = 1;
    while (_position < text.length && depth > 0) {
      if (_current == "'") {
        _skipQuotedText(all: true);
      } else {
        if (_current == '{') depth++;
        if (_current == '}') depth--;
        _position++;
      }
    }
  }

  void _skipQuotedText({bool plural = false, bool all = false}) {
    _position++;
    if (_current == "'") {
      _position++; // Doubled apostrophes are literal, including before braces.
      return;
    }

    // ICU apostrophes start quoting only before syntax characters. Ordinary
    // contractions such as "It's {name}" must not hide the argument.
    if (!all &&
        _current != '{' &&
        _current != '}' &&
        !(plural && _current == '#')) {
      return;
    }

    while (_position < text.length) {
      if (_current == "'") {
        _position++;
        if (_current != "'") return;
      }
      _position++;
    }
  }

  String? _readIdentifier() {
    _skipWhitespace();
    final match = _identifier.matchAsPrefix(text, _position);
    if (match == null) return null;
    _position = match.end;
    return match.group(0);
  }

  void _skipWhitespace() {
    final match = _whitespace.matchAsPrefix(text, _position);
    if (match != null) _position = match.end;
  }
}

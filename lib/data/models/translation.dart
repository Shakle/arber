import 'dart:convert';

class Translation {
  final String key;
  final String translation;
  final String? description;
  final List<String> placeholders;

  const Translation({
    required this.key,
    required this.translation,
    this.description = '',
    this.placeholders = const [],
  });

  String toJson(bool isLast) {
    final metadata = const JsonEncoder.withIndent('  ')
        .convert({
          'description': description,
          if (placeholders.isNotEmpty)
            'placeholders': {
              for (final name in placeholders) name: <String, dynamic>{},
            },
        })
        .replaceAll('\n', '\n  ');

    return '  ${jsonEncode(key)}: ${jsonEncode(translation)},\n'
        '  ${jsonEncode('@$key')}: $metadata${isLast ? '' : ','}';
  }
}

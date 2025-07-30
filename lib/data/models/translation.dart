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
    String translationRow = '  "$key": "$translation"';
    String descriptionRow = '  "@$key": {\n    "description": "$description"';

    if (placeholders.isNotEmpty) {
      String placeholdersRow = '${placeholders.map((p) => '      "$p": {}')
          .join(',\n')}\n';
      descriptionRow += ',\n    "placeholders": {\n$placeholdersRow    }';
    }

    descriptionRow += '\n  }';
    String coma = isLast ? '' : ',';

    return '$translationRow,\n$descriptionRow$coma';
  }
}

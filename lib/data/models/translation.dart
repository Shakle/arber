class Translation {
  final String key;
  final String translation;
  final String? description;

  const Translation({
    required this.key,
    required this.translation,
    this.description = '',
  });

  String? toJson(bool isLast) {
    String translationRow = '"$key": "$translation"';
    String descriptionRow = '"@$key": {\n"description": "$description"\n}';
    String coma = isLast ? '' : ',';

    if (translation.isNotEmpty) {
      return '$translationRow,\n$descriptionRow$coma';
    } else {
      return null;
    }
  }
}

class MissingTranslation {
  String key;
  List<String> missingTranslations;

  MissingTranslation({
    required this.key,
    this.missingTranslations = const [],
  });
}

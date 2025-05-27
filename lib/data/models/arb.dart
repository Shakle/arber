import 'package:arber/data/models/translation.dart';

class Arb {
  final String locale;
  final List<Translation> translations;

  const Arb({
    required this.locale,
    this.translations = const [],
  });

  String toJson() {
    String localeString = '  "@@locale": "$locale"';
    String translationsString = '';

    translations.removeWhere((t) => t.translation.isEmpty);
    
    for (Translation translation in translations) {
      String ts = translation.toJson(translation == translations.last);
      translationsString += '$ts\n';
    }

    return translationsString.isEmpty
        ? '{\n$localeString\n}'
        : '{\n$localeString,\n$translationsString}';
  }
}

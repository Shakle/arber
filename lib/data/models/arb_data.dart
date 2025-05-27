import 'package:arber/data/models/missing_translation.dart';

class ArbData {
  ArbData({
    required this.missingKeys,
    required this.missingTranslations,
  });

  final List<String> missingKeys;
  final List<MissingTranslation> missingTranslations;
}

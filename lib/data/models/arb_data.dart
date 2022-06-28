import 'package:arber/data/models/missing_translation.dart';

class ArbData {
  final List<String> missingKeys;
  final List<MissingTranslation> missingTranslations;

  ArbData({
    required this.missingKeys,
    required this.missingTranslations,
  });
}
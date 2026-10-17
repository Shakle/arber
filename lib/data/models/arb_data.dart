import 'package:arber/data/models/missing_translation.dart';

class ArbData {
  ArbData({
    required this.missingKeys,
    required this.missingTranslations,
    this.missingArbKeys = const [],
    this.arbCompared = false,
  });

  final List<String> missingKeys;
  final List<MissingTranslation> missingTranslations;
  final List<String> missingArbKeys;
  final bool arbCompared;
}

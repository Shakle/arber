import 'dart:convert';

import 'package:arber/data/models/translation.dart';

class Arb {
  final String locale;
  final List<Translation> translations;

  const Arb({required this.locale, this.translations = const []});

  String toJson() {
    final buffer = StringBuffer('{\n  "@@locale": ${jsonEncode(locale)}');

    // Encode entries separately so duplicate Excel keys stay visible in ARB.
    for (final translation in translations) {
      if (translation.translation.isEmpty) continue;
      buffer
        ..write(',\n')
        ..write(translation.toJson(true));
    }

    buffer.write('\n}');
    return buffer.toString();
  }
}

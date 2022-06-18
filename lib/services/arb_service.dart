import 'dart:io';
import 'dart:typed_data';

import 'package:arber/data/models/arb.dart';
import 'package:arber/data/models/translation.dart';
import 'package:excel/excel.dart';

class ArbService {

  List<Arb> getArbs(String filePath) {
    Sheet? sheet = _getExcelSheet(filePath);
    int firstTranslationIndex = 2;

    List<Arb> arbs = [];

    if (sheet != null) {
      arbs = _createEmptyArbs(sheet, firstTranslationIndex);

      // Walk through rows
      for (int i = 1; i < sheet.rows.length; i++) {
        String key = sheet.rows[i].first?.value ?? '';
        String description = sheet.rows[i][1]?.value.toString() ?? '';

        // Walk through columns
        for (int c = firstTranslationIndex; c < sheet.rows[i].length; c++) {
          Translation translation = _getTranslation(
            key: key,
            translation: sheet.rows[i][c]?.value.toString() ?? '',
            description: description,
          );

          arbs[c - firstTranslationIndex].translations.add(translation);
        }
      }
    }

    return arbs;
  }

  List<Arb> _createEmptyArbs(Sheet sheet, int firstTranslationIndex) {
    List<Arb> arbs = [];

    for (int i = firstTranslationIndex; i < sheet.rows.first.length; i++) {
      String locale = sheet.rows.first[i]?.value;
      arbs.add(
        Arb(
          locale: locale,
          translations: [],
        ),
      );
    }

    return arbs;
  }

  Translation _getTranslation({
    required String key,
    required String translation,
    String? description,
  }) {
    return Translation(
        key: key,
        translation: translation,
        description: description,
    );
  }

  Sheet? _getExcelSheet(String filePath) {
    Uint8List bytes = File(filePath).readAsBytesSync();
    Excel excel = Excel.decodeBytes(bytes);
    return excel.tables[excel.tables.keys.first];
  }
}
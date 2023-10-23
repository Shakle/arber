import 'dart:io';
import 'dart:typed_data';

import 'package:arber/data/models/arb.dart';
import 'package:arber/data/models/arb_data.dart';
import 'package:arber/data/models/missing_translation.dart';
import 'package:arber/data/models/translation.dart';
import 'package:excel/excel.dart';

class ArbService {

  final int firstTranslationIndex = 2;

  ArbData getArbExcelDifference(List<String> paths) {
    Sheet? sheet = _getExcelSheet(paths[0]);
    String arbPath = paths[1];

    if (sheet == null) {
      throw Exception('Excel file can\'t be read');
    }

    List<String> excelTranslationKeys = _getExcelTranslationKeys(sheet);

    List<String> missingKeys = [
      if (arbPath.trim().isNotEmpty)
        ..._getArbTranslationKeys(paths[1])
          .where((key) => !excelTranslationKeys.contains(key)),
    ];

    return ArbData(
        missingKeys: missingKeys,
        missingTranslations: _getMissingTranslations(sheet),
    );
  }

  List<MissingTranslation> _getMissingTranslations(Sheet sheet) {
    List<MissingTranslation> missingTranslations = [];

    for (int i = 1; i < sheet.rows.length; i++) {
      SharedString? key = sheet.rows[i].first?.value;

      if (key == null || key.node.text.trim().isEmpty) {
        continue;
      }

      List<String> translationKeys = [];

      for (int c = firstTranslationIndex; c < sheet.rows[i].length; c++) {
        dynamic data = sheet.rows[i][c]?.value;

        String? value = data != null && data is SharedString
            ? sheet.rows[i][c]?.value.node.text
            : null;

        SharedString lang = sheet.rows[0][c]?.value;

        if (value?.trim().isEmpty ?? true) {
          translationKeys.add(lang.node.text);
        }
      }

      if (translationKeys.isNotEmpty) {
        missingTranslations.add(
          MissingTranslation(
            key: key.node.text,
            missingTranslations: translationKeys,
          ),
        );
      }
    }

    return missingTranslations;
  }

  List<String> _getExcelTranslationKeys(Sheet sheet) {
    List<String> excelTranslationKeys = [];

    for (List<Data?> data in sheet.rows) {
      if (data.first != null && data.first!.value is SharedString) {
        SharedString sharedString = data.first!.value;
        if (sharedString.node.text.trim().isNotEmpty) {
          excelTranslationKeys.add(sharedString.node.text);
        }
      }
    }

    return excelTranslationKeys;
  }

  List<String> _getArbTranslationKeys(String arbFilePath) {
    List<String> arbTranslationKeys = [];

    File arbFile = File(arbFilePath);
    List<String> arbLines = arbFile.readAsLinesSync();

    arbLines.removeWhere((r) {
      bool isStartOrEnd = r.contains('{') || r.contains('}');
      bool isLocale = r.contains('@@');
      bool isDescription = r.contains('"description"');

      return isStartOrEnd || isLocale || isDescription;
    });

    for (String arbLine in arbLines) {
      String key = arbLine.split('"')[1];
      arbTranslationKeys.add(key);
    }

    return arbTranslationKeys;
  }

  List<Arb> getArbs(String excelPath) {
    Sheet? sheet = _getExcelSheet(excelPath);
    List<Arb> arbs = [];

    if (sheet != null) {
      arbs = _createEmptyArbs(sheet, firstTranslationIndex);

      // Walk through rows
      for (int i = 1; i < sheet.rows.length; i++) {
        SharedString? key = sheet.rows[i].first?.value;

        if (key == null) {
          continue;
        }

        String description = sheet.rows[i][1]?.value.node.text ?? '';

        // Walk through columns
        for (int c = firstTranslationIndex; c < sheet.rows[i].length; c++) {
          dynamic value = sheet.rows[i][c]?.value;

          if (value == null || value.toString().trim().isEmpty) {
            continue;
          }

          String text = value is SharedString
              ? value.node.text
              : value.toString();

          Translation translation = Translation(
            key: key.node.text,
            translation: text
                .replaceAll('\r', '')
                .replaceAll('\n', r'\n'),
            description: description
                .replaceAll('\r', '')
                .replaceAll('\n', r'\n'),
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
      SharedString locale = sheet.rows.first[i]?.value;
      arbs.add(
        Arb(
          locale: locale.node.text,
          translations: [],
        ),
      );
    }

    return arbs;
  }

  Sheet? _getExcelSheet(String filePath) {
    Uint8List bytes = File(filePath).readAsBytesSync();
    Excel excel = Excel.decodeBytes(bytes);
    return excel.tables[excel.tables.keys.first];
  }
}
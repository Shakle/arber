import 'dart:io';
import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:arber/data/models/arb.dart';
import 'package:arber/data/models/arb_data.dart';
import 'package:arber/data/models/missing_translation.dart';
import 'package:arber/data/models/translation.dart';

class ArbService {
  final int firstTranslationIndex = 2;

  ArbData getArbExcelDifference(List<String> paths) {
    final Sheet? sheet = _getExcelSheet(paths[0]);
    final String arbPath = paths[1].trim();

    if (sheet == null) {
      throw Exception('Excel file can\'t be read');
    }

    final excelTranslationKeys = _getExcelTranslationKeys(sheet);
    final List<String> missingKeys = arbPath.isNotEmpty
        ? _getArbTranslationKeys(arbPath)
        .where((k) => !excelTranslationKeys.contains(k))
        .toList()
        : <String>[];

    return ArbData(
      missingKeys: missingKeys,
      missingTranslations: _getMissingTranslations(sheet),
    );
  }

  List<MissingTranslation> _getMissingTranslations(Sheet sheet) {
    final List<MissingTranslation> missingTranslations = [];

    // Skip header row
    for (var row in sheet.rows.skip(1)) {
      final String? keyText = _cellValueToString(row.first?.value);
      if (keyText?.trim().isEmpty ?? true) continue;

      final List<String> localesMissing = [];
      for (var c = firstTranslationIndex; c < row.length; c++) {
        final String? cellText = _cellValueToString(row[c]?.value);
        if (cellText?.trim().isEmpty ?? true) {
          final String? locale = _cellValueToString(sheet.rows[0][c]?.value);
          if (locale != null) localesMissing.add(locale);
        }
      }

      if (localesMissing.isNotEmpty) {
        missingTranslations.add(
          MissingTranslation(
            key: keyText!,
            missingTranslations: localesMissing,
          ),
        );
      }
    }

    return missingTranslations;
  }

  List<String> _getExcelTranslationKeys(Sheet sheet) {
    return sheet.rows
        .map((row) => _cellValueToString(row.first?.value))
        .where((key) => key != null && key.trim().isNotEmpty)
        .cast<String>()
        .toList();
  }

  List<String> _getArbTranslationKeys(String arbFilePath) {
    final List<String> arbTranslationKeys = [];

    final File arbFile = File(arbFilePath);
    final List<String> arbLines = arbFile
        .readAsLinesSync()
      ..removeWhere((r) {
        return r.contains('{') || r.contains('}') ||
            r.contains('@@')   || r.contains('"description"');
      });

    for (final line in arbLines) {
      final key = line.split('"')[1];
      arbTranslationKeys.add(key);
    }

    return arbTranslationKeys;
  }

  List<Arb> getArbs(String excelPath) {
    final Sheet? sheet = _getExcelSheet(excelPath);
    if (sheet == null) return [];

    final arbs = _createEmptyArbs(sheet, firstTranslationIndex);

    for (var row in sheet.rows.skip(1)) {
      final String? keyText = _cellValueToString(row.first?.value);
      if (keyText == null) continue;

      final String description =
          _cellValueToString(row[1]?.value) ?? '';

      for (var c = firstTranslationIndex; c < row.length; c++) {
        final String? rawText = _cellValueToString(row[c]?.value);
        if (rawText?.trim().isEmpty ?? true) continue;

        final text = rawText!.replaceAll('\r', '').replaceAll('\n', r'\n');
        final placeholders = _extractPlaceholders(text);

        arbs[c - firstTranslationIndex].translations.add(
          Translation(
            key: keyText,
            translation: text,
            description: description.replaceAll('\r', '').replaceAll('\n', r'\n'),
            placeholders: placeholders,
          ),
        );
      }
    }

    return arbs;
  }

  List<String> _extractPlaceholders(String text) {
    final exp = RegExp(r'\{(\w+)\}');
    return exp.allMatches(text).map((m) => m.group(1)!).toList();
  }

  List<Arb> _createEmptyArbs(Sheet sheet, int firstTranslationIndex) {
    return [
      for (var i = firstTranslationIndex; i < sheet.rows.first.length; i++)
        Arb(locale: _cellValueToString(sheet.rows.first[i]?.value)!, translations: [])
    ];
  }

  Sheet? _getExcelSheet(String filePath) {
    final Uint8List bytes = File(filePath).readAsBytesSync();
    final Excel excel = Excel.decodeBytes(bytes);
    return excel.tables[excel.tables.keys.first];
  }

  /// Converts any CellValue subtype to its String representation.
  String? _cellValueToString(CellValue? cell) {
    if (cell == null) return null;
    if (cell is TextCellValue) {
      return cell.value.text ?? '';
    } else if (cell is IntCellValue) {
      return cell.value.toString();
    } else if (cell is DoubleCellValue) {
      return cell.value.toString();
    } else if (cell is BoolCellValue) {
      return cell.value.toString();
    } else if (cell is DateCellValue) {
      return cell.asDateTimeLocal().toIso8601String();
    } else if (cell is DateTimeCellValue) {
      return cell.asDateTimeLocal().toIso8601String();
    } else if (cell is TimeCellValue) {
      return cell.asDuration().toString();
    } else if (cell is FormulaCellValue) {
      // Use the last calculated result
      return cell.formula;
    }
    // Fallback
    return cell.toString();
  }
}

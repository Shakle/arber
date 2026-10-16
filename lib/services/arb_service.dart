import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:arber/data/models/arb.dart';
import 'package:arber/data/models/arb_data.dart';
import 'package:arber/data/models/missing_translation.dart';
import 'package:arber/data/models/translation.dart';
import 'package:arber/services/icu_placeholder_parser.dart';

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
    final locales = _getLocaleColumns(sheet);

    // Skip header row
    for (var row in sheet.rows.skip(1)) {
      final String? keyText = _cellValueToString(row.firstOrNull?.value);
      if (keyText?.trim().isEmpty ?? true) continue;

      final List<String> localesMissing = [];
      for (final entry in locales.entries) {
        final String? cellText = entry.key < row.length
            ? _cellValueToString(row[entry.key]?.value)
            : null;
        if (cellText?.trim().isEmpty ?? true) {
          localesMissing.add(entry.value);
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
        .skip(1)
        .map((row) => _cellValueToString(row.firstOrNull?.value))
        .where((key) => key != null && key.trim().isNotEmpty)
        .cast<String>()
        .toList();
  }

  List<String> _getArbTranslationKeys(String arbFilePath) {
    final decoded = jsonDecode(File(arbFilePath).readAsStringSync());
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('ARB file must contain a JSON object');
    }

    return decoded.keys.where((key) => !key.startsWith('@')).toList();
  }

  List<Arb> getArbs(String excelPath) {
    final Sheet? sheet = _getExcelSheet(excelPath);
    if (sheet == null) return [];

    final arbs = {
      for (final entry in _getLocaleColumns(sheet).entries)
        entry.key: Arb(locale: entry.value, translations: []),
    };

    for (var row in sheet.rows.skip(1)) {
      final String? keyText = _cellValueToString(row.firstOrNull?.value);
      if (keyText == null || keyText.trim().isEmpty) continue;

      final String description = row.length > 1
          ? _cellValueToString(row[1]?.value) ?? ''
          : '';

      for (final entry in arbs.entries) {
        final String? rawText = entry.key < row.length
            ? _cellValueToString(row[entry.key]?.value)
            : null;
        if (rawText?.trim().isEmpty ?? true) continue;

        final text = rawText!;
        final placeholders = extractIcuPlaceholders(text);

        entry.value.translations.add(
          Translation(
            key: keyText,
            translation: text,
            description: description,
            placeholders: placeholders,
          ),
        );
      }
    }

    return arbs.values.toList();
  }

  Map<int, String> _getLocaleColumns(Sheet sheet) {
    final header = sheet.rows.firstOrNull;
    if (header == null) return {};

    final locales = <int, String>{};
    for (var column = firstTranslationIndex; column < header.length; column++) {
      final locale = _cellValueToString(header[column]?.value)?.trim();
      if (locale != null && locale.isNotEmpty) {
        locales[column] = locale;
      }
    }
    return locales;
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

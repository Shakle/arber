import 'package:shared_preferences/shared_preferences.dart';

class StorageService {

  static late final SharedPreferences sharedPrefs;

  final String _excelPath = 'excel_path';
  final String _l10nPath = 'l10n_path';
  final String _mainArbPath = 'main_arb_path';

  Future<void> saveExcelPath(String path) async {
    await sharedPrefs.setString(_excelPath, path);
  }

  Future<void> removeExcelPath() async {
    await sharedPrefs.remove(_excelPath);
  }

  Future<void> saveL10nPath(String path) async {
    await sharedPrefs.setString(_l10nPath, path);
  }

  Future<void> removeL10nPath() async {
    await sharedPrefs.remove(_l10nPath);
  }

  Future<void> saveMainArbPath(String path) async {
    await sharedPrefs.setString(_mainArbPath, path);
  }

  Future<void> removeMainArbPath() async {
    await sharedPrefs.remove(_mainArbPath);
  }

  String getExcelPath() => sharedPrefs.getString(_excelPath) ?? '';

  String getL10nPath() => sharedPrefs.getString(_l10nPath) ?? '';

  String getMainArbPath() => sharedPrefs.getString(_mainArbPath) ?? '';
}
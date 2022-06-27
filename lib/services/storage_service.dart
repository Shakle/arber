import 'package:shared_preferences/shared_preferences.dart';

class StorageService {

  static late final SharedPreferences sharedPrefs;

  final String _excelPath = 'excel_path';
  final String _l10nPath = 'l10n_path';
  final String _mainArbPath = 'main_arb_path';

  Future<void> saveExcelPath(String path) async {
    sharedPrefs.setString(_excelPath, path);
  }

  Future<void> saveL10nPath(String path) async {
    sharedPrefs.setString(_l10nPath, path);
  }

  Future<void> saveMainArbPath(String path) async {
    sharedPrefs.setString(_mainArbPath, path);
  }

  Future<String> getExcelPath() async {
    return sharedPrefs.getString(_excelPath) ?? '';
  }

  Future<String> getL10nPath() async {
    return sharedPrefs.getString(_l10nPath) ?? '';
  }

  Future<String> getMainArbPath() async {
    return sharedPrefs.getString(_mainArbPath) ?? '';
  }
}
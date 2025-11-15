import 'dart:convert';

import 'package:arber/data/enums.dart';
import 'package:arber/data/models/bookmark.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {

  final SharedPreferencesAsync _sharedPrefs = SharedPreferencesAsync();

  final String _excelPath = 'excel_path';
  final String _l10nPath = 'l10n_path';
  final String _mainArbPath = 'main_arb_path';
  String _bookMarkPath(ArtifactType id) => 'bookmark_${id.name}';

  Future<void> saveExcelPath(String path) async {
    await _sharedPrefs.setString(_excelPath, path);
  }

  Future<void> removeExcelPath() async {
    await _sharedPrefs.remove(_excelPath);
  }

  Future<void> saveL10nPath(String path) async {
    await _sharedPrefs.setString(_l10nPath, path);
  }

  Future<void> removeL10nPath() async {
    await _sharedPrefs.remove(_l10nPath);
  }

  Future<void> saveMainArbPath(String path) async {
    await _sharedPrefs.setString(_mainArbPath, path);
  }

  Future<void> removeMainArbPath() async {
    await _sharedPrefs.remove(_mainArbPath);
  }

  Future<String> getExcelPath() async {
    return await _sharedPrefs.getString(_excelPath) ?? '';
  }

  Future<String> getL10nPath() async {
    return await _sharedPrefs.getString(_l10nPath) ?? '';
  }

  Future<String> getMainArbPath() async {
    return await _sharedPrefs.getString(_mainArbPath) ?? '';
  }

  Future<void> saveBookmark(Bookmark bookmark) async {
    String json = jsonEncode(bookmark.toJson());
    await _sharedPrefs.setString(_bookMarkPath(bookmark.id), json);
  }

  Future<Bookmark?> getBookmark(ArtifactType id) async {
    String? json = await _sharedPrefs.getString(_bookMarkPath(id));
    return json != null ? Bookmark.fromJson(jsonDecode(json)) : null;
  }

  Future<List<Bookmark>> getAllBookmarks() async {
    List<Bookmark?> bookmarks = await Future.wait(
        ArtifactType.values.map(getBookmark),
    );

    return bookmarks.whereType<Bookmark>().toList();
  }

}

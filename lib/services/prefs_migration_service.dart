import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

/// One-time migration of preferences out of the macOS App Sandbox container.
///
/// Dropping App Sandbox (required for self-updating) moves NSUserDefaults from
/// `~/Library/Containers/<bundle>/Data/Library/Preferences/` to
/// `~/Library/Preferences/`, so previously saved paths would silently vanish.
/// This copies them across on first launch of an unsandboxed build.
///
/// Security-scoped bookmarks are deliberately not migrated: they only mean
/// something inside a sandbox, and an unsandboxed app reads those folders
/// directly.
class PrefsMigrationService {

  static const String _bundleId = 'com.shakle.arber';
  static const String _migratedFlag = 'migrated_from_sandbox_container';

  static const List<String> _keys = [
    'excel_path',
    'l10n_path',
    'main_arb_path',
  ];

  final SharedPreferencesAsync _sharedPrefs = SharedPreferencesAsync();

  Future<void> migrate() async {
    if (!Platform.isMacOS) return;
    if (await _sharedPrefs.getBool(_migratedFlag) ?? false) return;

    final File container = File(
      '${Platform.environment['HOME']}/Library/Containers/$_bundleId'
      '/Data/Library/Preferences/$_bundleId.plist',
    );

    // Nothing to carry over: a fresh install, or already-unsandboxed prefs.
    if (!container.existsSync()) {
      await _sharedPrefs.setBool(_migratedFlag, true);
      return;
    }

    for (final String key in _keys) {
      // Never overwrite a value the unsandboxed build already has.
      if (await _sharedPrefs.getString(key) != null) continue;

      final String? value = await _read(key, container.path);
      if (value != null && value.isNotEmpty) {
        await _sharedPrefs.setString(key, value);
      }
    }

    await _sharedPrefs.setBool(_migratedFlag, true);
  }

  /// Reads a single string from a binary plist. `plutil` ships with macOS, so
  /// this needs no plist parser on the Dart side.
  Future<String?> _read(String key, String plistPath) async {
    try {
      final ProcessResult result = await Process.run('/usr/bin/plutil', [
        '-extract',
        key,
        'raw',
        '-o',
        '-',
        plistPath,
      ]);

      if (result.exitCode != 0) return null;
      return (result.stdout as String).trim();
    } catch (_) {
      // A failed migration must never block startup.
      return null;
    }
  }
}

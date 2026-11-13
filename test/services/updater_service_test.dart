import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:arber/services/updater_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('encodePowerShellCommand', () {
    test('is base64 of the script in UTF-16LE', () {
      const script = "Write-Log 'Grüße aus Ludwigshafen' # ✓\n\$x = 1";
      final Uint8List bytes = base64Decode(encodePowerShellCommand(script));
      final ByteData data = ByteData.sublistView(bytes);

      final decoded = String.fromCharCodes([
        for (int i = 0; i < bytes.length; i += 2)
          data.getUint16(i, Endian.little),
      ]);

      expect(decoded, script);
    });
  });

  group('swapBundle', () {
    late Directory root;

    setUp(() => root = Directory.systemTemp.createTempSync('arber_swap_test_'));
    tearDown(() => root.deleteSync(recursive: true));

    /// A fake bundle at [path] under [root] whose `version` file says [version].
    String bundle(String path, String version) {
      final Directory directory = Directory('${root.path}/$path')
        ..createSync(recursive: true);
      File('${directory.path}/version').writeAsStringSync(version);
      return directory.path;
    }

    String versionAt(String path) => File('$path/version').readAsStringSync();

    test('puts the new bundle in place and keeps the old one aside', () async {
      final String target = bundle('Applications/arber.app', 'old');
      final String source = bundle('staging/arber.app', 'new');

      await UpdaterService.swapBundle(source: source, target: target);

      expect(versionAt(target), 'new');
      expect(versionAt(UpdaterService.previousBundlePath(target)), 'old');
      expect(Directory(source).existsSync(), isFalse);
    });

    test('replaces a bundle an earlier update left behind', () async {
      final String target = bundle('Applications/arber.app', 'old');
      bundle('Applications/arber.app.old', 'older');
      final String source = bundle('staging/arber.app', 'new');

      await UpdaterService.swapBundle(source: source, target: target);

      expect(versionAt(target), 'new');
      expect(versionAt(UpdaterService.previousBundlePath(target)), 'old');
    });

    test('keeps the old version when the new one cannot be moved', () async {
      final String target = bundle('Applications/arber.app', 'old');

      await expectLater(
        UpdaterService.swapBundle(
          source: '${root.path}/staging/missing.app',
          target: target,
        ),
        throwsA(isA<UpdaterException>()),
      );

      expect(versionAt(target), 'old');
      expect(
        Directory(UpdaterService.previousBundlePath(target)).existsSync(),
        isFalse,
      );
    });

    test('removePreviousBundle deletes the bundle left behind', () async {
      final String target = bundle('Applications/arber.app', 'new');
      bundle('Applications/arber.app.old', 'old');

      await UpdaterService.removePreviousBundle(target);

      expect(
        Directory(UpdaterService.previousBundlePath(target)).existsSync(),
        isFalse,
      );
      expect(versionAt(target), 'new');
    });
  });

  group('windowsInstallScript', () {
    final String script = UpdaterService.windowsInstallScript(
      appPid: 4242,
      source: r"C:\Users\O'Neil\AppData\Local\Temp\arber_update_1\arber",
      target: r'C:\Tools\Arber',
      staging: r"C:\Users\O'Neil\AppData\Local\Temp\arber_update_1",
    );

    test('quotes the paths as PowerShell literals', () {
      expect(
        script,
        contains(
          r"$source = 'C:\Users\O''Neil\AppData\Local\Temp\arber_update_1\arber'",
        ),
      );
      expect(script, contains(r"$target = 'C:\Tools\Arber'"));
      expect(
        script,
        contains(
          r"$log = 'C:\Users\O''Neil\AppData\Local\Temp\arber_update_1\install.log'",
        ),
      );
    });

    test('waits for this app and starts the new one', () {
      expect(script, contains(r'$appPid = 4242'));
      expect(script, contains(r'Wait-Process -Id $appPid'));
      expect(script, contains(r"Join-Path $target 'arber.exe'"));
      expect(script, contains(r'Start-Process -FilePath $app'));
    });

    test('runs robocopy hidden and retries a locked file for 30 s only', () {
      expect(
        script,
        contains("Start-Process -FilePath 'robocopy.exe' -WindowStyle Hidden"),
      );
      expect(script, contains("'/R:30', '/W:1'"));
    });

    test('starts no console program other than through Start-Process', () {
      // A console program started directly from the console-less script would
      // open a console window of its own.
      for (final String program in ['cmd', 'tasklist', 'ping', 'findstr']) {
        expect(script, isNot(contains(program)));
      }
    });
  });
}

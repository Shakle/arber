import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

/// Replaces the running application with a freshly downloaded build.
///
/// On Windows the files of a running app are locked, so a detached helper
/// script waits for this process to exit, mirrors the new build over the
/// install folder and starts it. On macOS this process swaps the bundles
/// itself while it still runs ([swapBundle]), and the helper only reopens the
/// app. The helper outlives the app on purpose.
///
/// macOS note: this requires the app to run **without** App Sandbox, otherwise
/// it cannot touch `/Applications`.
class UpdaterService {

  /// Unpacks [archivePath] and hands control to the install helper. On success
  /// this never returns — the process exits so the helper can swap the bundle.
  ///
  /// Throws [UpdaterException] with a user-readable message if the update
  /// cannot be applied; the downloaded archive is left untouched so the user
  /// can still install it by hand.
  Future<Never> installAndRestart(String archivePath) async {
    final Directory staging = await Directory.systemTemp.createTemp(
      'arber_update_',
    );

    await _unpack(archivePath, staging);

    final String source = await _locateNewBuild(staging);
    final String target = _currentInstallPath();

    await _ensureWritable(target);

    if (Platform.isMacOS) {
      await swapBundle(source: source, target: target);
    }

    final File helper = await _writeHelper(
      staging: staging,
      source: source,
      target: target,
    );

    if (Platform.isWindows) {
      // A detached process has no console, and the script starts robocopy
      // hidden, so no console window shows up. The script goes in as
      // -EncodedCommand: a script file is subject to the execution policy,
      // which managed machines often restrict. install.ps1 stays for reference.
      await Process.start(
        'powershell.exe',
        [
          '-NoProfile',
          '-NonInteractive',
          '-WindowStyle',
          'Hidden',
          '-EncodedCommand',
          encodePowerShellCommand(helper.readAsStringSync()),
        ],
        mode: ProcessStartMode.detached,
        // Not the staging folder: the script deletes it once it is done.
        workingDirectory: Directory.systemTemp.path,
      );
    } else {
      await Process.start(
        '/bin/sh',
        [helper.path],
        mode: ProcessStartMode.detached,
        workingDirectory: staging.path,
      );
    }

    // Hand over to the helper. Anything after this is unreachable.
    exit(0);
  }

  /// Puts the bundle at [source] in place of the bundle at [target], keeping
  /// the old one at [previousBundlePath] until the new version deletes it on
  /// start ([tidyUpInstall]).
  ///
  /// This runs in the app itself, before it quits: macOS lets an app replace
  /// bundles signed by its own team. Done by a helper after the app has quit,
  /// the change is not attributed to the app, and macOS stops it until the user
  /// allows the app under App Management in Privacy & Security. Moving the
  /// running app's bundle is safe: the process keeps the files it has open.
  static Future<void> swapBundle({
    required String source,
    required String target,
  }) async {
    final Directory previous = Directory(previousBundlePath(target));
    if (previous.existsSync()) previous.deleteSync(recursive: true);

    await Directory(target).rename(previous.path);
    try {
      await _moveBundle(source: source, target: target);
    } catch (e) {
      // Put the working version back rather than leaving nothing installed.
      final Directory partial = Directory(target);
      if (partial.existsSync()) partial.deleteSync(recursive: true);
      await previous.rename(target);
      throw UpdaterException('Could not install the update.\n$e'.trim());
    }

    if (Platform.isMacOS) {
      // An archive the app downloads itself has no quarantine flag, but clear
      // it anyway, so that macOS does not ask before the first start.
      await Process.run('/usr/bin/xattr', ['-dr', 'com.apple.quarantine', target]);
    }
  }

  /// Renames [source] to [target], or copies it there when the two are on
  /// different volumes (the staging folder is on the system one).
  static Future<void> _moveBundle({
    required String source,
    required String target,
  }) async {
    try {
      await Directory(source).rename(target);
    } on FileSystemException {
      // ditto keeps symlinks, permissions and the code signature intact.
      final ProcessResult result = await Process.run('/usr/bin/ditto', [
        source,
        target,
      ]);
      if (result.exitCode != 0) {
        throw UpdaterException('${result.stderr}'.trim());
      }
    }
  }

  /// Where [swapBundle] keeps the replaced bundle of [target].
  static String previousBundlePath(String target) => '$target.old';

  /// Tidies up the install on start: deletes the bundle an update left next to
  /// this app ([swapBundle]) and renames a bundle still called `arber.app`
  /// ([renameLegacyBundle]). By now the old version has quit, and macOS lets
  /// the app change bundles of its own team. Never throws.
  static Future<void> tidyUpInstall() async {
    if (!Platform.isMacOS) return;
    try {
      // <bundle>.app/Contents/MacOS/<executable>
      final String bundle = File(Platform.resolvedExecutable).parent.parent.parent.path;
      if (!bundle.endsWith('.app')) return;

      try {
        await removePreviousBundle(bundle);
      } catch (_) {
        // Only disk space is at stake; the next start tries again.
      }
      await renameLegacyBundle(bundle);
    } catch (_) {
      // Only the name Finder and the Dock show is at stake; the next start
      // tries again.
    }
  }

  /// Deletes the bundle [swapBundle] left next to the bundle at [bundle].
  static Future<void> removePreviousBundle(String bundle) async {
    final Directory previous = Directory(previousBundlePath(bundle));
    if (await previous.exists()) await previous.delete(recursive: true);
  }

  /// The bundle's name before the app was called Arber. An update keeps the
  /// name of the bundle it replaces ([swapBundle]), so installs that update
  /// themselves stay `arber.app` until [renameLegacyBundle] renames them.
  static const String _legacyBundleName = 'arber.app';
  static const String _bundleName = 'Arber.app';

  /// Renames the bundle at [bundle] from `arber.app` to `Arber.app`, the name
  /// Finder and the Dock show, and returns where the bundle is afterwards. A
  /// bundle with any other name is left alone: the user may have chosen it.
  ///
  /// Only on a case-insensitive volume, where the old path still leads to the
  /// bundle: the running app keeps loading its resources through that path.
  static Future<String> renameLegacyBundle(String bundle) async {
    // The real path has the name as it is on disk, whatever case [bundle] has.
    final String current = await Directory(bundle).resolveSymbolicLinks();
    final int slash = current.lastIndexOf('/');
    if (current.substring(slash + 1) != _legacyBundleName) return bundle;

    final Directory renamed = Directory('${current.substring(0, slash)}/$_bundleName');
    // On a case-sensitive volume this is either missing or another bundle.
    if (!await renamed.exists() || await renamed.resolveSymbolicLinks() != current) {
      return bundle;
    }

    await Directory(current).rename(renamed.path);
    return renamed.path;
  }

  Future<void> _unpack(String archivePath, Directory destination) async {
    final ProcessResult result = Platform.isWindows
        // Expand-Archive is the only unzip guaranteed to be present.
        ? await Process.run('powershell.exe', [
            '-NoProfile',
            '-NonInteractive',
            '-Command',
            'Expand-Archive -LiteralPath ${_psQuote(archivePath)} '
                '-DestinationPath ${_psQuote(destination.path)} -Force',
          ])
        // ditto keeps symlinks, permissions and the code signature intact,
        // which plain unzip does not do for .app bundles.
        : await Process.run('/usr/bin/ditto', [
            '-x',
            '-k',
            archivePath,
            destination.path,
          ]);

    if (result.exitCode != 0) {
      throw UpdaterException(
        'Could not unpack the downloaded archive.\n${result.stderr}'.trim(),
      );
    }
  }

  /// Finds the unpacked build inside [staging]. Release archives sometimes wrap
  /// their payload in an extra folder, so one nested level is searched too.
  Future<String> _locateNewBuild(Directory staging) async {
    for (final Directory root in [staging, ...await _subdirectories(staging)]) {
      for (final FileSystemEntity entity in root.listSync()) {
        if (Platform.isMacOS) {
          if (entity is Directory && entity.path.endsWith('.app')) {
            return entity.path;
          }
        } else if (entity is File &&
            entity.uri.pathSegments.last.toLowerCase() == _windowsExecutable) {
          // On Windows the whole install folder is replaced, not a single file.
          return root.path;
        }
      }
    }

    throw UpdaterException(
      'The archive does not contain a ${Platform.isMacOS ? '.app bundle' : _windowsExecutable}.',
    );
  }

  Future<List<Directory>> _subdirectories(Directory root) async {
    return root.listSync().whereType<Directory>().toList();
  }

  /// Location that has to be replaced: the `.app` bundle on macOS, the folder
  /// holding the executable on Windows.
  String _currentInstallPath() {
    final File executable = File(Platform.resolvedExecutable);

    if (!Platform.isMacOS) return executable.parent.path;

    // <bundle>.app/Contents/MacOS/<executable>
    final Directory bundle = executable.parent.parent.parent;
    if (!bundle.path.endsWith('.app')) {
      throw UpdaterException(
        'Cannot locate the application bundle (running from ${executable.path}).',
      );
    }

    // While the quarantine flag is still set, Gatekeeper runs the app from a
    // read-only nullfs mount under AppTranslocation, so the bundle cannot be
    // replaced in place. Moving the app in Finder clears quarantine and stops
    // translocation.
    if (bundle.path.contains('/AppTranslocation/')) {
      throw const UpdaterException(
        'Arber is running from a temporary read-only copy, because macOS has '
        'not cleared its quarantine flag yet.\n'
        'Move Arber into your Applications folder using Finder, reopen it from '
        'there, and update again.',
      );
    }

    return bundle.path;
  }

  /// The helper runs unprivileged, so it can only swap the bundle if the
  /// containing folder is writable. Failing here keeps the app intact.
  Future<void> _ensureWritable(String target) async {
    final Directory parent = File(target).parent;

    try {
      File('${parent.path}${Platform.pathSeparator}.arber_update_probe')
        ..writeAsStringSync('')
        ..deleteSync();
    } catch (_) {
      throw UpdaterException(
        'No permission to update the app in ${parent.path}.\n'
        'Move the app somewhere writable, or install the downloaded archive '
        'manually.',
      );
    }
  }

  Future<File> _writeHelper({
    required Directory staging,
    required String source,
    required String target,
  }) async {
    final File helper = File(
      '${staging.path}${Platform.pathSeparator}'
      '${Platform.isWindows ? 'install.ps1' : 'install.sh'}',
    )..writeAsStringSync(
      Platform.isWindows
          ? windowsInstallScript(
              appPid: pid,
              source: source,
              target: target,
              staging: staging.path,
            )
          : _macosHelper(target: target),
    );

    if (!Platform.isWindows) {
      await Process.run('/bin/chmod', ['+x', helper.path]);
    }

    return helper;
  }

  /// The new bundle is already in place ([swapBundle]): the helper only waits
  /// for this process to quit and opens the new version. It must not touch any
  /// bundle, or macOS would ask for App Management access.
  String _macosHelper({required String target}) {
    return '''
#!/bin/sh
# Generated by arber's updater. The app has already swapped its bundle: wait
# for it to quit, then open the new version.
PID=$pid
TARGET=${_shQuote(target)}

while kill -0 "\$PID" 2>/dev/null; do sleep 0.2; done
open "\$TARGET"
''';
  }

  /// The PowerShell script that installs the update on Windows: waits for the
  /// app ([appPid]) to quit, mirrors [source] over [target] and starts the new
  /// version. It runs without a console, so it reports problems in a message
  /// box and in `install.log` inside [staging], which it deletes on success.
  static String windowsInstallScript({
    required int appPid,
    required String source,
    required String target,
    required String staging,
  }) {
    final String log = '$staging\\install.log';

    return '''
# Generated by arber's updater. Runs without a console window: waits for the
# app to quit, mirrors the new build over the install folder and starts it.
\$ErrorActionPreference = 'Stop'
\$appPid = $appPid
\$source = ${_psQuote(source)}
\$target = ${_psQuote(target)}
\$staging = ${_psQuote(staging)}
\$log = ${_psQuote(log)}
\$app = Join-Path \$target '$_windowsExecutable'

function Write-Log([string] \$message) {
  try { Add-Content -LiteralPath \$log -Value "\$(Get-Date -Format o) \$message" } catch {}
}

try {
  Wait-Process -Id \$appPid -Timeout 60 -ErrorAction SilentlyContinue
  Start-Sleep -Milliseconds 500

  # By default robocopy retries a locked file a million times, 30 s apart, and
  # an antivirus scanning the new files locks them for a moment: retry every
  # second, 30 s in all.
  \$copy = Start-Process -FilePath 'robocopy.exe' -WindowStyle Hidden -Wait -PassThru -ArgumentList @(
    "`"\$source`"", "`"\$target`"", '/MIR', '/R:30', '/W:1', '/NP', "/LOG+:`"\$log`""
  )
  # robocopy reports 0-7 for success, 8 and above for failures.
  if (\$copy.ExitCode -ge 8) {
    throw "robocopy failed with exit code \$(\$copy.ExitCode)."
  }

  Start-Process -FilePath \$app
  Write-Log 'Updated and restarted.'
  Remove-Item -LiteralPath \$staging -Recurse -Force -ErrorAction SilentlyContinue
} catch {
  \$problem = \$_
  Write-Log "Update failed: \$problem"
  # Bring back whatever is installed rather than leaving no app at all.
  try { Start-Process -FilePath \$app } catch {}
  \$message = "Arber could not be updated.`n`n\$problem`n`nDetails: \$log"
  try { (New-Object -ComObject WScript.Shell).Popup(\$message, 0, 'Arber update', 16) | Out-Null } catch {}
}
''';
  }

  static const String _windowsExecutable = 'arber.exe';

  static String _shQuote(String value) => "'${value.replaceAll("'", "'\\''")}'";

  static String _psQuote(String value) => "'${value.replaceAll("'", "''")}'";
}

/// [script] as PowerShell's `-EncodedCommand` expects it: base64 of UTF-16LE.
String encodePowerShellCommand(String script) {
  final ByteData bytes = ByteData(script.length * 2);
  for (int i = 0; i < script.length; i++) {
    bytes.setUint16(i * 2, script.codeUnitAt(i), Endian.little);
  }
  return base64Encode(bytes.buffer.asUint8List());
}

class UpdaterException implements Exception {
  const UpdaterException(this.message);

  final String message;

  @override
  String toString() => message;
}

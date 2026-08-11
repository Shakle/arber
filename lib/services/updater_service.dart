import 'dart:io';

/// Replaces the running application with a freshly downloaded build.
///
/// The archive cannot be unpacked over a running app, so installation is done
/// by a small detached helper script: it waits for this process to exit, swaps
/// the bundle (keeping the old one aside for rollback) and starts the new
/// version. The helper outlives the app on purpose.
///
/// macOS note: this requires the app to run **without** App Sandbox, otherwise
/// the helper inherits the sandbox and cannot touch `/Applications`.
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

    final File helper = await _writeHelper(
      staging: staging,
      source: source,
      target: target,
    );

    await Process.start(
      Platform.isWindows ? 'cmd.exe' : '/bin/sh',
      Platform.isWindows ? ['/c', helper.path] : [helper.path],
      mode: ProcessStartMode.detached,
      workingDirectory: staging.path,
    );

    // Hand the bundle over to the helper. Anything after this is unreachable.
    exit(0);
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
      '${Platform.isWindows ? 'install.bat' : 'install.sh'}',
    )..writeAsStringSync(
      Platform.isWindows
          ? _windowsHelper(source: source, target: target)
          : _macosHelper(source: source, target: target),
    );

    if (!Platform.isWindows) {
      await Process.run('/bin/chmod', ['+x', helper.path]);
    }

    return helper;
  }

  String _macosHelper({required String source, required String target}) {
    final String backup = '$target.old';

    return '''
#!/bin/sh
# Generated by arber's updater. Waits for the app to quit, then swaps bundles.
PID=$pid
SOURCE=${_shQuote(source)}
TARGET=${_shQuote(target)}
BACKUP=${_shQuote(backup)}

while kill -0 "\$PID" 2>/dev/null; do sleep 0.2; done
sleep 0.5

rm -rf "\$BACKUP"
mv "\$TARGET" "\$BACKUP" 2>/dev/null

if ! mv "\$SOURCE" "\$TARGET"; then
  # Put the working version back rather than leaving nothing installed.
  mv "\$BACKUP" "\$TARGET" 2>/dev/null
  open "\$TARGET"
  exit 1
fi

rm -rf "\$BACKUP"
xattr -dr com.apple.quarantine "\$TARGET" 2>/dev/null
open "\$TARGET"
''';
  }

  String _windowsHelper({required String source, required String target}) {
    return '''
@echo off
rem Generated by arber's updater. Waits for the app to quit, then mirrors the
rem new build over the install folder.
set "PID=$pid"
set "SOURCE=$source"
set "TARGET=$target"

:wait
tasklist /FI "PID eq %PID%" /NH 2>nul | findstr /R "[0-9]" >nul
if %errorlevel%==0 (
  rem ping is the reliable way to sleep without a console attached.
  ping -n 2 127.0.0.1 >nul
  goto wait
)

robocopy "%SOURCE%" "%TARGET%" /MIR /NFL /NDL /NJH /NJS /NP >nul
rem robocopy reports 0-7 for success, 8+ for real failures.
if %errorlevel% GEQ 8 exit /b 1

start "" "%TARGET%\\$_windowsExecutable"
''';
  }

  static const String _windowsExecutable = 'arber.exe';

  static String _shQuote(String value) => "'${value.replaceAll("'", "'\\''")}'";

  static String _psQuote(String value) => "'${value.replaceAll("'", "''")}'";
}

class UpdaterException implements Exception {
  const UpdaterException(this.message);

  final String message;

  @override
  String toString() => message;
}

import 'dart:io';

import 'package:arber/application.dart';
import 'package:arber/data/constants.dart';
import 'package:arber/logic/blocs/update/update_cubit.dart';
import 'package:arber/services/prefs_migration_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Future.wait([
    windowManager.ensureInitialized(),
    PackageInfo.fromPlatform().then((info) => packageInfo = info),
    // Must run before anything reads preferences.
    PrefsMigrationService().migrate(),
    // The app ships without App Sandbox, so it has no `files.user-selected`
    // entitlement for file_picker to find. Without this the picker refuses to
    // open at all with ENTITLEMENT_NOT_FOUND.
    if (Platform.isMacOS) FilePicker.skipEntitlementsChecks(),
  ]);

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    WindowOptions windowOptions = WindowOptions(
      minimumSize: const Size(1000, 700),
      size: const Size(1050, 750),
      center: true,
      titleBarStyle: Platform.isMacOS
          ? TitleBarStyle.hidden
          : TitleBarStyle.normal,
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  runApp(BlocProvider(
    lazy: false,
    create: (context) => UpdateCubit(),
    child: const Application(),
  ));
}

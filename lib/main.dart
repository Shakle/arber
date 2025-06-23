import 'dart:io';

import 'package:arber/application.dart';
import 'package:arber/data/constants.dart';
import 'package:arber/logic/blocs/update/update_cubit.dart';
import 'package:arber/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  StorageService.sharedPrefs = await SharedPreferences.getInstance();
  packageInfo = await PackageInfo.fromPlatform();

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    WindowOptions windowOptions = WindowOptions(
      minimumSize: const Size(1000, 700),
      size: const Size(1050, 750),
      backgroundColor: Colors.transparent,
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

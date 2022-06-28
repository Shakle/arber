import 'dart:io';

import 'package:arber/application.dart';
import 'package:arber/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  StorageService.sharedPrefs = await SharedPreferences.getInstance();

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    WindowOptions windowOptions = const WindowOptions(
      minimumSize: Size(1000, 700),
      size: Size(1050, 750),
      backgroundColor: Colors.transparent,
      titleBarStyle: TitleBarStyle.hidden,
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  runApp(const Application());
}

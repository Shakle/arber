import 'dart:io';

import 'package:arber/logic/blocs/update/update_endpoints.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';

part 'update_state.dart';

class UpdateCubit extends Cubit<UpdateState> {
  UpdateCubit() : super(UpdateInitial()) {
    checkForUpdate();
  }

  final Dio _client = Dio();

  Future<String?> getLatestVersion() async {
    Response response = await _client.getUri(
      Uri.parse(UpdateEndpoints.latestRelease),
    );

    return response.data['tag_name'];
  }

  Future<void> checkForUpdate() async {
    emit(UpdateChecking());
    await Future.delayed(const Duration(seconds: 1));

    try {
      String currentVersion = (await PackageInfo.fromPlatform()).version;
      String? availableVersion = await getLatestVersion();

      int currentVersionNumber = int.parse(currentVersion.replaceAll('.', ''));
      int? availableVersionNumber = int.parse(
        availableVersion?.replaceAll('.', '') ?? '0',
      );

      bool isUpdateAvailable = currentVersionNumber < availableVersionNumber;

      emit(UpdateChecked(
        currentVersion: currentVersion,
        availableVersion: availableVersion ?? currentVersion,
        isUpdateAvailable: isUpdateAvailable,
      ));
    } catch (e) {
      emit(UpdateError(message: e.toString()));
    }
  }

  Future<void> update() async {
    final currentState = state;
    emit(UpdateInstalling(updatePercent: 0));

    try {
      // 1. Get json with assets
      Response resp = await _client.getUri(
        Uri.parse(UpdateEndpoints.latestRelease),
      );
      Map<String, dynamic> data = resp.data;
      List<Map<String, dynamic>> assets = List.from(data['assets']);

      // 2. Choose ZIP by name
      String suffix = Platform.isMacOS
          ? 'macos.zip'
          : Platform.isWindows
          ? 'windows.zip'
          : throw UnsupportedError('Unsupported platform');

      Map<String, dynamic> asset = assets.firstWhere(
            (a) => (a['name'] as String).endsWith(suffix),
        orElse: () => throw StateError('Asset not found: $suffix'),
      );
      String url = asset['browser_download_url'];
      String fileName = asset['name'];

      // 3. Detecting "Downloads" folder
      String downloadsDir;
      if (Platform.isMacOS || Platform.isLinux) {
        downloadsDir = '${Platform.environment['HOME']}/Downloads';
      } else {
        downloadsDir = '${Platform.environment['USERPROFILE']}\\Downloads';
      }
      final savePath = Platform.isWindows
          ? '$downloadsDir\\$fileName'
          : '$downloadsDir/$fileName';

      // 4. Download
      await _client.download(
        url,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            emit(UpdateInstalling(
              updatePercent: (received / total).clamp(0.0, 1.0),
            ));
          }
        },
      );

      emit(UpdateSuccess());
      emit(currentState);
    } catch (e) {
      emit(UpdateError(message: e.toString()));
    }
  }
}

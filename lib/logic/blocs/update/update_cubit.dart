import 'dart:io';

import 'package:arber/logic/blocs/update/update_endpoints.dart';
import 'package:arber/services/updater_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';

part 'update_state.dart';

class UpdateCubit extends Cubit<UpdateState> {
  UpdateCubit() : super(UpdateInitial()) {
    checkForUpdate();
  }

  final Dio _client = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    // Dio measures this between two chunks, so it covers both the API call and
    // the download without cutting a slow but healthy transfer short.
    receiveTimeout: const Duration(seconds: 30),
    headers: const {'Accept': 'application/vnd.github+json'},
  ));

  final UpdaterService _updater = UpdaterService();

  /// Asset name suffix of the build for the current platform, or `null` when
  /// no builds are published for it.
  static String? get _assetSuffix {
    if (Platform.isMacOS) return 'macos.zip';
    if (Platform.isWindows) return 'windows.zip';
    return null;
  }

  Future<void> checkForUpdate() async {
    if (isClosed) return;
    emit(UpdateChecking());
    await Future.delayed(const Duration(seconds: 1));

    try {
      String currentVersion = (await PackageInfo.fromPlatform()).version;

      Response response = await _client.getUri(
        Uri.parse(UpdateEndpoints.latestRelease),
      );
      Map<String, dynamic> release = Map<String, dynamic>.from(response.data);

      String availableVersion =
          (release['tag_name'] as String?)?.trim() ?? currentVersion;

      if (isClosed) return;
      emit(UpdateChecked(
        currentVersion: currentVersion,
        availableVersion: availableVersion,
        isNewerVersionAvailable:
            _compareVersions(currentVersion, availableVersion) < 0,
        asset: _findAsset(release),
      ));
    } catch (e) {
      if (isClosed) return;
      emit(UpdateError(message: e.toString()));
    }
  }

  /// Downloads the new build and installs it over the current one. On success
  /// the process exits and the helper restarts the updated app, so this does
  /// not return.
  Future<void> update() async {
    final UpdateState previousState = state;
    if (previousState is! UpdateChecked) return;

    final ReleaseAsset? asset = previousState.asset;
    if (asset == null) {
      emit(UpdateError(
        message: 'Release ${previousState.availableVersion} does not ship a '
            'build for this platform yet.',
      ));
      return;
    }

    emit(UpdateDownloading(updatePercent: 0));
    String? savePath;

    try {
      savePath = _downloadPathFor(asset.name);

      await _client.download(
        asset.downloadUrl,
        savePath,
        onReceiveProgress: (received, total) {
          if (total <= 0 || isClosed) return;
          emit(UpdateDownloading(
            updatePercent: (received / total).clamp(0.0, 1.0),
          ));
        },
      );

      if (isClosed) return;
      emit(UpdateApplying());

      // Never returns: the app exits so the helper can swap the bundle.
      await _updater.installAndRestart(savePath);
    } catch (e) {
      if (isClosed) return;

      // The archive is already on disk, so a failed install is still
      // recoverable by hand.
      String hint = savePath == null
          ? ''
          : '\n\nThe archive is saved to $savePath — you can install it '
              'manually.';

      emit(UpdateError(
        message: (e is UpdaterException ? e.message : e.toString()) + hint,
      ));
    }
  }

  /// Picks the release asset matching the current platform. Returns `null` when
  /// the release has no build for it, which is expected for Windows.
  ReleaseAsset? _findAsset(Map<String, dynamic> release) {
    final String? suffix = _assetSuffix;
    if (suffix == null) return null;

    for (final dynamic entry in (release['assets'] as List? ?? const [])) {
      final Map<String, dynamic> asset = Map<String, dynamic>.from(entry);
      final String? name = asset['name'] as String?;
      final String? url = asset['browser_download_url'] as String?;

      if (name == null || url == null) continue;
      if (!name.toLowerCase().endsWith(suffix)) continue;

      return ReleaseAsset(name: name, downloadUrl: url);
    }

    return null;
  }

  /// Absolute path inside the user's Downloads folder.
  String _downloadPathFor(String fileName) {
    final String variable = Platform.isWindows ? 'USERPROFILE' : 'HOME';
    final String? home = Platform.environment[variable];

    if (home == null || home.isEmpty) {
      throw StateError('Cannot locate the home directory ($variable is unset)');
    }

    final String separator = Platform.pathSeparator;
    return '$home${separator}Downloads$separator$fileName';
  }

  /// Compares dot-separated versions segment by segment. Negative when [a] is
  /// older than [b], zero when they are equal, positive when [a] is newer.
  ///
  /// Segment-wise comparison matters: naively stripping the dots makes 1.2.10
  /// (1210) look newer than 1.3.0 (130).
  static int _compareVersions(String a, String b) {
    final List<int> left = _versionSegments(a);
    final List<int> right = _versionSegments(b);
    final int length = left.length > right.length ? left.length : right.length;

    for (int i = 0; i < length; i++) {
      final int l = i < left.length ? left[i] : 0;
      final int r = i < right.length ? right[i] : 0;
      if (l != r) return l < r ? -1 : 1;
    }

    return 0;
  }

  /// Splits `v1.2.10+21` into `[1, 2, 10]`. Unparsable segments become 0, so a
  /// stray tag like `Release` reads as an old version instead of throwing.
  static List<int> _versionSegments(String version) {
    String normalized = version.trim();

    if (normalized.startsWith('v') || normalized.startsWith('V')) {
      normalized = normalized.substring(1);
    }
    normalized = normalized.split('+').first.split('-').first;

    return normalized.split('.').map((part) => int.tryParse(part) ?? 0).toList();
  }
}

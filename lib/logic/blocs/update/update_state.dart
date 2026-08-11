part of 'update_cubit.dart';

/// A downloadable build attached to a GitHub release.
@immutable
final class ReleaseAsset {
  const ReleaseAsset({
    required this.name,
    required this.downloadUrl,
  });

  final String name;
  final String downloadUrl;
}

@immutable
sealed class UpdateState {}

final class UpdateInitial extends UpdateState {}
final class UpdateChecking extends UpdateState {}
final class UpdateChecked extends UpdateState {
  UpdateChecked({
    required this.currentVersion,
    required this.availableVersion,
    required this.isNewerVersionAvailable,
    required this.asset,
  });

  final String availableVersion;
  final String currentVersion;

  /// A newer release exists, regardless of whether it ships a build for the
  /// current platform.
  final bool isNewerVersionAvailable;

  /// The build for the current platform, or `null` when the release does not
  /// ship one (Windows builds are published irregularly).
  final ReleaseAsset? asset;

  /// A newer release exists *and* it can be installed here.
  bool get isUpdateAvailable => isNewerVersionAvailable && asset != null;

  /// A newer release exists but there is nothing to download on this platform.
  bool get isUpdateUnavailableHere => isNewerVersionAvailable && asset == null;
}

final class UpdateError extends UpdateState {
  UpdateError({
    required this.message,
  });

  final String message;
}

final class UpdateDownloading extends UpdateState {
  UpdateDownloading({
    required this.updatePercent,
  });

  final double updatePercent;
}

/// The archive is being unpacked and installed; the app is about to restart.
final class UpdateApplying extends UpdateState {}

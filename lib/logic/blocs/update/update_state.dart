part of 'update_cubit.dart';

@immutable
sealed class UpdateState {}

final class UpdateInitial extends UpdateState {}
final class UpdateChecking extends UpdateState {}
final class UpdateChecked extends UpdateState {
  UpdateChecked({
    required this.currentVersion,
    required this.availableVersion,
    required this.isUpdateAvailable,
  });

  final String availableVersion;
  final String currentVersion;
  final bool isUpdateAvailable;
}

final class UpdateError extends UpdateState {
  UpdateError({
    required this.message,
  });

  final String message;
}

final class UpdateSuccess extends UpdateState {
  UpdateSuccess();
}


final class UpdateInstalling extends UpdateState {
  UpdateInstalling({
   required this.updatePercent,
  });

  final double updatePercent;
}

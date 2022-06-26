part of 'path_cubit.dart';

@immutable
abstract class PathState {}

class PathInitial extends PathState {}

class PathConnected extends PathState {
  final PathArtifact pathArtifact;
  final List<FileException> failedArtifacts;

  PathConnected({
    required this.pathArtifact,
    required this.failedArtifacts,
  });
}

class PathConnectionFailed extends PathState {
  final List<FileException> failedArtifacts;
  final List<ArtifactType> successArtifacts;

  PathConnectionFailed({
    required this.failedArtifacts,
    required this.successArtifacts,
  });
}

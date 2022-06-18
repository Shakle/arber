part of 'path_cubit.dart';

@immutable
abstract class PathState {}

class PathInitial extends PathState {}

class PathConnected extends PathState {
  final PathArtifact pathArtifact;

  PathConnected({required this.pathArtifact});
}
class PathConnectionFailed extends PathState {
  final List<ArtifactType> failedArtifacts;
  final List<ArtifactType> successArtifacts;

  PathConnectionFailed({
    required this.failedArtifacts,
    required this.successArtifacts,
  });
}

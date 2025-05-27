import 'package:arber/data/enums.dart';

class FileException {
  final ArtifactType artifactType;
  final String exceptionMessage;

  FileException({
    required this.artifactType,
    required this.exceptionMessage
  });
}

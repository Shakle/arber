import 'dart:io';

class PathArtifact {
  final File excelFile;
  final String l10nDirectory;

  const PathArtifact({
    required this.excelFile,
    required this.l10nDirectory
  });
}

import 'dart:async';
import 'dart:io';

import 'package:arber/data/enums.dart';
import 'package:arber/data/models/pathway.dart';
import 'package:arber/services/file_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'path_state.dart';

class PathCubit extends Cubit<PathState> {
  PathCubit() : super(PathInitial()) {
    pathTimer = Timer.periodic(const Duration(milliseconds: 200), _pathListener);
  }

  final FileService _fileService = FileService();
  final TextEditingController excelFilePathController
    = TextEditingController();
  final TextEditingController l10nDirectoryPathController
    = TextEditingController();

  late final Timer pathTimer;

  File get excelFile => File(excelFilePathController.text);

  Directory get l10nDirectory => Directory(l10nDirectoryPathController.text);

  void _pathListener(Timer timer) {
    if (excelFile.existsSync() && l10nDirectory.existsSync()) {
      emit(PathConnected(
          pathArtifact: PathArtifact(
            excelFile: excelFile,
            l10nDirectory: l10nDirectory.path,
      )));
    } else {
      emit(PathConnectionFailed(
        successArtifacts: [
          if (excelFilePathController.text.isNotEmpty
              && excelFile.existsSync())
            ArtifactType.excel,
          if (l10nDirectoryPathController.text.isNotEmpty
              && l10nDirectory.existsSync())
            ArtifactType.l10n,
        ],
        failedArtifacts: [
          if (excelPathValidator() != null) ArtifactType.excel,
          if (l10nPathValidator() != null) ArtifactType.l10n,
        ],
      ));
    }
  }

  String? excelPathValidator() {
    if (excelFilePathController.text.isNotEmpty && !excelFile.existsSync()) {
      return '';
    }

    return null;
  }

  String? l10nPathValidator() {
    if (l10nDirectoryPathController.text.isNotEmpty
        && !l10nDirectory.existsSync()
    ) {
      return '';
    }

    return null;
  }

  Future<void> pickExcelFile() async {
    String? filePath = await _fileService.getFilePath();

    if (filePath != null) {
      excelFilePathController.text = filePath;
    }
  }

  Future<void> pickL10nDirectory() async {
    String? dirPath = await _fileService.getDirectoryPath();

    if (dirPath != null) {
      l10nDirectoryPathController.text = dirPath;
    }
  }

  @override
  Future<void> close() {
    excelFilePathController.dispose();
    l10nDirectoryPathController.dispose();
    return super.close();
  }
}

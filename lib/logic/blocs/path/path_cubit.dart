import 'dart:async';
import 'dart:io';

import 'package:arber/data/enums.dart';
import 'package:arber/data/models/file_exception.dart';
import 'package:arber/data/models/pathway.dart';
import 'package:arber/services/file_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'path_state.dart';

class PathCubit extends Cubit<PathState> {
  PathCubit() : super(PathInitial()) {
    pathTimer = Timer.periodic(const Duration(milliseconds: 100), _pathListener);
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
    bool excelSuccess = excelFilePathController.text.isNotEmpty
        && excelPathValidator() == null;
    bool l10nSuccess = l10nDirectoryPathController.text.isNotEmpty
        && l10nPathValidator() == null;

    if (excelSuccess && l10nSuccess) {
      emit(PathConnected(
          pathArtifact: PathArtifact(
            excelFile: excelFile,
            l10nDirectory: l10nDirectory.path,
      )));
    } else {
      emit(PathConnectionFailed(
        successArtifacts: [
          if (excelSuccess)
            ArtifactType.excel,
          if (l10nSuccess)
            ArtifactType.l10n,
        ],
        failedArtifacts: [
          if (excelPathValidator() != null) FileException(
              artifactType: ArtifactType.excel,
              exceptionMessage: excelPathValidator()!,
          ),
          if (l10nPathValidator() != null) FileException(
            artifactType: ArtifactType.l10n,
            exceptionMessage: l10nPathValidator()!,
          ),
        ],
      ));
    }
  }

  String? excelPathValidator() {
    if (excelFilePathController.text.isNotEmpty && !excelFile.existsSync()) {
      return 'File does not exist';
    }

    if (excelFile.existsSync()
        && !excelFile.path.split('.').last.contains('xlsx')) {
      return 'File must be .xlsx';
    }

    return null;
  }

  String? l10nPathValidator() {
    if (l10nDirectoryPathController.text.isNotEmpty
        && !l10nDirectory.existsSync()
    ) {
      return 'Directory does not exist';
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

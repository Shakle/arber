import 'dart:async';
import 'dart:io';

import 'package:arber/data/enums.dart';
import 'package:arber/data/models/file_exception.dart';
import 'package:arber/data/models/pathway.dart';
import 'package:arber/services/file_service.dart';
import 'package:arber/services/storage_service.dart';
import 'package:directory_bookmarks/directory_bookmarks.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'path_state.dart';

class PathCubit extends Cubit<PathState> {
  PathCubit() : super(PathInitial()) {
    excelFilePathController = TextEditingController()..addListener(_checkPaths);
    arbFilePathController = TextEditingController()..addListener(_checkPaths);
    l10nDirPathController = TextEditingController()..addListener(_checkPaths);
    _restorePaths();
  }

  final FileService _fileService = FileService();
  final StorageService _storageService = StorageService();

  late final TextEditingController excelFilePathController;
  late final TextEditingController arbFilePathController;
  late final TextEditingController l10nDirPathController;

  File get excelFile => File(excelFilePathController.text);
  File get arbFile => File(arbFilePathController.text);
  Directory get l10nDirectory => Directory(l10nDirPathController.text);

  Future<void> _checkPaths() async {
    bool excelSuccess = excelFilePathController.text.isNotEmpty
        && excelPathValidator() == null;
    bool l10nSuccess = l10nDirPathController.text.isNotEmpty
        && l10nPathValidator() == null;
    bool arbSuccess = arbFilePathController.text.isNotEmpty
        && arbPathValidator() == null;

    await savePaths(
      excelSuccess: excelSuccess,
      l10nSuccess: l10nSuccess,
      arbSuccess: arbSuccess,
    );

    if (excelSuccess && l10nSuccess && arbPathValidator() == null) {
      emitSuccess(arbSuccess);
    } else {
      emitConnectionFailed(
        arbSuccess: arbSuccess,
        excelSuccess: excelSuccess,
        l10nSuccess: l10nSuccess,
      );
    }
  }

  void emitSuccess(bool arbSuccess) {
    emit(PathConnected(
        pathArtifact: PathArtifact(
          excelFile: excelFile,
          l10nDirectory: l10nDirectory.path,
        ),
        failedArtifacts: [
          if (!arbSuccess) FileException(
            artifactType: ArtifactType.mainArb,
            exceptionMessage: arbPathValidator() != null
                ? arbPathValidator()!
                : 'Main arb was not synced',
          ),
        ],
    ));
  }

  void emitConnectionFailed({
    required bool excelSuccess,
    required bool l10nSuccess,
    required bool arbSuccess,
  }) {
    emit(PathConnectionFailed(
      successArtifacts: [
        if (excelSuccess)
          ArtifactType.excel,
        if (l10nSuccess)
          ArtifactType.l10n,
        if (arbSuccess)
          ArtifactType.mainArb,
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
        if (arbPathValidator() != null) FileException(
          artifactType: ArtifactType.mainArb,
          exceptionMessage: arbPathValidator()!,
        ),
      ],
    ));
  }

  Future<void> savePaths({
    required bool excelSuccess,
    required bool l10nSuccess,
    required bool arbSuccess,
  }) async {
    excelSuccess
        ? await _storageService.saveExcelPath(excelFilePathController.text)
        : await _storageService.removeExcelPath();
    l10nSuccess
        ? await _storageService.saveL10nPath(l10nDirPathController.text)
        : await _storageService.removeL10nPath();
    arbSuccess
        ? await _storageService.saveMainArbPath(arbFilePathController.text)
        : await _storageService.removeMainArbPath();
  }

  Future<void> _restorePaths() async {
    await Future.wait([
      if (!kIsWeb && Platform.isMacOS)
        DirectoryBookmarkHandler.resolveBookmark(),
      _storageService.getExcelPath()
          .then((v) => excelFilePathController.text = v),
      _storageService.getL10nPath()
          .then((v) => l10nDirPathController.text = v),
      _storageService.getMainArbPath()
          .then((v) => arbFilePathController.text = v),
    ]);

    await _checkPaths();
  }

  String? excelPathValidator() {
    if (excelFilePathController.text.isNotEmpty
        && !excelFile.existsSync()) {
      return 'File does not exist';
    }

    if (excelFile.existsSync()
        && !excelFile.path.split('.').last.contains('xlsx')) {
      return 'File must be .xlsx';
    }

    return null;
  }

  String? arbPathValidator() {
    if (arbFilePathController.text.isNotEmpty && !arbFile.existsSync()) {
      return 'File does not exist';
    }

    if (arbFile.existsSync() && !arbFile.path.split('.').last.contains('arb')) {
      return 'File must be .arb';
    }

    return null;
  }

  String? l10nPathValidator() {
    if (l10nDirPathController.text.isNotEmpty && !l10nDirectory.existsSync()) {
      return 'Directory does not exist';
    }

    return null;
  }

  Future<String?> pickFile() async {
    return await _fileService.getFilePath();
  }

  Future<void> pickExcelFile() async {
    String? filePath = await pickFile();

    if (filePath != null) {
      excelFilePathController.text = filePath;
    }
  }

  Future<void> pickMainArbFile() async {
    String? filePath = await pickFile();

    if (filePath != null) {
      arbFilePathController.text = filePath;
    }
  }

  Future<void> pickL10nDirectory() async {
    String? dirPath = await _fileService.getDirectoryPath();

    if (dirPath != null) {
      l10nDirPathController.text = dirPath;
      if (!kIsWeb && Platform.isMacOS) {
        await DirectoryBookmarkHandler.saveBookmark(dirPath);
      }
    }
  }

  @override
  Future<void> close() {
    excelFilePathController.dispose();
    l10nDirPathController.dispose();
    arbFilePathController.dispose();
    return super.close();
  }
}

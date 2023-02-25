import 'dart:io';

import 'package:arber/data/models/arb.dart';
import 'package:file_picker/file_picker.dart';

class FileService {
  final FilePicker _filePicker = FilePicker.platform;

  Future<String?> getFilePath() async {
    FilePickerResult? result = await _filePicker.pickFiles();
    return result?.files.single.path;
  }

  Future<String?> getDirectoryPath() async
  => await _filePicker.getDirectoryPath();

  Future<void> writeArbFiles(String l10nDirectoryPath, List<Arb> arbs) async {
    List<FileSystemEntity> fileSystemEntityList = Directory(l10nDirectoryPath)
        .listSync()
        .where((file) => file.path.split('.').last.contains('arb'))
        .toList();

    for (FileSystemEntity file in fileSystemEntityList) {
      file.deleteSync();
    }

    for (Arb arb in arbs) {
      File file = await File('$l10nDirectoryPath/intl_${arb.locale}.arb')
          .create();
      file.writeAsStringSync(arb.toJson());
    }
  }

}
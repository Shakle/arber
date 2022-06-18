import 'dart:io';

import 'package:arber/data/models/arb.dart';
import 'package:file_picker/file_picker.dart';

class FileService {

  Future<String?> getFilePath() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    return result?.files.single.path;
  }

  Future<String?> getDirectoryPath() async
    => await FilePicker.platform.getDirectoryPath();


  Future<void> writeArbFiles(String l10nDirectoryPath, List<Arb> arbs) async {
    List<FileSystemEntity> fileSystemEntityList = Directory(l10nDirectoryPath)
        .listSync();

    for (FileSystemEntity file in fileSystemEntityList) {
      if (file.path.split('.').last.contains('arb')) {
        file.deleteSync();
      }
    }

    for (Arb arb in arbs) {
      File file = await File('$l10nDirectoryPath/intl_${arb.locale}.arb')
          .create();
      file.writeAsStringSync(arb.toJson());
    }
  }
}
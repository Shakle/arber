import 'package:file_picker/file_picker.dart';

class FileService {

  Future<String?> getFilePath() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowedExtensions: ['xlsx'],
    );

    return result?.files.single.path;
  }

  Future<String?> getDirectoryPath() async
    => await FilePicker.platform.getDirectoryPath();


}
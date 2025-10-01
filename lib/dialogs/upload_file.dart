import 'package:district/structures/hashed_file.dart';
import 'package:district/widgets/files_list.dart';
import 'package:file_picker/file_picker.dart';

void uploadFiles(FilesList filesList) async {
  FilePickerResult? result = await FilePicker.platform.pickFiles(
    allowMultiple: true,
  );

  if (result != null) {
    for (var file in result.files) {
      HashedFile hashedFile = await HashedFile.fromPath(file.path.toString());
      filesList.files.add(hashedFile);
    }
  } else {
    print('Выбор файла отменен');
  }
}

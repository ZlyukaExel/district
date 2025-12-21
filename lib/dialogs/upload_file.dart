import 'package:district/structures/hashed_file.dart';
import 'package:district/widgets/files_list.dart';
import 'package:file_picker/file_picker.dart';
import 'package:district/structures/peer.dart';

void uploadFiles(FilesList filesList, Peer peer) async {
  FilePickerResult? result = await FilePicker.platform.pickFiles(
    allowMultiple: true,
  );

  if (result != null) {
    for (var file in result.files) {
      HashedFile hashedFile = await HashedFile.fromPath(file.path.toString());
      filesList.files.add(hashedFile);

      peer.addFileToBloomFilter(hashedFile.hash);
    }
  } else {
    print('Выбор файла отменен');
  }
}

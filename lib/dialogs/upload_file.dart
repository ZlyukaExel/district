import 'package:district/structures/hashed_file.dart';
import 'package:district/structures/notifier_list.dart';
import 'package:file_picker/file_picker.dart';
import 'package:district/structures/peer.dart';

Future<void> uploadFiles(NotifierList<HashedFile> filesList, Peer peer) async {
  FilePickerResult? result = await FilePicker.platform.pickFiles(
    allowMultiple: true,
  );

  if (result != null) {
    for (var file in result.files) {
      HashedFile hashedFile = await HashedFile.fromPath(file.path.toString());
      filesList.add(hashedFile);
      peer.addFileToBloomFilter(hashedFile.hash);
    }
  } else {
    print('Выбор файла отменен');
  }
}


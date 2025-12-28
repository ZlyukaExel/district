import 'package:district/structures/hashed_file.dart';
import 'package:file_picker/file_picker.dart';
import 'package:district/structures/peer.dart';

Future<void> uploadFiles(Peer peer) async {
  FilePickerResult? result = await FilePicker.platform.pickFiles(
    allowMultiple: true,
  );

  if (result != null) {
    for (var file in result.files) {
      HashedFile hashedFile = await HashedFile.fromPath(file.path.toString());
      peer.addFile(hashedFile);
    }
  } else {
    print('Выбор файла отменен');
  }
}

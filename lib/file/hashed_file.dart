import 'dart:io';
import 'package:crypto/crypto.dart';

class HashedFile {
  final String path;
  final String hash;

  HashedFile._({required this.path, required this.hash});

  static Future<HashedFile> fromPath(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('Файл не найден: $filePath');
    }

    final hash = await getFileHash(file);

    print("Путь к файлу: $filePath");
    print("Хэш файла: $hash");

    return HashedFile._(path: filePath, hash: hash);
  }
}

Future<String> getFileHash(File file) async {
  final input = file.openRead();
  final hash = await sha256.bind(input).first;
  return hash.toString();
}

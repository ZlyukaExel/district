import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:district/file/hashed_file.dart';

class FileChunk {
  final String senderId;
  final String transferId;
  final int chunkIndex;
  final Uint8List data;
  final String chunkHash;
  final String fileHash;
  final int totalChunks;
  final String fileName;

  FileChunk({
    required this.senderId,
    required this.transferId,
    required this.chunkIndex,
    required this.data,
    required this.chunkHash,
    required this.fileHash,
    required this.totalChunks,
    required this.fileName,
  });

  Uint8List encode() {
    final buffer = BytesBuilder();

    // 1. Sender ID (36 байт)
    buffer.add(senderId.padRight(36, ' ').substring(0, 36).codeUnits);

    // 2. Transfer ID
    final trIdBytes = transferId.codeUnits;
    buffer.addByte(trIdBytes.length);
    buffer.add(trIdBytes);

    // 3. Chunks (current, total)
    buffer.addByte((chunkIndex >> 24) & 0xFF);
    buffer.addByte((chunkIndex >> 16) & 0xFF);
    buffer.addByte((chunkIndex >> 8) & 0xFF);
    buffer.addByte(chunkIndex & 0xFF);

    buffer.addByte((totalChunks >> 24) & 0xFF);
    buffer.addByte((totalChunks >> 16) & 0xFF);
    buffer.addByte((totalChunks >> 8) & 0xFF);
    buffer.addByte(totalChunks & 0xFF);

    // 4. Chunk Hash
    final chunkHashBytes = chunkHash.codeUnits;
    buffer.addByte(chunkHashBytes.length);
    buffer.add(chunkHashBytes);

    // 5. File Hash
    final fileHashBytes = fileHash.codeUnits;
    buffer.addByte(fileHashBytes.length);
    buffer.add(fileHashBytes);

    // 6. FileName
    final nameBytes = utf8.encode(fileName);
    buffer.addByte((nameBytes.length >> 24) & 0xFF);
    buffer.addByte((nameBytes.length >> 16) & 0xFF);
    buffer.addByte((nameBytes.length >> 8) & 0xFF);
    buffer.addByte(nameBytes.length & 0xFF);
    buffer.add(nameBytes);

    // 7. Data
    final dSize = data.length;
    buffer.addByte((dSize >> 24) & 0xFF);
    buffer.addByte((dSize >> 16) & 0xFF);
    buffer.addByte((dSize >> 8) & 0xFF);
    buffer.addByte(dSize & 0xFF);

    buffer.add(data);
    return buffer.toBytes();
  }

  static FileChunk decode(Uint8List bytes) {
    int offset = 0;

    // 1. Sender
    final senderId = String.fromCharCodes(bytes.sublist(0, 36)).trim();
    offset += 36;

    // 2. Transfer
    final transferIdLen = bytes[offset++];
    final transferId = String.fromCharCodes(
      bytes.sublist(offset, offset + transferIdLen),
    );
    offset += transferIdLen;

    // 3. Chunks
    final chunkIndex =
        (bytes[offset] << 24) |
        (bytes[offset + 1] << 16) |
        (bytes[offset + 2] << 8) |
        bytes[offset + 3];
    offset += 4;

    final totalChunks =
        (bytes[offset] << 24) |
        (bytes[offset + 1] << 16) |
        (bytes[offset + 2] << 8) |
        bytes[offset + 3];
    offset += 4;

    // 4. Chunk hash
    final chunkHashLen = bytes[offset++];
    final chunkHash = String.fromCharCodes(
      bytes.sublist(offset, offset + chunkHashLen),
    );
    offset += chunkHashLen;

    // 5. File hash
    final fileHashLen = bytes[offset++];
    final fileHash = String.fromCharCodes(
      bytes.sublist(offset, offset + fileHashLen),
    );
    offset += fileHashLen;

    // 6. File name
    final nameLen =
        (bytes[offset] << 24) |
        (bytes[offset + 1] << 16) |
        (bytes[offset + 2] << 8) |
        bytes[offset + 3];
    offset += 4;
    final fileName = utf8.decode(bytes.sublist(offset, offset + nameLen));
    offset += nameLen;

    // 7. Data
    final dataSize =
        (bytes[offset] << 24) |
        (bytes[offset + 1] << 16) |
        (bytes[offset + 2] << 8) |
        bytes[offset + 3];
    offset += 4;

    final data = bytes.sublist(offset, offset + dataSize);

    return FileChunk(
      senderId: senderId,
      transferId: transferId,
      chunkIndex: chunkIndex,
      data: data,
      chunkHash: chunkHash,
      fileHash: fileHash,
      totalChunks: totalChunks,
      fileName: fileName,
    );
  }
}

class FileReader {
  static const int CHUNK_SIZE = 1024;

  static Stream<FileChunk> readFileStrictly(
    String filePath,
    String senderId,
    String transferId,
  ) async* {
    final file = File(filePath);
    final fileName = file.uri.pathSegments.last; // Получаем имя файла из пути

    final raf = await file.open(mode: FileMode.read);
    final fileSize = await file.length();
    final totalChunks = (fileSize / CHUNK_SIZE).ceil();
    final fileHash = await getFileHash(file);

    try {
      for (int i = 0; i < totalChunks; i++) {
        final data = await raf.read(CHUNK_SIZE);
        final chunkHash = md5.convert(data).toString();

        yield FileChunk(
          senderId: senderId,
          transferId: transferId,
          chunkIndex: i,
          data: data,
          chunkHash: chunkHash,
          fileHash: fileHash,
          totalChunks: totalChunks,
          fileName: fileName,
        );
      }
    } finally {
      await raf.close();
    }
  }
}

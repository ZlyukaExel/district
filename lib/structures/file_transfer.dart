import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

/// Метаданные о передаче файла
class FileTransferMetadata {
  final String fileHash;
  final String fileName;
  final int totalSize;
  final int totalChunks;
  final String transferId;

  FileTransferMetadata({
    required this.fileHash,
    required this.fileName,
    required this.totalSize,
    required this.totalChunks,
    required this.transferId,
  });

  Map<String, dynamic> toJson() => {
    'fileHash': fileHash,
    'fileName': fileName,
    'totalSize': totalSize,
    'totalChunks': totalChunks,
    'transferId': transferId,
  };

  static FileTransferMetadata fromJson(Map<String, dynamic> json) =>
      FileTransferMetadata(
        fileHash: json['fileHash'],
        fileName: json['fileName'],
        totalSize: json['totalSize'],
        totalChunks: json['totalChunks'],
        transferId: json['transferId'],
      );
}

/// Батч данных файла
class FileChunk {
  final String transferId;
  final int chunkIndex;
  final Uint8List data;
  final String chunkHash;
  final int totalChunks;

  FileChunk({
    required this.transferId,
    required this.chunkIndex,
    required this.data,
    required this.chunkHash,
    required this.totalChunks,
  });

  // Сериализация для отправки
  Uint8List encode() {
    final buffer = BytesBuilder();

    // transferId
    final transferIdBytes = transferId.padRight(64, '0').codeUnits;
    buffer.addByte(transferIdBytes.length);
    buffer.add(transferIdBytes);

    // chunkIndex (4 байта)
    buffer.add([(chunkIndex >> 24) & 0xFF, (chunkIndex >> 16) & 0xFF,
      (chunkIndex >> 8) & 0xFF, chunkIndex & 0xFF]);

    // totalChunks (4 байта)
    buffer.add([(totalChunks >> 24) & 0xFF, (totalChunks >> 16) & 0xFF,
      (totalChunks >> 8) & 0xFF, totalChunks & 0xFF]);

    // chunkHash
    final hashBytes = chunkHash.codeUnits;
    buffer.addByte(hashBytes.length);
    buffer.add(hashBytes);

    // data size (4 байта)
    final dataSize = data.length;
    buffer.add([(dataSize >> 24) & 0xFF, (dataSize >> 16) & 0xFF,
      (dataSize >> 8) & 0xFF, dataSize & 0xFF]);

    // сами данные
    buffer.add(data);

    return buffer.toBytes();
  }

  // Десериализация
  static FileChunk decode(Uint8List bytes) {
    int offset = 0;

    final transferIdLen = bytes[offset++];
    final transferIdBytes = bytes.sublist(offset, offset + transferIdLen);
    final transferId =
        String.fromCharCodes(transferIdBytes).replaceAll('0', '');
    offset += transferIdLen;

    final chunkIndex = (bytes[offset] << 24) |
        (bytes[offset + 1] << 16) |
        (bytes[offset + 2] << 8) |
        bytes[offset + 3];
    offset += 4;

    final totalChunks = (bytes[offset] << 24) |
        (bytes[offset + 1] << 16) |
        (bytes[offset + 2] << 8) |
        bytes[offset + 3];
    offset += 4;

    final hashLen = bytes[offset++];
    final hashBytes = bytes.sublist(offset, offset + hashLen);
    final chunkHash = String.fromCharCodes(hashBytes);
    offset += hashLen;

    final dataSize = (bytes[offset] << 24) |
        (bytes[offset + 1] << 16) |
        (bytes[offset + 2] << 8) |
        bytes[offset + 3];
    offset += 4;

    final data = bytes.sublist(offset, offset + dataSize);

    return FileChunk(
      transferId: transferId,
      chunkIndex: chunkIndex,
      data: data,
      chunkHash: chunkHash,
      totalChunks: totalChunks,
    );
  }
}

/// Вспомогательный класс для чтения файла батчами
class FileReader {
  static const int CHUNK_SIZE = 8192; // 8KB на батч

  static Future<List<FileChunk>> readFileAsChunks(
    String filePath,
    String transferId,
  ) async {
    final file = File(filePath);
    final fileSize = await file.length();
    final totalChunks = (fileSize / CHUNK_SIZE).ceil();

    final chunks = <FileChunk>[];
    final input = file.openRead();
    int chunkIndex = 0;

    await for (final List<int> chunkData in input) {
      final data = Uint8List.fromList(chunkData);
      final chunkHash = md5.convert(data).toString();

      chunks.add(FileChunk(
        transferId: transferId,
        chunkIndex: chunkIndex,
        data: data,
        chunkHash: chunkHash,
        totalChunks: totalChunks,
      ));

      chunkIndex++;
    }

    return chunks;
  }
}

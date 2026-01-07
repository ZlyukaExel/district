import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

class FileChunk {
  final String senderId;
  final String transferId;
  final int chunkIndex;
  final Uint8List data;
  final String chunkHash;
  final int totalChunks;

  FileChunk({
    required this.senderId,
    required this.transferId,
    required this.chunkIndex,
    required this.data,
    required this.chunkHash,
    required this.totalChunks,
  });

  Uint8List encode() {
    final buffer = BytesBuilder();
    // 1. Sender ID (36 байт)
    buffer.add(senderId.padRight(36, ' ').substring(0, 36).codeUnits);
    
    // 2. Transfer ID Len + Body
    final trIdBytes = transferId.codeUnits;
    buffer.addByte(trIdBytes.length);
    buffer.add(trIdBytes);
    
    // 3. Ints
    buffer.addByte((chunkIndex >> 24) & 0xFF);
    buffer.addByte((chunkIndex >> 16) & 0xFF);
    buffer.addByte((chunkIndex >> 8) & 0xFF);
    buffer.addByte(chunkIndex & 0xFF);

    buffer.addByte((totalChunks >> 24) & 0xFF);
    buffer.addByte((totalChunks >> 16) & 0xFF);
    buffer.addByte((totalChunks >> 8) & 0xFF);
    buffer.addByte(totalChunks & 0xFF);

    // 4. Hash
    final hBytes = chunkHash.codeUnits;
    buffer.addByte(hBytes.length);
    buffer.add(hBytes);
    
    // 5. Data
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

    final senderId = String.fromCharCodes(bytes.sublist(0, 36)).trim();
    offset += 36;

    final transferIdLen = bytes[offset++];
    final transferId = String.fromCharCodes(bytes.sublist(offset, offset + transferIdLen));
    offset += transferIdLen;

    final chunkIndex = (bytes[offset] << 24) | (bytes[offset + 1] << 16) | (bytes[offset + 2] << 8) | bytes[offset + 3];
    offset += 4;

    final totalChunks = (bytes[offset] << 24) | (bytes[offset + 1] << 16) | (bytes[offset + 2] << 8) | bytes[offset + 3];
    offset += 4;

    final hashLen = bytes[offset++];
    final chunkHash = String.fromCharCodes(bytes.sublist(offset, offset + hashLen));
    offset += hashLen;

    final dataSize = (bytes[offset] << 24) | (bytes[offset + 1] << 16) | (bytes[offset + 2] << 8) | bytes[offset + 3];
    offset += 4;

    final data = bytes.sublist(offset, offset + dataSize);

    return FileChunk(
      senderId: senderId,
      transferId: transferId,
      chunkIndex: chunkIndex,
      data: data,
      chunkHash: chunkHash,
      totalChunks: totalChunks,
    );
  }
}

class FileReader {
  // 1024 байта - безопасный размер для UDP
  static const int CHUNK_SIZE = 1024; 

  static Stream<FileChunk> readFileStrictly(
      String filePath, String senderId, String transferId) async* {
    final file = File(filePath);
    final raf = await file.open(mode: FileMode.read);
    final fileSize = await file.length();
    final totalChunks = (fileSize / CHUNK_SIZE).ceil();
    
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
          totalChunks: totalChunks,
        );
      }
    } finally {
      await raf.close();
    }
  }
}

// lib/structures/bloom_filter.dart
import 'dart:typed_data';
import 'dart:convert';

class BloomFilter {
  late Uint8List _bitArray;
  final int size;
  final int numHashes;

  BloomFilter({this.size = 50000, this.numHashes = 3}) {
    _bitArray = Uint8List((size + 7) ~/ 8);
  }

  int _hash(String item, int seed) {
    final str = '$item:$seed';
    final bytes = utf8.encode(str);
    int hash = 0;
    for (int byte in bytes) {
      hash = ((hash << 5) - hash) + byte;
      hash = hash & hash;
    }
    return (hash.abs() % size);
  }

  void addFile(String fileHash) {
    for (int i = 0; i < numHashes; i++) {
      int index = _hash(fileHash, i);
      int byteIndex = index ~/ 8;
      int bitIndex = index % 8;
      _bitArray[byteIndex] |= (1 << bitIndex);
    }
  }

  bool hasFile(String fileHash) {
    for (int i = 0; i < numHashes; i++) {
      int index = _hash(fileHash, i);
      int byteIndex = index ~/ 8;
      int bitIndex = index % 8;
      if ((_bitArray[byteIndex] & (1 << bitIndex)) == 0) {
        return false;
      }
    }
    return true;
  }

  void addFiles(List<String> fileHashes) {
    for (final hash in fileHashes) {
      addFile(hash);
    }
  }

  Map<String, dynamic> getStats() {
    return {
      'size': size,
      'numHashes': numHashes,
      'byteArraySize': _bitArray.length,
    };
  }
}
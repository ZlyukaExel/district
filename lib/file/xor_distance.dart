BigInt xorDistance(String hash1, String hash2) {
  final bytes1 = _hexToBytes(hash1);
  final bytes2 = _hexToBytes(hash2);

  if (bytes1.length != bytes2.length) {
    throw ArgumentError("Длины хэшей не совпадают");
  }

  final xorBytes = List<int>.generate(
    bytes1.length,
    (i) => bytes1[i] ^ bytes2[i],
  );

  // Преобразуем в BigInt (big-endian)
  final distance = BigInt.parse(
    xorBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(),
    radix: 16,
  );

  print("Distance: $distance");
  return distance;
}

List<int> _hexToBytes(String hex) {
  if (hex.length % 2 != 0) {
    throw ArgumentError("Нечётная длина hex-строки");
  }
  final List<int> bytes = [];
  for (int i = 0; i < hex.length; i += 2) {
    final byte = int.parse(hex.substring(i, i + 2), radix: 16);
    bytes.add(byte);
  }
  return bytes;
}

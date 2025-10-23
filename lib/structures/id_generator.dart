import 'dart:convert';
import 'package:crypto/crypto.dart';

String generateRandomId(String input, {int length = 32}) {
  final bytes = utf8.encode(input);
  final hash = sha256.convert(bytes);
  return hash.toString();
}

import 'dart:convert';
import 'package:crypto/crypto.dart';

String generateRandomId(String input, {int length = 32}) {
  final now = DateTime.now();

  // Формат: YYYY-MM-DD_HH-mm-ss
  final dateTime =
      '${now.year.toString().padLeft(4, '0')}-'
      '${now.month.toString().padLeft(2, '0')}-'
      '${now.day.toString().padLeft(2, '0')}_'
      '${now.hour.toString().padLeft(2, '0')}-'
      '${now.minute.toString().padLeft(2, '0')}-'
      '${now.second.toString().padLeft(2, '0')}';

  final combinedInput = '$input$dateTime';
  final bytes = utf8.encode(combinedInput);
  final hash = sha256.convert(bytes);

  return hash.toString().substring(0, length);
}

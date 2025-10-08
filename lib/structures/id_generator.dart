import 'dart:math';

String generateRandomId({int length = 16}) {
  const String chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
  Random random = Random.secure();
  return String.fromCharCodes(Iterable.generate(
  length,
  (_) => chars.codeUnitAt(random.nextInt(chars.length))
));
}
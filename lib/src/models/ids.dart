import 'dart:math';

final Random _random = Random();

String createId() {
  final time = DateTime.now().microsecondsSinceEpoch.toRadixString(16);
  final salt = _random.nextInt(0xFFFFFF).toRadixString(16);
  return '$time$salt';
}

import 'dart:convert';
import 'dart:io';

import 'package:district/services/message.dart';

class TcpClient {
  late Socket server;

  Future<bool> startClient(int port) async {
    try {
      server = await Socket.connect(
        '127.0.0.1',
        port,
        timeout: Duration(seconds: 5),
      );

      // Принимаем сообщения от сервера
      server.listen(
        (eventBytes) {
          final Message result = Message.fromString(utf8.decode(eventBytes));
          print('Получено сообщение: $result');
        },
        onDone: () {
          print('Сервер закрыл соединение');
        },
        onError: (error) {
          print('Ошибка соединения: $error');
        },
      );

      Message message = Message(
        type: 'connect',
        from: 'user',
        timestamp: DateTime.now(),
      );

      // Отправляем сообщение о подключении
      server.add(utf8.encode(jsonEncode(message.toJson())));

      return true;
    } catch (e) {
      return false;
    }
  }
}

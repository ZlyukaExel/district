import 'dart:convert';
import 'dart:io';

import 'package:district/services/message.dart';

class TcpServer {
  late ServerSocket server;
  final List<Socket> clients = [];

  Future<int> startServer() async {
    server = await ServerSocket.bind('0.0.0.0', 0);

    // Слушаем подключения
    server.listen((socket) {
      // Добавляем клиента
      clients.add(socket);
      print('Клиент подключился');

      // Принимаем сообщения от клиента
      socket.listen(
        // Обычное сообщение
        (eventBytes) {
          final Message result = Message.fromString(utf8.decode(eventBytes));
          print('Получено сообщение: $result');
        },

        // Отключение клиента
        onDone: () {
          clients.remove(socket);
          print('Клиент $socket отключился');
        },

        // Ошибка клиента
        onError: (error) {
          clients.remove(socket);
          print('Ошибка клиента: $error');
        },
      );
    });

    return server.port;
  }

  void sendToAll(String message) {
    Message decoded = Message(
      type: 'message',
      from: 'server',
      data: message,
      timestamp: DateTime.now(),
    );

    // Кодируем сообщение
    final encoded = utf8.encode(jsonEncode(decoded.toJson()));

    // Отправляем
    for (final socket in clients) {
      socket.add(encoded);
    }
  }
}

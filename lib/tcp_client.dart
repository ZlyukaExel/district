import 'dart:convert';
import 'dart:io';

class TcpClient {
  late Socket server;

  Future<void> startClient(int port) async {
    server = await Socket.connect('127.0.0.1', port);

    // Принимаем сообщения от сервера
    server.listen((eventBytes) {
      final result = utf8.decode(eventBytes);
      print('Получено сообщение: $result');
    });

    // Отправляем сообщение о подключении
    server.add(utf8.encode('Привет!'));
  }
}

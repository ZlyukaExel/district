import 'dart:convert';
import 'dart:io';

class TcpServer {
  late ServerSocket server;
  int port = -1;
  final List<Socket> _clients = [];

  Future<void> startServer(void Function(int) onPortReady) async {
    server = await ServerSocket.bind('0.0.0.0', 0);
    port = server.port;
    onPortReady(port);

    // Слушаем подключения
    server.listen((socket) {
      // Добавляем клиента
      _clients.add(socket);
      print('Клиент $socket подключился');

      // Принимаем сообщения от клиента
      socket.listen(
        // Обычное сообщение
        (eventBytes) {
          final result = utf8.decode(eventBytes);
          print('Получено сообщение: $result');
          socket.add(utf8.encode('Сообщение получено'));
        },

        // Отключение клиента
        onDone: () {
          _clients.remove(socket);
          print('Клиент $socket отключился');
        },

        // Ошибка клиента
        onError: (error) {
          _clients.remove(socket);
          print('Ошибка клиента: $error');
        },
      );
    });
  }

  void sendToAll(String message) {
    // Кодируем сообщение
    final encoded = utf8.encode(message);

    // Отправляем
    for (final socket in _clients) {
      socket.add(encoded);
    }
  }
}

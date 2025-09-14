import 'dart:convert';
import 'dart:io';

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
          final result = utf8.decode(eventBytes);
          print('Получено сообщение: $result');
        },
        onDone: () {
          print('Сервер закрыл соединение');
        },
        onError: (error) {
          print('Ошибка соединения: $error');
        },
      );

      // Отправляем сообщение о подключении
      server.add(utf8.encode('Привет!'));

      return true;
    } catch (e) {
      return false;
    }
  }
}

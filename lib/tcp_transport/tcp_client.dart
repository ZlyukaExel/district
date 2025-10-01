import 'dart:io';
import 'package:district/structures/message.dart';

class TcpClient {
  late Socket server;

  Future<bool> startClient(int port) async {
    try {
      server = await Socket.connect(
        'localhost',
        port,
        timeout: Duration(seconds: 5),
      );

      print("Подключился к серверу на порт $port");

      // Принимаем сообщения от сервера
      server.listen((eventBytes) {
        final Message message = Message.decode(eventBytes);
        print('Получено сообщение: $message');

        // Проверяем наличие файла и отправляем ответ если нашли
        bool hasFile = true;
        if (message.type == MessageType.request && hasFile) {
          final answer = Message(
            type: MessageType.answer,
            from: 'user',
            data: message.data,
          );
          server.add(answer.encode());
        }
      });
      return true;
    } catch (e) {
      print("Не удалось подключиться: $e");
      return false;
    }
  }
}

import 'dart:async';
import 'dart:io';
import 'package:district/structures/message.dart';

class TcpServer {
  late ServerSocket server;
  final Set<Socket> clients = <Socket>{};
  Completer<Message>? _completer;
  Message? _expectedRequest;

  Future<int> startServer() async {
    server = await ServerSocket.bind('localhost', 0);

    // Слушаем клиентов
    server.listen((socket) async {
      clients.add(socket);

      socket.listen(
        (eventBytes) {
          final message = Message.decode(eventBytes);
          print('Получено сообщение: $message');

          // Если ожидаем ответ
          if (_completer != null && _expectedRequest != null) {
            // Проверяем, что это действительно ожидаемый ответ
            if (message.data == _expectedRequest!.data) {
              _completer!.complete(message);
              _completer = null;
              _expectedRequest = null;
            }
          }
        },

        onDone: () {
          clients.remove(socket);
        },

        onError: () {
          clients.remove(socket);
        },
      );
    });

    return server.port;
  }

  Future<Message?> sendToAll(Message message, bool awaitResponce) async {
    // Кодируем сообщение
    final encoded = message.encode();

    // Отправляем всем известным
    for (final socket in clients) {
      socket.add(encoded);
    }

    // Если ответ не нужен - возвращаемся сразу
    if (!awaitResponce) {
      return null;
    }

    // Ожидаем ответ
    _completer = Completer<Message>();
    _expectedRequest = message;

    // _completer отслеживает входящие сообщения
    // Ожидаем ответа 5 секунд
    try {
      final response = await _completer!.future.timeout(Duration(seconds: 5));
      return response;
    } on TimeoutException {
      _completer = null;
      _expectedRequest = null;
      return null;
    } catch (e) {
      print(e);
      _completer = null;
      _expectedRequest = null;
      return null;
    }
  }
}

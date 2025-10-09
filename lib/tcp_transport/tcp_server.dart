import 'dart:async';
import 'dart:io';
import 'package:district/structures/message.dart';
import 'package:district/structures/peer.dart';

class TcpServer {
  final Peer _peer;
  late ServerSocket _server;
  final Set<Socket> clients = <Socket>{};
  late final int port;
  Completer<Message>? _completer;
  Message? _expectedRequest;

  static Future<TcpServer> create(Peer peer) async {
    TcpServer server = TcpServer._(peer: peer);
    await server._startServer();
    return server;
  }

  TcpServer._({required Peer peer}) : _peer = peer;

  Future<void> _startServer() async {
    _server = await ServerSocket.bind('localhost', 0);

    // Слушаем клиентов
    _server.listen((socket) async {
      clients.add(socket);

      socket.listen(
        (eventBytes) {
          final message = Message.decode(eventBytes);
          _peer.messageGot(message);

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

        onError: (e) {
          clients.remove(socket);
          print("Tcp Server listen error: $e");
        },
      );
    });

    port = _server.port;
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

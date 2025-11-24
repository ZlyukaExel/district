import 'dart:async';
import 'dart:io';
import 'package:district/structures/client_info.dart';
import 'package:district/structures/messages/message.dart';
import 'package:district/structures/peer.dart';

class TcpServer {
  final Peer _peer;
  late ServerSocket _server;
  final Set<ClientInfo> clients = <ClientInfo>{};
  late final int port;

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
      socket.listen(
        (eventBytes) {
          final message = decodeMessage(eventBytes);
          _peer.messageGot(message, socket);
        },

        onDone: () {
          clients.removeWhere((client) => socket == client.socket);
        },

        onError: (e) {
          clients.removeWhere((client) => socket == client.socket);
          print("Ошибка при прослушивании клиента: $e");
        },
      );
    });

    port = _server.port;
  }

  void sendMessage(Message message) {
    // Кодируем сообщение
    final encoded = message.encode();

    if (message.to == null) {
      // Отправляем всем клиентам
      for (final client in clients) {
        message.to = client.id;
        client.socket.add(encoded);
      }
    } else {
      // Отправляем конкретному пользователю
      for (final client in clients) {
        if (client.id == message.to) {
          client.socket.add(encoded);
        }
      }
    }
  }
}

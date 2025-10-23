import 'dart:async';
import 'dart:io';
import 'package:district/structures/messages/message.dart';
import 'package:district/structures/peer.dart';

class TcpServer {
  final Peer _peer;
  late ServerSocket _server;
  final Set<Socket> clients = <Socket>{};
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
      clients.add(socket);

      socket.listen(
        (eventBytes) {
          final message = decodeMessage(eventBytes);
          _peer.messageGot(message, socket);
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

  void sendToAll(Message message) async {
    // Кодируем сообщение
    final encoded = message.encode();

    // Отправляем всем известным
    for (final socket in clients) {
      socket.add(encoded);
    }
  }
}

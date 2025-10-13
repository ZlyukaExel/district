import 'dart:io';
import 'package:district/structures/message.dart';
import 'package:district/structures/peer.dart';

class TcpClient {
  final int port;

  TcpClient._({required this.port});

  static Future<TcpClient?> startClient(Peer peer, int port) async {
    try {
      // Пробуем подключиться к серверу
      Socket server = await Socket.connect(
        'localhost',
        port,
        timeout: Duration(seconds: 5),
      );

      print("Подключился к серверу на порт $port");

      TcpClient client = TcpClient._(port: port);

      // Принимаем сообщения от сервера
      server.listen((eventBytes) {
        final Message message = Message.decode(eventBytes);
        peer.messageGot(message, server);
      });

      return client;
    } catch (e) {
      print("Не удалось подключиться: $e");
      return null;
    }
  }
}

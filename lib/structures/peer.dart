import 'dart:math';

// import 'package:district/preferences.dart';
import 'package:district/structures/message.dart';
import 'package:district/tcp_transport/tcp_client.dart';
import 'package:district/tcp_transport/tcp_server.dart';
// import 'package:uuid/uuid.dart';

class Peer {
  String id = 'Undefined';
  int port = -1;
  final server = TcpServer();
  final client = TcpClient();

  Future<void> initialize() async {
    Random random = Random.secure();

    // Получаем/создаем ID узла
    id = random.nextInt(10000000).toString();

    //await Preferences.getString('id', 'Undefined');
    // if (id == 'Undefined') {
    //   id = const Uuid().v4();
    //   Preferences.setString('id', id);
    // }

    // Получаем порт узла
    port = await server.startServer();
  }

  Future<bool> requestFile(String hashKey) async {
    final message = Message(type: MessageType.request, from: id, data: hashKey);
    final isFound = await server.sendToAll(message, true) != null;
    print('Файл $hashKey ${isFound ? 'найден' : 'не найден'}');
    return isFound;
  }
}

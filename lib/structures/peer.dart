import 'dart:math';

// import 'package:district/preferences.dart';
import 'package:district/structures/message.dart';
import 'package:district/tcp_transport/tcp_client.dart';
import 'package:district/tcp_transport/tcp_server.dart';
import 'package:district/udp_broadcast.dart';
// import 'package:uuid/uuid.dart';

class Peer {
  late final String id;
  late final int port;
  late final TcpServer _server;
  late final Set<TcpClient> _clients = <TcpClient>{};
  final _udpDiscovery = UdpDiscovery();

  Peer._();

  static Future<Peer> create() async {
    Random random = Random.secure();

    // Создаем пир
    Peer peer = Peer._();

    // Получаем/создаем ID узла
    //await Preferences.getString('id', 'Undefined');
    // if (id == 'Undefined') {
    //   id = const Uuid().v4();
    //   Preferences.setString('id', id);
    // }
    peer.id = random.nextInt(10000000).toString();

    // Запускаем сервер
    peer._server = await TcpServer.create(peer);

    // Получаем пир сервера
    peer.port = peer._server.port;

    return peer;
  }

  void startDiscovery() {
    _udpDiscovery.startDiscovery(this);
  }

  Future<bool> requestFile(String hashKey) async {
    print('Запрошен файл $hashKey');
    final message = Message(type: MessageType.request, from: id, data: hashKey);
    final isFound = await _server.sendToAll(message, true) != null;
    print('Файл $hashKey ${isFound ? 'найден' : 'не найден'}');
    return isFound;
  }

  void send(String text) {
    final message = Message(type: MessageType.debug, from: id, data: text);
    _server.sendToAll(message, false);
  }

  void messageGot(Message message) {
    print('Получено сообщение: $message');
  }

  Future<bool> connect(int port) async {
    bool alreadyConnected = false;
    for (var client in _clients) {
      if (port == client.port) {
        alreadyConnected = true;
        break;
      }
    }

    if (!alreadyConnected) {
      TcpClient? client = await TcpClient.startClient(this, port);
      if (client != null) {
        _clients.add(client);
        return true;
      }
    }

    return false;
  }
}

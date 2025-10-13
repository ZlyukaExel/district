import 'dart:io';
import 'package:district/structures/hashed_file.dart';
import 'package:district/structures/id_generator.dart';
import 'package:district/structures/message.dart';
import 'package:district/tcp_transport/tcp_client.dart';
import 'package:district/tcp_transport/tcp_server.dart';
import 'package:district/udp_discovery.dart';
import 'package:flutter/material.dart';

class Peer {
  late final String id;
  late final int port;
  late final BuildContext context;
  late final TcpServer _server;
  late final Set<TcpClient> _clients = <TcpClient>{};
  final _udpDiscovery = UdpDiscovery();
  late final ValueNotifier<List<HashedFile>> _files;

  Peer._();

  static Future<Peer> create(
    BuildContext context,
    ValueNotifier<List<HashedFile>> files,
  ) async {
    // Создаем пир
    Peer peer = Peer._();

    peer.context = context;

    // Создаем ID узла
    peer.id = generateRandomId();

    // Запускаем сервер
    peer._server = await TcpServer.create(peer);

    // Получаем порт сервера
    peer.port = peer._server.port;

    // Передаем ссылку на список файлов
    peer._files = files;

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

  void messageGot(Message message, Socket sender) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("$message")));

    // Проверяем наличие файла и отправляем ответ если нашли
    if (message.type == MessageType.request) {
      bool containsFile = false;
      for (var hashedFile in _files.value) {
        if (hashedFile.hash == message.data) {
          containsFile = true;
          break;
        }
      }

      if (containsFile) {
        final answer = Message(
          type: MessageType.answer,
          from: id,
          to: message.from,
          data: message.data,
        );
        sender.add(answer.encode());
      }
    }
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

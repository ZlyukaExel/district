import 'dart:async';
import 'dart:io';
import 'package:district/structures/client_info.dart';
import 'package:district/structures/hashed_file.dart';
import 'package:district/structures/id_generator.dart';
import 'package:district/structures/messages/answer_message.dart';
import 'package:district/structures/messages/connect_message.dart';
import 'package:district/structures/messages/message.dart';
import 'package:district/structures/messages/request_message.dart';
import 'package:district/tcp_transport/tcp_client.dart';
import 'package:district/tcp_transport/tcp_server.dart';
import 'package:district/udp_discovery.dart';
import 'package:flutter/material.dart';
import 'package:district/structures/bloom_filter.dart';
import 'package:district/structures/hash_table.dart';

class Peer {
  late final String id;
  late final int port;
  static final int K = 3;
  late final BuildContext context;
  late final TcpServer _server;
  final _udpDiscovery = UdpDiscovery();
  late final BloomFilter _bloomFilter;
  late final HashTable<String, dynamic> _fileMetadata;
  late final ValueNotifier<List<HashedFile>> _files;


  Completer<Message>? _completer;
  Message? _expectedRequest;

  Peer._();

  static Future<Peer> create(
    BuildContext context,
    ValueNotifier<List<HashedFile>> files,
  ) async {
    // Создаем пир
    Peer peer = Peer._();

    peer.context = context;

    // Создаем ID узла
    peer.id = generateRandomId(
      DateTime.now().microsecondsSinceEpoch.toString(),
    );

    print("ID узла: ${peer.id}");

    // Запускаем сервер
    peer._server = await TcpServer.create(peer);

    // Получаем порт сервера
    peer.port = peer._server.port;

    // Передаем ссылку на список файлов
    peer._files = files;

    peer._bloomFilter = BloomFilter(size: 50000, numHashes: 3);

    peer._fileMetadata = HashTable<String, dynamic>();
     for (final hashedFile in files.value) {
      peer._bloomFilter.addFile(hashedFile.hash);
      peer._fileMetadata.put(hashedFile.hash, {
        'hash': hashedFile.hash,
        'peer_id': peer.id,
        'timestamp': DateTime.now().toIso8601String(),
      });
    }
    
    return peer;
  }

  void startDiscovery() {
    _udpDiscovery.startDiscovery(this);
  }

  Future<bool> requestFile(String hashKey) async {
    if (!_bloomFilter.hasFile(hashKey)) {
      print(' Файл $hashKey отсутствует в сети');
    if (context.mounted) {
       ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(' Файл не найден в сети'),
          backgroundColor: Colors.red,
        ),
      );
    }
    return false;
  }
    print('Запрошен файл $hashKey');
    final message = RequestMessage(from: id, data: hashKey);
    _server.sendMessage(message);

    // Ожидаем ответ
    bool isFound = false;

    // Completer отслеживает входящие сообщения
    _completer = Completer<Message>();
    _expectedRequest = message;

    // Ожидаем ответа 5 секунд
    try {
      await _completer!.future.timeout(Duration(seconds: 5));
      isFound = true;
    } on TimeoutException {
      _completer = null;
      _expectedRequest = null;
    } catch (e) {
      print(e);
      _completer = null;
      _expectedRequest = null;
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Файл $hashKey ${isFound ? 'найден' : 'не найден'}'),
        ),
      );
    }

    return isFound;
  }

  void messageGot(Message message, Socket sender) {
    // Если сообщение нам, обрабатываем его
    if (message.to == null || message.to == id) {
      // Если это запрос на подключение
      if (message is ConnectMessage) {
        bool alreadyConnected = _server.clients.any(
          (client) => client.id == message.from,
        );

        print("Запрос на подключение. Уже подключен: $alreadyConnected");

        // Если ещё не подключен, добавляем клиента в список
        if (!alreadyConnected) {
          ClientInfo client = ClientInfo(
            id: message.from,
            port: message.data,
            socket: sender,
          );
          _server.clients.add(client);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Подключился к ${message.from}')),
          );

          // Также отправляем обратный ответ
          ConnectMessage connectMessage = ConnectMessage(
            from: id,
            to: message.from,
            data: port,
          );

          sender.add(connectMessage.encode());
        }
      }
      // Если это запрос файла
      else if (message is RequestMessage) {
        bool containsFile = false;
        for (final hashedFile in _files.value) {
          if (hashedFile.hash == message.data) {
            containsFile = true;
            break;
          }
        }

        // Если имеем файл, возвращаем его хэш
        if (containsFile) {
          final answer = AnswerMessage(
            from: id,
            to: message.from,
            data: message.data,
          );
          sender.add(answer.encode());
        }
        // Если файла нет, возвращаем список имеющихся узлов для продолжения поиска
        else {
          final answer = AnswerMessage(
            from: id,
            to: message.from,
            data: _server.clients.map((client) => client.id).toList(),
          );
          sender.add(answer.encode());
        }
      }
      // Если это ответ
      else if (message is AnswerMessage) {
        // Если мы ожидаем ответ
        if (_completer != null && _expectedRequest != null) {
          // Если файл уже найден, заканчиваем поиск
          if (_expectedRequest!.data == message.data) {
            print("Файл ${_expectedRequest!.data} найден!");
            _completer!.complete(message);
            _completer = null;
            _expectedRequest = null;
          }
          // Если вернулся список других узлов - опрашиваем уже их =====================================================
          else {
            for (final peerId in message.data.toString().split(', ')) {
              final newMessage = RequestMessage(
                from: id,
                to: peerId,
                data: _expectedRequest?.data,
              );
              _server.sendMessage(newMessage);
            }
          }
        }
      }
    }
    // Если сообщение не нам, игнорируем его
    else {
      print("Сообщение не нам, игнорируем");
    }
  }

  Future<bool> connect(String senderId, int port) async {
    bool alreadyConnected = _server.clients.any(
      (client) => client.port == port,
    );

    // Если уже подключен, возвращаемся
    if (alreadyConnected) {
      return true;
    }

    print(
      "[Connect] Уже подключен: $alreadyConnected\n"
      "${_server.clients.map((client) => client.port)}, порт: $port",
    );

    final connectMessage = ConnectMessage(
      from: id,
      to: senderId,
      data: this.port,
    );

    TcpClient? client = await TcpClient.startClient(this, port, connectMessage);
    if (client != null) {
      return true;
    }
    return false;
  }
  void addFileToBloomFilter(String fileHash) {
    _bloomFilter.addFile(fileHash);
    _fileMetadata.put(fileHash, {
      'hash': fileHash,
      'peer_id': id,
      'timestamp': DateTime.now().toIso8601String(),
    });
    print('Файл $fileHash добавлен в фильтр');
  }

  bool keepSearching() => _server.clients.length < K;
}

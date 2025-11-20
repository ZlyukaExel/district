import 'dart:async';
import 'dart:io';
import 'package:district/structures/hashed_file.dart';
import 'package:district/structures/id_generator.dart';
import 'package:district/structures/messages/answer_message.dart';
import 'package:district/structures/messages/debug_message.dart';
import 'package:district/structures/messages/message.dart';
import 'package:district/structures/messages/request_message.dart';
import 'package:district/tcp_transport/tcp_client.dart';
import 'package:district/tcp_transport/tcp_server.dart';
import 'package:district/udp_discovery.dart';
import 'package:flutter/material.dart';
import 'package:district/structures/bloom_filter.dart';
import 'package:district/structures/hash_table.dart';
import 'package:district/structures/avl_tree.dart';

class Peer {
  late final String id;
  late final int port;
  static final int K = 8;
  late final BuildContext context;
  late final TcpServer _server;
  late final Set<TcpClient> _clients = <TcpClient>{};
  final _udpDiscovery = UdpDiscovery();
  late final ValueNotifier<List<HashedFile>> _files;
  late final BloomFilter _bloomFilter;
  late final HashTable<String, dynamic> _fileMetadata;
  late final AVLTree _reputationTree;

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

    peer._reputationTree = AVLTree();

    return peer;
  }

  void startDiscovery() {
    _udpDiscovery.startDiscovery(this);
  }

  Future<bool> requestFile(String hashKey) async {
    print('Запрошен файл $hashKey');
    final message = RequestMessage(from: id, data: hashKey);
    _server.sendToAll(message);

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

  void send(String text) {
    final message = DebugMessage(from: id, data: text);
    _server.sendToAll(message);
  }

  void messageGot(Message message, Socket sender) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("$message")));

    print(message.to);

    // Если сообщение нам, обрабатываем его
    if (message.to == null || message.to == id) {
      // Проверяем наличие файла и отправляем ответ если нашли
      if (message is RequestMessage) {
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
            data: _clients.join(),
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
          // Если вернулся список других узлов - опрашиваем уже их
          else {
            for (final peerId in message.data.toString().split(' ')) {
              final newMessage = RequestMessage(
                from: id,
                to: peerId,
                data: _expectedRequest?.data,
              );
              _server.sendToAll(newMessage);
            }
          }
        }
      }
    }
    // Если не нам, передаем дальше
    // --To-do: Вызывает петли запросов
    else {
      print("Сообщение не нам, передаем дальше");
      //_server.sendToAll(message);
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
  // Добавить файл 
void addFileToBloomFilter(String fileHash) {
_bloomFilter.addFile(fileHash);
print(' Файл $fileHash добавлен в фильтр Блума');
}

// Проверить наличие файла
bool checkFileInBloomFilter(String fileHash) {
return _bloomFilter.hasFile(fileHash);
}

// Добавить несколько файлов 
void addFilesToBloomFilter(List<String> fileHashes) {
_bloomFilter.addFiles(fileHashes);
print(' ${fileHashes.length} файлов добавлены в фильтр Блума');
}
// Сохранить метаданные файла
void storeFileMetadata(String fileHash, Map<String, dynamic> metadata) {
_fileMetadata.put(fileHash, metadata);
print(' Метаданные файла $fileHash сохранены');
}

//Получить метаданные
Map<String, dynamic>? getFileMetadata(String fileHash) {
return _fileMetadata.get(fileHash);
}
// Проверить, есть ли метаданные 
bool hasFileMetadata(String fileHash) {
return _fileMetadata.containsKey(fileHash);
}
List<Map<String, dynamic>> getAllFilesMetadata() {
return _fileMetadata.getValues().cast<Map<String, dynamic>>();
}
/// Добавить репутационный рейтинг пира
void addPeerReputation(int reputation) {
_reputationTree.insert(reputation);
print(' Рейтинг пира добавлен: $reputation');
}

// Проверить наличие рейтинга
bool hasPeerReputation(int reputation) {
return _reputationTree.search(reputation);
}

// Получить отсортированные
List<int> getSortedReputations() {
return _reputationTree.inOrder();
}

double getAverageReputation() {
List<int> reputations = getSortedReputations();
if (reputations.isEmpty) return 0;
int sum = reputations.fold(0, (a, b) => a + b);
return sum / reputations.length;
}
}

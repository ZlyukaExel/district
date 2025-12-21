import 'dart:async';
import 'dart:io';
import 'package:district/structures/hashed_file.dart';
import 'package:district/structures/id_generator.dart';
import 'package:district/structures/messages/answer_message.dart';
import 'package:district/structures/messages/connect_message.dart';
import 'package:district/structures/messages/message.dart';
import 'package:district/structures/messages/request_message.dart';
import 'package:district/udp_discovery.dart';
import 'package:flutter/material.dart';
import 'package:district/structures/bloom_filter.dart';
import 'package:district/structures/hash_table.dart';

class Peer {
  late final String id;
  static final int K = 3;
  late final BuildContext context;
  final _udpTransport = UdpTransport();
  final _peers = <String>{};
  final BloomFilter _bloomFilter = BloomFilter(size: 50000, numHashes: 3);
  final HashTable<String, dynamic> _fileMetadata = HashTable<String, dynamic>();
  late final ValueNotifier<List<HashedFile>> _files;

  Completer<Message?>? _completer;
  Message? _expectedRequest;
  Set<String>? _askedPeers;
  Set<String>? _alreadyAskedPeers;

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

    // Передаем ссылку на список файлов
    peer._files = files;
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

  void startTransport() {
    _udpTransport.start(this);
  }

  Future<bool> requestFile(String hashKey) async {
    print('Запрошен файл $hashKey');

    // Если нет узлов, то и опрашивать некого
    if (_peers.isEmpty) {
      print("No peers found");
      _finishSearch(false, "Нет знакомых узлов");
      return false;
    }

    final message = RequestMessage(from: id, data: hashKey);
    _askedPeers = <String>{};
    _alreadyAskedPeers = <String>{id};

    // Отправляем запросы всем узлам
    for (final peer in _peers) {
      message.to = peer;
      _udpTransport.send(message);
      _askedPeers!.add(peer);
    }

    // Ожидаем ответ
    bool isFound = false;

    // Completer отслеживает входящие сообщения
    _completer = Completer<Message?>();
    _expectedRequest = message;

    String resultMessage;

    // Ожидаем ответа 5 секунд
    try {
      Message? answer = await _completer!.future.timeout(Duration(seconds: 5));
      if (answer == null) {
        resultMessage = "Все известные узлы были опрошены";
      } else {
        isFound = true;
        resultMessage = "Проблем не обнаружено";
      }
    } on TimeoutException {
      resultMessage = "Время ожидания истекло";
    } catch (e) {
      resultMessage = e.toString();
    }

    _finishSearch(isFound, resultMessage);
    return isFound;
  }

  void handleMessage(Message message, InternetAddress address, int port) {
    // Если это запрос на подключение
    if (message is ConnectMessage) {
      if (_peersNeeded()) {
        //print("Узел ${message.from} подключился");
        _peers.add(message.from);
      }
    }
    // Если это запрос файла
    else if (message is RequestMessage) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Получено сообщение $message')));

      bool containsFile = _bloomFilter.hasFile(message.data);

      if (containsFile) {
        containsFile = false;
        for (final hashedFile in _files.value) {
          if (hashedFile.hash == message.data) {
            containsFile = true;
            break;
          }
        }
      }

      // Если имеем файл, отправляем его
      if (containsFile) {
        final answer = AnswerMessage(
          from: id,
          to: message.from,
          data: message.data,
        );
        _udpTransport.send(answer, address: address, port: port);
        _udpTransport.sendFile();
      }
      // Если файла нет, возвращаем список имеющихся узлов для продолжения поиска
      else {
        final answer = AnswerMessage(
          from: id,
          to: message.from,
          data: _peers.toList(),
        );
        _udpTransport.send(answer, address: address, port: port);
      }
    }
    // Если это ответ
    else if (message is AnswerMessage) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Получен ответ $message')));

      // Если мы ожидаем ответ
      if (_completer != null &&
          _expectedRequest != null &&
          _askedPeers!.contains(message.from)) {
        // Если файл найден, заканчиваем поиск
        if (_expectedRequest!.data == message.data) {
          print("Файл ${_expectedRequest!.data} найден!");
          _completer!.complete(message);
        }
        // Если вернулся список других узлов - опрашиваем уже их
        else {
          for (final peerId in message.data) {
            // Пропускаем уже опрошенные узлы
            if (_alreadyAskedPeers!.contains(peerId)) {
              continue;
            }
            _expectedRequest!.to = peerId;
            _udpTransport.send(_expectedRequest!);
            _askedPeers!.add(peerId);
          }

          _askedPeers!.remove(message.from);
          _alreadyAskedPeers!.add(message.from);

          if (_askedPeers!.isEmpty) {
            print("Все доступные узлы были опрошены");
            _completer!.complete(null);
          }
        }
      }
    }
  }

  void _finishSearch(bool isFound, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Запрошенный файл ${isFound ? 'найден' : 'не найден'}: $message',
          ),
        ),
      );
    }

    _completer = null;
    _expectedRequest = null;
    _askedPeers = _alreadyAskedPeers = null;
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

  bool _peersNeeded() => _peers.length < K;
}

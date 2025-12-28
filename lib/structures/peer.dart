import 'dart:async';
import 'dart:io';
import 'package:district/structures/hashed_file.dart';
import 'package:district/structures/id_generator.dart';
import 'package:district/structures/messages/answer_message.dart';
import 'package:district/structures/messages/connect_message.dart';
import 'package:district/structures/messages/message.dart';
import 'package:district/structures/messages/request_message.dart';
import 'package:district/structures/notifier_list.dart';
import 'package:district/udp_transport.dart';
import 'package:flutter/material.dart';
import 'package:district/structures/bloom_filter.dart';
import 'package:district/structures/hash_table.dart';
import 'package:district/structures/client_info.dart';

class Peer {
  late final String id;
  static final int K = 3;
  late final BuildContext _context;
  final _udpTransport = UdpTransport();
  final _peers = <String>{};
  final BloomFilter _bloomFilter = BloomFilter(size: 50000, numHashes: 3);
  final HashTable<String, dynamic> _fileMetadata = HashTable<String, dynamic>();
  late final NotifierList<HashedFile> _files;
  late final ClientInfo clientInfo;
  final Set<String> _fileHashes = <String>{};

  Completer<Message?>? _completer;
  Message? _expectedRequest;
  Set<String>? _askedPeers;
  Set<String>? _alreadyAskedPeers;

  Peer._();

  static Future<Peer> create(
    BuildContext context,
    NotifierList<HashedFile> files,
  ) async {
    Peer peer = Peer._();
    peer._context = context;
    peer.id = generateRandomId(
      DateTime.now().microsecondsSinceEpoch.toString(),
    );
    print("ID узла: ${peer.id}");

    peer.clientInfo = await ClientInfo.load(peer.id);
    print("Директория загрузок: ${peer.clientInfo.downloadDirectory}");
    print("Узел видим: ${peer.clientInfo.isVisible}");

    peer._files = files;
    for (final hashedFile in files.value) {
      peer._fileHashes.add(hashedFile.hash);
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

    if (_peers.isEmpty) {
      print("No peers found");
      _showMessage(false, "Нет знакомых узлов");
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

    bool isFound = false;

    _completer = Completer<Message?>();
    _expectedRequest = message;

    try {
      Message? answer = 
          await _completer!.future
              .timeout(
                Duration(seconds: 5),
                onTimeout: () {
                  _showMessage(isFound, "превышено время ожидания");
                  return null;
                },
              )
              .catchError((e) {
                _showMessage(isFound, "ошибка при поиске файла: $e");
                return null;
              });

      if (answer == null) {
        _showMessage(isFound, "файл не найден на известных узлах");
      } else {
        isFound = true;
        _showMessage(isFound, "успех!");
      }
    } finally {
      _completer = null;
      _expectedRequest = null;
      _askedPeers = null;
      _alreadyAskedPeers = null;
    }

    return isFound;
  }

  void _showMessage(bool isFound, String message) {
    // Проверяем, жив ли контекст
    if (!_context.mounted) {
      print("Context not mounted, skipping snackbar");
      return;
    }

    try {
      ScaffoldMessenger.of(_context).showSnackBar(
        SnackBar(
          content: Text(
            'Файл ${isFound ? 'найден' : 'не найден'}: $message',
          ),
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      print("Ошибка при показе сообщения: $e");
    }
  }

  Future<void> handleMessage(
    Message message,
    InternetAddress address,
    int port,
  ) async {
    try {
      // Если это запрос на подключение
      if (message is ConnectMessage) {
        if (_peersNeeded() && !_peers.contains(message.from)) {
          _peers.add(message.from);
          print("Узел ${message.from} подключился");
        }
      }
      // Если это запрос файла
      else if (message is RequestMessage) {
        _showToast('Получено сообщение от ${message.from}');

        bool containsFile = hasFile(message.data);

        // Если имеем файл, отправляем его
        if (containsFile) {
          final answer = AnswerMessage(
            from: id,
            to: message.from,
            data: message.data,
          );
          _udpTransport.send(answer, address: address, port: port);
          
          unawaited(
            sendFileToAddress(message.data, address, 9998),
          );
        }
        // Если у нас файла нет, возвращаем список имеющихся узлов
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
        _showToast('Получен ответ от ${message.from}');

        // Если мы ожидаем ответ
        if (_completer != null &&
            !_completer!.isCompleted &&
            _expectedRequest != null &&
            _askedPeers!.contains(message.from)) {
          
          // Если файл найден, заканчиваем поиск
          if (_expectedRequest!.data == message.data) {
            print("Файл ${_expectedRequest!.data} найден!");
            if (!_completer!.isCompleted) {
              _completer!.complete(message);
            }
          }
          // Если вернулся список других узлов - опрашиваем их
          else {
            for (final peerId in message.data) {
              if (_alreadyAskedPeers!.contains(peerId)) {
                continue;
              }
              _expectedRequest!.to = peerId;
              _udpTransport.send(_expectedRequest!);
              _askedPeers!.add(peerId);
            }

            _askedPeers!.remove(message.from);
            _alreadyAskedPeers!.add(message.from);

            // Если нет больше узлов для опроса
            if (_askedPeers!.isEmpty && _completer != null && !_completer!.isCompleted) {
              print("Все доступные узлы были опрошены");
              _completer!.complete(null);
            }
          }
        }
      }
    } catch (e) {
      print("Ошибка в handleMessage: $e");
    }
  }

  void _showToast(String message) {
    if (!_context.mounted) return;
    try {
      ScaffoldMessenger.of(_context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: Duration(seconds: 1),
        ),
      );
    } catch (e) {
      print("Toast error: $e");
    }
  }

  void addFile(HashedFile hashedFile) {
    if (_fileHashes.contains(hashedFile.hash)) {
      print('Файл уже есть: ${hashedFile.path}');
      return;
    }

    _files.value = [..._files.value, hashedFile];
    _fileHashes.add(hashedFile.hash);

    _bloomFilter.addFile(hashedFile.hash);
    _fileMetadata.put(hashedFile.hash, {
      'hash': hashedFile.hash,
      'peer_id': id,
      'timestamp': DateTime.now().toIso8601String(),
    });

    print('Файл добавлен: ${hashedFile.path}');
    return;
  }

  bool hasFile(String hashKey) => _fileHashes.contains(hashKey);

  Future<void> sendFileToAddress(
    String fileHash,
    InternetAddress address,
    int port,
  ) async {
    try {
      HashedFile? targetFile;
      for (final file in _files.value) {
        if (file.hash == fileHash) {
          targetFile = file;
          break;
        }
      }

      if (targetFile == null) {
        print('Файл с хешом $fileHash не найден');
        return;
      }

      final transferId = generateRandomId(
        '${id}_${fileHash}_${DateTime.now().microsecondsSinceEpoch}',
      );

      print('Начинаем передачу файла: ${targetFile.path}');

      await _udpTransport.sendFile(
        targetFile.path,
        transferId,
        address,
        port,
      );
    } catch (e) {
      print('Ошибка при отправке файла: $e');
    }
  }

  bool _peersNeeded() => _peers.length < K;
}

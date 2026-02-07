import 'dart:async';
import 'dart:io';
import 'package:collection/collection.dart';
import 'package:district/file/hashed_file.dart';
import 'package:district/file/sending_file.dart';
import 'package:district/file/xor_distance.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:district/foreground_services/MyTaskHandler.dart';
import 'package:district/message/cancel_operation_message.dart';
import 'package:district/message/find_node_message.dart';
import 'package:district/message/node_answer_message.dart';
import 'package:district/message/store_message.dart';
import 'package:district/message/value_answer_message.dart';
import 'package:district/client/id_generator.dart';
import 'package:district/message/advertising_message.dart';
import 'package:district/message/message.dart';
import 'package:district/message/find_value_message.dart';
import 'package:district/structures/notifier_list.dart';
import 'package:district/udp_transport.dart';
import 'package:flutter/material.dart';
import 'package:district/structures/bloom_filter.dart';
import 'package:district/structures/hash_table.dart';
import 'package:district/client/client_info.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

class Peer {
  late final String id;
  static const int K = 20;
  static const int _alpha = 3;
  late final BuildContext _context;
  late BloomFilter _bloomFilter = BloomFilter(size: 50000, numHashes: 3);
  final HashTable<String, String> _fileMetadata = HashTable<String, String>();
  late final NotifierList<HashedFile> _files;
  late final NotifierList<SendingFile> _sendingFiles;
  late final ClientInfo clientInfo;
  late final void Function(Object) sendToTransport;

  Function? _findNodeCallback;
  Function? _findValueCallback;

  // Storage of peers
  final Map<String, Timer> peers = {};

  Peer._() {}

  static Future<Peer> create(
    BuildContext context,
    NotifierList<HashedFile> files,
    NotifierList<SendingFile> sendingFiles,
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
    peer._sendingFiles = sendingFiles;
    for (final hashedFile in files.value) {
      peer._bloomFilter.addFile(hashedFile.hash);
      peer._fileMetadata.put(hashedFile.hash, peer.id);
    }

    FlutterForegroundTask.addTaskDataCallback(peer._onReceiveTaskData);
    if (Platform.isAndroid) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        requestPermissions();
        initService();
        startService(peer.id, peer.clientInfo.downloadDirectory);
      });
      peer.sendToTransport = FlutterForegroundTask.sendDataToTask;
    } else {
      final transport = UdpTransport(
        id: peer.id,
        sendToPeer: peer._onReceiveTaskData,
        downloadDirectory: peer.clientInfo.downloadDirectory,
      );
      transport.start();
      peer.sendToTransport = transport.onDataFromPeerRecieved;
    }

    return peer;
  }

  Future<bool> requestFile(String hashKey) async {
    print('Запрашиваем файл $hashKey');

    // Если нет знакомых узлов, даже не проверяем
    if (peers.isEmpty) {
      print("Нет знакомых узлов");
      showToast("File not found: no peers added");
      return false;
    }

    final message = FindValueMessage(from: id, data: hashKey);
    sendToTransport({'fileHash': hashKey, 'download': true});
    Map<String, BigInt> closestPeers = _findClosestLocalPeers(hashKey);
    final checkedPeers = <String>{id};

    // Результат работы
    Message? result;

    void handleAnswer(Message msg) {
      print("Получен ответ от ${msg.from}");

      // Если файл найден, сохраняем ответ
      if (msg.data is String && hashKey == msg.data) {
        result = msg;
      }
      // Если вернулся список других узлов - добавляем их в список для допроса
      else if (msg.data is Map) {
        Map<String, dynamic> serialized = msg.data;
        final deserialized = serialized.map(
          (key, value) => MapEntry(key, BigInt.parse(value.toString())),
        );

        closestPeers.addAll(deserialized);
      }
    }

    _findValueCallback = handleAnswer;

    // Отправляем запросы ближайшим узлам
    bool hasNew;
    do {
      hasNew = false;
      for (final peer in closestPeers.keys) {
        // Пропускаем уже опрошенные узлы
        if (checkedPeers.contains(peer)) {
          continue;
        }

        // Отправляем запрос на новый узел
        hasNew = true;
        message.to = peer;
        sendToTransport(message.toJson());
        checkedPeers.add(peer);
      }

      // Небольшая задержка для получения ответа
      await Future.delayed(Duration(seconds: 3));

      // Сортируем по расстоянию
      final sortedPeers = closestPeers.entries.toList()
        ..sort((a, b) => a.value.compareTo(b.value));

      // Берем только alpha ближайших узлов
      closestPeers = Map.fromEntries(sortedPeers.take(_alpha));
    } while (hasNew && result == null);

    print(
      "Файл $hashKey ${result != null ? 'найден' : 'не найден на известных узлах'}",
    );
    showToast(result != null ? 'File found' : 'File not found on peers');

    _findValueCallback = null;

    // Stop waiting if not found
    if (result == null) {
      sendToTransport({'fileHash': hashKey, 'download': false});
    }

    return result != null;
  }

  void handleJson(Map<String, dynamic> json) {
    Message message = Message.fromJson(json);
    handleMessage(message, InternetAddress(json['address']), json['port']);
  }

  Future<void> handleMessage(
    Message message,
    InternetAddress address,
    int port,
  ) async {
    try {
      // Если это реклама
      if (message is AdvertisingMessage) {
        if (peers.containsKey(message.from) || _peersNeeded()) {
          if (!peers.containsKey(message.from)) {
            showToast('Connected to ${message.from}');
            print('Connected to ${message.from}');
          } else {
            print('just reset the timer: ${DateTime.now()}');
          }
          peers[message.from]?.cancel();
          peers[message.from] = Timer(Duration(seconds: 12), () {
            peers.remove(message.from);
            if (Platform.isAndroid) {
              FlutterForegroundTask.sendDataToTask(peers.length);
            }
            showToast(
              "Peer ${message.from} was absen for too long and disconnected",
            );
            print(
              "Peer ${message.from} was absen for too long and disconnected: ${DateTime.now()}",
            );
          });
          if (Platform.isAndroid) {
            FlutterForegroundTask.sendDataToTask(peers.length);
          }
        }
      }
      // Если это поиск файла
      else if (message is FindValueMessage) {
        //showToast('Получен запрос файла от ${message.from}');

        String? fileOwner = getFileOwner(message.data);

        // Если имеем файл, отправляем данные о нем от имени владельца
        if (fileOwner != null) {
          print(
            "Запрошенный другим узлом файл ${message.data} найден на узле $fileOwner",
          );

          final answer = ValueAnswerMessage(
            from: fileOwner,
            to: message.from,
            data: message.data,
          );
          Map<String, dynamic> json = answer.toJson();
          json['address'] = address.address;
          json['port'] = port;
          sendToTransport(json);

          unawaited(sendFileToAddress(message.data, address, 9998));
        }
        // Если мы ничего не знаем о файле, возвращаем список ближайших узлов
        else {
          final closestPeers = _findClosestLocalPeers(message.data);
          final serialized = closestPeers.map(
            (key, value) => (MapEntry(key, value.toString())),
          );

          print(
            "Запрошенный другим узлом файл ${message.data} может быть на узлах $closestPeers",
          );

          final answer = ValueAnswerMessage(
            from: id,
            to: message.from,
            data: serialized,
          );
          Map<String, dynamic> json = answer.toJson();
          json['address'] = address.address;
          json['port'] = port;
          sendToTransport(json);
        }
      }
      // Если это поиск ближайшего узла
      else if (message is FindNodeMessage) {
        final closestPeers = _findClosestLocalPeers(message.data);
        final serializedClosestPeers = closestPeers.map(
          (key, value) => (MapEntry(key, value.toString())),
        );

        NodeAnswerMessage answer = NodeAnswerMessage(
          from: id,
          to: message.from,
          data: serializedClosestPeers,
        );
        Map<String, dynamic> json = answer.toJson();
        json['address'] = address.address;
        json['port'] = port;
        sendToTransport(json);
      }
      // Если это ответ по поводу узла
      else if (message is ValueAnswerMessage) {
        if (_findValueCallback != null) {
          _findValueCallback!(message);
        }
      }
      // Если это ответ по поводу файла
      else if (message is NodeAnswerMessage) {
        if (_findNodeCallback != null) {
          _findNodeCallback!(message);
        }
      }
      // Если это запрос на хранение файла
      else if (message is StoreMessage) {
        // showToast(
        //   'Получен запрос на хранение файла ${message.data} от ${message.from}',
        // );

        // Записываем файл себе
        _fileMetadata.put(message.data, message.from);
        _bloomFilter.addFile(message.data);

        print("Файл ${message.data} записан по запросу ${message.from}");
      }
      // Если это отмена операции
      else if (message is CancelOperationMessage) {
        sendToTransport({'transferId': message.data, 'download': false});
      }
      // Неизвестный тип сообщения
      else {
        print("Неизвестный тип сообщения ${message.data}");
      }
    } catch (e) {
      print("Ошибка в handleMessage: $e");
    }
  }

  void showToast(String message) {
    if (!_context.mounted) return;
    try {
      if (Platform.isAndroid) {
        Fluttertoast.showToast(msg: message);
      } else {
        ScaffoldMessenger.of(_context).showSnackBar(
          SnackBar(content: Text(message), duration: Duration(seconds: 1)),
        );
      }
    } catch (e) {
      print("Toast error: $e");
    }
  }

  void addFile(HashedFile hashedFile) {
    if (_files.value.contains(hashedFile.hash)) {
      print('Файл уже есть: ${hashedFile.path}');
      return;
    }

    // Список для отображения
    _files.add(hashedFile);

    // Сохраняем информацию о файле у себя
    _fileMetadata.put(hashedFile.hash, id);
    _bloomFilter.addFile(hashedFile.hash);

    // Записываем файл в ближайшие узлы
    _writeFileToPeers(hashedFile.hash);

    print('Файл успешно добавлен: ${hashedFile.path}');
    return;
  }

  void deleteFile(HashedFile hashedFile) {
    _files.remove(hashedFile);
    _recreateBloomFilter();
  }

  String? getFileOwner(String hashKey) => _fileMetadata.get(hashKey);

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

      final message = {
        'path': targetFile.path,
        'transferId': transferId,
        'address': address.address,
        'port': port,
      };

      sendToTransport(message);
    } catch (e) {
      print('Ошибка при отправке файла: $e');
    }
  }

  bool _peersNeeded() => peers.length < K;

  void _writeFileToPeers(String fileHash) async {
    Message writeMessage = StoreMessage(from: id, data: fileHash);

    final closestPeers = await _findClosestPeers(fileHash);
    for (final peer in closestPeers) {
      if (peer == id) {
        continue;
      }
      writeMessage.to = peer;
      sendToTransport(writeMessage.toJson());
      print("Записываем файл $fileHash на ближайший узел $peer");
    }
  }

  Future<List<String>> _findClosestPeers(String fileHash) async {
    final askedPeers = {id};
    Map<String, BigInt> closestPeers = Map<String, BigInt>();

    // Добавляем локальные ближайшие узлы
    final closestLocalPeers = _findClosestLocalPeers(fileHash);
    closestPeers.addAll(closestLocalPeers);

    final nodeRequest = FindNodeMessage(from: id, data: fileHash);

    // Регистрируем обработчик сообщений
    void handleAnswer(Message msg) {
      if (msg.data is Map) {
        Map<String, dynamic> serialized = msg.data;
        final deserialized = serialized.map(
          (key, value) => MapEntry(key, BigInt.parse(value.toString())),
        );

        closestPeers.addAll(deserialized);
      } else {
        print("Ошибка: неверный формат данных");
        print(msg.data);
      }
    }

    _findNodeCallback = handleAnswer;

    // Опрашиваем ближайшие узлы пока есть новые
    bool hasNew;
    do {
      hasNew = false;

      for (final peer in closestLocalPeers.keys) {
        // Пропускаем уже опрошенные узлы
        if (askedPeers.contains(peer)) {
          continue;
        }

        // Отправляем запрос на новый узел
        hasNew = true;
        askedPeers.add(peer);
        nodeRequest.to = peer;
        sendToTransport(nodeRequest.toJson());
      }

      // Ожидаем ответ
      await Future.delayed(const Duration(milliseconds: 300));

      // При получении ответа полученные узлы добавляются в closestPeers благодаря _findNodeCallback

      // Сортируем по расстоянию
      final sortedPeers = closestPeers.entries.toList()
        ..sort((a, b) => a.value.compareTo(b.value));

      // Берем только alpha ближайших узлов
      closestPeers = Map.fromEntries(sortedPeers.take(_alpha));
    } while (hasNew);

    return closestPeers.keys.toList();
  }

  Map<String, BigInt> _findClosestLocalPeers(String fileHash) {
    // Calculate distance for every peer
    final closest = Map<String, BigInt>();
    for (final peer in peers.keys) {
      closest[peer] = xorDistance(peer, fileHash);
    }

    // Sort by distance
    final sortedPeers = closest.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    // Take alpha closest
    final topAlpha = sortedPeers.take(_alpha);

    return Map.fromEntries(topAlpha);
  }

  void _onReceiveTaskData(Object message) {
    // Map<>: message or progress
    // string: toast

    if (message case Map<String, dynamic> json) {
      if (json.containsKey('progress')) {
        handleProgress(json);
      } else {
        handleJson(json);
      }
    } else if (message case String toast) {
      showToast(toast);
    }
  }

  void handleProgress(Map<String, dynamic> json) {
    // Add or update file
    SendingFile? currentFile = _sendingFiles.value.firstWhereOrNull(
      (file) => file.transferId == json['transferId'],
    );
    // If no file with this transferId, create new
    if (currentFile == null) {
      if (!json.containsKey('name') && !json.containsKey('isDownloading')) {
        return;
      }
      currentFile = SendingFile(
        json['name'],
        json['transferId'],
        json['isDownloading'],
        json['progress'],
      );

      _sendingFiles.add(currentFile);
    }
    // If have file with this transferId, just update it
    else {
      currentFile.progress = json['progress'];
      _sendingFiles.notify();
    }
  }

  void cancelOperation(String transferId) {
    sendToTransport({'transferId': transferId, 'download': false});
    final message = CancelOperationMessage(from: id, data: transferId);
    sendToTransport(message.toJson());
  }

  void _recreateBloomFilter() {
    _bloomFilter = BloomFilter(size: 50000, numHashes: 3);
    _bloomFilter.addFiles(_files.value.map((file) => file.hash).toList());
  }

  void onDestroy() {
    FlutterForegroundTask.removeTaskDataCallback(_onReceiveTaskData);
  }
}

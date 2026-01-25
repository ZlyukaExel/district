import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:district/message/advertising_message.dart';
import 'package:district/message/ack_message.dart';
import 'package:district/message/message.dart';
import 'package:district/peer/peer.dart';
import 'package:district/file/file_transfer.dart';
import 'package:district/widgets/download_bar.dart';
import 'package:district/widgets/file_buttons.dart';
import 'package:flutter/material.dart';

class UdpTransport {
  String? _broadcastIp;
  final _broadcastPort = 9999;
  final _fileTransferPort = 9998;

  late final RawDatagramSocket _socket;
  late final RawDatagramSocket _fileSocket;
  late final Peer _peer;
  late final Function(Widget) _updateFloatWidget;
  Timer? _advertTimer;

  // Хранилище входящих кусков
  final Map<String, Map<int, FileChunk>> _incomingFiles = {};
  final Map<String, Timer> _cleanupTimers = {};

  // Для ожидания ACK (TransferID -> ChunkIndex)
  Completer<void>? _currentAckCompleter;

  UdpTransport(Function(Widget) updateFloatWidget) {
    _updateFloatWidget = updateFloatWidget;
  }

  Future<void> start(Peer peer) async {
    _peer = peer;

    // Ищем доступный IP-адрес широковещательного канала
    String? broadcastIp = await getLocalIpAddress();
    if (broadcastIp == null) {
      print('Не удалось найти IP-адрес широковещательного канала');
      return;
    }
    _broadcastIp = broadcastIp;

    // 1. Основной сокет
    _socket = await RawDatagramSocket.bind(
      InternetAddress.anyIPv4,
      //InternetAddress('192.168.0.144')
      _broadcastPort,
    );
    _socket.broadcastEnabled = true;
    _socket.listen(_handleMainSocket);

    // 2. Файловый сокет
    _fileSocket = await RawDatagramSocket.bind(
      InternetAddress.anyIPv4,
      _fileTransferPort,
    );
    _fileSocket.broadcastEnabled = true;
    _fileSocket.listen(_handleFileSocket);

    print("UDP Transport запущен. ID: ${peer.id}");

    if (Platform.isWindows) {
      _advertTimer = Timer.periodic(Duration(seconds: 5), (t) {
        //peer.showToast("Отправляю объявление");
        send(AdvertisingMessage(from: peer.id));
      });
    }
  }

  void send(Message message, {InternetAddress? address, int? port}) {
    final data = message.encode();
    if (address != null && port != null) {
      _socket.send(data, address, port);
    } else {
      int res = _socket.send(
        data,
        InternetAddress(_broadcastIp!),
        _broadcastPort,
      );
      if (res == 0) {
        _peer.showToast("Не удалось отправить сообщение");
      } else {
        print("Сообщение $message отправлено");
      }
    }
  }

  void stop() {
    _advertTimer?.cancel();
    _socket.close();
    _fileSocket.close();
  }

  Future<void> sendFile(
    String filePath,
    String transferId,
    InternetAddress address,
    int port,
  ) async {
    final targetAddress = address;
    final file = File(filePath);
    if (!await file.exists()) {
      print("Файл не найден");
      return;
    }

    print(">>> ОТПРАВЛЯЮ ФАЙЛ НА ${targetAddress.address} (Порт 9998) >>>");

    final stream = FileReader.readFileStrictly(filePath, _peer.id, transferId);

    await for (final chunk in stream) {
      bool sent = false;
      int attempts = 0;

      while (!sent && attempts < 15) {
        attempts++;
        _currentAckCompleter = Completer<void>();

        _fileSocket.send(chunk.encode(), targetAddress, _fileTransferPort);

        try {
          await _currentAckCompleter!.future.timeout(
            Duration(milliseconds: 800),
          );
          sent = true;
        } catch (e) {
          // Timeout
        }
      }

      if (!sent) {
        print("!!! ОШИБКА: Не удалось отправить чанк ${chunk.chunkIndex}. !!!");
        _peer.showToast("Ошибка передачи: сеть заблокирована");
        return;
      }
    }
    print(">>> ФАЙЛ УСПЕШНО ОТПРАВЛЕН <<<");
    _peer.showToast("Файл успешно отправлен");
  }

  void _handleMainSocket(RawSocketEvent event) {
    if (event != RawSocketEvent.read) return;
    final dg = _socket.receive();
    if (dg == null) return;

    try {
      final message = decodeMessage(dg.data);

      if (message is AckMessage) {
        if (_currentAckCompleter != null &&
            !_currentAckCompleter!.isCompleted) {
          _currentAckCompleter!.complete();
        }
        return;
      }

      if (message.from != _peer.id) {
        _peer.handleMessage(message, dg.address, dg.port);
      }
    } catch (e) {}
  }

  void _handleFileSocket(RawSocketEvent event) {
    if (event != RawSocketEvent.read) return;
    final dg = _fileSocket.receive();
    if (dg == null) return;

    try {
      final chunk = FileChunk.decode(dg.data);
      final senderAddress = dg.address;

      // ACK
      final ack = AckMessage(
        from: _peer.id,
        to: chunk.senderId,
        transferId: chunk.transferId,
        chunkIndex: chunk.chunkIndex,
      );
      _socket.send(ack.encode(), senderAddress, _broadcastPort);

      // Save
      _incomingFiles.putIfAbsent(chunk.transferId, () => {});
      if (!_incomingFiles[chunk.transferId]!.containsKey(chunk.chunkIndex)) {
        _incomingFiles[chunk.transferId]![chunk.chunkIndex] = chunk;

        double progress =
            _incomingFiles[chunk.transferId]!.length / chunk.totalChunks;
        _updateFloatWidget(new DownloadBar(value: progress));
      }

      if (_incomingFiles[chunk.transferId]!.length == chunk.totalChunks) {
        _saveFile(chunk.transferId);
      }

      _cleanupTimers[chunk.transferId]?.cancel();

      _cleanupTimers[chunk.transferId] = Timer(Duration(seconds: 5), () {
        _cancelDownload(chunk.transferId);
        _peer.showToast("Операция завершена: таймаут");
      });
    } catch (e) {
      print("Ошибка обработки пакета файла: $e");
      _updateFloatWidget(new FileButtons(peer: _peer));
    }
  }

  void _saveFile(String transferId) async {
    try {
      final chunks = _incomingFiles[transferId]!;
      final sortedKeys = chunks.keys.toList()..sort();

      // Берем имя файла из первого чанка
      String fileName = chunks[0]?.fileName ?? 'unknown_file';

      // Если вдруг пришло пустое имя, генерируем временное
      if (fileName.isEmpty) {
        fileName = 'rec_${DateTime.now().millisecondsSinceEpoch}.bin';
      }

      final buffer = BytesBuilder();
      for (var k in sortedKeys) buffer.add(chunks[k]!.data);

      final path = '${_peer.clientInfo.downloadDirectory}/$fileName';

      File file = File(path);
      if (await file.exists()) {
        final nameWithoutExt = fileName.contains('.')
            ? fileName.split('.').first
            : fileName;
        final ext = fileName.contains('.') ? fileName.split('.').last : 'bin';
        final newName =
            '${nameWithoutExt}_${DateTime.now().millisecondsSinceEpoch}.$ext';
        file = File('${_peer.clientInfo.downloadDirectory}/$newName');
      }

      await file.create(recursive: true);
      await file.writeAsBytes(buffer.toBytes());

      print("!!! ФАЙЛ СОХРАНЕН: ${file.path} !!!");
      _peer.showToast("Файл сохранен: ${file.uri.pathSegments.last}");

      _cancelDownload(transferId);
    } catch (e) {
      print("Ошибка записи файла: $e");
      _updateFloatWidget(new FileButtons(peer: _peer));
    }
  }

  void _cancelDownload(String transferId) {
    _incomingFiles.remove(transferId);
    _cleanupTimers[transferId]?.cancel();
    _cleanupTimers.remove(transferId);
    _updateFloatWidget(new FileButtons(peer: _peer));
  }

  Future<String?> getLocalIpAddress() async {
    // 1. Получаем список всех сетевых интерфейсов на устройстве
    List<NetworkInterface> interfaces = await NetworkInterface.list(
      includeLoopback: false, // Исключаем 'localhost' (127.0.0.1)
      includeLinkLocal: false, // Исключаем служебные адреса (169.254.x.x)
    );

    // 2. Проходим по всем интерфейсам и ищем подходящий IPv4 адрес
    for (var interface in interfaces) {
      for (var address in interface.addresses) {
        if (address.type == InternetAddressType.IPv4) {
          final ip = address.address;

          // 3. Выбор правильного IP, если интерфейсов несколько (Wi-Fi, Ethernet, VPN, VM)
          // Мы ищем адреса из приватных диапазонов (LAN): 192.168.x.x, 10.x.x.x, 172.16.x.x
          if (ip.startsWith('192.168.0') ||
              ip.startsWith('192.168.1') ||
              ip.startsWith('10.') ||
              ip.startsWith('172.16.')) {
            final broadcastIp = ip.replaceFirst(RegExp(r'\.\d+$'), '.255');

            print(
              'Найден локальный IP: $ip, Широковещательный адрес: $broadcastIp',
            );
            return broadcastIp;
          }
        }
      }
    }

    // Если ни один из приватных адресов не найден (например, только VPN-соединение)
    return null;
  }
}

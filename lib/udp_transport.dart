import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

import 'package:district/message/advertising_message.dart';
import 'package:district/message/ack_message.dart';
import 'package:district/message/message.dart';
import 'package:district/peer/peer.dart';
import 'package:district/file/file_transfer.dart';

class UdpTransport {
  String? _broadcastIp;
  final _broadcastPort = 9999;
  final _fileTransferPort = 9998;

  late final RawDatagramSocket _socket; // JSON (Сигналы + ACK)
  late final RawDatagramSocket _fileSocket; // Binary (Данные)
  late final Peer _peer;
  Timer? _advertTimer;

  // Хранилище входящих кусков
  final Map<String, Map<int, FileChunk>> _incomingFiles = {};

  // Для ожидания ACK (TransferID -> ChunkIndex)
  Completer<void>? _currentAckCompleter;
  String? _waitingTransferId;
  int? _waitingChunkIndex;

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

    _advertTimer = Timer.periodic(Duration(seconds: 3), (t) {
      send(AdvertisingMessage(from: peer.id));
    });
  }

  void send(Message message, {InternetAddress? address, int? port}) {
    final data = message.encode();
    if (address != null && port != null) {
      _socket.send(data, address, port);
    } else {
      _socket.send(data, InternetAddress(_broadcastIp!), _broadcastPort);
    }
  }

  void stop() {
    _advertTimer?.cancel();
    _socket.close();
    _fileSocket.close();
  }

  // --- ОТПРАВКА ФАЙЛА (С подтверждением) ---
  Future<void> sendFile(
    String filePath,
    String transferId,
    InternetAddress address,
    int port,
  ) async {
    final file = File(filePath);
    if (!await file.exists()) return;

    print("Начало отправки файла: $filePath");

    // Читаем по кусочкам
    final stream = FileReader.readFileStrictly(filePath, _peer.id, transferId);

    await for (final chunk in stream) {
      bool sent = false;
      int attempts = 0;

      // Пытаемся отправить чанк, пока не получим ACK (до 10 попыток)
      while (!sent && attempts < 10) {
        attempts++;

        // 1. Готовим ожидание ACK
        _currentAckCompleter = Completer<void>();
        _waitingTransferId = transferId;
        _waitingChunkIndex = chunk.chunkIndex;

        // 2. Отправляем данные (Binary -> Port 9998)
        _fileSocket.send(chunk.encode(), address, _fileTransferPort);

        // 3. Ждем ACK (JSON <- Port 9999) или таймаут
        try {
          await _currentAckCompleter!.future.timeout(
            Duration(milliseconds: 500),
          );
          sent = true; // Успех
        } catch (e) {
          print("Timeout чанк ${chunk.chunkIndex}. Попытка $attempts");
        }
      }

      if (!sent) {
        print(
          "Ошибка: не удалось передать чанк ${chunk.chunkIndex} после $attempts попыток.",
        );
        return; // Сдаемся
      }
    }
    print("Файл успешно передан.");
    _resetAckWaiter();
  }

  // --- ОБРАБОТКА ВХОДЯЩИХ СИГНАЛОВ (Port 9999) ---
  void _handleMainSocket(RawSocketEvent event) {
    if (event != RawSocketEvent.read) return;

    Datagram? dg = _socket.receive();
    if (dg == null) return;

    try {
      final message = decodeMessage(dg.data);

      // Если это ACK, проверяем, ждем ли мы его
      if (message is AckMessage) {
        if (message.to == _peer.id &&
            message.transferId == _waitingTransferId &&
            message.chunkIndex == _waitingChunkIndex) {
          if (_currentAckCompleter != null &&
              !_currentAckCompleter!.isCompleted) {
            _currentAckCompleter!.complete();
          }
        }
        return;
      }

      // Остальные сообщения - в Peer
      if (message.from != _peer.id) {
        _peer.handleMessage(message, dg.address, dg.port);
      }
    } catch (e) {
      // Игнорируем битые пакеты
    }
  }

  // --- ОБРАБОТКА ВХОДЯЩИХ ФАЙЛОВ (Port 9998) ---
  void _handleFileSocket(RawSocketEvent event) {
    if (event != RawSocketEvent.read) return;

    Datagram? dg = _fileSocket.receive();
    if (dg == null) return;

    try {
      final chunk = FileChunk.decode(dg.data);

      // 1. Проверка хеша
      if (md5.convert(chunk.data).toString() != chunk.chunkHash) {
        print("Битый чанк ${chunk.chunkIndex}");
        return;
      }

      // 2. Сразу отправляем ACK отправителю (на порт 9999)
      final ack = AckMessage(
        from: _peer.id,
        to: chunk.senderId,
        transferId: chunk.transferId,
        chunkIndex: chunk.chunkIndex,
      );
      send(ack, address: dg.address, port: _broadcastPort); // Шлем на 9999

      // 3. Сохраняем
      _incomingFiles.putIfAbsent(chunk.transferId, () => {});
      _incomingFiles[chunk.transferId]![chunk.chunkIndex] = chunk;

      print("Получен чанк ${chunk.chunkIndex}/${chunk.totalChunks}");

      // 4. Если все собрали - сохраняем файл
      if (_incomingFiles[chunk.transferId]!.length == chunk.totalChunks) {
        _saveFile(chunk.transferId);
      }
    } catch (e) {
      print("Ошибка приема файла: $e");
    }
  }

  void _saveFile(String transferId) async {
    try {
      final chunks = _incomingFiles[transferId]!;
      final sortedKeys = chunks.keys.toList()..sort();

      final buffer = BytesBuilder();
      for (var k in sortedKeys) buffer.add(chunks[k]!.data);

      final path =
          '${_peer.clientInfo.downloadDirectory}/recv_${DateTime.now().millisecondsSinceEpoch}.bin';
      await File(path).writeAsBytes(buffer.toBytes());

      print("Файл сохранен: $path");
      _incomingFiles.remove(transferId);
    } catch (e) {
      print("Ошибка сохранения: $e");
    }
  }

  void _resetAckWaiter() {
    _waitingTransferId = null;
    _waitingChunkIndex = null;
    _currentAckCompleter = null;
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

          // 3. Выбор "правильного" IP, если интерфейсов несколько (Wi-Fi, Ethernet, VPN, VM)
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

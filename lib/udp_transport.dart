import 'dart:async';
import 'dart:io';
import 'package:district/structures/messages/connect_message.dart';
import 'package:district/structures/messages/message.dart';
import 'package:district/structures/peer.dart';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:district/structures/file_transfer.dart';


class UdpTransport {
  final _broadcastIp = '255.255.255.255';
  final _broadcastPort = 9999;
  final _fileTransferPort = 9998;
  final _timeout = 3;

  late final Timer _timer;
  late final RawDatagramSocket _socket;
  late final RawDatagramSocket _fileSocket;
  late final Peer _peer;

  // Хранилище для входящих файлов
  final Map<String, Map<int, FileChunk>> _incomingFiles = {};
  final Map<String, FileTransferMetadata> _fileMetadata = {};
  

  Future<void> start(Peer peer) async {
    try {
      // Создаем udp socket
      _socket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        _broadcastPort,
      );
      _socket.broadcastEnabled = true;
      
      // Сокет для передачи файлов
      _fileSocket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        _fileTransferPort,
      );
      _fileSocket.broadcastEnabled = true;

      this._peer = peer;

      // Создаем запрос на подключение
      Message message = ConnectMessage(from: peer.id);
      final encodedMessage = message.encode();

      // Слушаем запросы
      _socket.listen((RawSocketEvent event) {
        if (event == RawSocketEvent.read) {
          Datagram? dg = _socket.receive();
          if (dg != null) {
            try {
              final message = decodeMessage(dg.data);

              // Игнорируем свои сообщения
              if (message.from != peer.id &&
                  (message.to == peer.id || message.to == null)) {
                //print('Получено сообщение $message');
                peer.handleMessage(message, dg.address, dg.port);
              }
            } catch (e) {
              print('Ошибка при декодировании: $e');
            }
          }
        }
      });
      
      // Слушаем батчи файлов
      _fileSocket.listen((RawSocketEvent event) {
        if (event == RawSocketEvent.read) {
          Datagram? dg = _fileSocket.receive();
          if (dg != null) {
            _handleFileChunk(dg.data, dg.address, dg.port);
          }
        }
      });

      

      // Рекламируем этот узел
      _timer = Timer.periodic(Duration(seconds: _timeout), (Timer t) {
        _socket.send(
          encodedMessage,
          InternetAddress(_broadcastIp),
          _broadcastPort,
        );
      });
    } catch (e) {
      print('Ошибка создания UDP сокета: $e');
    }
  }

  void stop() {
  _timer.cancel();
  _socket.close();
  _fileSocket.close();
}


  void send(Message message, {InternetAddress? address, int? port}) {
    final encodedMessage = message.encode();
    if (address == null || port == null) {
      _socket.send(
        encodedMessage,
        InternetAddress(_broadcastIp),
        _broadcastPort,
      );
    } else {
      _socket.send(encodedMessage, address, port);
    }
  }

 /// Отправка файла по адресу и порту
  Future<void> sendFile(
    String filePath,
    String transferId,
    InternetAddress address,
    int port,
  ) async {
    try {
      print(' Начинаем отправку файла: $filePath   ${_socket.address} -> $address');

      final chunks = await FileReader.readFileAsChunks(filePath, transferId);

      for (final chunk in chunks) {
        final encodedChunk = chunk.encode();
        
        _fileSocket.send(encodedChunk, address, port);

        print(" Отправлен батч ${chunk.chunkIndex}. Выполняется задержка.");
        await Future.delayed(Duration(milliseconds: 10));

        print(' Батч ${chunk.chunkIndex + 1}/${chunk.totalChunks} отправлен');
      }

      print(' Файл полностью отправлен');
    } catch (e) {
      print(' Ошибка при отправке файла: $e');
    }
  }

  /// Обработка входящего батча файла
  void _handleFileChunk(
    List<int> data,
    InternetAddress address,
    int port,
  ) {
    try {
      final chunk = FileChunk.decode(Uint8List.fromList(data));

      _incomingFiles.putIfAbsent(chunk.transferId, () => {});

      final receivedHash = md5.convert(chunk.data).toString();
      if (receivedHash != chunk.chunkHash) {
        print(
            '  Батч ${chunk.chunkIndex} повреждён (хеш не совпадает), пропускаем');
        return;
      }

      _incomingFiles[chunk.transferId]![chunk.chunkIndex] = chunk;

      print(
          ' Получен батч ${chunk.chunkIndex + 1}/${chunk.totalChunks} (${chunk.data.length} байт)');

      if (_incomingFiles[chunk.transferId]!.length == chunk.totalChunks) {
        _completeFileTransfer(chunk.transferId, address, port);
      }
    } catch (e) {
      print(' Ошибка при обработке батча файла: $e');
    }
  }

  /// Завершение передачи файла
  Future<void> _completeFileTransfer(
    String transferId,
    InternetAddress address,
    int port,
  ) async {
    try {
      print(' Собираем файл из батчей...');

      final chunks = _incomingFiles[transferId]!;
      final buffer = BytesBuilder();

      for (int i = 0; i < chunks.length; i++) {
        buffer.add(chunks[i]!.data);
      }

      final fileData = buffer.toBytes();

      final downloadDir = _peer.clientInfo.downloadDirectory;
      final fileName =
          'downloaded_${DateTime.now().millisecondsSinceEpoch}.bin';
      final filePath = '$downloadDir/$fileName';

      final file = File(filePath);
      await file.create(recursive: true);
      await file.writeAsBytes(fileData);

      print('Файл сохранён: $filePath');

      _incomingFiles.remove(transferId);
      _fileMetadata.remove(transferId);
    } catch (e) {
      print(' Ошибка при завершении передачи файла: $e');
    }
  }
}

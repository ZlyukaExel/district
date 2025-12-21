import 'dart:async';
import 'dart:io';
import 'package:district/structures/messages/connect_message.dart';
import 'package:district/structures/messages/message.dart';
import 'package:district/structures/peer.dart';

class UdpTransport {
  final _broadcastIp = '255.255.255.255';
  final _broadcastPort = 9999;
  final _timeout = 3;

  late final Timer timer;
  late final RawDatagramSocket _socket;
  late final Peer peer;

  Future<void> start(Peer peer) async {
    try {
      // Создаем udp socket
      _socket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        _broadcastPort,
      );
      _socket.broadcastEnabled = true;

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

      // Рекламируем этот узел
      timer = Timer.periodic(Duration(seconds: _timeout), (Timer t) {
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
    timer.cancel();
    _socket.close();
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

  void sendFile() {}
}

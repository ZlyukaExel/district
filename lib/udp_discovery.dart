import 'dart:async';
import 'dart:io';
import 'package:district/structures/messages/connect_message.dart';
import 'package:district/structures/messages/message.dart';
import 'package:district/structures/peer.dart';

class UdpDiscovery {
  final _broadcastIp = '255.255.255.255';
  final _broadcastPort = 9999;
  final _timeout = 3;

  late final Timer timer;
  late final RawDatagramSocket socket;

  Future<void> startDiscovery(Peer peer) async {
    // Создаем udp socket
    socket = await RawDatagramSocket.bind(
      InternetAddress.anyIPv4,
      _broadcastPort,
    );
    socket.broadcastEnabled = true;

    // Создаем запрос на подключение
    Message message = ConnectMessage(
      from: peer.id,
      data: peer.port, // Tcp порт в качестве данных для подключения к серверу
    );
    final encodedMessage = message.encode();

    // Слушаем запросы
    socket.listen((RawSocketEvent event) {
      if (event == RawSocketEvent.read) {
        Datagram? dg = socket.receive();
        if (dg != null) {
          final responce = decodeMessage(dg.data);

          // Игнорируем свои сообщения
          if (responce.from != peer.id) {
            //print('Получен запрос от ${responce.from}: ${responce.type}: ${responce.data}');
            peer.connect(responce.data);
          }
        }
      } else {
        //print("Просто какой-то шум");
      }
    });

    // Отправляем запросы
    timer = Timer.periodic(Duration(seconds: _timeout), (Timer t) {
      socket.send(
        encodedMessage,
        InternetAddress(_broadcastIp),
        _broadcastPort,
      );
      //print("[${peer.id}] Request sent!");
    });
  }

  void stopDiscovery() {
    timer.cancel();
    socket.close();
  }
}

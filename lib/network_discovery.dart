// import 'dart:io';
// import 'dart:convert';

// class NetworkDiscovery {
//   static const int port = 45454;
//   static const String broadcastAddress = '255.255.255.255';

//   // Метод 1: Делает устройство видимым в локальной сети (отправляет broadcast-пакеты)
//   static Future<void> startAdvertising(String deviceName) async {
//     final sender = await TCP.bind(Endpoint.any(port: Port(port)));
//     final data = 'DISCOVER:$deviceName'.codeUnits;

//     // Отправляем broadcast каждые 2 секунды
//     Timer.periodic(Duration(seconds: 2), (timer) async {
//       await sender.send(data, Endpoint.broadcast(port: Port(port)));
//     });
//   }

//   // Метод 2: Возвращает поток с обнаруженными устройствами в сети
//   static Stream<String> discoverDevices() async* {
//     final receiver = await UDP.bind(Endpoint.any(port: Port(port)));

//     await for (final datagram in receiver.asStream()) {
//       if (datagram?.data != null) {
//         final message = String.fromCharCodes(datagram!.data);
//         if (message.startsWith('DISCOVER:')) {
//           final deviceName = message.substring(9); // "DISCOVER:".length == 9
//           yield deviceName;
//         }
//       }
//     }
//   }
// }

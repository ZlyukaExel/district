import 'dart:io';

class ClientInfo {
  final String id;
  final int port;
  final Socket socket;

  ClientInfo({required this.id, required this.port, required this.socket});
}

import 'package:district/services/preferences.dart';
import 'package:district/services/tcp_transport.dart';
import 'package:flutter/material.dart';

class Peer with ChangeNotifier {
  String nickname = '';
  String id = '';
  int port = -1;
  final TcpTransport transport = TcpTransport();

  void initialize() async {
    nickname = await Preferences.getString('nickname', 'Пользователь');
    port = await transport.startServer();
    notifyListeners();
  }

  void setNickname(String nickname) async {
    this.nickname = nickname;
    notifyListeners();
  }
}

import 'package:district/dialogs/connect_dialog.dart';
import 'package:district/dialogs/nickname_dialog.dart';
import 'package:district/home/home_page.dart';
import 'package:district/services/preferences.dart';
import 'package:district/services/tcp_transport.dart';
import 'package:district/widgets/connect_button.dart';
import 'package:district/widgets/greeting_text.dart';
import 'package:flutter/material.dart';

class HomePageState extends State<HomePage> {
  String _port = '';
  String nickname = "пользователь";
  final TcpTransport transport = TcpTransport();

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _initializeApp() async {
    updateNickname(await Preferences.getNickname());
    await startServerAndSavePort();
  }

  Future<void> startServerAndSavePort() async {
    try {
      await transport.startServer((int port) {
        setState(() {
          _port = 'Ваш порт: $port';
        });
      });
    } catch (e) {
      setState(() {
        _port = 'Ошибка запуска сервера';
      });
    }
  }

  void updateNickname(String newNickname) {
    setState(() {
      nickname = newNickname;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("district", style: TextStyle(fontSize: 16)),
        backgroundColor: const Color.fromARGB(255, 255, 255, 0),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[GreetingText(nickname: nickname)],
        ),
      ),
      floatingActionButton: ConnectButton(
        onPressed: () => showContactDialog(context, transport),
      ),

      drawer: Drawer(
        backgroundColor: const Color.fromARGB(255, 200, 200, 200),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Настройки",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),

              SizedBox(height: 20),

              Row(
                children: [
                  Text('Ник:', style: TextStyle(fontSize: 18)),
                  SizedBox(width: 10),
                  Text(
                    nickname,
                    style: TextStyle(
                      fontSize: 18,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () =>
                        showNicknameDialog(context, updateNickname),
                    child: const Icon(Icons.edit),
                  ),
                ],
              ),

              SizedBox(height: 20),

              Text(_port),
            ],
          ),
        ),
      ),
    );
  }
}

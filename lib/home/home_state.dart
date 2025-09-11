import 'package:district/dialogs/connect_dialog.dart';
import 'package:district/home/home_page.dart';
import 'package:district/services/preferences_service.dart';
import 'package:district/services/tcp_service.dart';
import 'package:district/widgets/connect_button.dart';
import 'package:district/widgets/greeting_text.dart';
import 'package:district/widgets/nickname_input.dart';
import 'package:flutter/material.dart';

class HomePageState extends State<HomePage> {
  late String _port;
  late String nickname;
  final TcpService tcpService = TcpService();
  final _inputController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    await updateNickname();
    await startServerAndSavePort();
  }

  Future<void> startServerAndSavePort() async {
    try {
      await tcpService.startServer((int port) {
        setState(() {
          _port = 'Порт сервера: $port';
        });
      });
    } catch (e) {
      setState(() {
        _port = 'Ошибка запуска сервера';
      });
    }
  }

  Future<void> saveNickname(String nickname) async {
    _inputController.clear();
    if (nickname.trim().isEmpty) return;

    await PreferencesService.saveNickname(nickname);
    setState(() {
      this.nickname = nickname;
    });
  }

  Future<void> updateNickname() async {
    final nickname = await PreferencesService.getNickname();
    setState(() {
      this.nickname = nickname;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("district"),
        backgroundColor: const Color.fromARGB(255, 255, 255, 0),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[GreetingText(nickname: nickname)],
        ),
      ),
      floatingActionButton: ConnectButton(
        onPressed: () => showContactDialog(context, tcpService),
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
              NicknameInput(
                controller: _inputController,
                onSubmitted: saveNickname,
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

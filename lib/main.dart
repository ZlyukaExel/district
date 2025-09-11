import 'package:district/tcp_client.dart';
import 'package:district/tcp_server.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'district',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color.fromARGB(255, 200, 200, 200),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late String _port;
  late String nickname;
  TcpServer server = TcpServer();
  TcpClient client = TcpClient();
  final _inputController = TextEditingController();

  // Вызываается при старте
  @override
  void initState() {
    super.initState();
    updateNickname();
    startServerAndSavePort();
  }

  // Вызывается при отключении
  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          // Элементы в столбце
          children: <Widget>[_buildGreetingText()],
        ),
      ),

      floatingActionButton: _buildConnectButton(),

      appBar: AppBar(
        title: Text("district"),
        backgroundColor: const Color.fromARGB(255, 255, 255, 0),
      ),

      drawer: Drawer(
        backgroundColor: const Color.fromARGB(255, 200, 200, 200),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Текст вверху шторки
              Text(
                "Настройки",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),

              SizedBox(height: 20),

              // Ввод ника
              _buildNicknameInput(),

              SizedBox(height: 20),

              // Отображает текущий порт
              Text(_port),
            ],
          ),
        ),
      ),
    );
  }

  // 1. Приветствие
  Widget _buildGreetingText() {
    return Text(
      'Здравствуйте, $nickname!',
      style: Theme.of(context).textTheme.headlineMedium,
      textAlign: TextAlign.center,
    );
  }

  // 2. Ввод ника
  Widget _buildNicknameInput() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: _inputController,
        decoration: const InputDecoration(
          labelText: 'Ваш ник',
          border: OutlineInputBorder(),
        ),
        onSubmitted: (String text) => {
          saveNickname(text),
          FocusScope.of(context).unfocus(),
        },
      ),
    );
  }

  // 3. Кнопка клиента
  Widget _buildConnectButton() {
    return FloatingActionButton(
      onPressed: () {
        _showInputDialog(context);
      },
      tooltip: 'Добавить контакт',
      child: Icon(Icons.add),
    );
  }

  Future<void> startServerAndSavePort() async {
    try {
      await server.startServer((int port) {
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('player_nickname', nickname);

    // Обновляем ник
    setState(() {
      this.nickname = nickname;
    });
  }

  Future<void> updateNickname() async {
    final prefs = await SharedPreferences.getInstance();
    String? nickname = prefs.getString('player_nickname');
    setState(() {
      this.nickname = (nickname == null || nickname.trim().isEmpty)
          ? 'пользователь'
          : nickname;
    });
  }

  void _showInputDialog(BuildContext context) async {
    final TextEditingController controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Новый контакт'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(hintText: "Введите порт..."),
            autofocus: true,
          ),

          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Отмена'),
            ),

            ElevatedButton(
              onPressed: () {
                String userInput = controller.text;
                Navigator.pop(context);

                client.startClient(int.parse(userInput));
              },
              child: Text('Добавить'),
            ),
          ],
        );
      },
    );
  }
}

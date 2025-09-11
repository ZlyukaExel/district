import 'package:district/services/tcp_service.dart';
import 'package:flutter/material.dart';

Future<void> showContactDialog(
  BuildContext context,
  TcpService tcpService,
) async {
  final TextEditingController controller = TextEditingController();

  await showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Новый контакт'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "Введите порт..."),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              final userInput = controller.text;
              Navigator.pop(context);
              tcpService.startClient(int.parse(userInput));
            },
            child: const Text('Добавить'),
          ),
        ],
      );
    },
  );
}

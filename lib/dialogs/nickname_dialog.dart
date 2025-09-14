import 'package:district/services/preferences.dart';
import 'package:flutter/material.dart';

Future<void> showNicknameDialog(
  BuildContext context,
  Function(String) onSubmit,
) async {
  final TextEditingController controller = TextEditingController();

  await showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Изменить ник'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "Введите ник..."),
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
              onSubmit.call(userInput);
              Preferences.saveNickname(userInput);
              Navigator.pop(context);
            },
            child: const Text('Подтвердить'),
          ),
        ],
      );
    },
  );
}

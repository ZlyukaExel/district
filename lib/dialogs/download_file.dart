import 'package:flutter/material.dart';

Future<void> showHashInputDialog(
  BuildContext context,
  Function(String hashKey) onConfirm,
) async {
  final TextEditingController controller = TextEditingController();

  final String? result = await showDialog<String>(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        title: const Text('Введите хэш-ключ'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Хэш-ключ',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) {
            final text = controller.text.trim();
            if (text.isNotEmpty) {
              Navigator.of(dialogContext).pop(text);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Отменить'),
          ),
          ElevatedButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                Navigator.of(dialogContext).pop(text);
              }
            },
            child: const Text('Принять'),
          ),
        ],
      );
    },
  );

  controller.dispose();

  if (result != null && result.isNotEmpty) {
    onConfirm(result);
  }
}

import 'package:flutter/material.dart';

Future<void> showHashInputDialog(
  BuildContext context,
  Function(String hashKey) onConfirm,
) async {
  final TextEditingController controller = TextEditingController();

  void confirm() {
    final text = controller.text.trim();
    if (text.isNotEmpty) {
      onConfirm(text);
      Navigator.of(context).pop();
    }
  }

  await showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        title: Text('Введите хэш-ключ'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'Хэш-ключ',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
          onSubmitted: (_) => confirm(),
          textInputAction: TextInputAction.done,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text('Отменить'),
          ),
          ElevatedButton(onPressed: confirm, child: Text('Принять')),
        ],
      );
    },
  );

  controller.dispose();
}

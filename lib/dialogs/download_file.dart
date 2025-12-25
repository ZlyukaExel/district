import 'package:flutter/material.dart';

Future<void> showHashInputDialog(
  BuildContext context,
  Function(String hashKey) onConfirm,
) async {
  final TextEditingController controller = TextEditingController();

  void confirm() {
    final text = controller.text.trim();
    if (text.isNotEmpty) {
      if (!context.mounted) return;
      
      Navigator.of(context).pop();
      
      onConfirm(text);
      
      controller.dispose();
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
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => confirm(),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              controller.dispose();
            },
            child: Text('Отменить'),
          ),
          ElevatedButton(
            onPressed: confirm,
            child: Text('Принять'),
          ),
        ],
      );
    },
  );
  
  if (!controller.text.isEmpty) {
    controller.dispose();
  }
}

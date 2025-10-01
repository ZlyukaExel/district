import 'package:flutter/material.dart';

class UploadFileButton extends StatelessWidget {
  final VoidCallback onPressed;

  const UploadFileButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onPressed,
      tooltip: 'Выложить файл',
      child: const Icon(Icons.add),
    );
  }
}

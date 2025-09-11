import 'package:flutter/material.dart';

class ConnectButton extends StatelessWidget {
  final VoidCallback onPressed;

  const ConnectButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onPressed,
      tooltip: 'Добавить контакт',
      child: const Icon(Icons.add),
    );
  }
}

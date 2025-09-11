import 'package:flutter/material.dart';

class NicknameInput extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onSubmitted;

  const NicknameInput({
    super.key,
    required this.controller,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: controller,
        decoration: const InputDecoration(
          labelText: 'Ваш ник',
          border: OutlineInputBorder(),
        ),
        onSubmitted: (String text) {
          onSubmitted(text);
          FocusScope.of(context).unfocus();
        },
      ),
    );
  }
}

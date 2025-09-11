import 'package:flutter/material.dart';

class GreetingText extends StatelessWidget {
  final String nickname;

  const GreetingText({super.key, required this.nickname});

  @override
  Widget build(BuildContext context) {
    return Text(
      'Здравствуйте, $nickname!',
      style: Theme.of(context).textTheme.headlineMedium,
      textAlign: TextAlign.center,
    );
  }
}

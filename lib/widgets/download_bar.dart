import 'package:flutter/material.dart';

class DownloadBar extends StatelessWidget {
  final value;

  const DownloadBar({Key? key, this.value = 0.0}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CircularProgressIndicator(
      value: value,
      backgroundColor: Colors.grey[300],
    );
  }
}

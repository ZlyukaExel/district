import 'package:flutter/material.dart';

class ChatsList extends StatelessWidget {
  final chats = [];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: chats.length,
      itemBuilder: (context, index) {
        final chat = chats[index];
        return ListTile(title: Text(chat), onTap: () {});
      },
    );
  }
}

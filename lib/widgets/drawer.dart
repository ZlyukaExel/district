import 'package:district/structures/peer.dart';
import 'package:flutter/material.dart';

class CustomDrawer extends StatelessWidget {
  final Peer peer;
  final BuildContext context;

  const CustomDrawer({super.key, required this.context, required this.peer});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color.fromARGB(255, 200, 200, 200),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Настройки",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

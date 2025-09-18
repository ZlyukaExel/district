import 'package:district/dialogs/nickname_dialog.dart';
import 'package:district/peer.dart';
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

            SizedBox(height: 20),

            Row(
              children: [
                Text('Ник:', style: TextStyle(fontSize: 18)),
                SizedBox(width: 10),
                Text(
                  peer.nickname,
                  style: TextStyle(
                    fontSize: 18,
                    decoration: TextDecoration.underline,
                  ),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () =>
                      showNicknameDialog(context, peer.setNickname),
                  child: const Icon(Icons.edit),
                ),
              ],
            ),

            SizedBox(height: 20),

            Text('Порт: ${peer.port}', style: TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}

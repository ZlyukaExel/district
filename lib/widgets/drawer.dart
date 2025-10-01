import 'package:district/structures/peer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
                Text('Ваш ID:', style: TextStyle(fontSize: 18)),
                SizedBox(width: 10),
                Text(
                  peer.id.toString(),
                  style: TextStyle(
                    fontSize: 18,
                    decoration: TextDecoration.underline,
                  ),
                ),
                SizedBox(width: 10),
                IconButton(
                  icon: const Icon(Icons.copy, size: 16),
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: peer.id));

                    // Типа тост
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Скопировано в буфер обмена'),
                      ),
                    );
                  },
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

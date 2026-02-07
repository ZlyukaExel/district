import 'package:district/client/client_info.dart';
import 'package:district/client/peer.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class CustomDrawer extends StatefulWidget {
  final Peer peer;

  const CustomDrawer({super.key, required this.peer});

  @override
  State<CustomDrawer> createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> {
  late TextEditingController _dirController;
  late bool _isVisible;

  ClientInfo get _clientInfo => peer.clientInfo;

  Peer get peer => widget.peer;

  @override
  void initState() {
    super.initState();
    _dirController = TextEditingController(text: _clientInfo.downloadDirectory);
    _isVisible = _clientInfo.isVisible;
  }

  @override
  void dispose() {
    _dirController.dispose();
    super.dispose();
  }

  Future<void> _pickDirectory() async {
    final path = await FilePicker.platform.getDirectoryPath();
    if (path == null) return;

    setState(() {
      _dirController.text = path;
      _clientInfo.downloadDirectory = path;
    });

    await _clientInfo.save();
  }

  Future<void> _toggleVisible(bool value) async {
    setState(() {
      _isVisible = value;
      _clientInfo.isVisible = value;
    });

    await _clientInfo.save();
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color.fromARGB(255, 200, 200, 200),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Settings",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            const Text(
              "Save to",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _dirController,
                    readOnly: true,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Select a directory',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _pickDirectory,
                  child: const Text("Change"),
                ),
              ],
            ),

            const SizedBox(height: 24),

            Row(
              children: [
                Checkbox(
                  value: _isVisible,
                  onChanged: (v) {
                    if (v != null) _toggleVisible(v);
                  },
                ),
                const Text("Peer visible"),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

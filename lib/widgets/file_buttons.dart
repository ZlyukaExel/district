import 'package:district/dialog/download_file.dart';
import 'package:district/dialog/upload_file.dart';
import 'package:district/client/peer.dart';
import 'package:flutter/material.dart';

class FileButtons extends StatelessWidget {
  final Peer peer;

  const FileButtons({Key? key, required this.peer}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        FloatingActionButton(
          heroTag: "uploadButton",
          tooltip: "Выложить файл",
          onPressed: () => uploadFiles(peer),
          child: Icon(Icons.upload),
        ),
        SizedBox(height: 10),
        FloatingActionButton(
          heroTag: "downloadButton",
          tooltip: "Скачать файл",
          onPressed: () => showHashInputDialog(context, peer.requestFile),
          child: Icon(Icons.download),
        ),
      ],
    );
  }
}

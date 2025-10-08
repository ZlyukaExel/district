import 'package:district/dialogs/download_file.dart';
import 'package:district/dialogs/upload_file.dart';
import 'package:district/home/home_page.dart';
import 'package:district/structures/peer.dart';
import 'package:district/udp_broadcast.dart';
import 'package:district/widgets/files_list.dart';
import 'package:flutter/material.dart';

class HomePageState extends State<HomePage> {
  late final Peer peer;
  final filesList = FilesList();
  final udpDiscovery = UdpDiscovery();

  // На старте
  @override
  void initState() {
    super.initState();
    _startApp();
  }

  // При завершении
  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _startApp() async {
    peer = await Peer.create();
    peer.startDiscovery();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("district", style: TextStyle(fontSize: 16)),
        backgroundColor: const Color.fromARGB(255, 255, 255, 0),
      ),

      body: filesList,
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "uploadButton",
            tooltip: "Выложить файл",
            onPressed: () => uploadFiles(filesList),
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
      ),

      //drawer: CustomDrawer(context: context, peer: peer),
    );
  }
}

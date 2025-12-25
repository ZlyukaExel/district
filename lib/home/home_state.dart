import 'package:district/dialogs/download_file.dart';
import 'package:district/dialogs/upload_file.dart';
import 'package:district/home/home_page.dart';
import 'package:district/structures/peer.dart';
import 'package:district/structures/hashed_file.dart';
import 'package:district/structures/notifier_list.dart';
import 'package:district/udp_discovery.dart';
import 'package:district/widgets/drawer.dart';
import 'package:district/widgets/files_list.dart';
import 'package:flutter/material.dart';

class HomePageState extends State<HomePage> {
  Peer? peer;
  late final NotifierList<HashedFile> files; 
  final udpDiscovery = UdpTransport();

  @override
  void initState() {
    super.initState();
    files = NotifierList<HashedFile>();  
    _startApp();
  }

  Future<void> _startApp() async {
    try {
      peer = await Peer.create(context, files); 
      peer!.startTransport();
      setState(() {});
    } catch (e) {
      print('Ошибка инициализации: $e');
    }
  }

  @override
  void dispose() {
    files.dispose();  
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (peer == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text("district", style: TextStyle(fontSize: 16)),
          backgroundColor: const Color.fromARGB(255, 255, 255, 0),
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("district", style: TextStyle(fontSize: 16)),
        backgroundColor: const Color.fromARGB(255, 255, 255, 0),
      ),
      body: FilesList(filesList: files),  
      drawer: CustomDrawer(peer: peer!),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "uploadButton",
            tooltip: "Выложить файл",
            onPressed: () => uploadFiles(files, peer!),
            child: Icon(Icons.upload),
          ),
          SizedBox(height: 10),
          FloatingActionButton(
            heroTag: "downloadButton",
            tooltip: "Скачать файл",
            onPressed: () => showHashInputDialog(context, peer!.requestFile),
            child: Icon(Icons.download),
          ),
        ],
      ),
    );
  }
}

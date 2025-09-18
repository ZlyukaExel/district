import 'package:district/dialogs/connect_dialog.dart';
import 'package:district/home/home_page.dart';
import 'package:district/peer.dart';
import 'package:district/services/tcp_transport.dart';
import 'package:district/widgets/chats_list.dart';
import 'package:district/widgets/connect_button.dart';
import 'package:district/widgets/drawer.dart';
import 'package:flutter/material.dart';

class HomePageState extends State<HomePage> {
  final Peer peer = Peer();
  final TcpTransport transport = TcpTransport();
  final List<String> contacts = [];

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
    await transport.startServer();
    peer.initialize();
    peer.addListener(updateUi);
  }

  void updateUi() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("district", style: TextStyle(fontSize: 16)),
        backgroundColor: const Color.fromARGB(255, 255, 255, 0),
      ),

      body: ChatsList(),
      floatingActionButton: ConnectButton(
        onPressed: () => showContactDialog(context, transport),
      ),

      drawer: CustomDrawer(context: context, peer: peer),
    );
  }

  void getClients() {
    for (var client in transport.server.clients) {
      print(client);
    }
  }
}

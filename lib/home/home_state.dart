import 'package:district/home/home_page.dart';
import 'package:district/peer/peer.dart';
import 'package:district/file/hashed_file.dart';
import 'package:district/structures/notifier_list.dart';
import 'package:district/widgets/drawer.dart';
import 'package:district/widgets/files_list.dart';
import 'package:district/widgets/file_buttons.dart';
import 'package:flutter/material.dart';

class HomePageState extends State<HomePage> with WidgetsBindingObserver {
  Peer? peer;
  late final NotifierList<HashedFile> files;
  Widget? floatWidget;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    files = NotifierList<HashedFile>();
    _startApp();
  }

  Future<void> _startApp() async {
    try {
      peer = await Peer.create(context, files, updateFloatWidget);
      peer!.startTransport();
      floatWidget = FileButtons(peer: peer!);
      setState(() {});
    } catch (e) {
      print('Ошибка инициализации: $e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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
      floatingActionButton: floatWidget,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      peer!.startTransport();
      peer!.showToast("Перезапускаем транспорт");
    } else if (state == AppLifecycleState.paused) {
      peer!.stopTransport();
    }
  }

  void updateFloatWidget(Widget newWidget) {
    setState(() {
      floatWidget = newWidget;
    });
  }
}

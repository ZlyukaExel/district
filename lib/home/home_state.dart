import 'package:district/file/sending_file.dart';
import 'package:district/home/home_page.dart';
import 'package:district/client/peer.dart';
import 'package:district/file/hashed_file.dart';
import 'package:district/structures/notifier_list.dart';
import 'package:district/widgets/drawer.dart';
import 'package:district/widgets/files_list.dart';
import 'package:district/widgets/file_buttons.dart';
import 'package:district/widgets/history_list.dart';
import 'package:flutter/material.dart';

class HomePageState extends State<HomePage>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  Peer? peer;
  late final NotifierList<HashedFile> files;
  late final NotifierList<SendingFile> sendingFiles;
  Widget? floatWidget;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabController = TabController(length: 2, vsync: this);
    files = NotifierList<HashedFile>();
    sendingFiles = NotifierList<SendingFile>();
    _startApp();
  }

  Future<void> _startApp() async {
    try {
      peer = await Peer.create(context, files, sendingFiles);
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
    sendingFiles.dispose();
    peer?.onDestroy();
    _tabController.dispose();
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
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Files'),
            Tab(text: 'History'),
          ],
          labelColor: Colors.black,
          unselectedLabelColor: Colors.black54,
          indicatorColor: Colors.black,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          FilesList(filesList: files, onDismissed: peer!.deleteFile),
          HistoryList(filesList: sendingFiles, onCancel: peer!.cancelOperation),
        ],
      ),
      drawer: CustomDrawer(peer: peer!),
      floatingActionButton: floatWidget,
    );
  }

  // @override
  // void didChangeAppLifecycleState(AppLifecycleState state) {
  //   super.didChangeAppLifecycleState(state);

  //   if (Platform.isAndroid) {
  //     if (state == AppLifecycleState.resumed) {
  //       peer!.startTransport();
  //       peer!.showToast("Перезапускаем транспорт");
  //     } else if (state == AppLifecycleState.paused) {
  //       peer?.stopTransport();
  //     }
  //   }
  // }
}

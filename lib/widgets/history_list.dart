import 'package:district/file/sending_file.dart';
import 'package:district/structures/notifier_list.dart';
import 'package:district/widgets/file_transfer.dart';
import 'package:flutter/material.dart';

class HistoryList extends StatelessWidget {
  final NotifierList<SendingFile> filesList;
  final void Function(Object) onCancel;

  const HistoryList({
    required this.filesList,
    required this.onCancel,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<SendingFile>>(
      valueListenable: filesList,
      builder: (context, files, child) {
        return ListView.builder(
          itemCount: files.length,
          itemBuilder: (context, index) {
            final file = files[index];
            return FileTransferWidget(file: file, onCancel: onCancel);
          },
        );
      },
    );
  }
}

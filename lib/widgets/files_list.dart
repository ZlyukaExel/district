import 'package:district/file/hashed_file.dart';
import 'package:district/structures/notifier_list.dart';
import 'package:district/widgets/file_list_element.dart';
import 'package:flutter/material.dart';

class FilesList extends StatelessWidget {
  final NotifierList<HashedFile> filesList;

  const FilesList({required this.filesList, super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<HashedFile>>(
      valueListenable: filesList,
      builder: (context, files, child) {
        return ListView.builder(
          itemCount: files.length,
          itemBuilder: (context, index) {
            final file = files[index];
            return FileListItem(
              file: file,
              onDismissed: () {
                filesList.remove(file);
              },
            );
          },
        );
      },
    );
  }
}

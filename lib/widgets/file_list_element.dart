import 'package:flutter/material.dart';
import 'package:district/structures/hashed_file.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart';

class FileListItem extends StatelessWidget {
  final HashedFile file;
  final VoidCallback onDismissed;

  const FileListItem({required this.file, required this.onDismissed});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      // Свайп элемента
      key: Key(file.path),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismissed(),

      // Задний фон удаления
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20), // Отступ по краям
        child: const Icon(Icons.delete, color: Colors.white),
      ),

      // Задний фон элемента
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),

        // Отступ по краям
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),

        // Сам файл
        child: ListTile(
          // Название файла
          title: Text(
            basename(file.path),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),

          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Путь к файлу
              Text(
                file.path,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),

              // Хэш-ключ файла
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Хэш-ключ: ${file.hash}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  // Кнопка копирования
                  IconButton(
                    icon: const Icon(Icons.copy, size: 16),
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: file.hash));

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
            ],
          ),
        ),
      ),
    );
  }
}

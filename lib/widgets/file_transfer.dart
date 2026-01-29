import 'package:district/file/sending_file.dart';
import 'package:flutter/material.dart';

class FileTransferWidget extends StatefulWidget {
  final SendingFile file;
  final void Function(Object) onCancel;

  const FileTransferWidget({
    Key? key,
    required this.file,
    required this.onCancel,
  }) : super(key: key);

  @override
  _FileTransferWidgetState createState() => _FileTransferWidgetState();
}

class _FileTransferWidgetState extends State<FileTransferWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Название файла
              Text(
                widget.file.isDownloading
                    ? 'Downloading '
                    : 'Sending ' + widget.file.fileName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  overflow: TextOverflow.ellipsis,
                ),
                maxLines: 1,
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Строка с состоянием, прогресс-баром и кнопкой
          Row(
            children: [
              // Прогресс-бар
              Expanded(
                flex: 5,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: LinearProgressIndicator(
                    value: widget.file.progress,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      widget.file.isDownloading ? Colors.green : Colors.blue,
                    ),
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),

              // Процент
              Expanded(
                flex: 1,
                child: Text(
                  '${(widget.file.progress * 100).toInt()}%',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              // Кнопка отмены
              Expanded(
                flex: 1,
                child: IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  color: Colors.grey[600],
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(),
                  onPressed: () => widget.onCancel(widget.file.transferId),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

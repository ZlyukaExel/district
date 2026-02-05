import 'package:district/file/sending_file.dart';
import 'package:flutter/material.dart';

class FileTransferWidget extends StatefulWidget {
  final SendingFile file;
  final void Function(String) onCancel;

  const FileTransferWidget({
    Key? key,
    required this.file,
    required this.onCancel,
  }) : super(key: key);

  @override
  _FileTransferWidgetState createState() => _FileTransferWidgetState();
}

class _FileTransferWidgetState extends State<FileTransferWidget> {
  static const double eps = 0.00001;

  @override
  Widget build(BuildContext context) {
    // Cancel
    if (widget.file.progress < -2 + eps) {
      Widget cancel = _cancelWidget();
      print('Filename: ${widget.file.fileName}');
      return cancel;
    }
    // Error
    if (widget.file.progress < -1 + eps) {
      return _errorWidget();
    }
    // Success
    if (widget.file.progress > 1 - eps) {
      return _successWidget();
    }
    // Process
    return _progressWidget();
  }

  Widget _progressWidget() {
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
          // Header (Downloading/Seinding + file name)
          Text(
            (widget.file.isDownloading ? 'Downloading ' : 'Sending ') +
                widget.file.fileName,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              overflow: TextOverflow.ellipsis,
            ),
            maxLines: 1,
          ),
          // Row(
          //   children: [
          //     // Название файла
          //     Text(
          //       widget.file.isDownloading
          //           ? 'Downloading '
          //           : 'Sending ' + widget.file.fileName,
          //       style: const TextStyle(
          //         fontSize: 16,
          //         fontWeight: FontWeight.w500,
          //         overflow: TextOverflow.ellipsis,
          //       ),
          //       maxLines: 1,
          //     ),
          //   ],
          // ),
          const SizedBox(height: 8),

          // Progress bar & cancel button
          Row(
            children: [
              // Progress bar
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

              // Percent
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

              // Cancel button
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

  Widget _successWidget() {
    return Container(
      padding: const EdgeInsets.all(12.0),
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.green[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  (widget.file.isDownloading ? 'Downloading' : 'Sending') +
                      ' ${widget.file.fileName}: Success',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    overflow: TextOverflow.ellipsis,
                  ),
                  maxLines: 1,
                ),
              ),
              Icon(Icons.check_circle, color: Colors.green[700], size: 20),
            ],
          ),
        ],
      ),
    );
  }

  Widget _errorWidget() {
    return Container(
      padding: const EdgeInsets.all(12.0),
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.red[300]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              widget.file.isDownloading
                  ? 'Downloading'
                  : 'Sending' + ' ${widget.file.fileName}: Error',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                overflow: TextOverflow.ellipsis,
              ),
              maxLines: 1,
            ),
          ),
          Icon(Icons.error, color: Colors.red[700], size: 20),
        ],
      ),
    );
  }

  Widget _cancelWidget() {
    return Container(
      padding: const EdgeInsets.all(12.0),
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.grey[400]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              (widget.file.isDownloading ? 'Downloading' : 'Sending') +
                  ' ${widget.file.fileName}: Canceled',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                overflow: TextOverflow.ellipsis,
              ),
              maxLines: 1,
            ),
          ),
          Icon(Icons.cancel, color: Colors.grey[600], size: 20),
        ],
      ),
    );
  }
}

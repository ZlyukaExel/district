class SendingFile {
  final String fileName;
  final String transferId;
  final bool isDownloading;
  double progress;

  SendingFile(
    this.fileName,
    this.transferId,
    this.isDownloading,
    this.progress,
  );
}

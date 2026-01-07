import 'package:district/message/message.dart';

class AckMessage extends Message {
  final String transferId;
  final int chunkIndex;

  AckMessage({
    required String from,
    String? to,
    required this.transferId,
    required this.chunkIndex,
  }) : super(from: from, to: to, data: null);

  factory AckMessage.fromJson(Map<String, dynamic> json) {
    return AckMessage(
      from: json['from'],
      to: json['to'],
      transferId: json['transferId'],
      chunkIndex: json['chunkIndex'],
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': MessageType.ack.index,
        'from': from,
        'to': to,
        'transferId': transferId,
        'chunkIndex': chunkIndex,
      };
}
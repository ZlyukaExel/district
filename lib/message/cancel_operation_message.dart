import 'package:district/message/message.dart';

class CancelOperationMessage extends Message {
  CancelOperationMessage({required super.from, super.to, required super.data});

  factory CancelOperationMessage.fromJson(Map<String, dynamic> json) {
    return CancelOperationMessage(
      from: json['from'] as String,
      to: json['to'],
      data: json['data'],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': MessageType.cancelOperation.index,
      'from': from,
      'to': to,
      'data': data,
    };
  }
}

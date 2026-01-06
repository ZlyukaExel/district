import 'package:district/message/message.dart';

class StoreMessage extends Message {
  StoreMessage({required super.from, super.to, super.data});

  factory StoreMessage.fromJson(Map<String, dynamic> json) {
    return StoreMessage(
      from: json['from'] as String,
      to: json['to'] as String?,
      data: json['data'],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': MessageType.store.index,
      'from': from,
      'to': to,
      'data': data,
    };
  }
}

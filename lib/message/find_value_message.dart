import 'package:district/message/message.dart';

class FindValueMessage extends Message {
  FindValueMessage({required super.from, super.to, super.data});

  factory FindValueMessage.fromJson(Map<String, dynamic> json) {
    return FindValueMessage(
      from: json['from'] as String,
      to: json['to'] as String?,
      data: json['data'],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': MessageType.findValue.index,
      'from': from,
      'to': to,
      'data': data,
    };
  }
}

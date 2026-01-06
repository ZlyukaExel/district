import 'package:district/message/message.dart';

class FindNodeMessage extends Message {
  FindNodeMessage({required super.from, super.to, super.data});

  factory FindNodeMessage.fromJson(Map<String, dynamic> json) {
    return FindNodeMessage(
      from: json['from'] as String,
      to: json['to'] as String?,
      data: json['data'],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': MessageType.findNode.index,
      'from': from,
      'to': to,
      'data': data,
    };
  }
}

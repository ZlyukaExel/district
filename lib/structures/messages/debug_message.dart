import 'package:district/structures/messages/message.dart';

class DebugMessage extends Message {
  DebugMessage({required super.from, super.to, super.data});

  factory DebugMessage.fromJson(Map<String, dynamic> json) {
    return DebugMessage(
      from: json['from'] as String,
      to: json['to'] as String?,
      data: json['data'],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': MessageType.debug.index,
      'from': from,
      'to': to,
      'data': data,
    };
  }
}

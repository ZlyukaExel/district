import 'package:district/structures/messages/message.dart';

class ConnectMessage extends Message {
  ConnectMessage({required super.from, super.to, super.data});

  factory ConnectMessage.fromJson(Map<String, dynamic> json) {
    return ConnectMessage(
      from: json['from'] as String,
      to: json['to'] as String?,
      data: json['data'],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': MessageType.connect.index,
      'from': from,
      'to': to,
      'data': data,
    };
  }
}

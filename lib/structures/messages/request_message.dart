import 'package:district/structures/messages/message.dart';

class RequestMessage extends Message {
  RequestMessage({required super.from, super.to, super.data});

  factory RequestMessage.fromJson(Map<String, dynamic> json) {
    return RequestMessage(
      from: json['from'] as String,
      to: json['to'] as String?,
      data: json['data'],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': MessageType.request.index,
      'from': from,
      'to': to,
      'data': data,
    };
  }
}

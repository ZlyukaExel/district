import 'package:district/message/message.dart';

class NodeAnswerMessage extends Message {
  NodeAnswerMessage({required super.from, super.to, super.data});

  factory NodeAnswerMessage.fromJson(Map<String, dynamic> json) {
    return NodeAnswerMessage(
      from: json['from'] as String,
      to: json['to'] as String?,
      data: json['data'],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': MessageType.nodeAnswer.index,
      'from': from,
      'to': to,
      'data': data,
    };
  }
}

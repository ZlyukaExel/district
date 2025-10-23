import 'package:district/structures/messages/message.dart';

class AnswerMessage extends Message {
  AnswerMessage({required super.from, super.to, super.data});

  factory AnswerMessage.fromJson(Map<String, dynamic> json) {
    return AnswerMessage(
      from: json['from'] as String,
      to: json['to'] as String?,
      data: json['data'],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': MessageType.answer.index,
      'from': from,
      'to': to,
      'data': data,
    };
  }
}

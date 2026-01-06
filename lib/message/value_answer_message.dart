import 'package:district/message/message.dart';

class ValueAnswerMessage extends Message {
  ValueAnswerMessage({required super.from, super.to, super.data});

  factory ValueAnswerMessage.fromJson(Map<String, dynamic> json) {
    return ValueAnswerMessage(
      from: json['from'] as String,
      to: json['to'] as String?,
      data: json['data'],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': MessageType.valueAnswer.index,
      'from': from,
      'to': to,
      'data': data,
    };
  }
}

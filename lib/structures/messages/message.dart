import 'dart:convert';
import 'dart:typed_data';
import 'package:district/structures/messages/answer_message.dart';
import 'package:district/structures/messages/connect_message.dart';
import 'package:district/structures/messages/debug_message.dart';
import 'package:district/structures/messages/request_message.dart';

enum MessageType { debug, connect, request, answer }

Message decodeMessage(Uint8List bytes) {
  final String jsonString = utf8.decode(bytes);
  final Map<String, dynamic> json = jsonDecode(jsonString);
  final MessageType type = MessageType.values[json['type']];

  switch (type) {
    case MessageType.connect:
      return ConnectMessage.fromJson(json);
    case MessageType.request:
      return RequestMessage.fromJson(json);
    case MessageType.answer:
      return AnswerMessage.fromJson(json);
    default:
      return DebugMessage.fromJson(json);
  }
}

abstract class Message {
  final String from;
  final String? to;
  final dynamic data;

  Message({required this.from, this.to, this.data});

  Map<String, dynamic> toJson();

  Uint8List encode() {
    final String jsonString = jsonEncode(toJson());
    return utf8.encode(jsonString);
  }

  static Message fromBytes(Uint8List bytes) => decodeMessage(bytes);
}

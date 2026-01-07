import 'dart:convert';
import 'dart:typed_data';
import 'package:district/message/advertising_message.dart';
import 'package:district/message/find_value_message.dart';
import 'package:district/message/node_answer_message.dart';
import 'package:district/message/store_message.dart';
import 'package:district/message/find_node_message.dart';
import 'package:district/message/value_answer_message.dart';
import 'package:district/message/ack_message.dart'; 

enum MessageType {
  connect,
  store,
  findNode,
  findValue,
  nodeAnswer,
  valueAnswer,
  ack, // Новый тип
}

Message decodeMessage(Uint8List bytes) {
  final String jsonString = utf8.decode(bytes);
  final Map<String, dynamic> json = jsonDecode(jsonString);
  final MessageType type = MessageType.values[json['type']];

  switch (type) {
    case MessageType.connect:
      return AdvertisingMessage.fromJson(json);
    case MessageType.findValue:
      return FindValueMessage.fromJson(json);
    case MessageType.store:
      return StoreMessage.fromJson(json);
    case MessageType.findNode:
      return FindNodeMessage.fromJson(json);
    case MessageType.nodeAnswer:
      return NodeAnswerMessage.fromJson(json);
    case MessageType.valueAnswer:
      return ValueAnswerMessage.fromJson(json);
    case MessageType.ack:
      return AckMessage.fromJson(json);
  }
}

abstract class Message {
  final String from;
  String? to;
  final dynamic data;

  Message({required this.from, this.to, this.data});

  Map<String, dynamic> toJson();

  Uint8List encode() {
    final String jsonString = jsonEncode(toJson());
    return utf8.encode(jsonString);
  }

  static Message fromBytes(Uint8List bytes) => decodeMessage(bytes);
}
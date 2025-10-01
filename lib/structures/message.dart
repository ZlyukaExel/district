import 'dart:convert';
import 'dart:typed_data';

class Message {
  final MessageType type;
  final String from;
  final dynamic data;

  Message({required this.type, required this.from, this.data});

  Map<String, dynamic> toJson() => {
    'type': type.index,
    'from': from,
    'data': data,
  };

  factory Message.decode(Uint8List uint) {
    final string = utf8.decode(uint);
    final json = jsonDecode(string);
    return Message(
      type: MessageType.values[json['type']],
      from: json['from'],
      data: json['data'],
    );
  }

  Uint8List encode() {
    final json = toJson();
    final string = jsonEncode(json);
    return utf8.encode(string);
  }

  @override
  String toString() {
    return jsonEncode(toJson());
  }
}

enum MessageType { connect, request, answer }

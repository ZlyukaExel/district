import 'dart:convert';

class Message {
  final String type;
  final String from;
  final dynamic data;
  final DateTime timestamp;

  Message({
    required this.type,
    required this.from,
    this.data,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'type': type,
    'from': from,
    'data': data,
    'timestamp': timestamp.toIso8601String(),
  };

  factory Message.fromString(String string) {
    Map<String, dynamic> json = jsonDecode(string);
    return Message(
      type: json['type'],
      from: json['from'],
      data: json['data'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  @override
  String toString() {
    return jsonEncode(toJson());
  }
}

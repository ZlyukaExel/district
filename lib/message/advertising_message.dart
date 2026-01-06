import 'package:district/message/message.dart';

class AdvertisingMessage extends Message {
  AdvertisingMessage({required super.from, super.to, super.data});

  factory AdvertisingMessage.fromJson(Map<String, dynamic> json) {
    return AdvertisingMessage(
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

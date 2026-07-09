import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String senderId;
  final String senderName;
  final String rol;
  final String text;
  final DateTime timestamp;

  const MessageModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.rol,
    required this.text,
    required this.timestamp,
  });

  factory MessageModel.fromMap(String id, Map<String, dynamic> map) {
    DateTime parsedDate;
    final raw = map['timestamp'];
    if (raw is Timestamp) {
      parsedDate = raw.toDate();
    } else {
      parsedDate = DateTime.now();
    }

    return MessageModel(
      id:         id,
      senderId:   map['senderId']   as String? ?? '',
      senderName: map['senderName'] as String? ?? '',
      rol:        map['rol']        as String? ?? '',
      text:       map['text']       as String? ?? '',
      timestamp:  parsedDate,
    );
  }
}

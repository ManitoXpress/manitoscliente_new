import 'package:cloud_firestore/cloud_firestore.dart';

class ConversationModel {
  final String id;
  final String serviceId;
  final String clientId;
  final String clientName;
  final String workerId;
  final String workerName;
  final String lastMessage;
  final DateTime lastAt;
  final int unreadClient;
  final int unreadWorker;

  const ConversationModel({
    required this.id,
    required this.serviceId,
    required this.clientId,
    required this.clientName,
    required this.workerId,
    required this.workerName,
    required this.lastMessage,
    required this.lastAt,
    required this.unreadClient,
    required this.unreadWorker,
  });

  factory ConversationModel.fromMap(String id, Map<String, dynamic> map) {
    DateTime parsedDate;
    final raw = map['lastAt'];
    if (raw is Timestamp) {
      parsedDate = raw.toDate();
    } else {
      parsedDate = DateTime.now();
    }

    return ConversationModel(
      id:           id,
      serviceId:    map['serviceId']   as String? ?? '',
      clientId:     map['clientId']    as String? ?? '',
      clientName:   map['clientName']  as String? ?? '',
      workerId:     map['workerId']    as String? ?? '',
      workerName:   map['workerName']  as String? ?? '',
      lastMessage:  map['lastMessage'] as String? ?? '',
      lastAt:       parsedDate,
      unreadClient: (map['unreadClient'] as num?)?.toInt() ?? 0,
      unreadWorker: (map['unreadWorker'] as num?)?.toInt() ?? 0,
    );
  }

  /// Cuántos mensajes no leídos tiene el cliente actual
  int unreadForClient(String myUid) =>
      myUid == clientId ? unreadClient : unreadWorker;
}

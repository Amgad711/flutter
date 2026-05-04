import 'package:cloud_firestore/cloud_firestore.dart';

import 'message_model.dart';

class LastMessage {
  final String text;
  final MessageType type;
  final DateTime timestamp;

  const LastMessage({
    required this.text,
    required this.type,
    required this.timestamp,
  });

  factory LastMessage.fromMap(Map<String, dynamic> map) {
    return LastMessage(
      text: map['text'] as String? ?? '',
      type: _parseType(map['type'] as String?),
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'type': type.name,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  static MessageType _parseType(String? type) {
    return switch (type) {
      'image' => MessageType.image,
      'voice' => MessageType.voice,
      _ => MessageType.text,
    };
  }
}

class ChatModel {
  final String id;
  final List<String> participants;
  final LastMessage? lastMessage;
  final DateTime updatedAt;
  final Map<String, int> unreadCount;

  const ChatModel({
    required this.id,
    required this.participants,
    this.lastMessage,
    required this.updatedAt,
    this.unreadCount = const {},
  });

  factory ChatModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatModel(
      id: doc.id,
      participants: List<String>.from(data['participants'] as List? ?? []),
      lastMessage: data['lastMessage'] != null
          ? LastMessage.fromMap(data['lastMessage'] as Map<String, dynamic>)
          : null,
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      unreadCount: Map<String, int>.from(data['unreadCount'] as Map? ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'participants': participants,
      if (lastMessage != null) 'lastMessage': lastMessage!.toMap(),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'unreadCount': unreadCount,
    };
  }

  String otherParticipantId(String currentUserId) {
    return participants.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );
  }
}

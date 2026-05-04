import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType { text, image, voice }

enum MessageStatus { sending, sent, delivered, read, failed }

class MessageMetadata {
  final int? duration; // voice duration in seconds
  final double? imageWidth;
  final double? imageHeight;

  const MessageMetadata({this.duration, this.imageWidth, this.imageHeight});

  factory MessageMetadata.fromMap(Map<String, dynamic> map) {
    return MessageMetadata(
      duration: map['duration'] as int?,
      imageWidth: (map['imageWidth'] as num?)?.toDouble(),
      imageHeight: (map['imageHeight'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (duration != null) 'duration': duration,
      if (imageWidth != null) 'imageWidth': imageWidth,
      if (imageHeight != null) 'imageHeight': imageHeight,
    };
  }
}

class MessageModel {
  final String id;
  final String senderId;
  final MessageType type;
  final String content;
  final DateTime timestamp;
  final MessageStatus status;
  final MessageMetadata? metadata;

  const MessageModel({
    required this.id,
    required this.senderId,
    required this.type,
    required this.content,
    required this.timestamp,
    this.status = MessageStatus.sent,
    this.metadata,
  });

  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MessageModel(
      id: doc.id,
      senderId: data['senderId'] as String? ?? '',
      type: _parseType(data['type'] as String?),
      content: data['content'] as String? ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: _parseStatus(data['status'] as String?),
      metadata: data['metadata'] != null
          ? MessageMetadata.fromMap(data['metadata'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'senderId': senderId,
      'type': type.name,
      'content': content,
      'timestamp': Timestamp.fromDate(timestamp),
      'status': status.name,
      if (metadata != null) 'metadata': metadata!.toMap(),
    };
  }

  MessageModel copyWith({MessageStatus? status}) {
    return MessageModel(
      id: id,
      senderId: senderId,
      type: type,
      content: content,
      timestamp: timestamp,
      status: status ?? this.status,
      metadata: metadata,
    );
  }

  static MessageType _parseType(String? type) {
    return switch (type) {
      'image' => MessageType.image,
      'voice' => MessageType.voice,
      _ => MessageType.text,
    };
  }

  static MessageStatus _parseStatus(String? status) {
    return switch (status) {
      'sending' => MessageStatus.sending,
      'delivered' => MessageStatus.delivered,
      'read' => MessageStatus.read,
      'failed' => MessageStatus.failed,
      _ => MessageStatus.sent,
    };
  }
}

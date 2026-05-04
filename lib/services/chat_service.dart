import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/chat_model.dart';
import '../models/message_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const int _pageSize = 30;

  String get currentUserId => _auth.currentUser!.uid;

  // --- Chat Operations ---

  Stream<List<ChatModel>> watchChats() {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: currentUserId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(ChatModel.fromFirestore).toList());
  }

  Future<ChatModel> getOrCreateChat(String otherUserId) async {
    final existingQuery = await _firestore
        .collection('chats')
        .where('participants', arrayContains: currentUserId)
        .get();

    for (final doc in existingQuery.docs) {
      final chat = ChatModel.fromFirestore(doc);
      if (chat.participants.contains(otherUserId)) return chat;
    }

    // Create new chat
    final chatRef = _firestore.collection('chats').doc();
    final chat = ChatModel(
      id: chatRef.id,
      participants: [currentUserId, otherUserId],
      updatedAt: DateTime.now(),
      unreadCount: {currentUserId: 0, otherUserId: 0},
    );
    await chatRef.set(chat.toFirestore());
    return chat;
  }

  // --- Message Operations ---

  Stream<List<MessageModel>> watchMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(_pageSize)
        .snapshots()
        .map((snap) => snap.docs.map(MessageModel.fromFirestore).toList());
  }

  Future<List<MessageModel>> loadOlderMessages(
    String chatId,
    DocumentSnapshot lastDoc,
  ) async {
    final snap = await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .startAfterDocument(lastDoc)
        .limit(_pageSize)
        .get();

    return snap.docs.map(MessageModel.fromFirestore).toList();
  }

  Future<DocumentSnapshot?> getLastMessageDoc(String chatId) async {
    final snap = await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty ? snap.docs.last : null;
  }

  Future<MessageModel> sendMessage({
    required String chatId,
    required MessageType type,
    required String content,
    MessageMetadata? metadata,
  }) async {
    final msgRef = _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc();

    final message = MessageModel(
      id: msgRef.id,
      senderId: currentUserId,
      type: type,
      content: content,
      timestamp: DateTime.now(),
      status: MessageStatus.sent,
      metadata: metadata,
    );

    final batch = _firestore.batch();

    batch.set(msgRef, message.toFirestore());

    final lastMessageText = switch (type) {
      MessageType.image => '📷 Photo',
      MessageType.voice => '🎤 Voice message',
      MessageType.text => content,
    };

    batch.update(_firestore.collection('chats').doc(chatId), {
      'lastMessage': LastMessage(
        text: lastMessageText,
        type: type,
        timestamp: message.timestamp,
      ).toMap(),
      'updatedAt': Timestamp.fromDate(message.timestamp),
    });

    await batch.commit();
    return message;
  }

  Future<void> markMessagesAsRead(String chatId) async {
    final snap = await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('senderId', isNotEqualTo: currentUserId)
        .where('status', whereIn: ['sent', 'delivered'])
        .get();

    final batch = _firestore.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'status': MessageStatus.read.name});
    }
    // Reset unread count
    batch.update(_firestore.collection('chats').doc(chatId), {
      'unreadCount.$currentUserId': 0,
    });
    await batch.commit();
  }

  Future<void> updateMessageStatus(
    String chatId,
    String messageId,
    MessageStatus status,
  ) async {
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .update({'status': status.name});
  }
}

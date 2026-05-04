import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../services/chat_service.dart';
import '../services/file_upload_service.dart';

final chatServiceProvider = Provider<ChatService>((ref) => ChatService());
final fileUploadServiceProvider = Provider<FileUploadService>((ref) => FileUploadService());

final chatsProvider = StreamProvider<List<ChatModel>>((ref) {
  return ref.watch(chatServiceProvider).watchChats();
});

final messagesProvider = StreamProvider.family<List<MessageModel>, String>((ref, chatId) {
  return ref.watch(chatServiceProvider).watchMessages(chatId);
});

// Chat room notifier handles pagination and sending
final chatRoomProvider = StateNotifierProvider.family<ChatRoomNotifier, ChatRoomState, String>(
  (ref, chatId) => ChatRoomNotifier(
    chatId: chatId,
    chatService: ref.watch(chatServiceProvider),
    fileUploadService: ref.watch(fileUploadServiceProvider),
  ),
);

class ChatRoomState {
  final List<MessageModel> messages;
  final bool isLoadingMore;
  final bool hasMore;
  final bool isSending;
  final DocumentSnapshot? lastDoc;
  final String? errorMessage;

  const ChatRoomState({
    this.messages = const [],
    this.isLoadingMore = false,
    this.hasMore = true,
    this.isSending = false,
    this.lastDoc,
    this.errorMessage,
  });

  ChatRoomState copyWith({
    List<MessageModel>? messages,
    bool? isLoadingMore,
    bool? hasMore,
    bool? isSending,
    DocumentSnapshot? lastDoc,
    String? errorMessage,
  }) {
    return ChatRoomState(
      messages: messages ?? this.messages,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      isSending: isSending ?? this.isSending,
      lastDoc: lastDoc ?? this.lastDoc,
      errorMessage: errorMessage,
    );
  }
}

class ChatRoomNotifier extends StateNotifier<ChatRoomState> {
  final String chatId;
  final ChatService chatService;
  final FileUploadService fileUploadService;

  ChatRoomNotifier({
    required this.chatId,
    required this.chatService,
    required this.fileUploadService,
  }) : super(const ChatRoomState());

  Future<void> loadMoreMessages() async {
    if (state.isLoadingMore || !state.hasMore || state.lastDoc == null) return;

    state = state.copyWith(isLoadingMore: true);
    try {
      final older = await chatService.loadOlderMessages(chatId, state.lastDoc!);
      if (older.isEmpty) {
        state = state.copyWith(isLoadingMore: false, hasMore: false);
        return;
      }
      final newLastDoc = await chatService.getLastMessageDoc(chatId);
      state = state.copyWith(
        messages: [...state.messages, ...older],
        isLoadingMore: false,
        hasMore: older.length >= 30,
        lastDoc: newLastDoc,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, errorMessage: e.toString());
    }
  }

  Future<void> sendText(String text) async {
    if (text.trim().isEmpty) return;
    state = state.copyWith(isSending: true);
    try {
      await chatService.sendMessage(
        chatId: chatId,
        type: MessageType.text,
        content: text.trim(),
      );
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    } finally {
      state = state.copyWith(isSending: false);
    }
  }

  Future<void> sendImage(String filePath) async {
    state = state.copyWith(isSending: true);
    try {
      final result = await fileUploadService.uploadImage(chatId, filePath);
      await chatService.sendMessage(
        chatId: chatId,
        type: MessageType.image,
        content: result.url,
        metadata: result.metadata,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    } finally {
      state = state.copyWith(isSending: false);
    }
  }

  Future<void> sendVoice(String filePath, int durationSeconds) async {
    state = state.copyWith(isSending: true);
    try {
      final result = await fileUploadService.uploadVoice(chatId, filePath, durationSeconds);
      await chatService.sendMessage(
        chatId: chatId,
        type: MessageType.voice,
        content: result.url,
        metadata: result.metadata,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    } finally {
      state = state.copyWith(isSending: false);
    }
  }

  Future<void> markAsRead() async {
    await chatService.markMessagesAsRead(chatId);
  }
}

// Voice recording notifier
final voiceRecordingProvider = StateNotifierProvider<VoiceRecordingNotifier, VoiceRecordingState>(
  (ref) => VoiceRecordingNotifier(),
);

class VoiceRecordingState {
  final bool isRecording;
  final int elapsedSeconds;
  final String? recordingPath;

  const VoiceRecordingState({
    this.isRecording = false,
    this.elapsedSeconds = 0,
    this.recordingPath,
  });

  VoiceRecordingState copyWith({
    bool? isRecording,
    int? elapsedSeconds,
    String? recordingPath,
  }) {
    return VoiceRecordingState(
      isRecording: isRecording ?? this.isRecording,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      recordingPath: recordingPath ?? this.recordingPath,
    );
  }
}

class VoiceRecordingNotifier extends StateNotifier<VoiceRecordingState> {
  VoiceRecordingNotifier() : super(const VoiceRecordingState());

  void startRecording() {
    state = state.copyWith(isRecording: true, elapsedSeconds: 0, recordingPath: null);
  }

  void tick() {
    state = state.copyWith(elapsedSeconds: state.elapsedSeconds + 1);
  }

  void stopRecording(String path) {
    state = state.copyWith(isRecording: false, recordingPath: path);
  }

  void reset() {
    state = const VoiceRecordingState();
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/theme.dart';
import '../../models/message_model.dart';
import 'image_message_bubble.dart';
import 'voice_message_bubble.dart';

class MessageBubble extends ConsumerWidget {
  final MessageModel message;
  final bool isMe;
  final String chatId;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.chatId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          top: 2, bottom: 2,
          left: isMe ? 64 : 0,
          right: isMe ? 0 : 64,
        ),
        child: switch (message.type) {
          MessageType.text => _TextBubble(message: message, isMe: isMe),
          MessageType.image => ImageMessageBubble(message: message, isMe: isMe),
          MessageType.voice => VoiceMessageBubble(message: message, isMe: isMe),
        },
      ),
    );
  }
}

class _TextBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;

  const _TextBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final bgColor = isMe ? AppTheme.sentBubble : AppTheme.receivedBubble;
    final textColor = isMe ? AppTheme.sentBubbleText : AppTheme.receivedBubbleText;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(isMe ? 18 : 4),
          bottomRight: Radius.circular(isMe ? 4 : 18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            message.content,
            style: TextStyle(
              color: textColor,
              fontSize: 15,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 3),
          _MessageMeta(message: message, isMe: isMe),
        ],
      ),
    );
  }
}

class _MessageMeta extends StatelessWidget {
  final MessageModel message;
  final bool isMe;

  const _MessageMeta({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final timeText = _formatTime(message.timestamp);
    final metaColor = isMe
        ? AppTheme.sentBubbleText.withOpacity(0.7)
        : AppTheme.textSecondary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          timeText,
          style: TextStyle(fontSize: 11, color: metaColor),
        ),
        if (isMe) ...[
          const SizedBox(width: 3),
          _StatusIcon(status: message.status),
        ],
      ],
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _StatusIcon extends StatelessWidget {
  final MessageStatus status;

  const _StatusIcon({required this.status});

  @override
  Widget build(BuildContext context) {
    return switch (status) {
      MessageStatus.sending => const SizedBox(
          width: 12, height: 12,
          child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white54),
        ),
      MessageStatus.sent => const Icon(Icons.check, size: 14, color: Colors.white70),
      MessageStatus.delivered => const Icon(Icons.done_all, size: 14, color: Colors.white70),
      MessageStatus.read => const Icon(Icons.done_all, size: 14, color: Colors.lightBlueAccent),
      MessageStatus.failed => const Icon(Icons.error_outline, size: 14, color: Colors.redAccent),
    };
  }
}

// Export meta for reuse in other bubble types
class BubbleMetaRow extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final Color? color;

  const BubbleMetaRow({
    super.key,
    required this.message,
    required this.isMe,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return _MessageMeta(message: message, isMe: isMe);
  }
}

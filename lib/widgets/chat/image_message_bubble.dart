import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

import '../../config/theme.dart';
import '../../models/message_model.dart';
import 'message_bubble.dart';

class ImageMessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;

  const ImageMessageBubble({
    super.key,
    required this.message,
    required this.isMe,
  });

  double get _aspectRatio {
    final meta = message.metadata;
    if (meta?.imageWidth != null && meta?.imageHeight != null && meta!.imageHeight! > 0) {
      return meta.imageWidth! / meta.imageHeight!;
    }
    return 4 / 3;
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = isMe ? AppTheme.sentBubble : AppTheme.receivedBubble;

    return GestureDetector(
      onTap: () => _openFullScreen(context),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 220),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMe ? 18 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 18),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMe ? 18 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              AspectRatio(
                aspectRatio: _aspectRatio.clamp(0.5, 2.0),
                child: CachedNetworkImage(
                  imageUrl: message.content,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    color: AppTheme.inputBackground,
                    child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    color: AppTheme.inputBackground,
                    child: const Icon(Icons.broken_image_outlined, color: AppTheme.textSecondary),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 4, 10, 6),
                child: BubbleMetaRow(message: message, isMe: isMe),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openFullScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _FullScreenImageViewer(imageUrl: message.content),
      ),
    );
  }
}

class _FullScreenImageViewer extends StatelessWidget {
  final String imageUrl;

  const _FullScreenImageViewer({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: PhotoView(
        imageProvider: CachedNetworkImageProvider(imageUrl),
        minScale: PhotoViewComputedScale.contained,
        maxScale: PhotoViewComputedScale.covered * 4,
        backgroundDecoration: const BoxDecoration(color: Colors.black),
        loadingBuilder: (_, __) => const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      ),
    );
  }
}

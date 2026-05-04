import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';

import '../../config/theme.dart';
import '../../models/message_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/permission_service.dart';
import '../../widgets/chat/message_bubble.dart';
import '../../widgets/common/user_avatar.dart';

class ChatRoomScreen extends ConsumerStatefulWidget {
  final String chatId;
  final UserModel otherUser;

  const ChatRoomScreen({
    super.key,
    required this.chatId,
    required this.otherUser,
  });

  @override
  ConsumerState<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends ConsumerState<ChatRoomScreen> with WidgetsBindingObserver {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _imagePicker = ImagePicker();
  final _permissionService = PermissionService();
  final _audioRecorder = AudioRecorder();

  bool _isRecording = false;
  int _recordingSeconds = 0;
  Timer? _recordingTimer;
  String? _recordingPath;
  bool _isAtBottom = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatRoomProvider(widget.chatId).notifier).markAsRead();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _messageController.dispose();
    _scrollController.dispose();
    _recordingTimer?.cancel();
    _audioRecorder.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      ref.read(authServiceProvider).updateOnlineStatus(false);
    } else if (state == AppLifecycleState.resumed) {
      ref.read(authServiceProvider).updateOnlineStatus(true);
    }
  }

  void _onScroll() {
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    setState(() => _isAtBottom = (maxScroll - currentScroll) < 150);
  }

  void _scrollToBottom({bool animate = true}) {
    if (!_scrollController.hasClients) return;
    if (animate) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      _scrollController.jumpTo(0);
    }
  }

  Future<void> _sendText() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    _messageController.clear();
    await ref.read(chatRoomProvider(widget.chatId).notifier).sendText(text);
    _scrollToBottom();
  }

  Future<void> _pickImage(ImageSource source) async {
    Navigator.pop(context);
    final granted = source == ImageSource.camera
        ? await _permissionService.requestCamera()
        : await _permissionService.requestPhotos();
    if (!granted) return;

    final picked = await _imagePicker.pickImage(source: source, imageQuality: 85);
    if (picked == null) return;

    await ref.read(chatRoomProvider(widget.chatId).notifier).sendImage(picked.path);
    _scrollToBottom();
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: AppTheme.textTertiary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.camera_alt_outlined, color: AppTheme.primary),
              ),
              title: const Text('Take a photo'),
              onTap: () => _pickImage(ImageSource.camera),
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.photo_library_outlined, color: AppTheme.secondary),
              ),
              title: const Text('Choose from gallery'),
              onTap: () => _pickImage(ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _startRecording() async {
    final granted = await _permissionService.requestMicrophone();
    if (!granted) return;

    final tmpDir = await getTemporaryDirectory();
    _recordingPath = '${tmpDir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _audioRecorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 64000),
      path: _recordingPath!,
    );

    setState(() {
      _isRecording = true;
      _recordingSeconds = 0;
    });

    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _recordingSeconds++);
    });
  }

  Future<void> _stopRecording({bool send = true}) async {
    _recordingTimer?.cancel();
    _recordingTimer = null;

    await _audioRecorder.stop();
    final duration = _recordingSeconds;

    setState(() {
      _isRecording = false;
      _recordingSeconds = 0;
    });

    if (send && _recordingPath != null && duration > 0) {
      await ref.read(chatRoomProvider(widget.chatId).notifier).sendVoice(
        _recordingPath!,
        duration,
      );
      _scrollToBottom();
    }
    _recordingPath = null;
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(1, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(messagesProvider(widget.chatId));
    final otherUserAsync = ref.watch(userProvider(widget.otherUser.id));
    final currentUser = ref.watch(authStateProvider).value;
    final chatRoom = ref.watch(chatRoomProvider(widget.chatId));

    // Auto-scroll on new messages if at bottom
    ref.listen(messagesProvider(widget.chatId), (_, next) {
      if (_isAtBottom) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      }
    });

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        titleSpacing: 0,
        title: otherUserAsync.when(
          data: (user) => Row(
            children: [
              UserAvatar(
                imageUrl: user.profileImageUrl,
                name: user.name,
                radius: 18,
                showOnlineIndicator: true,
                isOnline: user.isOnline,
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    user.isOnline ? 'Online' : 'Offline',
                    style: TextStyle(
                      fontSize: 12,
                      color: user.isOnline ? AppTheme.onlineGreen : AppTheme.textSecondary,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ],
          ),
          loading: () => Text(widget.otherUser.name),
          error: (_, __) => Text(widget.otherUser.name),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              data: (messages) => _buildMessageList(messages, currentUser?.uid ?? ''),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
          if (!_isAtBottom)
            Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 12, bottom: 4),
                child: FloatingActionButton.small(
                  onPressed: _scrollToBottom,
                  backgroundColor: AppTheme.surface,
                  child: const Icon(Icons.keyboard_arrow_down, color: AppTheme.primary),
                ),
              ),
            ),
          _buildInputBar(chatRoom),
        ],
      ),
    );
  }

  Widget _buildMessageList(List<MessageModel> messages, String currentUserId) {
    if (messages.isEmpty) {
      return const Center(
        child: Text(
          'Say hello!',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
        ),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notif) {
        if (notif is ScrollEndNotification &&
            _scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 50) {
          ref.read(chatRoomProvider(widget.chatId).notifier).loadMoreMessages();
        }
        return false;
      },
      child: ListView.builder(
        controller: _scrollController,
        reverse: true,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: messages.length + 1,
        itemBuilder: (context, index) {
          if (index == messages.length) {
            final state = ref.watch(chatRoomProvider(widget.chatId));
            if (state.isLoadingMore) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            }
            return const SizedBox.shrink();
          }
          final message = messages[index];
          final isMe = message.senderId == currentUserId;
          final showDateSeparator = _shouldShowDate(messages, index);

          return Column(
            children: [
              if (showDateSeparator) _buildDateSeparator(message.timestamp),
              MessageBubble(
                message: message,
                isMe: isMe,
                chatId: widget.chatId,
              ),
            ],
          );
        },
      ),
    );
  }

  bool _shouldShowDate(List<MessageModel> messages, int index) {
    if (index == messages.length - 1) return true;
    final current = messages[index].timestamp;
    final next = messages[index + 1].timestamp;
    return current.day != next.day ||
        current.month != next.month ||
        current.year != next.year;
  }

  Widget _buildDateSeparator(DateTime date) {
    final now = DateTime.now();
    String label;
    if (date.day == now.day && date.month == now.month && date.year == now.year) {
      label = 'Today';
    } else if (date.day == now.day - 1 && date.month == now.month && date.year == now.year) {
      label = 'Yesterday';
    } else {
      label = '${date.day}/${date.month}/${date.year}';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.textTertiary.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputBar(ChatRoomState chatRoom) {
    return Container(
      color: AppTheme.surface,
      padding: EdgeInsets.only(
        left: 12, right: 12, top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      child: _isRecording ? _buildRecordingBar() : _buildNormalInputBar(chatRoom),
    );
  }

  Widget _buildRecordingBar() {
    return Row(
      children: [
        GestureDetector(
          onTap: () => _stopRecording(send: false),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.error.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.delete_outline, color: AppTheme.error, size: 22),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.error.withOpacity(0.08),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppTheme.error.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                _RecordingWaveIndicator(),
                const SizedBox(width: 8),
                const Text(
                  'Recording...',
                  style: TextStyle(color: AppTheme.error, fontWeight: FontWeight.w500),
                ),
                const Spacer(),
                Text(
                  _formatDuration(_recordingSeconds),
                  style: const TextStyle(
                    color: AppTheme.error,
                    fontWeight: FontWeight.w600,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => _stopRecording(send: true),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: AppTheme.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
          ),
        ),
      ],
    );
  }

  Widget _buildNormalInputBar(ChatRoomState chatRoom) {
    return Row(
      children: [
        GestureDetector(
          onTap: _showAttachmentOptions,
          child: Container(
            padding: const EdgeInsets.all(8),
            child: const Icon(Icons.attach_file_rounded, color: AppTheme.textSecondary, size: 24),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: TextField(
            controller: _messageController,
            maxLines: 5,
            minLines: 1,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => _sendText(),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Message',
              hintStyle: const TextStyle(color: AppTheme.textSecondary),
              filled: true,
              fillColor: AppTheme.inputBackground,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
              isDense: true,
            ),
          ),
        ),
        const SizedBox(width: 8),
        if (_messageController.text.trim().isNotEmpty || chatRoom.isSending)
          GestureDetector(
            onTap: chatRoom.isSending ? null : _sendText,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: chatRoom.isSending ? AppTheme.textTertiary : AppTheme.primary,
                shape: BoxShape.circle,
              ),
              child: chatRoom.isSending
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          )
        else
          GestureDetector(
            onLongPressStart: (_) => _startRecording(),
            onLongPressEnd: (_) => _stopRecording(send: true),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: AppTheme.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.mic_none_rounded, color: Colors.white, size: 22),
            ),
          ),
      ],
    );
  }
}

class _RecordingWaveIndicator extends StatefulWidget {
  @override
  State<_RecordingWaveIndicator> createState() => _RecordingWaveIndicatorState();
}

class _RecordingWaveIndicatorState extends State<_RecordingWaveIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) => Row(
        children: List.generate(4, (i) {
          final height = 6.0 + (i % 2 == 0 ? _controller.value : 1 - _controller.value) * 10;
          return Container(
            width: 3,
            height: height,
            margin: const EdgeInsets.symmetric(horizontal: 1.5),
            decoration: BoxDecoration(
              color: AppTheme.error,
              borderRadius: BorderRadius.circular(2),
            ),
          );
        }),
      ),
    );
  }
}

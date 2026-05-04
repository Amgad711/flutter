import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../../config/theme.dart';
import '../../models/message_model.dart';
import 'message_bubble.dart';

class VoiceMessageBubble extends StatefulWidget {
  final MessageModel message;
  final bool isMe;

  const VoiceMessageBubble({
    super.key,
    required this.message,
    required this.isMe,
  });

  @override
  State<VoiceMessageBubble> createState() => _VoiceMessageBubbleState();
}

class _VoiceMessageBubbleState extends State<VoiceMessageBubble> {
  late final AudioPlayer _player;
  bool _isPlaying = false;
  double _progress = 0.0;
  int _currentSeconds = 0;

  int get _totalSeconds => widget.message.metadata?.duration ?? 0;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _player.playerStateStream.listen((state) {
      if (!mounted) return;
      setState(() => _isPlaying = state.playing);
      if (state.processingState == ProcessingState.completed) {
        setState(() {
          _isPlaying = false;
          _progress = 0;
          _currentSeconds = 0;
        });
        _player.seek(Duration.zero);
      }
    });
    _player.positionStream.listen((position) {
      if (!mounted) return;
      final total = _totalSeconds;
      setState(() {
        _currentSeconds = position.inSeconds;
        _progress = total > 0 ? position.inSeconds / total : 0;
      });
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlayback() async {
    if (_isPlaying) {
      await _player.pause();
    } else {
      if (_player.duration == null) {
        await _player.setUrl(widget.message.content);
      }
      await _player.play();
    }
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(1, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isMe ? AppTheme.sentBubble : AppTheme.receivedBubble;
    // final fgColor = widget.isMe ? Colors.white : AppTheme.textPrimary;
    final secondaryColor = widget.isMe ? Colors.white54 : AppTheme.textSecondary;
    final progressColor = widget.isMe ? Colors.white : AppTheme.primary;
    final trackColor = widget.isMe ? Colors.white30 : AppTheme.textTertiary;

    return Container(
      constraints: const BoxConstraints(minWidth: 180, maxWidth: 240),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(widget.isMe ? 18 : 4),
          bottomRight: Radius.circular(widget.isMe ? 4 : 18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: _togglePlayback,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: widget.isMe ? Colors.white24 : AppTheme.primary.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: widget.isMe ? Colors.white : AppTheme.primary,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SliderTheme(
                      data: SliderThemeData(
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                        trackHeight: 3,
                        activeTrackColor: progressColor,
                        inactiveTrackColor: trackColor,
                        thumbColor: progressColor,
                        overlayShape: SliderComponentShape.noOverlay,
                      ),
                      child: Slider(
                        value: _progress.clamp(0.0, 1.0),
                        onChanged: (v) async {
                          final pos = Duration(seconds: (_totalSeconds * v).round());
                          await _player.seek(pos);
                        },
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _isPlaying || _currentSeconds > 0
                              ? _formatDuration(_currentSeconds)
                              : _formatDuration(_totalSeconds),
                          style: TextStyle(fontSize: 11, color: secondaryColor),
                        ),
                        const Icon(Icons.graphic_eq_rounded, size: 14, color: Colors.grey),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          BubbleMetaRow(message: widget.message, isMe: widget.isMe),
        ],
      ),
    );
  }
}

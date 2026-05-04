import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../config/theme.dart';

class UserAvatar extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final double radius;
  final bool showOnlineIndicator;
  final bool isOnline;

  const UserAvatar({
    super.key,
    this.imageUrl,
    required this.name,
    this.radius = 24,
    this.showOnlineIndicator = false,
    this.isOnline = false,
  });

  String get _initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    if (name.isNotEmpty) return name[0].toUpperCase();
    return '?';
  }

  Color get _avatarColor {
    final colors = [
      const Color(0xFF0A84FF),
      const Color(0xFF30D158),
      const Color(0xFFFF9F0A),
      const Color(0xFFFF453A),
      const Color(0xFF64D2FF),
      const Color(0xFFBF5AF2),
    ];
    return colors[name.hashCode.abs() % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CircleAvatar(
          radius: radius,
          backgroundColor: _avatarColor.withOpacity(0.15),
          backgroundImage: imageUrl != null
              ? CachedNetworkImageProvider(imageUrl!)
              : null,
          child: imageUrl == null
              ? Text(
                  _initials,
                  style: TextStyle(
                    color: _avatarColor,
                    fontWeight: FontWeight.w600,
                    fontSize: radius * 0.6,
                  ),
                )
              : null,
        ),
        if (showOnlineIndicator)
          Positioned(
            bottom: 0, right: 0,
            child: Container(
              width: radius * 0.55,
              height: radius * 0.55,
              decoration: BoxDecoration(
                color: isOnline ? AppTheme.onlineGreen : AppTheme.textTertiary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
            ),
          ),
      ],
    );
  }
}

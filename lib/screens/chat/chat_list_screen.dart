import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../config/theme.dart';
import '../../models/chat_model.dart';
import '../../models/message_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/common/user_avatar.dart';
import 'chat_room_screen.dart';
import 'new_chat_screen.dart';
import '../profile/profile_screen.dart';

class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({super.key});

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatsAsync = ref.watch(chatsProvider);
    final currentUserAsync = ref.watch(currentUserModelProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        title: const Text('Messages'),
        actions: [
          currentUserAsync.when(
            data: (user) => GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              ),
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: UserAvatar(
                  imageUrl: user?.profileImageUrl,
                  name: user?.name ?? '',
                  radius: 18,
                ),
              ),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: chatsAsync.when(
              data: (chats) => _buildChatList(chats),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NewChatScreen()),
        ),
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.edit_outlined, color: Colors.white),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: AppTheme.surface,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: TextField(
        controller: _searchController,
        onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
        decoration: InputDecoration(
          hintText: 'Search conversations',
          prefixIcon: const Icon(Icons.search, size: 20, color: AppTheme.textSecondary),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18, color: AppTheme.textSecondary),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          filled: true,
          fillColor: AppTheme.inputBackground,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),
    );
  }

  Widget _buildChatList(List<ChatModel> chats) {
    if (chats.isEmpty) {
      return _buildEmptyState();
    }

    final currentUser = ref.watch(authStateProvider).value;
    final filtered = _searchQuery.isEmpty
        ? chats
        : chats; // Filtering happens in ChatTile based on the other user's name

    return ListView.separated(
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const Divider(height: 0),
      itemBuilder: (context, index) {
        final chat = filtered[index];
        final otherId = chat.otherParticipantId(currentUser?.uid ?? '');
        return ChatListTile(
          chat: chat,
          otherUserId: otherId,
          searchQuery: _searchQuery,
          currentUserId: currentUser?.uid ?? '',
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.chat_bubble_outline_rounded, size: 72, color: AppTheme.textTertiary),
          const SizedBox(height: 16),
          const Text(
            'No conversations yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Start a new chat by tapping the\ncompose button below',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: AppTheme.textSecondary, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class ChatListTile extends ConsumerWidget {
  final ChatModel chat;
  final String otherUserId;
  final String searchQuery;
  final String currentUserId;

  const ChatListTile({
    super.key,
    required this.chat,
    required this.otherUserId,
    required this.searchQuery,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProvider(otherUserId));

    return userAsync.when(
      data: (user) {
        if (searchQuery.isNotEmpty &&
            !user.name.toLowerCase().contains(searchQuery)) {
          return const SizedBox.shrink();
        }
        return _buildTile(context, user);
      },
      loading: () => const ListTile(
        leading: CircleAvatar(radius: 26, backgroundColor: AppTheme.inputBackground),
        title: SizedBox(height: 14, child: ColoredBox(color: AppTheme.inputBackground)),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildTile(BuildContext context, UserModel user) {
    final unread = chat.unreadCount[currentUserId] ?? 0;

    return Material(
      color: AppTheme.surface,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatRoomScreen(
              chatId: chat.id,
              otherUser: user,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              UserAvatar(
                imageUrl: user.profileImageUrl,
                name: user.name,
                radius: 26,
                showOnlineIndicator: true,
                isOnline: user.isOnline,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            user.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: unread > 0 ? FontWeight.w700 : FontWeight.w500,
                              color: AppTheme.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (chat.lastMessage != null)
                          Text(
                            timeago.format(chat.lastMessage!.timestamp, locale: 'en_short'),
                            style: TextStyle(
                              fontSize: 12,
                              color: unread > 0 ? AppTheme.primary : AppTheme.textSecondary,
                              fontWeight: unread > 0 ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _lastMessagePreview(),
                            style: TextStyle(
                              fontSize: 14,
                              color: unread > 0 ? AppTheme.textPrimary : AppTheme.textSecondary,
                              fontWeight: unread > 0 ? FontWeight.w500 : FontWeight.normal,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (unread > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: const BoxDecoration(
                              color: AppTheme.primary,
                              borderRadius: BorderRadius.all(Radius.circular(10)),
                            ),
                            child: Text(
                              unread > 99 ? '99+' : '$unread',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _lastMessagePreview() {
    final msg = chat.lastMessage;
    if (msg == null) return 'No messages yet';
    return switch (msg.type) {
      MessageType.image => '📷 Photo',
      MessageType.voice => '🎤 Voice message',
      MessageType.text => msg.text,
    };
  }
}

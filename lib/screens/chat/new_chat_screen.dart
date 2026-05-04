import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/theme.dart';
import '../../models/user_model.dart';
import '../../providers/chat_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/common/user_avatar.dart';
import 'chat_room_screen.dart';

class NewChatScreen extends ConsumerStatefulWidget {
  const NewChatScreen({super.key});

  @override
  ConsumerState<NewChatScreen> createState() => _NewChatScreenState();
}

class _NewChatScreenState extends ConsumerState<NewChatScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _startChat(UserModel user) async {
    final chat = await ref.read(chatServiceProvider).getOrCreateChat(user.id);
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ChatRoomScreen(chatId: chat.id, otherUser: user),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final searchResults = ref.watch(userSearchProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        title: const Text('New Chat'),
      ),
      body: Column(
        children: [
          Container(
            color: AppTheme.surface,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              onChanged: (v) => ref.read(userSearchProvider.notifier).search(v),
              decoration: InputDecoration(
                hintText: 'Search by name',
                prefixIcon: const Icon(Icons.search, size: 20, color: AppTheme.textSecondary),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18, color: AppTheme.textSecondary),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(userSearchProvider.notifier).clear();
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
          ),
          Expanded(
            child: searchResults.when(
              data: (users) {
                if (users.isEmpty && _searchController.text.isNotEmpty) {
                  return const Center(
                    child: Text(
                      'No users found',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  );
                }
                if (users.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_search, size: 56, color: AppTheme.textTertiary),
                        SizedBox(height: 16),
                        Text(
                          'Search for people to chat with',
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 15),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  itemCount: users.length,
                  separatorBuilder: (_, __) => const Divider(height: 0),
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return Material(
                      color: AppTheme.surface,
                      child: ListTile(
                        leading: UserAvatar(
                          imageUrl: user.profileImageUrl,
                          name: user.name,
                          radius: 24,
                          showOnlineIndicator: true,
                          isOnline: user.isOnline,
                        ),
                        title: Text(
                          user.name,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        subtitle: Text(
                          user.email,
                          style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                        ),
                        onTap: () => _startChat(user),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }
}

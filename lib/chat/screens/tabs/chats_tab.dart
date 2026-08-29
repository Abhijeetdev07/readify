import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/sqlite_service.dart';
import '../../services/firestore_service.dart';
import '../../models/chat_model.dart';
import '../../models/user_model.dart';
import '../../core/utils/date_formatter.dart';
import '../chat_room/chat_room_screen.dart';
import '../search/search_users_screen.dart';

class ChatsTab extends StatefulWidget {
  const ChatsTab({super.key});

  @override
  State<ChatsTab> createState() => _ChatsTabState();
}

class _ChatsTabState extends State<ChatsTab> {
  late Future<List<ChatModel>> _chatsFuture;
  final _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _refreshChats();
  }

  void _refreshChats() {
    setState(() {
      _chatsFuture = SqliteService.instance.getConversations();
    });
  }

  void _openChat(UserModel peerUser) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatRoomScreen(peerUser: peerUser),
      ),
    );
    _refreshChats();
  }

  void _openChatFromModel(ChatModel chat) async {
    final peerUser = await _firestoreService.getUserById(chat.peerId);
    if (!mounted) return;
    if (peerUser != null) {
      _openChat(peerUser);
    }
  }

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      body: FutureBuilder<List<ChatModel>>(
        future: _chatsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF128C7E)),
            );
          }

          final chats = snapshot.data ?? [];

          if (chats.isEmpty) {
            return _buildEmptyWithFriendsList(myUid);
          }

          return RefreshIndicator(
            color: const Color(0xFF128C7E),
            onRefresh: () async => _refreshChats(),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 6),
              itemCount: chats.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, indent: 76, endIndent: 16),
              itemBuilder: (context, index) {
                final chat = chats[index];
                return _ChatListTile(
                  chat: chat,
                  onTap: () => _openChatFromModel(chat),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF25D366),
        foregroundColor: Colors.white,
        elevation: 4,
        tooltip: 'New Chat',
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SearchUsersScreen()),
          );
          _refreshChats();
        },
        child: const Icon(Icons.message_rounded),
      ),
    );
  }

  Widget _buildEmptyWithFriendsList(String myUid) {
    if (myUid.isEmpty) {
      return const Center(child: Text('Please log in'));
    }

    return StreamBuilder<List<UserModel>>(
      stream: _firestoreService.streamFriends(myUid),
      builder: (context, snapshot) {
        final friends = snapshot.data ?? [];

        if (friends.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: const Color(0xFF128C7E).withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 44,
                      color: Color(0xFF128C7E),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No conversations yet',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Tap the button below to find and add friends.',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SearchUsersScreen()),
                      );
                      _refreshChats();
                    },
                    icon: const Icon(Icons.person_add_alt_1_rounded),
                    label: const Text('Find Friends'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF128C7E),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          color: const Color(0xFF128C7E),
          onRefresh: () async => _refreshChats(),
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 12),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Text(
                  'START A CHAT WITH YOUR FRIENDS (${friends.length})',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF128C7E),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              ...friends.map((friend) {
                return Column(
                  children: [
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                      leading: CircleAvatar(
                        radius: 26,
                        backgroundColor: const Color(0xFF128C7E),
                        backgroundImage: friend.avatarUrl.isNotEmpty
                            ? CachedNetworkImageProvider(friend.avatarUrl)
                            : null,
                        child: friend.avatarUrl.isEmpty
                            ? Text(
                                friend.name.isNotEmpty ? friend.name[0].toUpperCase() : '?',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                              )
                            : null,
                      ),
                      title: Text(friend.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      subtitle: Text(
                        friend.about.isNotEmpty ? friend.about : 'Tap to start conversation',
                        style: const TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF25D366),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.chat, size: 14, color: Colors.white),
                            SizedBox(width: 4),
                            Text('CHAT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                          ],
                        ),
                      ),
                      onTap: () => _openChat(friend),
                    ),
                    const Divider(height: 1, indent: 76, endIndent: 16),
                  ],
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

class _ChatListTile extends StatelessWidget {
  final ChatModel chat;
  final VoidCallback onTap;

  const _ChatListTile({required this.chat, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasUnread = chat.unreadCount > 0;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: const Color(0xFF128C7E),
              backgroundImage: chat.peerAvatar.isNotEmpty
                  ? CachedNetworkImageProvider(chat.peerAvatar)
                  : null,
              child: chat.peerAvatar.isEmpty
                  ? Text(
                      chat.peerName.isNotEmpty ? chat.peerName[0].toUpperCase() : '?',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                    )
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          chat.peerName,
                          style: TextStyle(
                            fontWeight: hasUnread ? FontWeight.bold : FontWeight.w600,
                            fontSize: 15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        DateFormatter.formatChatListTime(chat.lastMessageTime),
                        style: TextStyle(
                          fontSize: 11,
                          color: hasUnread ? const Color(0xFF128C7E) : Colors.grey,
                          fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          chat.lastMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: hasUnread ? Colors.black87 : Colors.grey,
                            fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (hasUnread) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF25D366),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            chat.unreadCount > 99 ? '99+' : '${chat.unreadCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ]
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

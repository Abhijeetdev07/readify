import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/firestore_service.dart';
import '../../models/user_model.dart';
import '../chat_room/chat_room_screen.dart';

class SearchUsersScreen extends StatefulWidget {
  const SearchUsersScreen({super.key});

  @override
  State<SearchUsersScreen> createState() => _SearchUsersScreenState();
}

class _SearchUsersScreenState extends State<SearchUsersScreen> {
  final _searchController = TextEditingController();
  final _firestoreService = FirestoreService();
  UserModel? _foundUser;
  bool _isFriendWithFoundUser = false;
  bool _isLoading = false;
  bool _hasSearched = false;
  bool _requestSent = false;

  void _search() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _hasSearched = false;
        _foundUser = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _hasSearched = true;
      _requestSent = false;
      _isFriendWithFoundUser = false;
    });

    final currentUser = FirebaseAuth.instance.currentUser;
    final user = await _firestoreService.searchUserByEmail(query);

    bool isFriend = false;
    if (user != null && currentUser != null) {
      // Check if already friends
      final friends = await _firestoreService.streamFriendsUids(currentUser.uid).first;
      isFriend = friends.contains(user.uid);
    }

    if (mounted) {
      setState(() {
        _foundUser = user;
        _isFriendWithFoundUser = isFriend;
        _isLoading = false;
      });
    }
  }

  void _sendRequest() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || _foundUser == null) return;

    if (_foundUser!.uid == currentUser.uid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You cannot add yourself!'), backgroundColor: Colors.orange),
      );
      return;
    }

    final fromUser = UserModel(
      uid: currentUser.uid,
      name: currentUser.displayName ?? currentUser.email?.split('@').first ?? 'User',
      email: currentUser.email ?? '',
    );

    try {
      await _firestoreService.sendFriendRequest(
        fromUser: fromUser,
        toUid: _foundUser!.uid,
      );

      setState(() {
        _requestSent = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Friend request sent!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      final msg = e.toString().replaceAll('Exception:', '').trim();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.orange),
        );
      }
    }
  }

  void _openChat(UserModel peerUser) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ChatRoomScreen(peerUser: peerUser),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Start New Chat'),
        backgroundColor: const Color(0xFF128C7E),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search input bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              cursorColor: const Color(0xFF128C7E),
              decoration: InputDecoration(
                hintText: 'Search by email address...',
                hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 15),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF128C7E)),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _hasSearched = false;
                            _foundUser = null;
                          });
                        },
                      )
                    : IconButton(
                        icon: const Icon(Icons.arrow_forward, color: Color(0xFF128C7E)),
                        onPressed: _search,
                      ),
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              onSubmitted: (_) => _search(),
              onChanged: (val) {
                if (val.isEmpty && _hasSearched) {
                  setState(() {
                    _hasSearched = false;
                    _foundUser = null;
                  });
                }
              },
            ),
          ),

          // Content area
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF128C7E)))
                : _hasSearched
                    ? _buildSearchResults()
                    : _buildFriendsList(currentUid),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_foundUser == null) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_off_outlined, size: 56, color: Colors.grey),
            SizedBox(height: 12),
            Text(
              'No user found with that email address.',
              style: TextStyle(color: Colors.grey, fontSize: 15),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: ListTile(
              leading: CircleAvatar(
                radius: 26,
                backgroundColor: const Color(0xFF128C7E),
                backgroundImage: _foundUser!.avatarUrl.isNotEmpty
                    ? CachedNetworkImageProvider(_foundUser!.avatarUrl)
                    : null,
                child: _foundUser!.avatarUrl.isEmpty
                    ? Text(
                        _foundUser!.name.isNotEmpty ? _foundUser!.name[0].toUpperCase() : '?',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                      )
                    : null,
              ),
              title: Text(_foundUser!.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              subtitle: Text(_foundUser!.email, style: const TextStyle(color: Colors.grey, fontSize: 13)),
              trailing: _isFriendWithFoundUser
                  ? ElevatedButton.icon(
                      onPressed: () => _openChat(_foundUser!),
                      icon: const Icon(Icons.chat, size: 16),
                      label: const Text('Chat'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                    )
                  : ElevatedButton(
                      onPressed: _requestSent ? null : _sendRequest,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF128C7E),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: Text(_requestSent ? 'SENT' : 'ADD'),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFriendsList(String currentUid) {
    if (currentUid.isEmpty) return const SizedBox.shrink();

    return StreamBuilder<List<UserModel>>(
      stream: _firestoreService.streamFriends(currentUid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF128C7E)));
        }

        final friends = snapshot.data ?? [];

        if (friends.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.group_outlined, size: 56, color: Colors.grey),
                SizedBox(height: 12),
                Text(
                  'Search users by email above to add friends',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(
                'YOUR FRIENDS (${friends.length})',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF128C7E),
                  letterSpacing: 0.5,
                ),
              ),
            ),
            Expanded(
              child: ListView.separated(
                itemCount: friends.length,
                separatorBuilder: (_, __) => const Divider(height: 1, indent: 76, endIndent: 16),
                itemBuilder: (context, index) {
                  final friend = friends[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    leading: CircleAvatar(
                      radius: 24,
                      backgroundColor: const Color(0xFF128C7E),
                      backgroundImage: friend.avatarUrl.isNotEmpty
                          ? CachedNetworkImageProvider(friend.avatarUrl)
                          : null,
                      child: friend.avatarUrl.isEmpty
                          ? Text(
                              friend.name.isNotEmpty ? friend.name[0].toUpperCase() : '?',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            )
                          : null,
                    ),
                    title: Text(friend.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    subtitle: Text(
                      friend.about.isNotEmpty ? friend.about : friend.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    trailing: const Icon(Icons.chat_bubble_outline, color: Color(0xFF128C7E), size: 20),
                    onTap: () => _openChat(friend),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

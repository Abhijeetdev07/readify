import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/firestore_service.dart';
import '../../models/friend_request_model.dart';
import '../../models/user_model.dart';
import '../../core/utils/date_formatter.dart';

class RequestsTab extends StatefulWidget {
  const RequestsTab({super.key});

  @override
  State<RequestsTab> createState() => _RequestsTabState();
}

class _RequestsTabState extends State<RequestsTab> with SingleTickerProviderStateMixin {
  final _firestoreService = FirestoreService();
  late final TabController _tabController;
  final _searchController = TextEditingController();
  String _myUid = '';

  UserModel? _foundUser;
  bool _isSearching = false;
  bool _hasSearched = false;
  bool _requestSent = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _myUid = FirebaseAuth.instance.currentUser?.uid ?? '';
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isSearching = true;
      _hasSearched = true;
      _requestSent = false;
      _foundUser = null;
    });

    try {
      final user = await _firestoreService.searchUserByEmail(query);
      setState(() {
        _foundUser = user;
        _isSearching = false;
      });
    } catch (_) {
      setState(() {
        _isSearching = false;
      });
    }
  }

  Future<void> _sendFriendRequest(UserModel targetUser) async {
    if (_myUid.isEmpty) return;

    if (targetUser.uid == _myUid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You cannot add yourself as a friend!')),
      );
      return;
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    final fromUser = UserModel(
      uid: _myUid,
      name: currentUser?.displayName ?? currentUser?.email?.split('@').first ?? 'User',
      email: currentUser?.email ?? '',
    );

    try {
      await _firestoreService.sendFriendRequest(
        fromUser: fromUser,
        toUid: targetUser.uid,
      );

      setState(() => _requestSent = true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Friend request sent to ${targetUser.name}!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_myUid.isEmpty) {
      _myUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    }

    return Scaffold(
      body: Column(
        children: [
          // 1. Search Bar to look up users by exact email
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            color: Colors.grey.shade50,
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _performSearch(),
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                  cursorColor: const Color(0xFF128C7E),
                  decoration: InputDecoration(
                    hintText: 'Search user by email...',
                    hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 15),
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF128C7E)),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
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
                            onPressed: _performSearch,
                          ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                ),

                // Search Result Card
                if (_isSearching) ...[
                  const SizedBox(height: 12),
                  const LinearProgressIndicator(color: Color(0xFF128C7E)),
                ] else if (_foundUser != null) ...[
                  const SizedBox(height: 12),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: const Color(0xFF128C7E),
                            backgroundImage: _foundUser!.avatarUrl.isNotEmpty
                                ? CachedNetworkImageProvider(_foundUser!.avatarUrl)
                                : null,
                            child: _foundUser!.avatarUrl.isEmpty
                                ? Text(
                                    _foundUser!.name.isNotEmpty ? _foundUser!.name[0].toUpperCase() : '?',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _foundUser!.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                                Text(
                                  _foundUser!.email,
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _requestSent ? null : () => _sendFriendRequest(_foundUser!),
                            icon: Icon(_requestSent ? Icons.done : Icons.person_add, size: 16),
                            label: Text(_requestSent ? 'SENT' : 'ADD'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF128C7E),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else if (_hasSearched) ...[
                  const SizedBox(height: 8),
                  Text(
                    'No registered user found with that email.',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ],
              ],
            ),
          ),

          // 2. TabBar Header (Received vs Sent)
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFF128C7E),
              labelColor: const Color(0xFF128C7E),
              unselectedLabelColor: Colors.grey,
              tabs: const [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.call_received, size: 18),
                      SizedBox(width: 8),
                      Text('Received'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.call_made, size: 18),
                      SizedBox(width: 8),
                      Text('Sent'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 3. TabBar Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildReceivedRequestsTab(),
                _buildSentRequestsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Tab 1: Received Requests ---
  Widget _buildReceivedRequestsTab() {
    return StreamBuilder<List<FriendRequestModel>>(
      stream: _firestoreService.streamReceivedRequests(_myUid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == connectionStateWaiting && !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF128C7E)));
        }

        final requests = snapshot.data ?? [];
        if (requests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.mark_email_read_outlined, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 12),
                const Text(
                  'No received friend requests',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  'When someone adds you, their request appears here.',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: requests.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final req = requests[index];
            return ListTile(
              leading: CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFF128C7E),
                backgroundImage: req.fromAvatar.isNotEmpty
                    ? CachedNetworkImageProvider(req.fromAvatar)
                    : null,
                child: req.fromAvatar.isEmpty
                    ? Text(
                        req.fromName.isNotEmpty ? req.fromName[0].toUpperCase() : '?',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      )
                    : null,
              ),
              title: Text(req.fromName, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(req.fromEmail, style: const TextStyle(fontSize: 13)),
                  Text(
                    DateFormatter.formatMessageTime(req.createdAt),
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                  ),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Accept Button
                  IconButton(
                    icon: const Icon(Icons.check_circle, color: Colors.green, size: 28),
                    tooltip: 'Accept',
                    onPressed: () async {
                      await _firestoreService.acceptFriendRequest(
                        requestId: req.id,
                        fromUid: req.fromUid,
                        toUid: req.toUid,
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Accepted ${req.fromName} as a friend!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    },
                  ),
                  // Decline Button
                  IconButton(
                    icon: const Icon(Icons.cancel, color: Colors.redAccent, size: 28),
                    tooltip: 'Decline',
                    onPressed: () async {
                      await _firestoreService.rejectFriendRequest(req.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Request declined.')),
                        );
                      }
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // --- Tab 2: Sent Requests ---
  Widget _buildSentRequestsTab() {
    return StreamBuilder<List<FriendRequestModel>>(
      stream: _firestoreService.streamSentRequests(_myUid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == connectionStateWaiting && !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF128C7E)));
        }

        final requests = snapshot.data ?? [];
        if (requests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.outgoing_mail, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 12),
                const Text(
                  'No pending sent requests',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  'Search above to send friend requests to your contacts.',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: requests.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final req = requests[index];
            return ListTile(
              leading: const CircleAvatar(
                radius: 24,
                backgroundColor: Colors.blueGrey,
                child: Icon(Icons.person, color: Colors.white),
              ),
              title: Text('Request to: ${req.toUid.substring(0, req.toUid.length > 8 ? 8 : req.toUid.length)}...'),
              subtitle: Text(
                'Sent ${DateFormatter.formatMessageTime(req.createdAt)}',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.shade300),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          height: 10,
                          width: 10,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.orange.shade800),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Pending',
                          style: TextStyle(color: Colors.orange.shade900, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey, size: 20),
                    tooltip: 'Cancel Request',
                    onPressed: () async {
                      await _firestoreService.rejectFriendRequest(req.id);
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  static const ConnectionState connectionStateWaiting = ConnectionState.waiting;
}

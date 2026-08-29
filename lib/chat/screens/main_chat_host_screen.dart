import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'tabs/chats_tab.dart';
import 'tabs/calls_tab.dart';
import 'tabs/requests_tab.dart';
import 'tabs/profile_tab.dart';
import '../services/firestore_service.dart';
import '../models/friend_request_model.dart';

class MainChatHostScreen extends StatefulWidget {
  const MainChatHostScreen({super.key});

  @override
  State<MainChatHostScreen> createState() => _MainChatHostScreenState();
}

class _MainChatHostScreenState extends State<MainChatHostScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  final _firestoreService = FirestoreService();
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  static const Color _brandGreen = Color(0xFF128C7E);

  static const List<String> _titles = [
    'ChatsUp',
    'Calls',
    'Requests',
    'Profile',
  ];

  static const List<String> _subtitles = [
    'Your conversations',
    'Recent calls',
    'Friend requests',
    'Your account',
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _onTabChanged(int index) {
    if (index == _currentIndex) return;
    _fadeController.reset();
    setState(() => _currentIndex = index);
    _fadeController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: _buildAppBar(),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: IndexedStack(
          index: _currentIndex,
          children: const [
            ChatsTab(),
            CallsTab(),
            RequestsTab(),
            ProfileTab(),
          ],
        ),
      ),
      bottomNavigationBar: StreamBuilder<List<FriendRequestModel>>(
        stream: myUid.isNotEmpty
            ? _firestoreService.streamReceivedRequests(myUid)
            : const Stream.empty(),
        builder: (context, snapshot) {
          final pendingCount = snapshot.data?.length ?? 0;
          return _buildNavigationBar(pendingCount);
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(70),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0D7377), Color(0xFF128C7E), Color(0xFF14A085)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0x33128C7E),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                // Logo mark
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.lock_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _titles[_currentIndex],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                        ),
                      ),
                      Text(
                        _subtitles[_currentIndex],
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                // Search icon (Chats tab only)
                if (_currentIndex == 0)
                  _AppBarAction(
                    icon: Icons.search_rounded,
                    onTap: () {},
                  ),
                const SizedBox(width: 8),
                // More options
                _AppBarAction(
                  icon: Icons.more_vert_rounded,
                  onTap: () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationBar(int pendingCount) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onTabChanged,
        backgroundColor: Colors.transparent,
        elevation: 0,
        indicatorColor: const Color(0xFF128C7E).withValues(alpha: 0.12),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        animationDuration: const Duration(milliseconds: 400),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.chat_bubble_outline_rounded),
            selectedIcon: const Icon(
              Icons.chat_bubble_rounded,
              color: _brandGreen,
            ),
            label: 'Chats',
          ),
          NavigationDestination(
            icon: const Icon(Icons.call_outlined),
            selectedIcon: const Icon(Icons.call_rounded, color: _brandGreen),
            label: 'Calls',
          ),
          NavigationDestination(
            icon: pendingCount > 0
                ? Badge(
                    label: Text(
                      pendingCount > 9 ? '9+' : '$pendingCount',
                      style: const TextStyle(fontSize: 10),
                    ),
                    backgroundColor: Colors.redAccent,
                    child: const Icon(Icons.group_outlined),
                  )
                : const Icon(Icons.group_outlined),
            selectedIcon: pendingCount > 0
                ? Badge(
                    label: Text(
                      pendingCount > 9 ? '9+' : '$pendingCount',
                      style: const TextStyle(fontSize: 10),
                    ),
                    backgroundColor: Colors.redAccent,
                    child: const Icon(Icons.group_rounded, color: _brandGreen),
                  )
                : const Icon(Icons.group_rounded, color: _brandGreen),
            label: 'Requests',
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline_rounded),
            selectedIcon:
                const Icon(Icons.person_rounded, color: _brandGreen),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

/// Reusable circular icon button for AppBar actions
class _AppBarAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _AppBarAction({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

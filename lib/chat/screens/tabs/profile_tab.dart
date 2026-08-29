import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';
import '../../services/sqlite_service.dart';
import '../auth/login_screen.dart';
import '../profile/edit_profile_screen.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  double _storageUsedMB = 0.0;
  int _totalMessages = 0;
  int _totalCalls = 0;

  static const Color _brandGreen = Color(0xFF128C7E);

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      // Count messages from SQLite
      final msgs = await SqliteService.instance.getConversations();
      int msgCount = 0;
      for (final c in msgs) {
        msgCount += c.unreadCount;
      }

      // Count call logs
      final calls = await SqliteService.instance.getCallLogs();

      // Estimate storage from app_storage directory
      double storageBytes = 0;
      final storageDir = Directory('/storage/emulated/0/Android/data/com.example.readify/files/app_storage');
      if (await storageDir.exists()) {
        await for (final entity in storageDir.list(recursive: true)) {
          if (entity is File) {
            storageBytes += await entity.length();
          }
        }
      }

      if (mounted) {
        setState(() {
          _totalMessages = msgCount;
          _totalCalls = calls.length;
          _storageUsedMB = storageBytes / (1024 * 1024);
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: StreamBuilder(
        stream: AuthService().currentUserStream,
        builder: (context, snapshot) {
          final user = snapshot.data ?? authProvider.currentUser;

          return RefreshIndicator(
            color: _brandGreen,
            onRefresh: () async => _loadStats(),
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // ─── Header card ───────────────────────────────────────────
                _buildProfileHeader(user, context),

                const SizedBox(height: 16),

                // ─── Stats ─────────────────────────────────────────────────
                _buildStatsRow(),

                const SizedBox(height: 16),

                // ─── About / Status ─────────────────────────────────────────
                _buildSectionCard([
                  _buildListTile(
                    icon: Icons.info_outline_rounded,
                    color: _brandGreen,
                    title: 'Status',
                    subtitle: user?.about.isNotEmpty == true
                        ? user!.about
                        : 'Hey there! I am using Readify Chat.',
                  ),
                ]),

                const SizedBox(height: 12),

                // ─── Storage ─────────────────────────────────────────────────
                _buildSectionCard([
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.storage_rounded,
                                color: _brandGreen, size: 20),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text('Storage Used',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14)),
                            ),
                            Text(
                              '${_storageUsedMB.toStringAsFixed(1)} MB',
                              style: const TextStyle(
                                  color: _brandGreen,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: (_storageUsedMB / 500).clamp(0.0, 1.0),
                            minHeight: 7,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                _brandGreen),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${_storageUsedMB.toStringAsFixed(1)} MB of 500 MB used',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ]),

                const SizedBox(height: 12),

                // ─── Account Actions ─────────────────────────────────────────
                _buildSectionCard([
                  _buildListTile(
                    icon: Icons.edit_rounded,
                    color: _brandGreen,
                    title: 'Edit Profile',
                    subtitle: 'Name, photo, and status',
                    onTap: user == null
                        ? null
                        : () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      EditProfileScreen(user: user)),
                            ),
                  ),
                  const Divider(height: 1, indent: 56),
                  _buildListTile(
                    icon: Icons.privacy_tip_outlined,
                    color: Colors.blueAccent,
                    title: 'Privacy',
                    subtitle: 'Manage who can see your info',
                    onTap: () {},
                  ),
                  const Divider(height: 1, indent: 56),
                  _buildListTile(
                    icon: Icons.notifications_outlined,
                    color: Colors.orange,
                    title: 'Notifications',
                    subtitle: 'Message and call alerts',
                    onTap: () {},
                  ),
                ]),

                const SizedBox(height: 12),

                // ─── Danger zone ─────────────────────────────────────────
                _buildSectionCard([
                  _buildListTile(
                    icon: Icons.logout_rounded,
                    color: Colors.redAccent,
                    title: 'Sign Out',
                    subtitle: 'Return to Readify',
                    titleColor: Colors.redAccent,
                    onTap: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Sign Out'),
                          content: const Text(
                              'Are you sure you want to sign out?'),
                          actions: [
                            TextButton(
                                onPressed: () =>
                                    Navigator.pop(ctx, false),
                                child: const Text('Cancel')),
                            TextButton(
                                onPressed: () =>
                                    Navigator.pop(ctx, true),
                                child: const Text('Sign Out',
                                    style: TextStyle(
                                        color: Colors.redAccent))),
                          ],
                        ),
                      );
                      if (confirmed == true && context.mounted) {
                        await authProvider.signOut();
                        if (context.mounted) {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const LoginScreen()),
                            (route) => false,
                          );
                        }
                      }
                    },
                  ),
                ]),

                const SizedBox(height: 32),

                // ─── Version tag ────────────────────────────────────────────
                const Center(
                  child: Text(
                    '🔒 ChatsUp — Secret Chat Module v1.0',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(user, BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0D7377), Color(0xFF128C7E), Color(0xFF14A085)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 28),
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 52,
                backgroundColor: Colors.white.withValues(alpha: 0.25),
                backgroundImage: user?.avatarUrl.isNotEmpty == true
                    ? CachedNetworkImageProvider(user!.avatarUrl)
                        as ImageProvider
                    : null,
                child: user?.avatarUrl.isEmpty != false
                    ? Text(
                        user?.name.isNotEmpty == true
                            ? user!.name[0].toUpperCase()
                            : 'U',
                        style: const TextStyle(
                            fontSize: 40,
                            color: Colors.white,
                            fontWeight: FontWeight.bold),
                      )
                    : null,
              ),
              Positioned(
                right: 2,
                bottom: 2,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF25D366),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(Icons.circle,
                      size: 8, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            user?.name ?? 'User',
            style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            user?.email ?? '',
            style: TextStyle(
                fontSize: 13, color: Colors.white.withValues(alpha: 0.8)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _StatCard(
              icon: Icons.chat_rounded,
              label: 'Messages',
              value: '$_totalMessages',
              color: const Color(0xFF128C7E)),
          const SizedBox(width: 12),
          _StatCard(
              icon: Icons.call_rounded,
              label: 'Calls',
              value: '$_totalCalls',
              color: Colors.blueAccent),
          const SizedBox(width: 12),
          _StatCard(
              icon: Icons.people_rounded,
              label: 'Friends',
              value: '—',
              color: Colors.orange),
        ],
      ),
    );
  }

  Widget _buildSectionCard(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required Color color,
    required String title,
    String? subtitle,
    Color? titleColor,
    VoidCallback? onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 19),
      ),
      title: Text(
        title,
        style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: titleColor ?? Colors.black87),
      ),
      subtitle: subtitle != null
          ? Text(subtitle,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              maxLines: 1,
              overflow: TextOverflow.ellipsis)
          : null,
      trailing: onTap != null
          ? Icon(Icons.chevron_right_rounded,
              color: Colors.grey.shade400, size: 20)
          : null,
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: color)),
            const SizedBox(height: 2),
            Text(label,
                style:
                    const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

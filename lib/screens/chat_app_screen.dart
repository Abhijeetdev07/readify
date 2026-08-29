import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../chat/screens/auth/login_screen.dart';
import '../chat/screens/main_chat_host_screen.dart';

/// Stealth Gatekeeper — entry point for the secret chat module.
/// Triggered by the 3-tap Easter Egg on the Settings screen.
///
/// Auth flow:
///   - Resolving: Shows branded lock splash screen.
///   - Logged in:  → MainChatHostScreen (4-tab chat host)
///   - Logged out: → LoginScreen (email/password auth)
class ChatAppScreen extends StatelessWidget {
  const ChatAppScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // ── Auth state resolving ──────────────────────────────────
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _StealthSplash();
        }

        // ── Logged in → Main chat host ────────────────────────────
        if (snapshot.hasData && snapshot.data != null) {
          return const MainChatHostScreen();
        }

        // ── Not logged in → Login screen ──────────────────────────
        return const LoginScreen();
      },
    );
  }
}

/// Branded loading screen shown while Firebase resolves auth state.
class _StealthSplash extends StatefulWidget {
  const _StealthSplash();

  @override
  State<_StealthSplash> createState() => _StealthSplashState();
}

class _StealthSplashState extends State<_StealthSplash>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _opacityAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _scaleAnim = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _opacityAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0D7377), Color(0xFF128C7E), Color(0xFF14A085)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated lock icon
            AnimatedBuilder(
              animation: _controller,
              builder: (_, __) => Transform.scale(
                scale: _scaleAnim.value,
                child: Opacity(
                  opacity: _opacityAnim.value,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.4),
                          width: 2),
                    ),
                    child: const Icon(
                      Icons.lock_rounded,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'ChatsUp',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Secure. Private. Always.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 14,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.white.withValues(alpha: 0.8)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
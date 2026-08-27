import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/theme_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Readify',
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.picture_as_pdf_rounded,
          size: 40,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      children: [
        const Text('Readify — a simple, fast PDF reader.'),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                SwitchListTile(
                  title: const Text('Dark Mode'),
                  subtitle: Text(isDarkMode ? 'On' : 'Off'),
                  secondary: Icon(
                    isDarkMode ? Icons.dark_mode : Icons.light_mode,
                  ),
                  value: isDarkMode,
                  onChanged: (bool value) {
                    themeProvider.setThemeMode(
                      value ? ThemeMode.dark : ThemeMode.light,
                    );
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('About Readify'),
                  onTap: () => _showAboutDialog(context),
                ),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16.0, top: 8.0),
              child: Opacity(
                opacity: 0.45,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Built with ',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    const Text(
                      '♥️',
                      style: TextStyle(fontSize: 12),
                    ),
                    Text(
                      ' by Readify',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

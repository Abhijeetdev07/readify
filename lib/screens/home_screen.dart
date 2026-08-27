import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/recent_pdf.dart';
import '../services/recent_files_service.dart';
import '../widgets/recent_pdf_tile.dart';
import 'pdf_viewer_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const MethodChannel _intentChannel =
      MethodChannel('com.example.readify/intent');

  final RecentFilesService _recentFilesService = RecentFilesService();
  late Future<List<RecentPdf>> _recentPdfsFuture;

  @override
  void initState() {
    super.initState();
    _refreshRecentPdfs();
    _initIntentListener();
  }

  void _initIntentListener() {
    _intentChannel.setMethodCallHandler((call) async {
      if (call.method == 'onPdfOpened' && call.arguments is Map) {
        final data = Map<String, dynamic>.from(call.arguments as Map);
        final path = data['path'] as String?;
        final name = data['name'] as String? ?? 'Document.pdf';
        if (path != null && path.isNotEmpty) {
          _openReceivedPdf(path, name);
        }
      }
    });

    _checkInitialIntent();
  }

  Future<void> _checkInitialIntent() async {
    try {
      final initialData = await _intentChannel.invokeMethod('getInitialPdf');
      if (initialData is Map && mounted) {
        final data = Map<String, dynamic>.from(initialData);
        final path = data['path'] as String?;
        final name = data['name'] as String? ?? 'Document.pdf';
        if (path != null && path.isNotEmpty) {
          _openReceivedPdf(path, name);
        }
      }
    } catch (_) {
      // Ignored if not available on current platform
    }
  }

  Future<void> _openReceivedPdf(String filePath, String fileName) async {
    await _recentFilesService.addRecentPdf(
      RecentPdf(
        name: fileName,
        path: filePath,
        lastOpened: DateTime.now(),
      ),
    );

    if (mounted) {
      _refreshRecentPdfs();
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PdfViewerScreen(filePath: filePath),
        ),
      );
      if (mounted) {
        _refreshRecentPdfs();
      }
    }
  }

  void _refreshRecentPdfs() {
    setState(() {
      _recentPdfsFuture = _recentFilesService.getRecentPdfs();
    });
  }

  Future<void> _pickAndOpenPdf() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null &&
          result.files.isNotEmpty &&
          result.files.single.path != null) {
        final filePath = result.files.single.path!;
        final fileName = result.files.single.name;

        await _recentFilesService.addRecentPdf(
          RecentPdf(
            name: fileName,
            path: filePath,
            lastOpened: DateTime.now(),
          ),
        );

        if (mounted) {
          _refreshRecentPdfs();
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PdfViewerScreen(filePath: filePath),
            ),
          );
          if (mounted) {
            _refreshRecentPdfs();
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open PDF: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _openRecentPdf(RecentPdf pdf) async {
    try {
      if (!File(pdf.path).existsSync()) {
        await _removeRecentPdf(pdf.path);
        return;
      }

      await _recentFilesService.addRecentPdf(
        RecentPdf(
          name: pdf.name,
          path: pdf.path,
          lastOpened: DateTime.now(),
        ),
      );

      if (mounted) {
        _refreshRecentPdfs();
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PdfViewerScreen(filePath: pdf.path),
          ),
        );
        if (mounted) {
          _refreshRecentPdfs();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open file: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _removeRecentPdf(String path) async {
    await _recentFilesService.removeRecentPdf(path);
    if (mounted) {
      _refreshRecentPdfs();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Removed from recent files'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Readify'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          Center(
            child: ElevatedButton.icon(
              onPressed: _pickAndOpenPdf,
              icon: const Text(
                '📂',
                style: TextStyle(fontSize: 24),
              ),
              label: const Text(
                'Open PDF',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Recently Opened',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: FutureBuilder<List<RecentPdf>>(
              future: _recentPdfsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error loading recents: ${snapshot.error}'),
                  );
                }

                final recents = snapshot.data ?? [];

                if (recents.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.picture_as_pdf_outlined,
                          size: 64,
                          color: theme.colorScheme.outline.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No PDFs opened yet',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: recents.length,
                  itemBuilder: (context, index) {
                    final pdf = recents[index];
                    return RecentPdfTile(
                      pdf: pdf,
                      onTap: () => _openRecentPdf(pdf),
                      onRemove: () => _removeRecentPdf(pdf.path),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

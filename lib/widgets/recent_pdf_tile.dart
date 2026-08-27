import 'dart:io';
import 'package:flutter/material.dart';
import '../models/recent_pdf.dart';

class RecentPdfTile extends StatelessWidget {
  final RecentPdf pdf;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const RecentPdfTile({
    super.key,
    required this.pdf,
    required this.onTap,
    required this.onRemove,
  });

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final difference = now.difference(dt);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1 && now.day == dt.day) {
      final hour = dt.hour.toString().padLeft(2, '0');
      final minute = dt.minute.toString().padLeft(2, '0');
      return 'Today at $hour:$minute';
    } else if (difference.inDays < 2) {
      final hour = dt.hour.toString().padLeft(2, '0');
      final minute = dt.minute.toString().padLeft(2, '0');
      return 'Yesterday at $hour:$minute';
    } else {
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      final hour = dt.hour.toString().padLeft(2, '0');
      final minute = dt.minute.toString().padLeft(2, '0');
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}, $hour:$minute';
    }
  }

  @override
  Widget build(BuildContext context) {
    final fileExists = File(pdf.path).existsSync();
    final colorScheme = Theme.of(context).colorScheme;

    if (!fileExists) {
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        color: colorScheme.errorContainer.withValues(alpha: 0.4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          leading: Icon(
            Icons.broken_image_outlined,
            color: colorScheme.error,
            size: 32,
          ),
          title: Text(
            pdf.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            'File not found (tap to remove)',
            style: TextStyle(color: colorScheme.error, fontSize: 12),
          ),
          trailing: IconButton(
            icon: Icon(Icons.delete_outline, color: colorScheme.error),
            tooltip: 'Remove from recents',
            onPressed: onRemove,
          ),
          onTap: onRemove,
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.picture_as_pdf_rounded,
            color: colorScheme.primary,
            size: 28,
          ),
        ),
        title: Text(
          pdf.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          _formatDate(pdf.lastOpened),
          style: TextStyle(
            color: colorScheme.onSurfaceVariant,
            fontSize: 12,
          ),
        ),
        trailing: IconButton(
          icon: Icon(
            Icons.close,
            size: 18,
            color: colorScheme.outline,
          ),
          tooltip: 'Remove from recents',
          onPressed: onRemove,
        ),
        onTap: onTap,
      ),
    );
  }
}

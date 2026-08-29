import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';

class ChatUtils {
  /// Deterministic 1-on-1 Chat ID generator ensuring two users always share the same conversation room
  static String getChatId(String uid1, String uid2) {
    return uid1.hashCode <= uid2.hashCode ? '${uid1}_$uid2' : '${uid2}_$uid1';
  }

  /// Returns appropriate status icon & color for messages (WhatsApp style)
  static Widget getStatusIcon(String status, {double size = 16}) {
    switch (status) {
      case AppConstants.statusPending:
        return Icon(Icons.access_time_rounded, size: size, color: Colors.grey.shade400);
      case AppConstants.statusSent:
        return Icon(Icons.check, size: size, color: Colors.grey.shade400);
      case AppConstants.statusDelivered:
        return Icon(Icons.done_all, size: size, color: Colors.grey.shade400);
      case AppConstants.statusRead:
        return Icon(Icons.done_all, size: size, color: const Color(0xFF34B7F1)); // WhatsApp Blue Tick
      default:
        return Icon(Icons.check, size: size, color: Colors.grey.shade400);
    }
  }
}

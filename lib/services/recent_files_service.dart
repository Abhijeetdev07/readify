import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/recent_pdf.dart';

class RecentFilesService {
  static const String _recentPdfsKey = 'recent_pdfs';
  static const int _maxRecentItems = 10;

  Future<List<RecentPdf>> getRecentPdfs() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStringList = prefs.getStringList(_recentPdfsKey);

    if (jsonStringList == null) {
      return [];
    }

    try {
      return jsonStringList
          .map((item) => RecentPdf.fromJson(jsonDecode(item) as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> addRecentPdf(RecentPdf pdf) async {
    final prefs = await SharedPreferences.getInstance();
    List<RecentPdf> currentList = await getRecentPdfs();

    // Deduplicate by path
    currentList.removeWhere((item) => item.path == pdf.path);

    // Add to top
    currentList.insert(0, pdf);

    // Cap list at 10 items
    if (currentList.length > _maxRecentItems) {
      currentList = currentList.sublist(0, _maxRecentItems);
    }

    final jsonStringList = currentList
        .map((item) => jsonEncode(item.toJson()))
        .toList();

    await prefs.setStringList(_recentPdfsKey, jsonStringList);
  }

  Future<void> removeRecentPdf(String path) async {
    final prefs = await SharedPreferences.getInstance();
    List<RecentPdf> currentList = await getRecentPdfs();

    currentList.removeWhere((item) => item.path == path);

    final jsonStringList = currentList
        .map((item) => jsonEncode(item.toJson()))
        .toList();

    await prefs.setStringList(_recentPdfsKey, jsonStringList);
  }

  Future<void> clearRecentPdfs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_recentPdfsKey);
  }
}

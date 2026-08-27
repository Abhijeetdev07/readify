class RecentPdf {
  final String name;
  final String path;
  final DateTime lastOpened;

  RecentPdf({
    required this.name,
    required this.path,
    required this.lastOpened,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'path': path,
      'lastOpened': lastOpened.toIso8601String(),
    };
  }

  factory RecentPdf.fromJson(Map<String, dynamic> json) {
    return RecentPdf(
      name: json['name'] as String,
      path: json['path'] as String,
      lastOpened: DateTime.parse(json['lastOpened'] as String),
    );
  }
}

class LocalComicRecord {
  const LocalComicRecord({
    required this.title,
    required this.cover,
    required this.comicUrl,
    required this.updatedAt,
    this.chapterTitle = '',
    this.chapterUrl = '',
  });

  final String title;
  final String cover;
  final String comicUrl;
  final int updatedAt;
  final String chapterTitle;
  final String chapterUrl;

  factory LocalComicRecord.fromMap(Map<String, dynamic> map) {
    return LocalComicRecord(
      title: map['title'] as String? ?? '',
      cover: map['cover'] as String? ?? '',
      comicUrl: map['comicUrl'] as String? ?? '',
      updatedAt: map['updatedAt'] as int? ?? 0,
      chapterTitle: map['chapterTitle'] as String? ?? '',
      chapterUrl: map['chapterUrl'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'title': title,
    'cover': cover,
    'comicUrl': comicUrl,
    'updatedAt': updatedAt,
    'chapterTitle': chapterTitle,
    'chapterUrl': chapterUrl,
  };
}

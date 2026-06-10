class EducationContent {
  final String id;
  final String title;
  final String slug;
  final String content;
  final String? category;
  final String contentType;
  final String? summary;
  final String? thumbnailUrl;
  final String? videoUrl;
  final String? author;
  final String? source;
  final List<String> tags;
  final int viewCount;
  final DateTime createdAt;

  EducationContent({
    required this.id,
    required this.title,
    required this.slug,
    required this.content,
    this.category,
    this.contentType = 'article',
    this.summary,
    this.thumbnailUrl,
    this.videoUrl,
    this.author,
    this.source,
    this.tags = const [],
    this.viewCount = 0,
    required this.createdAt,
  });

  factory EducationContent.fromMap(Map<String, dynamic> map) {
    final rawTags = map['tags'];
    final tags = <String>[];
    if (rawTags is List) {
      tags.addAll(rawTags.map((e) => e.toString()));
    }
    return EducationContent(
      id: map['id'].toString(),
      title: map['title']?.toString() ?? '',
      slug: map['slug']?.toString() ?? map['id'].toString(),
      content: map['content']?.toString() ?? '',
      category: map['category']?.toString(),
      contentType: map['content_type']?.toString() ?? 'article',
      summary: map['summary']?.toString(),
      thumbnailUrl: map['thumbnail_url']?.toString(),
      videoUrl: map['video_url']?.toString(),
      author: map['author']?.toString(),
      source: map['source']?.toString(),
      tags: tags,
      viewCount: (map['view_count'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  bool get isVideo => contentType == 'video' && (videoUrl?.isNotEmpty ?? false);
  bool get isInfographic => contentType == 'infographic';
}

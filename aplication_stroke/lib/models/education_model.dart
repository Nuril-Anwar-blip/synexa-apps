class EducationContent {
  final String id;
  final String title;
  final String content;
  final String? category;
  final String? imageUrl;
  final DateTime createdAt;

  EducationContent({
    required this.id,
    required this.title,
    required this.content,
    this.category,
    this.imageUrl,
    required this.createdAt,
  });

  factory EducationContent.fromMap(Map<String, dynamic> map) {
    return EducationContent(
      id: map['id'],
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      category: map['category'],
      imageUrl: map['media_url'] ?? map['image_url'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}

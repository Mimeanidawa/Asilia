class DailyLesson {
  DailyLesson({
    required this.id,
    required this.title,
    required this.excerpt,
    required this.content,
    required this.imageUrl,
    required this.publishedAt,
    required this.authorName,
    required this.readTimeMinutes,
    this.topicTag,
    this.isPublished = false,
  });

  final String id;
  final String title;
  final String excerpt;
  final String content;
  final String imageUrl;
  final DateTime publishedAt;
  final String authorName;
  final int readTimeMinutes;
  final String? topicTag;
  bool isPublished;

  bool get isToday {
    final now = DateTime.now();
    return publishedAt.year == now.year &&
        publishedAt.month == now.month &&
        publishedAt.day == now.day;
  }

  String get formattedDate {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[publishedAt.month - 1]} ${publishedAt.day}, ${publishedAt.year}';
  }

  DailyLesson copyWith({
    String? title,
    String? excerpt,
    String? content,
    String? imageUrl,
    DateTime? publishedAt,
    String? authorName,
    int? readTimeMinutes,
    String? topicTag,
    bool? isPublished,
  }) =>
      DailyLesson(
        id: id,
        title: title ?? this.title,
        excerpt: excerpt ?? this.excerpt,
        content: content ?? this.content,
        imageUrl: imageUrl ?? this.imageUrl,
        publishedAt: publishedAt ?? this.publishedAt,
        authorName: authorName ?? this.authorName,
        readTimeMinutes: readTimeMinutes ?? this.readTimeMinutes,
        topicTag: topicTag ?? this.topicTag,
        isPublished: isPublished ?? this.isPublished,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'excerpt': excerpt,
        'content': content,
        'imageUrl': imageUrl,
        'publishedAt': publishedAt.toIso8601String(),
        'authorName': authorName,
        'readTimeMinutes': readTimeMinutes,
        if (topicTag != null) 'topicTag': topicTag,
        'isPublished': isPublished,
      };

  factory DailyLesson.fromJson(Map<String, dynamic> json) => DailyLesson(
        id: json['id'] as String,
        title: json['title'] as String,
        excerpt: json['excerpt'] as String,
        content: json['content'] as String,
        imageUrl: json['imageUrl'] as String,
        publishedAt: DateTime.parse(json['publishedAt'] as String),
        authorName: json['authorName'] as String,
        readTimeMinutes: json['readTimeMinutes'] as int,
        topicTag: json['topicTag'] as String?,
        isPublished: json['isPublished'] as bool? ?? false,
      );
}

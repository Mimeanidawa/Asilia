enum HerbCategory { herbs, conditions, wellness, treatment }

enum ArticleCategory { healthTips, herbs101, nutrition }

enum ConditionIconType { cough, stomach, heart, diabetes, skin }

enum AppScreen { home, herbDetails, askExpert, learn, conditions, profile, darasaHuru, contentList, contentDetail, auth, notifications }

enum TopicLinkType { learn, conditions, askExpert, herb, condition }

class EducationTopic {
  const EducationTopic({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.categoryLabel,
    required this.linkType,
    this.linkId,
  });

  final String id;
  final String title;
  final String subtitle;
  final String imageUrl;
  final String categoryLabel;
  final TopicLinkType linkType;
  final String? linkId;
}

class Herb {
  const Herb({
    required this.id,
    required this.name,
    required this.scientificName,
    this.localName,
    required this.imageUrl,
    required this.usedFor,
    required this.description,
    required this.benefits,
    required this.howToUse,
    required this.isPopular,
    required this.category,
  });

  final String id;
  final String name;
  final String scientificName;
  final String? localName;
  final String imageUrl;
  final List<String> usedFor;
  final String description;
  final List<String> benefits;
  final String howToUse;
  final bool isPopular;
  final HerbCategory category;
}

class Condition {
  const Condition({
    required this.id,
    required this.name,
    required this.shortDesc,
    required this.longDesc,
    required this.remedies,
    required this.iconType,
  });

  final String id;
  final String name;
  final String shortDesc;
  final String longDesc;
  final List<String> remedies;
  final ConditionIconType iconType;
}

class Article {
  const Article({
    required this.id,
    required this.title,
    required this.category,
    required this.imageUrl,
    required this.readTime,
    required this.summary,
    required this.content,
  });

  final String id;
  final String title;
  final ArticleCategory category;
  final String imageUrl;
  final String readTime;
  final String summary;
  final String content;

  String get categoryLabel {
    switch (category) {
      case ArticleCategory.healthTips:
        return 'Health Tips';
      case ArticleCategory.herbs101:
        return 'Herbs 101';
      case ArticleCategory.nutrition:
        return 'Nutrition';
    }
  }
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    this.image,
  });

  final String id;
  final String role;
  final String content;
  final String? image;

  Map<String, dynamic> toJson() => {
        'id': id,
        'role': role,
        'content': content,
        if (image != null) 'image': image,
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json['id'] as String,
        role: json['role'] as String,
        content: json['content'] as String,
        image: json['image'] as String?,
      );
}

class Reminder {
  const Reminder({
    required this.id,
    required this.title,
    required this.time,
    required this.herbId,
    required this.active,
  });

  final String id;
  final String title;
  final String time;
  final String herbId;
  final bool active;

  Reminder copyWith({bool? active}) => Reminder(
        id: id,
        title: title,
        time: time,
        herbId: herbId,
        active: active ?? this.active,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'time': time,
        'herbId': herbId,
        'active': active,
      };

  factory Reminder.fromJson(Map<String, dynamic> json) => Reminder(
        id: json['id'] as String,
        title: json['title'] as String,
        time: json['time'] as String,
        herbId: json['herbId'] as String,
        active: json['active'] as bool,
      );
}

class DailyLesson {
  const DailyLesson({
    required this.id,
    required this.title,
    required this.excerpt,
    required this.content,
    required this.imageUrl,
    required this.publishedAt,
    required this.authorName,
    required this.readTimeMinutes,
    this.topicTag,
    this.isPublished = true,
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
  final bool isPublished;

  bool get isToday {
    final now = DateTime.now();
    return publishedAt.year == now.year &&
        publishedAt.month == now.month &&
        publishedAt.day == now.day;
  }

  String get readTimeLabel => '$readTimeMinutes min read';

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
        isPublished: json['isPublished'] as bool? ?? true,
      );
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    this.isRead = false,
    this.lessonId,
    this.contentId,
    this.imageUrl = '',
    this.type = 'general',
  });

  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  final bool isRead;
  final String? lessonId;
  final String? contentId;
  final String imageUrl;
  final String type;

  AppNotification copyWith({bool? isRead}) => AppNotification(
        id: id,
        title: title,
        body: body,
        timestamp: timestamp,
        isRead: isRead ?? this.isRead,
        lessonId: lessonId,
        contentId: contentId,
        imageUrl: imageUrl,
        type: type,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'timestamp': timestamp.toIso8601String(),
        'isRead': isRead,
        if (lessonId != null) 'lessonId': lessonId,
        if (contentId != null) 'contentId': contentId,
        if (imageUrl.isNotEmpty) 'imageUrl': imageUrl,
        'type': type,
      };

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
        id: json['id'] as String,
        title: json['title'] as String,
        body: json['body'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        isRead: json['isRead'] as bool? ?? false,
        lessonId: json['lessonId'] as String?,
        contentId: json['contentId'] as String?,
        imageUrl: json['imageUrl'] as String? ?? '',
        type: json['type'] as String? ?? 'general',
      );
}

class SavedQuestion {
  const SavedQuestion({
    required this.id,
    required this.query,
    required this.answer,
    required this.timestamp,
  });

  final String id;
  final String query;
  final String answer;
  final String timestamp;

  Map<String, dynamic> toJson() => {
        'id': id,
        'query': query,
        'answer': answer,
        'timestamp': timestamp,
      };

  factory SavedQuestion.fromJson(Map<String, dynamic> json) => SavedQuestion(
        id: json['id'] as String,
        query: json['query'] as String,
        answer: json['answer'] as String,
        timestamp: json['timestamp'] as String,
      );
}

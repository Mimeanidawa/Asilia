import '../models/content_models.dart';
import '../models/models.dart';
import '../services/content_service.dart';
import '../services/lesson_service.dart';

class ContentSearchHit {
  const ContentSearchHit.post(this.post, {required this.score})
      : lesson = null,
        kind = ContentSearchHitKind.post;

  const ContentSearchHit.lesson(this.lesson, {required this.score})
      : post = null,
        kind = ContentSearchHitKind.lesson;

  final ContentPost? post;
  final DailyLesson? lesson;
  final int score;
  final ContentSearchHitKind kind;

  String get id => post?.id ?? lesson!.id;
  String get title => post?.title ?? lesson!.title;
  String get subtitle => post?.subtitle.isNotEmpty == true
      ? post!.subtitle
      : (post?.excerpt ?? lesson?.excerpt ?? '');
  String get imageUrl => post?.imageUrl ?? lesson?.imageUrl ?? '';
}

enum ContentSearchHitKind { post, lesson }

class ContentSearch {
  ContentSearch._();

  static List<ContentSearchHit> search({
    required String query,
    required ContentService content,
    LessonService? lessons,
    String? subtitleHint,
    String? preferredId,
  }) {
    final terms = _searchTerms(query, subtitleHint);
    if (terms.isEmpty && (preferredId == null || preferredId.isEmpty)) return [];

    final hits = <ContentSearchHit>[];

    for (final post in content.allPosts) {
      var score = terms.isEmpty
          ? 0
          : _scoreText(
              terms,
              '${post.title} ${post.subtitle} ${post.excerpt} '
              '${post.categoryLabel} ${ContentSections.sectionLabel(post.section)}',
              primary: post.title,
            );
      if (preferredId != null && post.id == preferredId) score += 200;
      if (score > 0) hits.add(ContentSearchHit.post(post, score: score));
    }

    for (final lesson in lessons?.publishedLessons ?? const <DailyLesson>[]) {
      var score = terms.isEmpty
          ? 0
          : _scoreText(
              terms,
              '${lesson.title} ${lesson.excerpt} ${lesson.topicTag ?? ''} Darasa Huru',
              primary: lesson.title,
            );
      if (preferredId != null && lesson.id == preferredId) score += 200;
      if (score > 0) hits.add(ContentSearchHit.lesson(lesson, score: score));
    }

    hits.sort((a, b) => b.score.compareTo(a.score));
    return hits;
  }

  static List<String> _searchTerms(String title, String? subtitle) {
    final raw = '${title.trim()} ${subtitle?.trim() ?? ''}'.trim();
    final normalized = _normalize(raw);
    if (normalized.isEmpty) return [];

    final terms = <String>{normalized};
    for (final word in normalized.split(RegExp(r'\s+'))) {
      if (word.length >= 3) terms.add(word);
    }
    return terms.toList();
  }

  static int _scoreText(List<String> terms, String haystack, {required String primary}) {
    final hay = _normalize(haystack);
    final title = _normalize(primary);
    if (hay.isEmpty || title.isEmpty) return 0;

    var score = 0;
    final mainQuery = terms.first;

    if (title == mainQuery) score += 120;
    if (title.contains(mainQuery) || mainQuery.contains(title)) score += 80;

    for (final term in terms) {
      if (term.length < 3) continue;
      if (title.contains(term)) score += 25;
      if (hay.contains(term)) score += 12;
    }

    return score;
  }

  static String _normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s\u00C0-\u024F]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}

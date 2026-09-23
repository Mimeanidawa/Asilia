import '../data/app_data.dart' as app_catalog;
import '../models/content_models.dart';
import '../models/models.dart';
import '../services/content_service.dart';
import '../services/lesson_service.dart';

enum ContentSearchHitKind { post, lesson, condition }

class ContentSearchHit {
  const ContentSearchHit.post(this.post, {required this.score})
      : lesson = null,
        condition = null,
        kind = ContentSearchHitKind.post;

  const ContentSearchHit.lesson(this.lesson, {required this.score})
      : post = null,
        condition = null,
        kind = ContentSearchHitKind.lesson;

  const ContentSearchHit.condition(this.condition, {required this.score})
      : post = null,
        lesson = null,
        kind = ContentSearchHitKind.condition;

  final ContentPost? post;
  final DailyLesson? lesson;
  final Condition? condition;
  final int score;
  final ContentSearchHitKind kind;

  String get id => post?.id ?? lesson?.id ?? condition!.id;
  String get title => post?.title ?? lesson?.title ?? condition!.name;
  String get subtitle => post?.subtitle.isNotEmpty == true
      ? post!.subtitle
      : (post?.excerpt ?? lesson?.excerpt ?? condition?.shortDesc ?? '');
  String get imageUrl => post?.imageUrl ?? lesson?.imageUrl ?? '';
}

class ContentSearch {
  ContentSearch._();

  static List<ContentSearchHit> search({
    required String query,
    required ContentService content,
    LessonService? lessons,
    List<Condition>? conditionsList,
    String? subtitleHint,
    String? preferredId,
  }) {
    final terms = _searchTerms(query, subtitleHint);
    if (terms.isEmpty && (preferredId == null || preferredId.isEmpty)) return [];

    final hits = <ContentSearchHit>[];

    // Search Magonjwa (Conditions)
    final conditionsToSearch = conditionsList ?? app_catalog.conditions;
    for (final condition in conditionsToSearch) {
      final remedyNames = condition.remedies
          .map((r) => app_catalog.herbById(r)?.name ?? r)
          .join(' ');
      var score = terms.isEmpty
          ? 0
          : _scoreText(
              terms,
              '${condition.name} ${condition.shortDesc} ${condition.longDesc} $remedyNames Ugonjwa Magonjwa Afya Tiba Asili',
              primary: condition.name,
            );
      if (preferredId != null && condition.id == preferredId) score += 200;
      if (score > 0) hits.add(ContentSearchHit.condition(condition, score: score));
    }

    // Search Makala (Content Posts)
    for (final post in content.allPosts) {
      var score = terms.isEmpty
          ? 0
          : _scoreText(
              terms,
              '${post.title} ${post.subtitle} ${post.excerpt} '
              '${post.categoryLabel} ${ContentSections.sectionLabel(post.section)} Makala Dawa',
              primary: post.title,
            );
      if (preferredId != null && post.id == preferredId) score += 200;
      if (score > 0) hits.add(ContentSearchHit.post(post, score: score));
    }

    // Search Masomo (Daily Lessons)
    for (final lesson in lessons?.publishedLessons ?? const <DailyLesson>[]) {
      var score = terms.isEmpty
          ? 0
          : _scoreText(
              terms,
              '${lesson.title} ${lesson.excerpt} ${lesson.topicTag ?? ''} Darasa Huru Somo',
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
      if (word.length >= 2) terms.add(word);
    }
    return terms.toList();
  }

  static int _scoreText(List<String> terms, String haystack, {required String primary}) {
    final hay = _normalize(haystack);
    final title = _normalize(primary);
    if (hay.isEmpty || title.isEmpty) return 0;

    var score = 0;
    final mainQuery = terms.first;

    if (title == mainQuery) score += 150;
    if (title.startsWith(mainQuery)) score += 100;
    if (title.contains(mainQuery) || mainQuery.contains(title)) score += 80;
    if (hay.contains(mainQuery)) score += 45;

    for (final term in terms) {
      if (term.isEmpty) continue;
      if (title.contains(term)) score += 30;
      if (hay.contains(term)) score += 15;
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

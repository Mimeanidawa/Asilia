import '../models/models.dart';

/// Legacy static catalog — empty; all content comes from the admin API.
const herbs = <Herb>[];
const conditions = <Condition>[];
const articles = <Article>[];

Herb? herbById(String id) {
  for (final h in herbs) {
    if (h.id == id) return h;
  }
  return null;
}

Condition? conditionById(String id) {
  for (final c in conditions) {
    if (c.id == id) return c;
  }
  return null;
}

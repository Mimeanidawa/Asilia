import 'package:asilia/data/app_data.dart';
import 'package:asilia/providers/app_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Static catalog is empty — content comes from admin API', () {
    expect(herbs, isEmpty);
    expect(conditions, isEmpty);
    expect(articles, isEmpty);
  });

  test('AppProvider starts with empty profile defaults', () {
    final provider = AppProvider();
    expect(provider.favorites, isEmpty);
    expect(provider.reminders, isEmpty);
    expect(provider.questions, isEmpty);
    expect(provider.selectedHerbId, isNull);
  });
}

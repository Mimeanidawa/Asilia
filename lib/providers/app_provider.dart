import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';
import '../services/chat_service.dart';
import '../services/lesson_service.dart';

const _welcomeMessage = ChatMessage(
  id: 'welcome',
  role: 'model',
  content: 'Karibu! Uliza swali lako kuhusu mimea, mizizi na matunda.',
);

class AppProvider extends ChangeNotifier {
  AppProvider({
    ChatService? chatService,
    LessonService? lessonService,
  })  : _chatService = chatService ?? ChatService(),
        _lessonService = lessonService ?? LessonService() {
    _lessonService.addListener(_onLessonsChanged);
  }

  final ChatService _chatService;
  final LessonService _lessonService;

  LessonService get lessonService => _lessonService;

  void _onLessonsChanged() => notifyListeners();

  void openLessonFromNotification(String lessonId) {
    selectedLessonId = lessonId;
    navigate(AppScreen.darasaHuru, lessonId: lessonId);
  }

  void openContentFromNotification(String contentId) {
    selectedContentId = contentId;
    navigate(AppScreen.contentDetail, contentId: contentId);
  }

  void openFromNotification({String? lessonId, String? contentId, String? type}) {
    if (type == 'message') {
      navigate(AppScreen.askExpert);
    } else if (contentId != null) {
      openContentFromNotification(contentId);
    } else if (lessonId != null) {
      openLessonFromNotification(lessonId);
    }
  }

  Future<void> refreshLessons() => _lessonService.syncFromServer();

  AppScreen activeScreen = AppScreen.home;
  final List<AppScreen> screenHistory = [AppScreen.home];
  String? selectedHerbId;
  String? selectedConditionId;

  String? selectedLessonId;
  String? selectedContentId;
  String? selectedContentSection;
  String? selectedContentCategory;

  List<String> favorites = [];
  List<Reminder> reminders = [];
  List<SavedQuestion> questions = [];
  List<ChatMessage> chatMessages = [_welcomeMessage];
  bool isChatLoading = false;

  bool _loaded = false;
  bool get isLoaded => _loaded;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();

    final favJson = prefs.getString('da_favorites');
    if (favJson != null) {
      favorites = List<String>.from(jsonDecode(favJson) as List);
    }

    final remJson = prefs.getString('da_reminders');
    if (remJson != null) {
      reminders = (jsonDecode(remJson) as List)
          .map((e) => Reminder.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    final qJson = prefs.getString('da_questions');
    if (qJson != null) {
      questions = (jsonDecode(qJson) as List)
          .map((e) => SavedQuestion.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    final chatJson = prefs.getString('da_chat');
    if (chatJson != null) {
      chatMessages = (jsonDecode(chatJson) as List)
          .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    await _lessonService.load();

    _loaded = true;
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('da_favorites', jsonEncode(favorites));
    await prefs.setString(
      'da_reminders',
      jsonEncode(reminders.map((r) => r.toJson()).toList()),
    );
    await prefs.setString(
      'da_questions',
      jsonEncode(questions.map((q) => q.toJson()).toList()),
    );
    await prefs.setString(
      'da_chat',
      jsonEncode(chatMessages.map((m) => m.toJson()).toList()),
    );
  }

  void navigate(AppScreen screen, {
    String? herbId,
    String? conditionId,
    String? lessonId,
    String? contentId,
    String? contentSection,
    String? contentCategory,
  }) {
    if (herbId != null) selectedHerbId = herbId;
    if (conditionId != null) selectedConditionId = conditionId;
    if (lessonId != null) selectedLessonId = lessonId;
    if (contentId != null) selectedContentId = contentId;
    if (contentSection != null) selectedContentSection = contentSection;
    if (contentCategory != null) selectedContentCategory = contentCategory;
    activeScreen = screen;
    screenHistory.add(screen);
    notifyListeners();
  }

  void goBack() {
    if (screenHistory.length > 1) {
      screenHistory.removeLast();
      activeScreen = screenHistory.last;
    } else {
      activeScreen = AppScreen.home;
    }
    notifyListeners();
  }

  void toggleFavorite(String herbId) {
    if (favorites.contains(herbId)) {
      favorites = favorites.where((id) => id != herbId).toList();
    } else {
      favorites = [...favorites, herbId];
    }
    _persist();
    notifyListeners();
  }

  bool isFavorite(String herbId) => favorites.contains(herbId);

  void addReminder(String title, String time, String herbId) {
    reminders = [
      ...reminders,
      Reminder(
        id: 'rem-${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        time: time,
        herbId: herbId,
        active: true,
      ),
    ];
    _persist();
    notifyListeners();
  }

  void toggleReminder(String id) {
    reminders = reminders
        .map((r) => r.id == id ? r.copyWith(active: !r.active) : r)
        .toList();
    _persist();
    notifyListeners();
  }

  void deleteReminder(String id) {
    reminders = reminders.where((r) => r.id != id).toList();
    _persist();
    notifyListeners();
  }

  Future<void> sendChatMessage(String content, {String? imageUrl}) async {
    if (content.trim().isEmpty && imageUrl == null) return;

    final userMsg = ChatMessage(
      id: 'msg-${DateTime.now().millisecondsSinceEpoch}',
      role: 'user',
      content: content,
      image: imageUrl,
    );
    chatMessages = [...chatMessages, userMsg];
    isChatLoading = true;
    notifyListeners();

    try {
      final history = chatMessages
          .where((m) => m.id != 'welcome')
          .toList()
          .reversed
          .take(6)
          .toList()
          .reversed
          .map((m) => {'role': m.role, 'content': m.content})
          .toList();

      final response = await _chatService.getExpertResponse(
        history: history,
        currentMessage: content,
        hasImage: imageUrl != null,
      );

      final botMsg = ChatMessage(
        id: 'msg-${DateTime.now().millisecondsSinceEpoch + 1}',
        role: 'model',
        content: response,
      );
      chatMessages = [...chatMessages, botMsg];

      if (content.length > 15) {
        final duplicate = questions.any(
          (q) => q.query.toLowerCase() == content.toLowerCase(),
        );
        if (!duplicate) {
          questions = [
            SavedQuestion(
              id: 'q-${DateTime.now().millisecondsSinceEpoch}',
              query: content,
              answer: response,
              timestamp: 'Just Now',
            ),
            ...questions,
          ];
        }
      }
    } catch (_) {
      chatMessages = [
        ...chatMessages,
        ChatMessage(
          id: 'msg-${DateTime.now().millisecondsSinceEpoch + 1}',
          role: 'model',
          content:
              'Habari! My roots run deep but my network is struggling. Please ensure you are connected to the online server, or check back shortly. Neem, Aloe Vera and Lemongrass remain your true companions!',
        ),
      ];
    } finally {
      isChatLoading = false;
      await _persist();
      notifyListeners();
    }
  }

  void clearChat() {
    chatMessages = [_welcomeMessage];
    _persist();
    notifyListeners();
  }

  Future<void> resetProfileState() async {
    favorites = [];
    reminders = [];
    questions = [];
    chatMessages = [_welcomeMessage];
    activeScreen = AppScreen.home;
    screenHistory
      ..clear()
      ..add(AppScreen.home);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('da_recent_searches');
    await _persist();
    notifyListeners();
  }
}

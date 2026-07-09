import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/content_models.dart';
import 'api_client.dart';

class MwalimuService extends ChangeNotifier {
  MwalimuService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();
  static const _seenAdminMessageKey = 'da_mwalimu_seen_admin_message_id';
  static const _guestMessagesKey = 'da_guest_chat_messages';
  static const _guestCountKey = 'da_guest_message_count';

  final ApiClient _api;

  MwalimuSettings settings = const MwalimuSettings();
  List<MwalimuMessage> messages = [];
  List<MwalimuMessage> guestMessages = [];
  int messageCount = 0;
  int guestMessageCount = 0;
  int? messageLimit;
  bool isPremium = false;
  bool isLoading = false;
  String? error;
  int unreadCount = 0;

  bool _chatOpen = false;
  bool _stateLoaded = false;
  String? _lastSeenAdminMessageId;

  Future<void> _loadState() async {
    if (_stateLoaded) return;
    final prefs = await SharedPreferences.getInstance();
    _lastSeenAdminMessageId = prefs.getString(_seenAdminMessageKey);
    _stateLoaded = true;
  }

  Future<void> _saveSeenAdminMessageId(String? id) async {
    final prefs = await SharedPreferences.getInstance();
    if (id == null || id.isEmpty) {
      await prefs.remove(_seenAdminMessageKey);
      return;
    }
    await prefs.setString(_seenAdminMessageKey, id);
  }

  Future<void> loadGuestState() async {
    final prefs = await SharedPreferences.getInstance();
    guestMessageCount = prefs.getInt(_guestCountKey) ?? 0;
    final raw = prefs.getString(_guestMessagesKey);
    if (raw == null || raw.isEmpty) {
      guestMessages = [];
      return;
    }

    try {
      final list = jsonDecode(raw) as List;
      guestMessages = list
          .map((e) => MwalimuMessage.fromJson(e as Map<String, dynamic>))
          .toList();
      guestMessageCount = math.max(guestMessageCount, guestMessages.length);
    } catch (e) {
      debugPrint('Guest chat load error: $e');
      guestMessages = [];
      guestMessageCount = 0;
    }
    notifyListeners();
  }

  Future<void> _saveGuestState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_guestCountKey, guestMessageCount);
    await prefs.setString(
      _guestMessagesKey,
      jsonEncode(guestMessages.map(_messageToJson).toList()),
    );
  }

  Map<String, dynamic> _messageToJson(MwalimuMessage message) => {
        'id': message.id,
        'senderType': message.senderType,
        'content': message.content,
        'createdAt': message.createdAt,
      };

  Future<bool> sendGuestMessage(String content) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty || !canSendAsGuest()) return false;

    final msg = MwalimuMessage(
      id: 'guest_${DateTime.now().microsecondsSinceEpoch}',
      senderType: 'user',
      content: trimmed,
      createdAt: DateTime.now().toUtc().toIso8601String(),
    );
    guestMessages = [...guestMessages, msg];
    guestMessageCount++;
    await _saveGuestState();
    notifyListeners();
    return true;
  }

  Future<void> flushGuestMessagesToServer(String userToken) async {
    if (guestMessages.isEmpty) return;

    while (guestMessages.isNotEmpty && canSendMessage()) {
      final msg = guestMessages.first;
      final ok = await sendMessage(msg.content, userToken);
      if (!ok) break;
      guestMessages = guestMessages.sublist(1);
      guestMessageCount = guestMessages.length;
      await _saveGuestState();
    }

    if (guestMessages.isEmpty) {
      guestMessageCount = 0;
      await _saveGuestState();
    }
    notifyListeners();
  }

  Future<void> loadSettings() async {
    try {
      final data = await _api.get('/api/chat/settings');
      settings = MwalimuSettings.fromJson(
        data['settings'] as Map<String, dynamic>,
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Mwalimu settings error: $e');
    }
  }

  Future<void> loadMessages(String? userToken) async {
    if (userToken == null) return;
    await _loadState();
    isLoading = true;
    notifyListeners();

    try {
      final data = await _api.get('/api/chat/messages', token: userToken);
      messages = (data['messages'] as List)
          .map((e) => MwalimuMessage.fromJson(e as Map<String, dynamic>))
          .toList();
      messageCount = data['messageCount'] as int? ?? 0;
      messageLimit = data['messageLimit'] as int?;
      isPremium = data['isPremium'] as bool? ?? false;
      _recomputeUnreadFromMessages();
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> sendMessage(String content, String userToken) async {
    try {
      final data = await _api.post('/api/chat/messages', body: {
        'content': content,
      }, token: userToken);

      final msg = MwalimuMessage.fromJson(
        data['message'] as Map<String, dynamic>,
      );
      messages = [...messages, msg];
      messageCount++;
      notifyListeners();
      return true;
    } catch (e) {
      error = e.toString().replaceAll('ApiException: ', '');
      notifyListeners();
      return false;
    }
  }

  bool canSendMessage() {
    if (isPremium) return true;
    if (messageLimit == null) return true;
    return messageCount < messageLimit!;
  }

  bool canSendAsGuest() {
    final limit = settings.freeMessageLimit;
    return guestMessageCount < limit;
  }

  int get remainingGuestMessages {
    final limit = settings.freeMessageLimit;
    return (limit - guestMessageCount).clamp(0, limit);
  }

  int get remainingMessages {
    if (isPremium || messageLimit == null) return -1;
    return (messageLimit! - messageCount).clamp(0, messageLimit!);
  }

  void setChatOpen(bool isOpen) {
    _chatOpen = isOpen;
    if (isOpen) {
      markAllRead();
    }
  }

  Future<void> markAllRead() async {
    final latestAdminId = _latestAdminMessageId(messages);
    unreadCount = 0;
    _lastSeenAdminMessageId = latestAdminId;
    await _saveSeenAdminMessageId(latestAdminId);
    notifyListeners();
  }

  Future<void> handleIncomingAdminPush() async {
    await _loadState();
    if (_chatOpen) return;
    unreadCount = (unreadCount + 1).clamp(0, 99);
    notifyListeners();
  }

  Future<void> syncMessages(String? userToken) async {
    if (userToken == null) return;
    await _loadState();
    try {
      final data = await _api.get('/api/chat/messages', token: userToken);
      messages = (data['messages'] as List)
          .map((e) => MwalimuMessage.fromJson(e as Map<String, dynamic>))
          .toList();
      messageCount = data['messageCount'] as int? ?? 0;
      messageLimit = data['messageLimit'] as int?;
      isPremium = data['isPremium'] as bool? ?? false;
      final bumped = unreadCount;
      _recomputeUnreadFromMessages();
      unreadCount = math.max(unreadCount, bumped);
      notifyListeners();
    } catch (e) {
      debugPrint('Mwalimu sync error: $e');
    }
  }

  void _recomputeUnreadFromMessages() {
    final latestAdminId = _latestAdminMessageId(messages);
    if (latestAdminId == null) {
      unreadCount = 0;
      return;
    }

    if (_lastSeenAdminMessageId == null) {
      _lastSeenAdminMessageId = latestAdminId;
      unreadCount = 0;
      _saveSeenAdminMessageId(latestAdminId);
      return;
    }

    if (_chatOpen) {
      unreadCount = 0;
      if (_lastSeenAdminMessageId != latestAdminId) {
        _lastSeenAdminMessageId = latestAdminId;
        _saveSeenAdminMessageId(latestAdminId);
      }
      return;
    }

    unreadCount = _countAdminMessagesAfter(_lastSeenAdminMessageId!, messages);
  }

  String? _latestAdminMessageId(List<MwalimuMessage> list) {
    for (var i = list.length - 1; i >= 0; i--) {
      final msg = list[i];
      if (msg.isAdmin) return msg.id;
    }
    return null;
  }

  int _countAdminMessagesAfter(String seenId, List<MwalimuMessage> list) {
    final seenIndex = list.indexWhere((m) => m.id == seenId);
    if (seenIndex == -1) {
      return list.where((m) => m.isAdmin).length;
    }
    return list.skip(seenIndex + 1).where((m) => m.isAdmin).length;
  }

  /// Admin-configured expert name — use everywhere instead of hardcoded lesson authors.
  String get displayName {
    final name = settings.mwalimuName.trim();
    return name.isEmpty ? 'Mwalimu' : name;
  }
}

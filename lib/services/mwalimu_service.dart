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
  static const _guestSessionKey = 'da_guest_session_id';

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
  String? _guestSessionId;

  Future<void> _loadState() async {
    if (_stateLoaded) return;
    final prefs = await SharedPreferences.getInstance();
    _lastSeenAdminMessageId = prefs.getString(_seenAdminMessageKey);
    _guestSessionId = prefs.getString(_guestSessionKey);
    _stateLoaded = true;
  }

  Future<String> getGuestSessionId() async {
    await _loadState();
    if (_guestSessionId != null && _guestSessionId!.isNotEmpty) {
      return _guestSessionId!;
    }

    final rand = math.Random.secure();
    final bytes = List<int>.generate(16, (_) => rand.nextInt(256));
    final id = base64Url.encode(bytes).replaceAll('=', '');

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_guestSessionKey, id);
    _guestSessionId = id;
    return id;
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
    final raw = prefs.getString(_guestMessagesKey);
    if (raw == null || raw.isEmpty) {
      guestMessages = [];
    } else {
      try {
        final list = jsonDecode(raw) as List;
        guestMessages = list
            .map((e) => MwalimuMessage.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (e) {
        debugPrint('Guest chat load error: $e');
        guestMessages = [];
      }
    }
    notifyListeners();
  }

  Future<void> loadGuestMessages() async {
    await _loadState();
    isLoading = true;
    notifyListeners();

    try {
      final sessionId = await getGuestSessionId();
      final data = await _api.get(
        '/api/chat/guest/messages?sessionId=${Uri.encodeComponent(sessionId)}',
      );
      guestMessages = (data['messages'] as List)
          .map((e) => MwalimuMessage.fromJson(e as Map<String, dynamic>))
          .toList();
      guestMessageCount = data['messageCount'] as int? ?? 0;
      messageLimit = data['messageLimit'] as int?;
      await _saveGuestState();
      _recomputeUnreadFromMessages(guestMessages);
    } catch (e) {
      debugPrint('Guest messages sync error: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  int get guestSentCount => guestMessageCount > 0
      ? guestMessageCount
      : guestMessages.where((m) => m.isUser).length;

  Future<void> _saveGuestState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _guestMessagesKey,
      jsonEncode(guestMessages.map(_messageToJson).toList()),
    );
    await prefs.remove('da_guest_message_count');
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

    final sessionId = await getGuestSessionId();

    // Optimistic local bubble while request is in flight
    final pendingId = 'guest_${DateTime.now().microsecondsSinceEpoch}';
    final pending = MwalimuMessage(
      id: pendingId,
      senderType: 'user',
      content: trimmed,
      createdAt: DateTime.now().toUtc().toIso8601String(),
    );
    guestMessages = [...guestMessages, pending];
    notifyListeners();

    try {
      final data = await _api.post('/api/chat/guest/messages', body: {
        'content': trimmed,
        'sessionId': sessionId,
      });

      final msg = MwalimuMessage.fromJson(
        data['message'] as Map<String, dynamic>,
      );
      guestMessageCount = data['messageCount'] as int? ?? guestMessageCount + 1;
      messageLimit = data['messageLimit'] as int?;

      guestMessages = [
        ...guestMessages.where((m) => m.id != pendingId),
        msg,
      ];
      await _saveGuestState();
      notifyListeners();
      return true;
    } catch (e) {
      error = e.toString().replaceAll('ApiException: ', '');
      guestMessages = guestMessages.where((m) => m.id != pendingId).toList();
      notifyListeners();
      return false;
    }
  }

  Future<void> linkGuestSession(String userToken) async {
    final sessionId = await getGuestSessionId();
    try {
      await _api.post('/api/chat/guest/link', body: {
        'sessionId': sessionId,
      }, token: userToken);
      guestMessages = [];
      guestMessageCount = 0;
      await _saveGuestState();
    } catch (e) {
      debugPrint('Guest session link error: $e');
    }
  }

  Future<void> flushGuestMessagesToServer(String userToken) async {
    await loadGuestState();

    // Retry any messages that failed to reach the server
    final pending = guestMessages
        .where((m) => m.isUser && m.id.startsWith('guest_'))
        .toList();
    for (final msg in pending) {
      if (!canSendAsGuest()) break;
      final ok = await sendGuestMessage(msg.content);
      if (!ok) break;
    }

    await linkGuestSession(userToken);

    // Fallback: send any remaining local-only messages as authenticated user
    while (guestMessages.isNotEmpty && canSendMessage()) {
      final msg = guestMessages.first;
      if (!msg.isUser) {
        guestMessages = guestMessages.sublist(1);
        continue;
      }
      final ok = await sendMessage(msg.content, userToken);
      if (!ok) break;
      guestMessages = guestMessages.sublist(1);
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
      _recomputeUnreadFromMessages(messages);
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
    final limit = messageLimit ?? settings.freeMessageLimit;
    return guestSentCount < limit;
  }

  void setChatOpen(bool isOpen) {
    _chatOpen = isOpen;
    if (isOpen) {
      markAllRead();
    }
  }

  Future<void> markAllRead() async {
    final list = messages.isNotEmpty ? messages : guestMessages;
    final latestAdminId = _latestAdminMessageId(list);
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
    if (userToken == null) {
      await loadGuestMessages();
      return;
    }
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
      _recomputeUnreadFromMessages(messages);
      unreadCount = math.max(unreadCount, bumped);
      notifyListeners();
    } catch (e) {
      debugPrint('Mwalimu sync error: $e');
    }
  }

  void _recomputeUnreadFromMessages(List<MwalimuMessage> list) {
    final latestAdminId = _latestAdminMessageId(list);
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

    unreadCount = _countAdminMessagesAfter(_lastSeenAdminMessageId!, list);
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

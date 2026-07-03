import 'package:flutter/foundation.dart';

import '../models/content_models.dart';
import 'api_client.dart';

class MwalimuService extends ChangeNotifier {
  MwalimuService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  MwalimuSettings settings = const MwalimuSettings();
  List<MwalimuMessage> messages = [];
  int messageCount = 0;
  int? messageLimit;
  bool isPremium = false;
  bool isLoading = false;
  String? error;

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

  int get remainingMessages {
    if (isPremium || messageLimit == null) return -1;
    return (messageLimit! - messageCount).clamp(0, messageLimit!);
  }
}

import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/remote_app_config.dart';
import 'api_client.dart';

class RemoteAppConfigService extends ChangeNotifier {
  RemoteAppConfigService({ApiClient? apiClient})
      : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  RemoteAppConfig _config = const RemoteAppConfig();
  String? _dismissedMessageId;
  String _currentVersion = '';
  int _currentBuild = 0;
  bool _loaded = false;
  bool _updateDialogShown = false;

  RemoteAppConfig get config => _config;
  ScreenMessageConfig get screenMessage => _config.screenMessage;
  AppUpdateConfig get update => _config.update;
  bool get isLoaded => _loaded;
  String get currentVersion => _currentVersion;
  int get currentBuild => _currentBuild;

  bool get showScreenMessage {
    final msg = _config.screenMessage;
    if (!msg.isVisible) return false;
    if (msg.dismissible &&
        msg.id.isNotEmpty &&
        msg.id == _dismissedMessageId) {
      return false;
    }
    return true;
  }

  bool get needsUpdate {
    final u = _config.update;
    if (!u.forceUpdate) return false;

    final minBuild = u.minBuild;
    if (minBuild > 0) {
      if (_currentBuild <= 0 || _currentBuild < minBuild) return true;
    }

    final minV = u.minVersion.trim();
    if (minV.isNotEmpty) {
      if (_currentVersion.isEmpty) return true;
      return compareAppVersions(_currentVersion, minV) < 0;
    }

    // Force flag alone without a version/build floor does not lock users.
    return false;
  }

  bool get shouldBlockWithUpdateDialog => needsUpdate && !_updateDialogShown;

  Future<void> loadLocalMeta() async {
    try {
      final info = await PackageInfo.fromPlatform();
      _currentVersion = info.version;
      _currentBuild = int.tryParse(info.buildNumber) ?? 0;
    } catch (_) {}
    try {
      final prefs = await SharedPreferences.getInstance();
      _dismissedMessageId = prefs.getString('da_dismissed_screen_message_id');
    } catch (_) {}
  }

  Future<void> syncFromServer({bool silent = true}) async {
    try {
      if (_currentVersion.isEmpty) await loadLocalMeta();
      final data = await _api.get('/api/app/config');
      final raw = data['config'] as Map<String, dynamic>?;
      _config = RemoteAppConfig.fromJson(raw);
      _loaded = true;
      notifyListeners();
    } catch (e) {
      if (!silent) rethrow;
      debugPrint('RemoteAppConfig sync error: $e');
    }
  }

  Future<void> dismissScreenMessage() async {
    final id = _config.screenMessage.id;
    if (id.isEmpty) return;
    _dismissedMessageId = id;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('da_dismissed_screen_message_id', id);
    } catch (_) {}
  }

  void markUpdateDialogShown() {
    _updateDialogShown = true;
  }
}

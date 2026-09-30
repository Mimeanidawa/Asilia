import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'services/admin_notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final isMobile = !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);
  if (isMobile) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  if (defaultTargetPlatform == TargetPlatform.linux) {
    final previousHandler = FlutterError.onError;
    FlutterError.onError = (details) {
      final message = details.exceptionAsString();
      if (message.contains('MouseTracker')) return;
      previousHandler?.call(details);
    };
  }

  // Launch UI immediately so the app never freezes on startup
  runApp(const AdminApp());

  // Bootstrap push notifications in background with safety timeout
  if (isMobile) {
    unawaited(
      bootstrapAdminNotifications()
          .timeout(const Duration(seconds: 4))
          .catchError((e) {
        debugPrint('Admin FCM bootstrap skipped/failed: $e');
      }),
    );
  }
}

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

import 'config/app_config.dart';

/// Firebase options from --dart-define flags.
/// Run `flutterfire configure` or pass:
///   FIREBASE_API_KEY, FIREBASE_APP_ID,
///   FIREBASE_MESSAGING_SENDER_ID, FIREBASE_PROJECT_ID
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (!AppConfig.hasFirebase) {
      throw UnsupportedError('Firebase is not configured. Set dart-define flags.');
    }

    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'Firebase Messaging is only supported on Android, iOS, and Web.',
        );
    }
  }

  static FirebaseOptions get web => FirebaseOptions(
        apiKey: AppConfig.firebaseApiKey,
        appId: AppConfig.firebaseAppId,
        messagingSenderId: AppConfig.firebaseMessagingSenderId,
        projectId: AppConfig.firebaseProjectId,
        authDomain: '${AppConfig.firebaseProjectId}.firebaseapp.com',
        storageBucket: '${AppConfig.firebaseProjectId}.appspot.com',
      );

  static FirebaseOptions get android => FirebaseOptions(
        apiKey: AppConfig.firebaseApiKey,
        appId: AppConfig.firebaseAppId,
        messagingSenderId: AppConfig.firebaseMessagingSenderId,
        projectId: AppConfig.firebaseProjectId,
        storageBucket: '${AppConfig.firebaseProjectId}.appspot.com',
      );

  static FirebaseOptions get ios => FirebaseOptions(
        apiKey: AppConfig.firebaseApiKey,
        appId: AppConfig.firebaseAppId,
        messagingSenderId: AppConfig.firebaseMessagingSenderId,
        projectId: AppConfig.firebaseProjectId,
        storageBucket: '${AppConfig.firebaseProjectId}.appspot.com',
        iosBundleId: 'com.example.asilia',
      );
}

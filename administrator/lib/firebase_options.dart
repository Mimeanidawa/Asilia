import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

import 'config/admin_config.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (!AdminConfig.hasFirebase) {
      throw UnsupportedError('Firebase is not configured.');
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
        apiKey: AdminConfig.firebaseApiKey,
        appId: AdminConfig.firebaseAppId,
        messagingSenderId: AdminConfig.firebaseMessagingSenderId,
        projectId: AdminConfig.firebaseProjectId,
        authDomain: '${AdminConfig.firebaseProjectId}.firebaseapp.com',
        storageBucket: AdminConfig.firebaseStorageBucket,
      );

  static FirebaseOptions get android => FirebaseOptions(
        apiKey: AdminConfig.firebaseApiKey,
        appId: AdminConfig.firebaseAppId,
        messagingSenderId: AdminConfig.firebaseMessagingSenderId,
        projectId: AdminConfig.firebaseProjectId,
        storageBucket: AdminConfig.firebaseStorageBucket,
      );

  static FirebaseOptions get ios => FirebaseOptions(
        apiKey: AdminConfig.firebaseApiKey,
        appId: AdminConfig.firebaseAppId,
        messagingSenderId: AdminConfig.firebaseMessagingSenderId,
        projectId: AdminConfig.firebaseProjectId,
        storageBucket: AdminConfig.firebaseStorageBucket,
        iosBundleId: 'com.asilia.admin',
      );
}

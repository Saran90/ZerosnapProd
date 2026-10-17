// File generated from google-services.json for project processfriendly-51420
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web – '
        'reconfigure with FlutterFire CLI if needed.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for iOS – '
          'add a GoogleService-Info.plist and reconfigure with FlutterFire CLI.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBYVXMK9GDpMFRcJu8mcFxJZ4rL5bMZBr8',
    appId: '1:325373388791:android:22da9a6f889e95b9e2f0f2',
    messagingSenderId: '325373388791',
    projectId: 'processfriendly-51420',
    storageBucket: 'processfriendly-51420.firebasestorage.app',
  );
}

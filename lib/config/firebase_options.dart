// IMPORTANT: Replace these placeholder values with your actual Firebase project configuration.
// Run `flutterfire configure` after setting up your Firebase project to auto-generate this file.
// See README.md for step-by-step Firebase setup instructions.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // Replace with your actual Firebase Web config
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDYC2rUuQqPFXWSRTzIoFH2Ji8FZtC18vw',
    appId: '1:880850190734:android:b9c8a23a84836eff86e4df',
    messagingSenderId: '880850190734',
    projectId: 'semapp-c69ca',
    authDomain: 'semapp-c69ca.firebasestorage.app',
    storageBucket: 'semapp-c69ca.firebasestorage.app',
  );

  // Replace with your actual Firebase Android config (from google-services.json)
  static const FirebaseOptions android = FirebaseOptions(
     apiKey: 'AIzaSyDYC2rUuQqPFXWSRTzIoFH2Ji8FZtC18vw',
    appId: '1:880850190734:android:b9c8a23a84836eff86e4df',
    messagingSenderId: '880850190734',
    projectId: 'semapp-c69ca',
    storageBucket: 'semapp-c69ca.firebasestorage.app',
  );

  // Replace with your actual Firebase iOS config (from GoogleService-Info.plist)
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBp7_MBuuw4R--T0gwmccHR3SzAYItOUwI',
    appId: '1:880850190734:ios:c9dddc93efaa427686e4df',
    messagingSenderId: '880850190734',
    projectId: 'semapp-c69ca',
    storageBucket: 'semapp-c69ca.firebasestorage.app',
    // iosClientId: 'YOUR_IOS_CLIENT_ID',
    iosBundleId: 'sqs.semApp.com',
  );
}

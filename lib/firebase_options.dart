import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
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
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macOS - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for Linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDE_rCQoZ5b95prwL79FEfqWBSuUJ8eOPU',
    appId: '1:356379315387:android:6569c2d6fcaed34b2eed9e', // Ganti dengan App ID web yang benar dari Firebase Console
    messagingSenderId: '356379315387',
    projectId: 'expense-tracker-adc2d',
    authDomain: 'expense-tracker-adc2d.firebaseapp.com',
    storageBucket: 'expense-tracker-adc2d.firebasestorage.app',
    measurementId: null, // Add if using Analytics
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDE_rCQoZ5b95prwL79FEfqWBSuUJ8eOPU',
    appId: '1:356379315387:android:6569c2d6fcaed34b2eed9e',
    messagingSenderId: '356379315387',
    projectId: 'expense-tracker-adc2d',
    storageBucket: 'expense-tracker-adc2d.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDE_rCQoZ5b95prwL79FEfqWBSuUJ8eOPU',
    appId: '1:356379315387:ios:6569c2d6fcaed34b2eed9e', // Update with actual iOS app ID
    messagingSenderId: '356379315387',
    projectId: 'expense-tracker-adc2d',
    storageBucket: 'expense-tracker-adc2d.firebasestorage.app',
    iosBundleId: 'com.example.apps_uas',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDE_rCQoZ5b95prwL79FEfqWBSuUJ8eOPU',
    appId: '1:356379315387:windows:6569c2d6fcaed34b2eed9e',
    messagingSenderId: '356379315387',
    projectId: 'expense-tracker-adc2d',
    storageBucket: 'expense-tracker-adc2d.firebasestorage.app',
  );
}
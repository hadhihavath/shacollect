// File generated for Sha Collects production & offline-first route recovery.
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
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI.',
        );
      default:
        return android;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCobSByfqMkv2QdqFSjoVRSWXKhUj8VXV8',
    appId: '1:1012136392195:web:85b2648f588f71c6438036',
    messagingSenderId: '1012136392195',
    projectId: 'sha-collect',
    authDomain: 'sha-collect.firebaseapp.com',
    storageBucket: 'sha-collect.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCobSByfqMkv2QdqFSjoVRSWXKhUj8VXV8',
    appId: '1:1012136392195:android:85b2648f588f71c6438036',
    messagingSenderId: '1012136392195',
    projectId: 'sha-collect',
    storageBucket: 'sha-collect.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCobSByfqMkv2QdqFSjoVRSWXKhUj8VXV8',
    appId: '1:1012136392195:ios:85b2648f588f71c6438036',
    messagingSenderId: '1012136392195',
    projectId: 'sha-collect',
    storageBucket: 'sha-collect.firebasestorage.app',
    iosBundleId: 'com.havath.shacollect',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCobSByfqMkv2QdqFSjoVRSWXKhUj8VXV8',
    appId: '1:1012136392195:ios:85b2648f588f71c6438036',
    messagingSenderId: '1012136392195',
    projectId: 'sha-collect',
    storageBucket: 'sha-collect.firebasestorage.app',
    iosBundleId: 'com.havath.shacollect',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCobSByfqMkv2QdqFSjoVRSWXKhUj8VXV8',
    appId: '1:1012136392195:web:85b2648f588f71c6438036',
    messagingSenderId: '1012136392195',
    projectId: 'sha-collect',
    storageBucket: 'sha-collect.firebasestorage.app',
  );
}

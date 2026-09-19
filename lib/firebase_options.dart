import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
        throw UnsupportedError('DefaultFirebaseOptions are not supported for this platform.');
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDCPdxHhxuc1GQ1UbzcwBqu2zBrGeLik7Y',
    appId: '1:195945538733:web:e19aacb812280d3b5e9224',
    messagingSenderId: '195945538733',
    projectId: 'flutter-app-18-afa2b',
    authDomain: 'flutter-app-18-afa2b.firebaseapp.com',
    storageBucket: 'flutter-app-18-afa2b.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDCPdxHhxuc1GQ1UbzcwBqu2zBrGeLik7Y',
    appId: '1:195945538733:android:e19aacb812280d3b5e9224',
    messagingSenderId: '195945538733',
    projectId: 'flutter-app-18-afa2b',
    storageBucket: 'flutter-app-18-afa2b.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDCPdxHhxuc1GQ1UbzcwBqu2zBrGeLik7Y',
    appId: '1:195945538733:ios:e19aacb812280d3b5e9224',
    messagingSenderId: '195945538733',
    projectId: 'flutter-app-18-afa2b',
    storageBucket: 'flutter-app-18-afa2b.firebasestorage.app',
    iosBundleId: 'com.sailesh.flutterApp',
  );
}

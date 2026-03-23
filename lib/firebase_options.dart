import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'package:flutter_dotenv/flutter_dotenv.dart';

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
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static FirebaseOptions get android => FirebaseOptions(
    apiKey: dotenv.get('FIREBASE_API_KEY_ANDROID', fallback: ''),
    appId: dotenv.get('FIREBASE_APP_ID_ANDROID', fallback: ''),
    messagingSenderId: dotenv.get('FIREBASE_MESSAGING_SENDER_ID', fallback: ''),
    projectId: dotenv.get('FIREBASE_PROJECT_ID', fallback: ''),
    storageBucket: dotenv.get('FIREBASE_STORAGE_BUCKET', fallback: ''),
  );

  static FirebaseOptions get ios => FirebaseOptions(
    apiKey: dotenv.get('FIREBASE_API_KEY_IOS', fallback: ''),
    appId: dotenv.get('FIREBASE_APP_ID_IOS', fallback: ''),
    messagingSenderId: dotenv.get('FIREBASE_MESSAGING_SENDER_ID', fallback: ''),
    projectId: dotenv.get('FIREBASE_PROJECT_ID', fallback: ''),
    storageBucket: dotenv.get('FIREBASE_STORAGE_BUCKET', fallback: ''),
    iosBundleId: dotenv.get('FIREBASE_IOS_BUNDLE_ID', fallback: ''),
  );
}

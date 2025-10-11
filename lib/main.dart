import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'app/app.dart';
import 'firebase_options.dart';
import 'core/services/cloudinary_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    usePathUrlStrategy();
  }
  try {
    await dotenv.load(fileName: '.env');
  } catch (error) {
    debugPrint('Could not load .env file: $error');
  }

  final cloudinaryReady = await cloudinaryService.ensureInitialized();
  if (!cloudinaryReady) {
    debugPrint('Cloudinary is not configured. Skipping Cloudinary setup.');
  }
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (!kIsWeb) {
    try {
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
    } on FirebaseException catch (error) {
      debugPrint('Failed to enable offline persistence: ${error.message}');
    }
  }
  runApp(const ProviderScope(child: MoneyBaseApp()));
}

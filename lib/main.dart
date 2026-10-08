import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'core/constants/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'services/notification_service.dart';
import 'providers/auth_provider.dart';
import 'providers/firestore_providers.dart';
import 'screens/auth/auth_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize Local Notifications for promised date alarms
  await NotificationService().initialize();

  // Initialize Firebase with Offline Persistence enabled
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
    debugPrint('Firebase & Firestore offline persistence enabled successfully');
  } catch (e) {
    debugPrint('Firebase initialize note: $e (Offline & demo mode active)');
  }

  runApp(
    const ProviderScope(
      child: ShaCollectsApp(),
    ),
  );
}

class ShaCollectsApp extends ConsumerStatefulWidget {
  const ShaCollectsApp({super.key});

  @override
  ConsumerState<ShaCollectsApp> createState() => _ShaCollectsAppState();
}

class _ShaCollectsAppState extends ConsumerState<ShaCollectsApp> {
  @override
  void initState() {
    super.initState();
    _checkAndSeedInitialData();
  }

  Future<void> _checkAndSeedInitialData() async {
    Future.microtask(() async {
      try {
        final firestoreService = ref.read(firestoreServiceProvider);
        final user = ref.read(authStateProvider).valueOrNull;
        await firestoreService.ensureUserAccountInitialized(
          user: user,
        );
        debugPrint('Account database synchronized with Cloud Firestore');
      } catch (e) {
        debugPrint('Account initialization note: $e');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AuthGate(),
    );
  }
}

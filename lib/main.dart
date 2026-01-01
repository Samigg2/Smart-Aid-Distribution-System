import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart';
import 'config/env_config.dart';
import 'widgets/auth_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize environment configuration (loads .env if available)
  await EnvConfig.initialize();
  
  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  // Enable offline persistence (caches data locally for offline access)
  // This allows the app to work offline by using cached data from Firestore
  // When offline:
  //   - Reads use cached data automatically
  //   - Writes are queued and synced when connection is restored
  //   - All changes are synchronized automatically
  // Note: On mobile (Android/iOS), persistence is enabled by default
  // This explicit call ensures it's enabled and allows tab synchronization on web
  try {
    await FirebaseFirestore.instance.enablePersistence(
      const PersistenceSettings(synchronizeTabs: true),
    );
  } catch (e) {
    // Persistence might already be enabled or not supported on this platform
    // Note: enablePersistence is deprecated but still works
    // Firestore automatically enables persistence on mobile platforms
    // The app will work offline with cached data regardless
    if (kDebugMode) {
      debugPrint('Persistence setup: $e');
    }
  }
  
  runApp(
    const ProviderScope(
      child: SmartAidApp(),
    ),
  );
}

class SmartAidApp extends StatelessWidget {
  const SmartAidApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Aid Distribution',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
      debugShowCheckedModeBanner: false,
      // Set background color to prevent black screen
      builder: (context, child) {
        return Container(
          color: Colors.white,
          child: child ?? const SizedBox(),
        );
      },
    );
  }
}

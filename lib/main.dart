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
  // Note: On mobile, this is enabled by default, but we're being explicit
  // This allows the app to work offline by using cached data
  try {
    await FirebaseFirestore.instance.enablePersistence(
      const PersistenceSettings(synchronizeTabs: true),
    );
  } catch (e) {
    // Persistence might already be enabled or not supported on this platform
    // Note: enablePersistence is deprecated, but still works
    // Firestore automatically enables persistence on mobile platforms
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

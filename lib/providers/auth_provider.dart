import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../utils/logger.dart';

// AuthService provider (singleton)
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

// Current user stream provider
final authStateChangesProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

// Current user data provider
final currentUserDataProvider = FutureProvider<UserModel?>((ref) async {
  final authService = ref.watch(authServiceProvider);
  return await authService.getCurrentUserData();
});

// Current user data stream (for real-time updates)
// This properly reacts to auth state changes and fetches user data
final currentUserDataStreamProvider = StreamProvider<UserModel?>((ref) {
  final authService = ref.watch(authServiceProvider);

  // Transform auth state changes into user data stream
  return authService.authStateChanges.asyncMap((user) async {
    if (user == null) {
      return null;
    }
    try {
      // Get user data from Firestore
      return await authService.getCurrentUserData();
    } catch (e, stackTrace) {
      Logger.error('Error fetching user data', error: e, stackTrace: stackTrace, tag: 'AuthProvider');
      return null;
    }
  });
});

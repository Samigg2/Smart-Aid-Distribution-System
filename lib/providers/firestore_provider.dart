import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';
import 'auth_provider.dart';

// FirestoreService provider (singleton)
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

// All users stream provider
// Only loads when user is authenticated and user data is available
final allUsersProvider = StreamProvider<List<UserModel>>((ref) {
  // Watch for user data to be available first
  final userDataAsync = ref.watch(currentUserDataStreamProvider);
  
  // If user data is still loading or null, don't access Firestore yet
  // This prevents Firestore rules from being evaluated before user data exists
  if (userDataAsync.isLoading || userDataAsync.value == null) {
    // Return a stream that waits (doesn't emit, doesn't complete)
    // This keeps the provider in loading state until user data is ready
    final controller = StreamController<List<UserModel>>();
    // Don't close the controller - let it wait
    return controller.stream;
  }
  
  // Now safe to access Firestore - user document exists
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getAllUsers();
});

// User statistics provider
final userStatisticsProvider = FutureProvider<Map<String, int>>((ref) async {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return await firestoreService.getUserStatistics();
});


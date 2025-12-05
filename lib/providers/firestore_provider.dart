import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';

// FirestoreService provider (singleton)
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

// All users stream provider
final allUsersProvider = StreamProvider<List<UserModel>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getAllUsers();
});

// User statistics provider
final userStatisticsProvider = FutureProvider<Map<String, int>>((ref) async {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return await firestoreService.getUserStatistics();
});


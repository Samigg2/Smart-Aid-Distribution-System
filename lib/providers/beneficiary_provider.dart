import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/beneficiary_service.dart';
import '../services/cloudinary_service.dart';
import '../models/beneficiary_model.dart';
import 'auth_provider.dart';

// BeneficiaryService provider
final beneficiaryServiceProvider = Provider<BeneficiaryService>((ref) {
  return BeneficiaryService();
});

// CloudinaryService provider
final cloudinaryServiceProvider = Provider<CloudinaryService>((ref) {
  return CloudinaryService();
});

// All beneficiaries stream provider
// Only loads when user is authenticated and user data is available
final allBeneficiariesProvider = StreamProvider<List<BeneficiaryModel>>((ref) {
  // Watch for user data to be available first
  final userDataAsync = ref.watch(currentUserDataStreamProvider);
  
  // If user data is still loading or null, don't access Firestore yet
  // This prevents Firestore rules from being evaluated before user data exists
  if (userDataAsync.isLoading || userDataAsync.value == null) {
    // Return a stream that waits (doesn't emit, doesn't complete)
    // This keeps the provider in loading state until user data is ready
    final controller = StreamController<List<BeneficiaryModel>>();
    // Don't close the controller - let it wait
    return controller.stream;
  }
  
  // Now safe to access Firestore - user document exists
  final service = ref.watch(beneficiaryServiceProvider);
  return service.getAllBeneficiaries();
});

// Beneficiaries by staff member stream provider
final beneficiariesByStaffProvider =
    StreamProvider.family<List<BeneficiaryModel>, String>((ref, staffUid) {
      // Watch for user data to be available first
      final userDataAsync = ref.watch(currentUserDataStreamProvider);
      
      // If user data is still loading or null, don't access Firestore yet
      // This prevents Firestore rules from being evaluated before user data exists
      if (userDataAsync.isLoading || userDataAsync.value == null) {
        // Return a stream that waits (doesn't emit, doesn't complete)
        // This keeps the provider in loading state until user data is ready
        final controller = StreamController<List<BeneficiaryModel>>();
        // Don't close the controller - let it wait
        return controller.stream;
      }
      
      // Now safe to access Firestore - user document exists
      final service = ref.watch(beneficiaryServiceProvider);
      return service.getBeneficiariesByStaff(staffUid);
    });

// Beneficiary by ID provider
final beneficiaryByIdProvider =
    FutureProvider.family<BeneficiaryModel?, String>((
      ref,
      beneficiaryId,
    ) async {
      final service = ref.watch(beneficiaryServiceProvider);
      return await service.getBeneficiaryById(beneficiaryId);
    });

// Beneficiary statistics provider
final beneficiaryStatisticsProvider = FutureProvider<Map<String, int>>((
  ref,
) async {
  final service = ref.watch(beneficiaryServiceProvider);
  return await service.getBeneficiaryStatistics();
});



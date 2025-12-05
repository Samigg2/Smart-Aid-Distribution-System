import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/beneficiary_service.dart';
import '../services/cloudinary_service.dart';
import '../models/beneficiary_model.dart';

// BeneficiaryService provider
final beneficiaryServiceProvider = Provider<BeneficiaryService>((ref) {
  return BeneficiaryService();
});

// CloudinaryService provider
final cloudinaryServiceProvider = Provider<CloudinaryService>((ref) {
  return CloudinaryService();
});

// All beneficiaries stream provider
final allBeneficiariesProvider = StreamProvider<List<BeneficiaryModel>>((ref) {
  final service = ref.watch(beneficiaryServiceProvider);
  return service.getAllBeneficiaries();
});

// Beneficiaries by staff member stream provider
final beneficiariesByStaffProvider =
    StreamProvider.family<List<BeneficiaryModel>, String>((ref, staffUid) {
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



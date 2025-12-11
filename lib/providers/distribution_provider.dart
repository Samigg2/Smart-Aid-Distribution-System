import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/distribution_service.dart';
import '../models/distribution_model.dart';
import '../models/beneficiary_model.dart';
import 'auth_provider.dart';

// DistributionService provider
final distributionServiceProvider = Provider<DistributionService>((ref) {
  return DistributionService();
});

// All programs stream provider
final allProgramsProvider = StreamProvider<List<DistributionProgram>>((ref) {
  final userDataAsync = ref.watch(currentUserDataStreamProvider);
  
  if (userDataAsync.isLoading || userDataAsync.value == null) {
    final controller = StreamController<List<DistributionProgram>>();
    return controller.stream;
  }
  
  final service = ref.watch(distributionServiceProvider);
  return service.getAllPrograms();
});

// Active programs only
final activeProgramsProvider = StreamProvider<List<DistributionProgram>>((ref) {
  final userDataAsync = ref.watch(currentUserDataStreamProvider);
  
  if (userDataAsync.isLoading || userDataAsync.value == null) {
    final controller = StreamController<List<DistributionProgram>>();
    return controller.stream;
  }
  
  final service = ref.watch(distributionServiceProvider);
  return service.getActivePrograms();
});

// Program by ID - waits for user data
final programByIdProvider = FutureProvider.family<DistributionProgram?, String>(
  (ref, programId) async {
    final userDataAsync = ref.watch(currentUserDataStreamProvider);
    
    // Wait for user data to be ready
    if (userDataAsync.isLoading || userDataAsync.value == null) {
      return null;
    }
    
    final service = ref.watch(distributionServiceProvider);
    return await service.getProgramById(programId);
  },
);

// Eligible beneficiaries for a program - waits for user data
final eligibleBeneficiariesProvider = FutureProvider.family<List<BeneficiaryModel>, DistributionProgram>(
  (ref, program) async {
    final userDataAsync = ref.watch(currentUserDataStreamProvider);
    
    // Wait for user data to be ready
    if (userDataAsync.isLoading || userDataAsync.value == null) {
      return [];
    }
    
    final service = ref.watch(distributionServiceProvider);
    return await service.getEligibleBeneficiaries(program);
  },
);

// Distributions by program - waits for user data
final distributionsByProgramProvider = StreamProvider.family<List<DistributionRecord>, String>(
  (ref, programId) {
    final userDataAsync = ref.watch(currentUserDataStreamProvider);
    
    if (userDataAsync.isLoading || userDataAsync.value == null) {
      final controller = StreamController<List<DistributionRecord>>();
      return controller.stream;
    }
    
    final service = ref.watch(distributionServiceProvider);
    return service.getDistributionsByProgram(programId);
  },
);

// Distributions by beneficiary - waits for user data
final distributionsByBeneficiaryProvider = StreamProvider.family<List<DistributionRecord>, String>(
  (ref, beneficiaryId) {
    final userDataAsync = ref.watch(currentUserDataStreamProvider);
    
    if (userDataAsync.isLoading || userDataAsync.value == null) {
      final controller = StreamController<List<DistributionRecord>>();
      return controller.stream;
    }
    
    final service = ref.watch(distributionServiceProvider);
    return service.getDistributionsByBeneficiary(beneficiaryId);
  },
);

// Recent distributions
final recentDistributionsProvider = StreamProvider<List<DistributionRecord>>((ref) {
  final userDataAsync = ref.watch(currentUserDataStreamProvider);
  
  if (userDataAsync.isLoading || userDataAsync.value == null) {
    final controller = StreamController<List<DistributionRecord>>();
    return controller.stream;
  }
  
  final service = ref.watch(distributionServiceProvider);
  return service.getRecentDistributions(limit: 20);
});

// Distributions by current staff
final myDistributionsProvider = StreamProvider<List<DistributionRecord>>((ref) {
  final userDataAsync = ref.watch(currentUserDataStreamProvider);
  
  if (userDataAsync.isLoading || userDataAsync.value == null) {
    final controller = StreamController<List<DistributionRecord>>();
    return controller.stream;
  }
  
  final user = userDataAsync.value;
  if (user == null) {
    return Stream.value([]);
  }
  
  final service = ref.watch(distributionServiceProvider);
  // For staff, get their distributions; for admin, get recent
  if (user.isAdmin) {
    return service.getRecentDistributions(limit: 50);
  } else {
    return service.getDistributionsByStaff(user.uid);
  }
});

// Distribution statistics - waits for user data
final distributionStatisticsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final userDataAsync = ref.watch(currentUserDataStreamProvider);
  
  // Wait for user data to be ready
  if (userDataAsync.isLoading || userDataAsync.value == null) {
    return {
      'totalPrograms': 0,
      'activePrograms': 0,
      'totalDistributions': 0,
      'uniqueBeneficiariesReached': 0,
      'byAidType': {},
    };
  }
  
  final service = ref.watch(distributionServiceProvider);
  return await service.getDistributionStatistics();
});

// Check if already received (for double-distribution prevention) - waits for user data
final hasAlreadyReceivedProvider = FutureProvider.family<bool, ({String programId, String beneficiaryId})>(
  (ref, params) async {
    final userDataAsync = ref.watch(currentUserDataStreamProvider);
    
    // Wait for user data to be ready
    if (userDataAsync.isLoading || userDataAsync.value == null) {
      return false;
    }
    
    final service = ref.watch(distributionServiceProvider);
    return await service.hasAlreadyReceived(params.programId, params.beneficiaryId);
  },
);

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/priority_classification_service.dart';
import '../models/beneficiary_model.dart';

/// Provider for PriorityClassificationService (singleton)
final priorityClassificationServiceProvider =
    Provider<PriorityClassificationService>((ref) {
  return PriorityClassificationService();
});

/// Provider to classify a beneficiary's priority
final beneficiaryPriorityProvider = FutureProvider.family
    .autoDispose<PriorityLevel, BeneficiaryModel>((ref, beneficiary) async {
  final service = ref.watch(priorityClassificationServiceProvider);
  return await service.classifyPriority(beneficiary);
});




import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/priority_model_ai_service.dart';

final priorityModelAiServiceProvider = Provider<PriorityModelAiService>((ref) {
  return PriorityModelAiService();
});





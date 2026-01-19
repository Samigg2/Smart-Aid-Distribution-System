import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../utils/logger.dart';

class PriorityAiPrediction {
  final String priority;
  final double confidence;

  PriorityAiPrediction({required this.priority, required this.confidence});
}

class PriorityModelAiService {
  Future<bool> checkHealth() async {
    if (!AppConfig.isPriorityAiEnabled) {
      return false;
    }
    final Uri uri = Uri.parse('${AppConfig.priorityAiBaseUrl}/health');
    try {
      final http.Response response = await http
          .get(uri)
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      Logger.warning(
        'Priority AI health check failed: $e',
        tag: 'PriorityModelAiService',
      );
      return false;
    }
  }

  Future<PriorityAiPrediction?> predictPriority({
    required int age,
    required String gender,
    required String income,
    required String disability,
    required int dependents,
    required String description,
  }) async {
    if (!AppConfig.isPriorityAiEnabled) {
      return null;
    }
    final Uri uri = Uri.parse('${AppConfig.priorityAiBaseUrl}/predict');
    final Map<String, dynamic> payload = <String, dynamic>{
      'age': age,
      'gender': gender,
      'income': income,
      'disability': disability,
      'dependents': dependents,
      'description': description,
    };
    try {
      // Build headers with API key if provided
      final Map<String, String> headers = <String, String>{
        'Content-Type': 'application/json',
      };
      if (AppConfig.priorityAiApiKey.trim().isNotEmpty) {
        headers['X-API-Key'] = AppConfig.priorityAiApiKey;
      }

      final http.Response response = await http
          .post(uri, headers: headers, body: jsonEncode(payload))
          .timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) {
        Logger.warning(
          'Priority AI /predict failed: ${response.statusCode} ${response.body}',
          tag: 'PriorityModelAiService',
        );
        return null;
      }
      final Map<String, dynamic> decoded =
          jsonDecode(response.body) as Map<String, dynamic>;

      // Handle both response formats:
      // Format 1: {"success": true, "result": {"priority": "High", ...}}
      // Format 2: {"priority": "High", "confidence": 0.92, ...} (direct)
      Map<String, dynamic> result;
      if (decoded.containsKey('success')) {
        // Format 1: Wrapped response
        final bool isSuccess = (decoded['success'] as bool?) ?? false;
        if (!isSuccess) {
          Logger.warning(
            'Priority AI /predict returned success=false: ${decoded['error']}',
            tag: 'PriorityModelAiService',
          );
          return null;
        }
        result =
            (decoded['result'] as Map<String, dynamic>?) ?? <String, dynamic>{};
      } else {
        // Format 2: Direct response (your Render API format)
        result = decoded;
      }

      final String priorityRaw = (result['priority'] as String?) ?? 'Medium';
      final double confidence = ((result['confidence'] as num?) ?? 0)
          .toDouble();
      final String normalized = priorityRaw.trim().toLowerCase();
      final String priority =
          normalized == 'high' || normalized == 'medium' || normalized == 'low'
          ? normalized
          : 'medium';
      return PriorityAiPrediction(priority: priority, confidence: confidence);
    } catch (e) {
      Logger.warning(
        'Priority AI /predict error: $e',
        tag: 'PriorityModelAiService',
      );
      return null;
    }
  }
}

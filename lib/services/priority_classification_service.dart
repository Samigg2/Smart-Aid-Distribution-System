import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/beneficiary_model.dart';
import '../utils/logger.dart';

/// Priority levels for beneficiary classification
enum PriorityLevel {
  low('low', 'Low Priority'),
  medium('medium', 'Medium Priority'),
  high('high', 'High Priority');

  final String value;
  final String label;
  const PriorityLevel(this.value, this.label);

  static PriorityLevel fromValue(String value) {
    return PriorityLevel.values.firstWhere(
      (e) => e.value == value,
      orElse: () => PriorityLevel.medium,
    );
  }
}

/// Service for AI-based priority classification using Hugging Face models
/// with rule-based fallback
class PriorityClassificationService {
  // Hugging Face Inference API endpoint (free tier)
  // Using a zero-shot classification model that doesn't require training
  static const String _huggingFaceApiUrl =
      'https://api-inference.huggingface.co/models/facebook/bart-large-mnli';
  
  // Alternative model (backup if first fails)
  static const String _backupApiUrl =
      'https://api-inference.huggingface.co/models/typeform/distilbert-base-uncased-mnli';

  // Cache for API responses to reduce API calls
  final Map<String, PriorityLevel> _cache = {};

  /// Generate title and description from beneficiary data
  String _generateTitle(BeneficiaryModel beneficiary) {
    final categories = beneficiary.vulnerableCategories;
    final buffer = StringBuffer();

    if (categories.contains('pregnant_woman') && beneficiary.isPregnant) {
      buffer.write('Pregnant Woman');
      if (beneficiary.pregnancyTrimester == 3) {
        buffer.write(' (Third Trimester)');
      } else if (beneficiary.pregnancyTrimester == 2) {
        buffer.write(' (Second Trimester)');
      }
    } else if (categories.contains('lactating_mother')) {
      buffer.write('Lactating Mother');
    } else if (categories.contains('child_under_5') ||
        beneficiary.childrenUnder5Count > 0) {
      buffer.write('Child Under 5');
      if (beneficiary.childrenUnder5Count > 1) {
        buffer.write(' (${beneficiary.childrenUnder5Count} children)');
      }
    } else if (categories.contains('elderly')) {
      buffer.write('Elderly Person');
      if (beneficiary.isLivingAlone) {
        buffer.write(' (Living Alone)');
      }
    } else if (categories.contains('disabled')) {
      buffer.write('Person with Disability');
      if (beneficiary.disabilitySeverity == 'severe') {
        buffer.write(' (Severe)');
      }
    } else if (categories.contains('chronically_ill')) {
      buffer.write('Chronically Ill Person');
    } else {
      buffer.write('Vulnerable Beneficiary');
    }

    if (beneficiary.incomeLevel == 'less_than_1000') {
      buffer.write(' - Low Income');
    }

    return buffer.toString();
  }

  /// Generate detailed description from beneficiary data
  String _generateDescription(BeneficiaryModel beneficiary) {
    final buffer = StringBuffer();
    buffer.write('${beneficiary.fullName} is a ');

    if (beneficiary.age != null) {
      buffer.write('${beneficiary.age}-year-old ');
    }
    buffer.write('${beneficiary.gender} from ${beneficiary.region}.');

    // Category details
    final categories = beneficiary.vulnerableCategories;
    if (categories.contains('pregnant_woman') && beneficiary.isPregnant) {
      buffer.write(' Currently pregnant');
      if (beneficiary.pregnancyTrimester != null) {
        buffer.write(' in the ${_getTrimesterName(beneficiary.pregnancyTrimester!)} trimester');
      }
      buffer.write('.');
    }

    if (categories.contains('lactating_mother')) {
      buffer.write(' Currently breastfeeding.');
    }

    if (categories.contains('child_under_5') ||
        beneficiary.childrenUnder5Count > 0) {
      buffer.write(' Has ${beneficiary.childrenUnder5Count} children under 5 years old');
      if (beneficiary.childrenAges.isNotEmpty) {
        final youngest = beneficiary.youngestChildAge;
        buffer.write(', with youngest being $youngest months old');
      }
      buffer.write('.');
    }

    if (categories.contains('elderly')) {
      buffer.write(' Elderly person');
      if (beneficiary.isLivingAlone) {
        buffer.write(' living alone');
      } else if (beneficiary.hasCaregiver) {
        buffer.write(' with caregiver support');
      }
      if (beneficiary.mobilityLevel != null) {
        buffer.write(' (${beneficiary.mobilityLevel} mobility)');
      }
      buffer.write('.');
    }

    if (categories.contains('disabled')) {
      buffer.write(' Person with ${beneficiary.disabilityType ?? 'disability'}');
      if (beneficiary.disabilitySeverity != null) {
        buffer.write(' (${beneficiary.disabilitySeverity} severity)');
      }
      if (beneficiary.needsPersonalAssistance) {
        buffer.write(' requiring personal assistance');
      }
      buffer.write('.');
    }

    if (categories.contains('chronically_ill')) {
      buffer.write(' Diagnosed with ${beneficiary.chronicIllnessType ?? 'chronic illness'}');
      if (beneficiary.needsRegularMedicalCare) {
        buffer.write(' requiring regular medical care');
      }
      buffer.write('.');
    }

    // Family and economic details
    buffer.write(' Household consists of ${beneficiary.totalFamilySize} members');
    if (beneficiary.isFemaleHeadedHousehold) {
      buffer.write(' in a female-headed household');
    }
    buffer.write('.');

    buffer.write(' Income level: ${_getIncomeLabel(beneficiary.incomeLevel)}.');
    if (!beneficiary.currentlyReceivingOtherAid) {
      buffer.write(' Not currently receiving other aid.');
    } else {
      buffer.write(' Currently receiving other aid.');
    }

    return buffer.toString();
  }

  String _getTrimesterName(int trimester) {
    switch (trimester) {
      case 1:
        return 'first';
      case 2:
        return 'second';
      case 3:
        return 'third';
      default:
        return 'unknown';
    }
  }

  String _getIncomeLabel(String incomeLevel) {
    switch (incomeLevel) {
      case 'less_than_1000':
        return 'less than 1,000 ETB per month';
      case '1000-3000':
        return '1,000 to 3,000 ETB per month';
      case '3000-5000':
        return '3,000 to 5,000 ETB per month';
      case 'above_5000':
        return 'above 5,000 ETB per month';
      default:
        return incomeLevel;
    }
  }

  /// Classify priority using AI (Hugging Face) with fallback to rule-based
  Future<PriorityLevel> classifyPriority(BeneficiaryModel beneficiary) async {
    final title = _generateTitle(beneficiary);
    final description = _generateDescription(beneficiary);
    final cacheKey = '$title|$description';

    // Check cache first
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    try {
      // Try AI classification first
      final aiPriority = await _classifyWithAI(title, description);
      if (aiPriority != null) {
        _cache[cacheKey] = aiPriority;
        return aiPriority;
      }
    } catch (e) {
      Logger.warning(
        'AI classification failed, using rule-based fallback: $e',
        tag: 'PriorityClassificationService',
      );
    }

    // Fallback to rule-based classification
    final ruleBasedPriority = _classifyWithRules(beneficiary);
    _cache[cacheKey] = ruleBasedPriority;
    return ruleBasedPriority;
  }

  /// Classify using Hugging Face zero-shot classification
  Future<PriorityLevel?> _classifyWithAI(
    String title,
    String description,
  ) async {
    final inputText = '$title. $description';
    final candidateLabels = ['high priority', 'medium priority', 'low priority'];

    try {
      // Try primary model
      final result = await _callHuggingFaceAPI(
        _huggingFaceApiUrl,
        inputText,
        candidateLabels,
      );

      if (result != null) {
        return _parseAIPriority(result);
      }

      // Try backup model
      final backupResult = await _callHuggingFaceAPI(
        _backupApiUrl,
        inputText,
        candidateLabels,
      );

      if (backupResult != null) {
        return _parseAIPriority(backupResult);
      }
    } catch (e) {
      Logger.error(
        'Error calling Hugging Face API',
        error: e,
        tag: 'PriorityClassificationService',
      );
    }

    return null;
  }

  /// Call Hugging Face Inference API
  Future<Map<String, dynamic>?> _callHuggingFaceAPI(
    String apiUrl,
    String inputText,
    List<String> candidateLabels,
  ) async {
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'inputs': inputText,
          'parameters': {
            'candidate_labels': candidateLabels,
          },
        }),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('API request timeout');
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data;
      } else if (response.statusCode == 503) {
        // Model is loading, wait and retry once
        await Future.delayed(const Duration(seconds: 5));
        final retryResponse = await http.post(
          Uri.parse(apiUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'inputs': inputText,
            'parameters': {'candidate_labels': candidateLabels},
          }),
        ).timeout(const Duration(seconds: 10));

        if (retryResponse.statusCode == 200) {
          return jsonDecode(retryResponse.body) as Map<String, dynamic>;
        }
      }

      Logger.warning(
        'Hugging Face API returned status ${response.statusCode}',
        tag: 'PriorityClassificationService',
      );
      return null;
    } catch (e) {
      Logger.error(
        'Error calling Hugging Face API',
        error: e,
        tag: 'PriorityClassificationService',
      );
      return null;
    }
  }

  /// Parse AI response to PriorityLevel
  PriorityLevel? _parseAIPriority(Map<String, dynamic> response) {
    try {
      // Response format: {"sequence": "...", "labels": [...], "scores": [...]}
      final labels = response['labels'] as List<dynamic>?;
      final scores = response['scores'] as List<dynamic>?;

      if (labels == null || scores == null || labels.isEmpty) {
        return null;
      }

      // Find highest score
      double maxScore = 0.0;
      int maxIndex = 0;
      for (int i = 0; i < scores.length; i++) {
        final score = (scores[i] as num).toDouble();
        if (score > maxScore) {
          maxScore = score;
          maxIndex = i;
        }
      }

      final label = labels[maxIndex].toString().toLowerCase();
      if (label.contains('high')) {
        return PriorityLevel.high;
      } else if (label.contains('low')) {
        return PriorityLevel.low;
      } else {
        return PriorityLevel.medium;
      }
    } catch (e) {
      Logger.error(
        'Error parsing AI response',
        error: e,
        tag: 'PriorityClassificationService',
      );
      return null;
    }
  }

  /// Rule-based classification fallback
  PriorityLevel _classifyWithRules(BeneficiaryModel beneficiary) {
    double score = beneficiary.urgencyScore;

    // Convert urgency score to priority
    if (score >= 0.7) {
      return PriorityLevel.high;
    } else if (score >= 0.4) {
      return PriorityLevel.medium;
    } else {
      return PriorityLevel.low;
    }
  }

  /// Clear cache
  void clearCache() {
    _cache.clear();
  }
}


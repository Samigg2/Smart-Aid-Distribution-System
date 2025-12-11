import 'package:cloud_firestore/cloud_firestore.dart';

/// Vulnerable group categories - a beneficiary can belong to multiple
enum VulnerableCategory {
  pregnantWoman('pregnant_woman', 'Pregnant Woman'),
  lactatingMother('lactating_mother', 'Lactating Mother'),
  childUnder5('child_under_5', 'Child Under 5'),
  elderly('elderly', 'Elderly (60+)'),
  disabled('disabled', 'Person with Disability'),
  chronicallyIll('chronically_ill', 'Chronically Ill');

  final String value;
  final String label;
  const VulnerableCategory(this.value, this.label);

  static VulnerableCategory fromValue(String value) {
    return VulnerableCategory.values.firstWhere(
      (e) => e.value == value,
      orElse: () => VulnerableCategory.pregnantWoman,
    );
  }
}

/// Income level enum
enum IncomeLevel {
  lessThan1000('less_than_1000', 'Less than 1,000 ETB'),
  between1000_3000('1000-3000', '1,000 - 3,000 ETB'),
  between3000_5000('3000-5000', '3,000 - 5,000 ETB'),
  above5000('above_5000', 'Above 5,000 ETB');

  final String value;
  final String label;
  const IncomeLevel(this.value, this.label);

  static IncomeLevel fromValue(String value) {
    return IncomeLevel.values.firstWhere(
      (e) => e.value == value,
      orElse: () => IncomeLevel.lessThan1000,
    );
  }
}

/// Mobility level for elderly
enum MobilityLevel {
  canWalk('can_walk', 'Can Walk Independently'),
  usesAid('uses_aid', 'Uses Walking Aid'),
  bedridden('bedridden', 'Bedridden');

  final String value;
  final String label;
  const MobilityLevel(this.value, this.label);

  static MobilityLevel fromValue(String value) {
    return MobilityLevel.values.firstWhere(
      (e) => e.value == value,
      orElse: () => MobilityLevel.canWalk,
    );
  }
}

/// Disability type
enum DisabilityType {
  physical('physical', 'Physical'),
  visual('visual', 'Visual'),
  hearing('hearing', 'Hearing'),
  intellectual('intellectual', 'Intellectual'),
  multiple('multiple', 'Multiple Disabilities');

  final String value;
  final String label;
  const DisabilityType(this.value, this.label);

  static DisabilityType fromValue(String value) {
    return DisabilityType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => DisabilityType.physical,
    );
  }
}

/// Disability severity
enum DisabilitySeverity {
  mild('mild', 'Mild'),
  moderate('moderate', 'Moderate'),
  severe('severe', 'Severe');

  final String value;
  final String label;
  const DisabilitySeverity(this.value, this.label);

  static DisabilitySeverity fromValue(String value) {
    return DisabilitySeverity.values.firstWhere(
      (e) => e.value == value,
      orElse: () => DisabilitySeverity.moderate,
    );
  }
}

/// Chronic illness type
enum ChronicIllnessType {
  hivAids('hiv_aids', 'HIV/AIDS'),
  tuberculosis('tuberculosis', 'Tuberculosis'),
  diabetes('diabetes', 'Diabetes'),
  heartDisease('heart_disease', 'Heart Disease'),
  cancer('cancer', 'Cancer'),
  kidneyDisease('kidney_disease', 'Kidney Disease'),
  other('other', 'Other Chronic Illness');

  final String value;
  final String label;
  const ChronicIllnessType(this.value, this.label);

  static ChronicIllnessType fromValue(String value) {
    return ChronicIllnessType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ChronicIllnessType.other,
    );
  }
}

class BeneficiaryModel {
  final String beneficiaryId;
  final String fullName;
  final String nationalId;
  final String? phoneNumber;
  final int? age;
  final String gender;

  // Multi-select vulnerable categories
  final List<String> vulnerableCategories;

  // Mother & Child specific fields (kept for compatibility)
  final String? beneficiaryType; // Legacy field
  final bool isPregnant;
  final int? pregnancyTrimester;
  final int childrenUnder5Count;
  final List<int> childrenAges;

  // Elderly specific fields (60+)
  final bool isLivingAlone;
  final bool hasCaregiver;
  final String? mobilityLevel;

  // Disability specific fields
  final String? disabilityType;
  final String? disabilitySeverity;
  final bool usesAssistiveDevice;
  final bool needsPersonalAssistance;

  // Chronic illness specific fields
  final String? chronicIllnessType;
  final bool isOnMedication;
  final bool needsRegularMedicalCare;

  // Family & Vulnerability
  final int totalFamilySize;
  final bool isFemaleHeadedHousehold;
  final String incomeLevel;
  final bool currentlyReceivingOtherAid;

  // Location
  final String region;
  final String? zone;
  final String? woreda;
  final double? latitude;
  final double? longitude;

  // Photo (OPTIONAL now)
  final String? photoUrl;

  // Metadata
  final String registeredBy;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final double urgencyScore;

  BeneficiaryModel({
    required this.beneficiaryId,
    required this.fullName,
    required this.nationalId,
    this.phoneNumber,
    this.age,
    required this.gender,
    required this.vulnerableCategories,
    this.beneficiaryType,
    required this.isPregnant,
    this.pregnancyTrimester,
    required this.childrenUnder5Count,
    required this.childrenAges,
    this.isLivingAlone = false,
    this.hasCaregiver = false,
    this.mobilityLevel,
    this.disabilityType,
    this.disabilitySeverity,
    this.usesAssistiveDevice = false,
    this.needsPersonalAssistance = false,
    this.chronicIllnessType,
    this.isOnMedication = false,
    this.needsRegularMedicalCare = false,
    required this.totalFamilySize,
    required this.isFemaleHeadedHousehold,
    required this.incomeLevel,
    required this.currentlyReceivingOtherAid,
    required this.region,
    this.zone,
    this.woreda,
    this.latitude,
    this.longitude,
    this.photoUrl,
    required this.registeredBy,
    required this.createdAt,
    this.updatedAt,
    required this.urgencyScore,
  });

  // Calculate youngest child age in months
  int get youngestChildAge {
    if (childrenAges.isEmpty) return 0;
    return childrenAges.reduce((a, b) => a < b ? a : b);
  }

  // Check if belongs to a category
  bool hasCategory(VulnerableCategory category) {
    return vulnerableCategories.contains(category.value);
  }

  // Get categories as enum list
  List<VulnerableCategory> get categoriesAsEnum {
    return vulnerableCategories
        .map((v) => VulnerableCategory.fromValue(v))
        .toList();
  }

  // Factory constructor from Firestore
  factory BeneficiaryModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // Handle legacy beneficiaryType field
    List<String> categories = [];
    if (data['vulnerableCategories'] != null) {
      categories = List<String>.from(data['vulnerableCategories']);
    } else if (data['beneficiaryType'] != null) {
      // Convert legacy field to new format
      categories = [data['beneficiaryType']];
    }

    return BeneficiaryModel(
      beneficiaryId: doc.id,
      fullName: data['fullName'] ?? '',
      nationalId: data['nationalId'] ?? '',
      phoneNumber: data['phoneNumber'],
      age: data['age'],
      gender: data['gender'] ?? 'female',
      vulnerableCategories: categories,
      beneficiaryType: data['beneficiaryType'],
      isPregnant: data['isPregnant'] ?? false,
      pregnancyTrimester: data['pregnancyTrimester'],
      childrenUnder5Count: data['childrenUnder5Count'] ?? 0,
      childrenAges: List<int>.from(data['childrenAges'] ?? []),
      isLivingAlone: data['isLivingAlone'] ?? false,
      hasCaregiver: data['hasCaregiver'] ?? false,
      mobilityLevel: data['mobilityLevel'],
      disabilityType: data['disabilityType'],
      disabilitySeverity: data['disabilitySeverity'],
      usesAssistiveDevice: data['usesAssistiveDevice'] ?? false,
      needsPersonalAssistance: data['needsPersonalAssistance'] ?? false,
      chronicIllnessType: data['chronicIllnessType'],
      isOnMedication: data['isOnMedication'] ?? false,
      needsRegularMedicalCare: data['needsRegularMedicalCare'] ?? false,
      totalFamilySize: data['totalFamilySize'] ?? 1,
      isFemaleHeadedHousehold: data['isFemaleHeadedHousehold'] ?? false,
      incomeLevel: data['incomeLevel'] ?? 'less_than_1000',
      currentlyReceivingOtherAid: data['currentlyReceivingOtherAid'] ?? false,
      region: data['region'] ?? '',
      zone: data['zone'],
      woreda: data['woreda'],
      latitude: data['latitude']?.toDouble(),
      longitude: data['longitude']?.toDouble(),
      photoUrl: data['photoUrl'],
      registeredBy: data['registeredBy'] ?? '',
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      urgencyScore: (data['urgencyScore'] ?? 0.0).toDouble(),
    );
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'nationalId': nationalId,
      'phoneNumber': phoneNumber,
      'age': age,
      'gender': gender,
      'vulnerableCategories': vulnerableCategories,
      'beneficiaryType': beneficiaryType,
      'isPregnant': isPregnant,
      'pregnancyTrimester': pregnancyTrimester,
      'childrenUnder5Count': childrenUnder5Count,
      'childrenAges': childrenAges,
      'isLivingAlone': isLivingAlone,
      'hasCaregiver': hasCaregiver,
      'mobilityLevel': mobilityLevel,
      'disabilityType': disabilityType,
      'disabilitySeverity': disabilitySeverity,
      'usesAssistiveDevice': usesAssistiveDevice,
      'needsPersonalAssistance': needsPersonalAssistance,
      'chronicIllnessType': chronicIllnessType,
      'isOnMedication': isOnMedication,
      'needsRegularMedicalCare': needsRegularMedicalCare,
      'totalFamilySize': totalFamilySize,
      'isFemaleHeadedHousehold': isFemaleHeadedHousehold,
      'incomeLevel': incomeLevel,
      'currentlyReceivingOtherAid': currentlyReceivingOtherAid,
      'region': region,
      'zone': zone,
      'woreda': woreda,
      'latitude': latitude,
      'longitude': longitude,
      'photoUrl': photoUrl,
      'registeredBy': registeredBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'urgencyScore': urgencyScore,
    };
  }

  /// Calculate urgency score based on ALL vulnerability factors
  static double calculateUrgencyScore({
    required List<String> vulnerableCategories,
    required bool isPregnant,
    int? pregnancyTrimester,
    required int childrenUnder5Count,
    required List<int> childrenAges,
    required bool isFemaleHeadedHousehold,
    required String incomeLevel,
    required bool currentlyReceivingOtherAid,
    // Elderly
    bool isLivingAlone = false,
    String? mobilityLevel,
    // Disabled
    String? disabilitySeverity,
    bool needsPersonalAssistance = false,
    // Chronically ill
    bool needsRegularMedicalCare = false,
  }) {
    double score = 0.0;

    // === CATEGORY-BASED SCORING ===

    // Pregnant Woman: +0.25, +0.1 for 3rd trimester
    if (vulnerableCategories.contains('pregnant_woman') || isPregnant) {
      score += 0.25;
      if (pregnancyTrimester == 3) score += 0.1;
      if (pregnancyTrimester == 2) score += 0.05;
    }

    // Lactating Mother: +0.15
    if (vulnerableCategories.contains('lactating_mother')) {
      score += 0.15;
    }

    // Child Under 5: +0.20, +0.1 if under 12 months
    if (vulnerableCategories.contains('child_under_5') ||
        childrenUnder5Count > 0) {
      score += 0.20;
      if (childrenAges.any((age) => age < 12)) {
        score += 0.1; // Very young child
      }
      // More children = higher urgency
      score += (childrenUnder5Count * 0.05).clamp(0.0, 0.15);
    }

    // Elderly (60+): +0.20, +0.1 if living alone, +0.1 if bedridden
    if (vulnerableCategories.contains('elderly')) {
      score += 0.20;
      if (isLivingAlone) score += 0.1;
      if (mobilityLevel == 'bedridden') score += 0.1;
      if (mobilityLevel == 'uses_aid') score += 0.05;
    }

    // Disabled: +0.20, +0.15 if severe, +0.1 if needs assistance
    if (vulnerableCategories.contains('disabled')) {
      score += 0.20;
      if (disabilitySeverity == 'severe') score += 0.15;
      if (disabilitySeverity == 'moderate') score += 0.08;
      if (needsPersonalAssistance) score += 0.1;
    }

    // Chronically Ill: +0.15, +0.1 if needs regular medical care
    if (vulnerableCategories.contains('chronically_ill')) {
      score += 0.15;
      if (needsRegularMedicalCare) score += 0.1;
    }

    // === ADDITIONAL FACTORS ===

    // Female-headed household: +0.15
    if (isFemaleHeadedHousehold) {
      score += 0.15;
    }

    // Income level
    switch (incomeLevel) {
      case 'less_than_1000':
        score += 0.20;
        break;
      case '1000-3000':
        score += 0.10;
        break;
      case '3000-5000':
        score += 0.05;
        break;
    }

    // Not receiving other aid = higher urgency
    if (!currentlyReceivingOtherAid) {
      score += 0.1;
    }

    return score.clamp(0.0, 1.0);
  }

  // Create copy with updated fields
  BeneficiaryModel copyWith({
    String? beneficiaryId,
    String? fullName,
    String? nationalId,
    String? phoneNumber,
    int? age,
    String? gender,
    List<String>? vulnerableCategories,
    String? beneficiaryType,
    bool? isPregnant,
    int? pregnancyTrimester,
    int? childrenUnder5Count,
    List<int>? childrenAges,
    bool? isLivingAlone,
    bool? hasCaregiver,
    String? mobilityLevel,
    String? disabilityType,
    String? disabilitySeverity,
    bool? usesAssistiveDevice,
    bool? needsPersonalAssistance,
    String? chronicIllnessType,
    bool? isOnMedication,
    bool? needsRegularMedicalCare,
    int? totalFamilySize,
    bool? isFemaleHeadedHousehold,
    String? incomeLevel,
    bool? currentlyReceivingOtherAid,
    String? region,
    String? zone,
    String? woreda,
    double? latitude,
    double? longitude,
    String? photoUrl,
    String? registeredBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? urgencyScore,
  }) {
    return BeneficiaryModel(
      beneficiaryId: beneficiaryId ?? this.beneficiaryId,
      fullName: fullName ?? this.fullName,
      nationalId: nationalId ?? this.nationalId,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      vulnerableCategories: vulnerableCategories ?? this.vulnerableCategories,
      beneficiaryType: beneficiaryType ?? this.beneficiaryType,
      isPregnant: isPregnant ?? this.isPregnant,
      pregnancyTrimester: pregnancyTrimester ?? this.pregnancyTrimester,
      childrenUnder5Count: childrenUnder5Count ?? this.childrenUnder5Count,
      childrenAges: childrenAges ?? this.childrenAges,
      isLivingAlone: isLivingAlone ?? this.isLivingAlone,
      hasCaregiver: hasCaregiver ?? this.hasCaregiver,
      mobilityLevel: mobilityLevel ?? this.mobilityLevel,
      disabilityType: disabilityType ?? this.disabilityType,
      disabilitySeverity: disabilitySeverity ?? this.disabilitySeverity,
      usesAssistiveDevice: usesAssistiveDevice ?? this.usesAssistiveDevice,
      needsPersonalAssistance:
          needsPersonalAssistance ?? this.needsPersonalAssistance,
      chronicIllnessType: chronicIllnessType ?? this.chronicIllnessType,
      isOnMedication: isOnMedication ?? this.isOnMedication,
      needsRegularMedicalCare:
          needsRegularMedicalCare ?? this.needsRegularMedicalCare,
      totalFamilySize: totalFamilySize ?? this.totalFamilySize,
      isFemaleHeadedHousehold:
          isFemaleHeadedHousehold ?? this.isFemaleHeadedHousehold,
      incomeLevel: incomeLevel ?? this.incomeLevel,
      currentlyReceivingOtherAid:
          currentlyReceivingOtherAid ?? this.currentlyReceivingOtherAid,
      region: region ?? this.region,
      zone: zone ?? this.zone,
      woreda: woreda ?? this.woreda,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      photoUrl: photoUrl ?? this.photoUrl,
      registeredBy: registeredBy ?? this.registeredBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      urgencyScore: urgencyScore ?? this.urgencyScore,
    );
  }
}

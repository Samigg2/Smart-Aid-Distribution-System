import 'package:cloud_firestore/cloud_firestore.dart';

enum BeneficiaryType {
  pregnantWoman('pregnant_woman', 'Pregnant Woman'),
  lactatingMother('lactating_mother', 'Lactating Mother'),
  singleMother('single_mother', 'Single Mother'),
  childOnly('child_only', 'Child Only');

  final String value;
  final String label;
  const BeneficiaryType(this.value, this.label);
}

enum IncomeLevel {
  lessThan1000('less_than_1000', 'Less than 1,000 ETB'),
  between1000_3000('1000-3000', '1,000 - 3,000 ETB'),
  between3000_5000('3000-5000', '3,000 - 5,000 ETB'),
  above5000('above_5000', 'Above 5,000 ETB');

  final String value;
  final String label;
  const IncomeLevel(this.value, this.label);
}

class BeneficiaryModel {
  final String beneficiaryId;
  final String fullName;
  final String nationalId; // TEXT ONLY, no photo
  final String? phoneNumber;
  final int? age;
  final String gender; // Usually "female" for mothers
  final String beneficiaryType;
  final bool isPregnant;
  final int? pregnancyTrimester; // 1, 2, or 3
  final int childrenUnder5Count;
  final List<int> childrenAges; // in months
  final int totalFamilySize;
  final bool isFemaleHeadedHousehold;
  final String incomeLevel;
  final bool currentlyReceivingOtherAid;
  final String region;
  final String? zone;
  final String? woreda;
  final double? latitude;
  final double? longitude;
  final String photoUrl; // Cloudinary URL
  final String registeredBy; // Staff UID
  final DateTime createdAt;
  final DateTime? updatedAt;
  final double urgencyScore; // Calculated based on vulnerability

  BeneficiaryModel({
    required this.beneficiaryId,
    required this.fullName,
    required this.nationalId,
    this.phoneNumber,
    this.age,
    required this.gender,
    required this.beneficiaryType,
    required this.isPregnant,
    this.pregnancyTrimester,
    required this.childrenUnder5Count,
    required this.childrenAges,
    required this.totalFamilySize,
    required this.isFemaleHeadedHousehold,
    required this.incomeLevel,
    required this.currentlyReceivingOtherAid,
    required this.region,
    this.zone,
    this.woreda,
    this.latitude,
    this.longitude,
    required this.photoUrl,
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

  // Factory constructor from Firestore
  factory BeneficiaryModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return BeneficiaryModel(
      beneficiaryId: doc.id,
      fullName: data['fullName'] ?? '',
      nationalId: data['nationalId'] ?? '',
      phoneNumber: data['phoneNumber'],
      age: data['age'],
      gender: data['gender'] ?? 'female',
      beneficiaryType: data['beneficiaryType'] ?? '',
      isPregnant: data['isPregnant'] ?? false,
      pregnancyTrimester: data['pregnancyTrimester'],
      childrenUnder5Count: data['childrenUnder5Count'] ?? 0,
      childrenAges: List<int>.from(data['childrenAges'] ?? []),
      totalFamilySize: data['totalFamilySize'] ?? 1,
      isFemaleHeadedHousehold: data['isFemaleHeadedHousehold'] ?? false,
      incomeLevel: data['incomeLevel'] ?? '',
      currentlyReceivingOtherAid: data['currentlyReceivingOtherAid'] ?? false,
      region: data['region'] ?? '',
      zone: data['zone'],
      woreda: data['woreda'],
      latitude: data['latitude']?.toDouble(),
      longitude: data['longitude']?.toDouble(),
      photoUrl: data['photoUrl'] ?? '',
      registeredBy: data['registeredBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
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
      'beneficiaryType': beneficiaryType,
      'isPregnant': isPregnant,
      'pregnancyTrimester': pregnancyTrimester,
      'childrenUnder5Count': childrenUnder5Count,
      'childrenAges': childrenAges,
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

  // Calculate urgency score based on vulnerability factors
  static double calculateUrgencyScore({
    required bool isPregnant,
    int? pregnancyTrimester,
    required int childrenUnder5Count,
    required List<int> childrenAges,
    required bool isFemaleHeadedHousehold,
    required String incomeLevel,
    required bool currentlyReceivingOtherAid,
  }) {
    double score = 0.0;

    // Pregnancy adds urgency
    if (isPregnant) {
      score += 0.3;
      // Later trimesters are more urgent
      if (pregnancyTrimester == 3) score += 0.2;
      if (pregnancyTrimester == 2) score += 0.1;
    }

    // More children under 5 = higher urgency
    score += (childrenUnder5Count * 0.1).clamp(0.0, 0.3);

    // Very young children (under 12 months) add urgency
    if (childrenAges.any((age) => age < 12)) {
      score += 0.2;
    }

    // Female-headed household adds vulnerability
    if (isFemaleHeadedHousehold) {
      score += 0.15;
    }

    // Lower income = higher urgency
    switch (incomeLevel) {
      case 'less_than_1000':
        score += 0.2;
        break;
      case '1000-3000':
        score += 0.1;
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
    String? beneficiaryType,
    bool? isPregnant,
    int? pregnancyTrimester,
    int? childrenUnder5Count,
    List<int>? childrenAges,
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
      beneficiaryType: beneficiaryType ?? this.beneficiaryType,
      isPregnant: isPregnant ?? this.isPregnant,
      pregnancyTrimester: pregnancyTrimester ?? this.pregnancyTrimester,
      childrenUnder5Count: childrenUnder5Count ?? this.childrenUnder5Count,
      childrenAges: childrenAges ?? this.childrenAges,
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



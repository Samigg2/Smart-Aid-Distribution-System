import 'package:cloud_firestore/cloud_firestore.dart';

/// Type of aid being distributed
enum AidType {
  food('food', 'Food Package'),
  medicine('medicine', 'Medicine/Medical Supplies'),
  cash('cash', 'Cash Transfer'),
  clothing('clothing', 'Clothing'),
  shelter('shelter', 'Shelter Materials'),
  water('water', 'Water/Hygiene Kit'),
  nutrition('nutrition', 'Nutritional Supplements'),
  education('education', 'Education Materials'),
  other('other', 'Other');

  final String value;
  final String label;
  const AidType(this.value, this.label);

  static AidType fromValue(String value) {
    return AidType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => AidType.other,
    );
  }
}

/// Program status
enum ProgramStatus {
  draft('draft', 'Draft'),
  active('active', 'Active'),
  paused('paused', 'Paused'),
  completed('completed', 'Completed'),
  cancelled('cancelled', 'Cancelled');

  final String value;
  final String label;
  const ProgramStatus(this.value, this.label);

  static ProgramStatus fromValue(String value) {
    return ProgramStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ProgramStatus.draft,
    );
  }
}

/// Distribution Program - defines what aid to give to which categories
class DistributionProgram {
  final String programId;
  final String programName;
  final String? description;
  final String aidType;
  final List<String> targetCategories; // Which vulnerable categories to target
  final double quantityPerBeneficiary;
  final String unit; // e.g., "kg", "ETB", "pcs"
  final double? totalBudget;
  final int? maxBeneficiaries;
  final DateTime startDate;
  final DateTime? endDate;
  final String status;
  final String? region; // Optional: limit to specific region
  final String createdBy;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Computed fields (not stored in Firestore)
  final int distributedCount;
  final double distributedQuantity;

  DistributionProgram({
    required this.programId,
    required this.programName,
    this.description,
    required this.aidType,
    required this.targetCategories,
    required this.quantityPerBeneficiary,
    required this.unit,
    this.totalBudget,
    this.maxBeneficiaries,
    required this.startDate,
    this.endDate,
    required this.status,
    this.region,
    required this.createdBy,
    required this.createdAt,
    this.updatedAt,
    this.distributedCount = 0,
    this.distributedQuantity = 0,
  });

  bool get isActive => status == 'active';

  factory DistributionProgram.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return DistributionProgram(
      programId: doc.id,
      programName: data['programName'] ?? '',
      description: data['description'],
      aidType: data['aidType'] ?? 'other',
      targetCategories: List<String>.from(data['targetCategories'] ?? []),
      quantityPerBeneficiary: (data['quantityPerBeneficiary'] ?? 0).toDouble(),
      unit: data['unit'] ?? 'pcs',
      totalBudget: data['totalBudget']?.toDouble(),
      maxBeneficiaries: data['maxBeneficiaries'],
      startDate: data['startDate'] != null
          ? (data['startDate'] as Timestamp).toDate()
          : DateTime.now(),
      endDate: data['endDate'] != null
          ? (data['endDate'] as Timestamp).toDate()
          : null,
      status: data['status'] ?? 'draft',
      region: data['region'],
      createdBy: data['createdBy'] ?? '',
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      distributedCount: data['distributedCount'] ?? 0,
      distributedQuantity: (data['distributedQuantity'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'programName': programName,
      'description': description,
      'aidType': aidType,
      'targetCategories': targetCategories,
      'quantityPerBeneficiary': quantityPerBeneficiary,
      'unit': unit,
      'totalBudget': totalBudget,
      'maxBeneficiaries': maxBeneficiaries,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'status': status,
      'region': region,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'distributedCount': distributedCount,
      'distributedQuantity': distributedQuantity,
    };
  }

  DistributionProgram copyWith({
    String? programId,
    String? programName,
    String? description,
    String? aidType,
    List<String>? targetCategories,
    double? quantityPerBeneficiary,
    String? unit,
    double? totalBudget,
    int? maxBeneficiaries,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
    String? region,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? distributedCount,
    double? distributedQuantity,
  }) {
    return DistributionProgram(
      programId: programId ?? this.programId,
      programName: programName ?? this.programName,
      description: description ?? this.description,
      aidType: aidType ?? this.aidType,
      targetCategories: targetCategories ?? this.targetCategories,
      quantityPerBeneficiary: quantityPerBeneficiary ?? this.quantityPerBeneficiary,
      unit: unit ?? this.unit,
      totalBudget: totalBudget ?? this.totalBudget,
      maxBeneficiaries: maxBeneficiaries ?? this.maxBeneficiaries,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      region: region ?? this.region,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      distributedCount: distributedCount ?? this.distributedCount,
      distributedQuantity: distributedQuantity ?? this.distributedQuantity,
    );
  }
}

/// Distribution Record - tracks individual aid given to beneficiary
class DistributionRecord {
  final String recordId;
  final String programId;
  final String programName; // Denormalized for easy display
  final String beneficiaryId;
  final String beneficiaryName; // Denormalized
  final String beneficiaryNationalId; // Denormalized
  final String aidType;
  final double quantity;
  final String unit;
  final String distributedBy; // Staff UID
  final String? distributedByName; // Denormalized
  final DateTime distributedAt;
  final double? latitude;
  final double? longitude;
  final String? notes;
  final String? signature; // Base64 or URL if signature capture implemented

  DistributionRecord({
    required this.recordId,
    required this.programId,
    required this.programName,
    required this.beneficiaryId,
    required this.beneficiaryName,
    required this.beneficiaryNationalId,
    required this.aidType,
    required this.quantity,
    required this.unit,
    required this.distributedBy,
    this.distributedByName,
    required this.distributedAt,
    this.latitude,
    this.longitude,
    this.notes,
    this.signature,
  });

  factory DistributionRecord.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return DistributionRecord(
      recordId: doc.id,
      programId: data['programId'] ?? '',
      programName: data['programName'] ?? '',
      beneficiaryId: data['beneficiaryId'] ?? '',
      beneficiaryName: data['beneficiaryName'] ?? '',
      beneficiaryNationalId: data['beneficiaryNationalId'] ?? '',
      aidType: data['aidType'] ?? '',
      quantity: (data['quantity'] ?? 0).toDouble(),
      unit: data['unit'] ?? '',
      distributedBy: data['distributedBy'] ?? '',
      distributedByName: data['distributedByName'],
      distributedAt: data['distributedAt'] != null
          ? (data['distributedAt'] as Timestamp).toDate()
          : DateTime.now(),
      latitude: data['latitude']?.toDouble(),
      longitude: data['longitude']?.toDouble(),
      notes: data['notes'],
      signature: data['signature'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'programId': programId,
      'programName': programName,
      'beneficiaryId': beneficiaryId,
      'beneficiaryName': beneficiaryName,
      'beneficiaryNationalId': beneficiaryNationalId,
      'aidType': aidType,
      'quantity': quantity,
      'unit': unit,
      'distributedBy': distributedBy,
      'distributedByName': distributedByName,
      'distributedAt': Timestamp.fromDate(distributedAt),
      'latitude': latitude,
      'longitude': longitude,
      'notes': notes,
      'signature': signature,
    };
  }
}


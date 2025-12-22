import 'dart:io';
import '../utils/beneficiary_validator.dart';

/// Shared data model for multi-step beneficiary registration
class BeneficiaryRegistrationData {
  // Step 1: Personal Information
  String? fullName;
  String? nationalId;
  String? phoneNumber;
  int? age;
  String gender = 'female';

  // Step 1: Vulnerable Categories
  final Set<String> selectedCategories = {};

  // Step 2: Category-specific fields
  // Pregnant Woman
  bool isPregnant = false;
  int? pregnancyTrimester;

  // Child Under 5
  int childrenUnder5Count = 0;
  final List<int> childrenAges = [];

  // Elderly
  bool isLivingAlone = false;
  bool hasCaregiver = false;
  String mobilityLevel = 'can_walk';

  // Disabled
  String disabilityType = 'physical';
  String disabilitySeverity = 'moderate';
  bool usesAssistiveDevice = false;
  bool needsPersonalAssistance = false;

  // Chronically Ill
  String chronicIllnessType = 'other';
  bool isOnMedication = false;
  bool needsRegularMedicalCare = false;

  // Step 3: Family & Vulnerability
  int totalFamilySize = 1;
  bool isFemaleHeadedHousehold = false;
  String incomeLevel = 'less_than_1000';
  bool currentlyReceivingOtherAid = false;

  // Step 3: Location
  String region = 'Addis Ababa';
  String? zone;
  String? woreda;
  double? latitude;
  double? longitude;

  // Step 3: Photo
  File? photoFile;
  String? photoUrl;

  /// Validate Step 1 data
  List<String> validateStep1() {
    final errors = <String>[];
    if (fullName == null || fullName!.trim().isEmpty) {
      errors.add('Full name is required');
    }
    final nationalIdError = BeneficiaryValidator.validateNationalId(nationalId);
    if (nationalIdError != null) {
      errors.add(nationalIdError);
    }
    final phoneError = BeneficiaryValidator.validateEthiopianPhone(
      phoneNumber,
      isRequired: true,
    );
    if (phoneError != null) {
      errors.add(phoneError);
    }
    if (selectedCategories.isEmpty) {
      errors.add('Please select at least one vulnerable category');
    }
    return errors;
  }

  /// Validate Step 2 data (category-specific)
  List<String> validateStep2() {
    final errors = <String>[];
    if (selectedCategories.contains('pregnant_woman') &&
        pregnancyTrimester == null) {
      errors.add('Pregnancy trimester is required');
    }
    if (selectedCategories.contains('elderly') && mobilityLevel.isEmpty) {
      errors.add('Mobility level is required for elderly');
    }
    if (selectedCategories.contains('disabled') && disabilityType.isEmpty) {
      errors.add('Disability type is required');
    }
    if (selectedCategories.contains('chronically_ill') &&
        chronicIllnessType.isEmpty) {
      errors.add('Chronic illness type is required');
    }
    return errors;
  }

  /// Validate Step 3 data
  List<String> validateStep3() {
    final errors = <String>[];
    if (totalFamilySize < 1) {
      errors.add('Family size must be at least 1');
    }
    if (region.isEmpty) {
      errors.add('Region is required');
    }
    return errors;
  }

  /// Check if all steps are valid
  bool isComplete() {
    return validateStep1().isEmpty &&
        validateStep2().isEmpty &&
        validateStep3().isEmpty;
  }
}

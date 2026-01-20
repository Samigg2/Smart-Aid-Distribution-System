import 'package:flutter_test/flutter_test.dart';
import 'package:firs_app/utils/beneficiary_validator.dart';

void main() {
  group('BeneficiaryValidator', () {
    group('validateNationalId', () {
      test('returns null for valid 12-digit national ID', () {
        expect(BeneficiaryValidator.validateNationalId('123456789012'), isNull);
      });

      test('returns error for null national ID', () {
        expect(
          BeneficiaryValidator.validateNationalId(null),
          equals('National ID is required'),
        );
      });

      test('returns error for empty national ID', () {
        expect(
          BeneficiaryValidator.validateNationalId(''),
          equals('National ID is required'),
        );
      });

      test('returns error for whitespace-only national ID', () {
        expect(
          BeneficiaryValidator.validateNationalId('   '),
          equals('National ID is required'),
        );
      });

      test('returns error for non-numeric national ID', () {
        expect(
          BeneficiaryValidator.validateNationalId('abcdefghijkl'),
          equals('National ID must be exactly 12 digits'),
        );
      });

      test('returns error for national ID with less than 12 digits', () {
        expect(
          BeneficiaryValidator.validateNationalId('12345678901'),
          equals('National ID must be exactly 12 digits'),
        );
      });

      test('returns error for national ID with more than 12 digits', () {
        expect(
          BeneficiaryValidator.validateNationalId('1234567890123'),
          equals('National ID must be exactly 12 digits'),
        );
      });
    });

    group('validateEthiopianPhone', () {
      test('returns null for valid phone starting with 09', () {
        expect(
          BeneficiaryValidator.validateEthiopianPhone('0988277799'),
          isNull,
        );
      });

      test('returns null for valid phone starting with 9', () {
        expect(
          BeneficiaryValidator.validateEthiopianPhone('988277799'),
          isNull,
        );
      });

      test('returns null for null phone when not required', () {
        expect(
          BeneficiaryValidator.validateEthiopianPhone(null, isRequired: false),
          isNull,
        );
      });

      test('returns error for null phone when required', () {
        expect(
          BeneficiaryValidator.validateEthiopianPhone(null, isRequired: true),
          equals('Phone number is required'),
        );
      });

      test('returns error for invalid phone format', () {
        expect(
          BeneficiaryValidator.validateEthiopianPhone('123456789'),
          equals('Phone must match Ethiopian format (e.g., 0988277799 or 988277799)'),
        );
      });

      test('trims whitespace before validation', () {
        expect(
          BeneficiaryValidator.validateEthiopianPhone('  0988277799  '),
          isNull,
        );
      });
    });

    group('areCategoriesConflicting', () {
      test('returns true for pregnant_woman and elderly', () {
        expect(
          BeneficiaryValidator.areCategoriesConflicting(
            'pregnant_woman',
            'elderly',
          ),
          isTrue,
        );
      });

      test('returns true for lactating_mother and elderly', () {
        expect(
          BeneficiaryValidator.areCategoriesConflicting(
            'lactating_mother',
            'elderly',
          ),
          isTrue,
        );
      });

      test('returns true for child_under_5 and elderly', () {
        expect(
          BeneficiaryValidator.areCategoriesConflicting(
            'child_under_5',
            'elderly',
          ),
          isTrue,
        );
      });

      test('returns true for pregnant_woman and lactating_mother', () {
        expect(
          BeneficiaryValidator.areCategoriesConflicting(
            'pregnant_woman',
            'lactating_mother',
          ),
          isTrue,
        );
      });

      test('returns false for non-conflicting categories', () {
        expect(
          BeneficiaryValidator.areCategoriesConflicting(
            'pregnant_woman',
            'disabled',
          ),
          isFalse,
        );
      });
    });

    group('validateCategorySelection', () {
      test('returns null for valid category selection', () {
        expect(
          BeneficiaryValidator.validateCategorySelection(
            'disabled',
            {'chronically_ill'},
            null,
          ),
          isNull,
        );
      });

      test('returns error for conflicting categories', () {
        expect(
          BeneficiaryValidator.validateCategorySelection(
            'pregnant_woman',
            {'elderly'},
            null,
          ),
          isNotNull,
        );
      });

      test('returns error for elderly category with age < 60', () {
        expect(
          BeneficiaryValidator.validateCategorySelection(
            'elderly',
            {},
            50,
          ),
          equals('Elderly category requires age 60 or older'),
        );
      });

      test('returns null for elderly category with age >= 60', () {
        expect(
          BeneficiaryValidator.validateCategorySelection(
            'elderly',
            {},
            65,
          ),
          isNull,
        );
      });

      test('returns error for pregnant_woman with age >= 60', () {
        expect(
          BeneficiaryValidator.validateCategorySelection(
            'pregnant_woman',
            {},
            65,
          ),
          equals('Pregnant woman category requires age less than 60'),
        );
      });

      test('returns null for pregnant_woman with age < 60', () {
        expect(
          BeneficiaryValidator.validateCategorySelection(
            'pregnant_woman',
            {},
            30,
          ),
          isNull,
        );
      });
    });

    group('getConflictingCategories', () {
      test('returns correct conflicts for pregnant_woman', () {
        final conflicts = BeneficiaryValidator.getConflictingCategories(
          'pregnant_woman',
        );
        expect(conflicts, containsAll(['elderly', 'lactating_mother']));
      });

      test('returns correct conflicts for elderly', () {
        final conflicts = BeneficiaryValidator.getConflictingCategories('elderly');
        expect(
          conflicts,
          containsAll(['pregnant_woman', 'lactating_mother', 'child_under_5']),
        );
      });

      test('returns empty list for non-conflicting category', () {
        final conflicts = BeneficiaryValidator.getConflictingCategories('disabled');
        expect(conflicts, isEmpty);
      });
    });
  });
}


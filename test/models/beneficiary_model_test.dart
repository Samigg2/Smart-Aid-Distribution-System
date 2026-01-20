import 'package:flutter_test/flutter_test.dart';
import 'package:firs_app/models/beneficiary_model.dart';

void main() {
  group('BeneficiaryModel', () {

    test('VulnerableCategory enum values are correct', () {
      expect(VulnerableCategory.pregnantWoman.value, equals('pregnant_woman'));
      expect(VulnerableCategory.pregnantWoman.label, equals('Pregnant Woman'));
      expect(VulnerableCategory.elderly.value, equals('elderly'));
      expect(VulnerableCategory.elderly.label, equals('Elderly (60+)'));
    });

    test('VulnerableCategory.fromValue returns correct enum', () {
      expect(
        VulnerableCategory.fromValue('pregnant_woman'),
        equals(VulnerableCategory.pregnantWoman),
      );
      expect(
        VulnerableCategory.fromValue('elderly'),
        equals(VulnerableCategory.elderly),
      );
    });

    test('VulnerableCategory.fromValue returns default for unknown value', () {
      expect(
        VulnerableCategory.fromValue('unknown'),
        equals(VulnerableCategory.pregnantWoman),
      );
    });

    test('IncomeLevel enum values are correct', () {
      expect(IncomeLevel.lessThan1000.value, equals('less_than_1000'));
      expect(IncomeLevel.lessThan1000.label, equals('Less than 1,000 ETB'));
      expect(IncomeLevel.above5000.value, equals('above_5000'));
      expect(IncomeLevel.above5000.label, equals('Above 5,000 ETB'));
    });

    test('IncomeLevel.fromValue returns correct enum', () {
      expect(
        IncomeLevel.fromValue('1000-3000'),
        equals(IncomeLevel.between1000_3000),
      );
    });

    test('MobilityLevel enum values are correct', () {
      expect(MobilityLevel.canWalk.value, equals('can_walk'));
      expect(MobilityLevel.bedridden.value, equals('bedridden'));
    });

    test('DisabilityType enum values are correct', () {
      expect(DisabilityType.physical.value, equals('physical'));
      expect(DisabilityType.multiple.value, equals('multiple'));
    });

    test('DisabilitySeverity enum values are correct', () {
      expect(DisabilitySeverity.mild.value, equals('mild'));
      expect(DisabilitySeverity.severe.value, equals('severe'));
    });
  });
}


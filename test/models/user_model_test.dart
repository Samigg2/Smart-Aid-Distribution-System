import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firs_app/models/user_model.dart';

void main() {
  group('UserModel', () {
    final testUser = UserModel(
      uid: 'test-uid-123',
      email: 'test@example.com',
      role: 'admin',
      fullName: 'Test User',
      phone: '0987654321',
      isActive: true,
      createdAt: DateTime(2024, 1, 1),
      lastLogin: DateTime(2024, 1, 15),
    );

    test('creates UserModel with all properties', () {
      expect(testUser.uid, equals('test-uid-123'));
      expect(testUser.email, equals('test@example.com'));
      expect(testUser.role, equals('admin'));
      expect(testUser.fullName, equals('Test User'));
      expect(testUser.phone, equals('0987654321'));
      expect(testUser.isActive, isTrue);
      expect(testUser.createdAt, equals(DateTime(2024, 1, 1)));
      expect(testUser.lastLogin, equals(DateTime(2024, 1, 15)));
    });

    test('isAdmin returns true for admin role', () {
      expect(testUser.isAdmin, isTrue);
    });

    test('isAdmin returns false for staff role', () {
      final staffUser = testUser.copyWith(role: 'staff');
      expect(staffUser.isAdmin, isFalse);
    });

    test('isStaff returns true for staff role', () {
      final staffUser = testUser.copyWith(role: 'staff');
      expect(staffUser.isStaff, isTrue);
    });

    test('isStaff returns false for admin role', () {
      expect(testUser.isStaff, isFalse);
    });

    // Note: fromFirestore tests require Firebase/Firestore setup
    // These should be tested with integration tests or Firebase emulator
    // Skipping unit tests for fromFirestore due to DocumentSnapshot being sealed

    test('toMap converts UserModel to Map correctly', () {
      final map = testUser.toMap();
      expect(map['email'], equals('test@example.com'));
      expect(map['role'], equals('admin'));
      expect(map['fullName'], equals('Test User'));
      expect(map['phone'], equals('0987654321'));
      expect(map['isActive'], isTrue);
      expect(map['createdAt'], isA<Timestamp>());
      expect(map['lastLogin'], isA<Timestamp>());
    });

    test('copyWith creates new instance with updated fields', () {
      final updatedUser = testUser.copyWith(
        email: 'newemail@example.com',
        isActive: false,
      );
      expect(updatedUser.email, equals('newemail@example.com'));
      expect(updatedUser.isActive, isFalse);
      expect(updatedUser.uid, equals(testUser.uid));
      expect(updatedUser.role, equals(testUser.role));
    });

    test('copyWith keeps original values when fields not provided', () {
      final copiedUser = testUser.copyWith();
      expect(copiedUser.uid, equals(testUser.uid));
      expect(copiedUser.email, equals(testUser.email));
      expect(copiedUser.role, equals(testUser.role));
      expect(copiedUser.fullName, equals(testUser.fullName));
    });
  });
}


import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../models/beneficiary_model.dart';
import '../utils/logger.dart';

class BeneficiaryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Generate unique beneficiary ID
  String _generateBeneficiaryId() {
    final now = DateTime.now();
    final year = now.year;
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    final random = now.millisecond % 1000;
    return 'BEN-$year$month$day-${random.toString().padLeft(3, '0')}';
  }

  // Create new beneficiary
  Future<String?> createBeneficiary(BeneficiaryModel beneficiary) async {
    try {
      // Check if national ID already exists
      final existingQuery = await _firestore
          .collection('beneficiaries')
          .where('nationalId', isEqualTo: beneficiary.nationalId)
          .limit(1)
          .get();

      if (existingQuery.docs.isNotEmpty) {
        Fluttertoast.showToast(
          msg: 'National ID already registered',
          toastLength: Toast.LENGTH_LONG,
        );
        return null;
      }

      // Generate beneficiary ID
      final beneficiaryId = _generateBeneficiaryId();

      // Create document
      await _firestore
          .collection('beneficiaries')
          .doc(beneficiaryId)
          .set(beneficiary.copyWith(beneficiaryId: beneficiaryId).toMap());

      Fluttertoast.showToast(msg: 'Beneficiary registered successfully');
      return beneficiaryId;
    } catch (e, stackTrace) {
      Logger.error('Error creating beneficiary', error: e, stackTrace: stackTrace, tag: 'BeneficiaryService');
      Fluttertoast.showToast(msg: 'Failed to register beneficiary');
      return null;
    }
  }

  // Get all beneficiaries (stream for real-time updates)
  Stream<List<BeneficiaryModel>> getAllBeneficiaries() {
    return _firestore
        .collection('beneficiaries')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => BeneficiaryModel.fromFirestore(doc))
              .toList();
        });
  }

  // Get beneficiaries by staff member
  Stream<List<BeneficiaryModel>> getBeneficiariesByStaff(String staffUid) {
    return _firestore
        .collection('beneficiaries')
        .where('registeredBy', isEqualTo: staffUid)
        .snapshots()
        .map((snapshot) {
          final beneficiaries = snapshot.docs
              .map((doc) => BeneficiaryModel.fromFirestore(doc))
              .toList();
          // Sort by createdAt in memory (avoids needing composite index)
          beneficiaries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return beneficiaries;
        });
  }

  // Get beneficiary by ID
  Future<BeneficiaryModel?> getBeneficiaryById(String beneficiaryId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('beneficiaries')
          .doc(beneficiaryId)
          .get();

      if (doc.exists) {
        return BeneficiaryModel.fromFirestore(doc);
      }
      return null;
    } catch (e, stackTrace) {
      Logger.error('Error getting beneficiary', error: e, stackTrace: stackTrace, tag: 'BeneficiaryService');
      return null;
    }
  }

  // Search beneficiaries by name or national ID
  Future<List<BeneficiaryModel>> searchBeneficiaries(String query) async {
    try {
      // Search by name (case-insensitive)
      final nameQuery = await _firestore
          .collection('beneficiaries')
          .where('fullName', isGreaterThanOrEqualTo: query)
          .where('fullName', isLessThanOrEqualTo: '$query\uf8ff')
          .get();

      // Search by national ID
      final idQuery = await _firestore
          .collection('beneficiaries')
          .where('nationalId', isEqualTo: query)
          .get();

      // Combine and deduplicate
      final allDocs = <String, DocumentSnapshot>{};
      for (var doc in nameQuery.docs) {
        allDocs[doc.id] = doc;
      }
      for (var doc in idQuery.docs) {
        allDocs[doc.id] = doc;
      }

      return allDocs.values
          .map((doc) => BeneficiaryModel.fromFirestore(doc))
          .toList();
    } catch (e, stackTrace) {
      Logger.error('Error searching beneficiaries', error: e, stackTrace: stackTrace, tag: 'BeneficiaryService');
      return [];
    }
  }

  // Update beneficiary
  Future<bool> updateBeneficiary(
    String beneficiaryId,
    BeneficiaryModel beneficiary,
  ) async {
    try {
      await _firestore
          .collection('beneficiaries')
          .doc(beneficiaryId)
          .update(
            beneficiary
                .copyWith(
                  beneficiaryId: beneficiaryId,
                  updatedAt: DateTime.now(),
                )
                .toMap(),
          );

      Fluttertoast.showToast(msg: 'Beneficiary updated successfully');
      return true;
    } catch (e, stackTrace) {
      Logger.error('Error updating beneficiary', error: e, stackTrace: stackTrace, tag: 'BeneficiaryService');
      Fluttertoast.showToast(msg: 'Failed to update beneficiary');
      return false;
    }
  }

  // Delete beneficiary
  Future<bool> deleteBeneficiary(String beneficiaryId) async {
    try {
      await _firestore.collection('beneficiaries').doc(beneficiaryId).delete();

      Fluttertoast.showToast(msg: 'Beneficiary deleted');
      return true;
    } catch (e, stackTrace) {
      Logger.error('Error deleting beneficiary', error: e, stackTrace: stackTrace, tag: 'BeneficiaryService');
      Fluttertoast.showToast(msg: 'Failed to delete beneficiary');
      return false;
    }
  }

  // Get all beneficiaries for export (one-time fetch)
  Future<List<BeneficiaryModel>> getAllBeneficiariesForExport() async {
    try {
      final snapshot = await _firestore
          .collection('beneficiaries')
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => BeneficiaryModel.fromFirestore(doc))
          .toList();
    } catch (e, stackTrace) {
      Logger.error('Error getting beneficiaries for export', error: e, stackTrace: stackTrace, tag: 'BeneficiaryService');
      return [];
    }
  }

  // Get beneficiary statistics
  Future<Map<String, int>> getBeneficiaryStatistics() async {
    try {
      final allBeneficiaries = await _firestore
          .collection('beneficiaries')
          .get();

      final pregnant = await _firestore
          .collection('beneficiaries')
          .where('isPregnant', isEqualTo: true)
          .get();

      final withChildren = await _firestore
          .collection('beneficiaries')
          .where('childrenUnder5Count', isGreaterThan: 0)
          .get();

      final femaleHeaded = await _firestore
          .collection('beneficiaries')
          .where('isFemaleHeadedHousehold', isEqualTo: true)
          .get();

      return {
        'total': allBeneficiaries.docs.length,
        'pregnant': pregnant.docs.length,
        'withChildren': withChildren.docs.length,
        'femaleHeaded': femaleHeaded.docs.length,
      };
    } catch (e, stackTrace) {
      Logger.error('Error getting statistics', error: e, stackTrace: stackTrace, tag: 'BeneficiaryService');
      return {'total': 0, 'pregnant': 0, 'withChildren': 0, 'femaleHeaded': 0};
    }
  }
}



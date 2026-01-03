import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../models/distribution_model.dart';
import '../models/beneficiary_model.dart';
import '../utils/logger.dart';

class DistributionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==================== PROGRAM OPERATIONS ====================

  /// Create a new distribution program
  Future<String?> createProgram(DistributionProgram program) async {
    try {
      final docRef = await _firestore
          .collection('distribution_programs')
          .add(program.toMap());
      Fluttertoast.showToast(msg: 'Program created successfully');
      return docRef.id;
    } catch (e, stackTrace) {
      Logger.error(
        'Error creating program',
        error: e,
        stackTrace: stackTrace,
        tag: 'DistributionService',
      );
      Fluttertoast.showToast(msg: 'Failed to create program');
      return null;
    }
  }

  /// Get all distribution programs (sorted in memory)
  Stream<List<DistributionProgram>> getAllPrograms() {
    return _firestore.collection('distribution_programs').snapshots().map((
      snapshot,
    ) {
      final programs = snapshot.docs
          .map((doc) => DistributionProgram.fromFirestore(doc))
          .toList();
      programs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return programs;
    });
  }

  /// Get active programs only (sorted in memory)
  Stream<List<DistributionProgram>> getActivePrograms() {
    return _firestore
        .collection('distribution_programs')
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snapshot) {
          final programs = snapshot.docs
              .map((doc) => DistributionProgram.fromFirestore(doc))
              .toList();
          programs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return programs;
        });
  }

  /// Get program by ID
  Future<DistributionProgram?> getProgramById(String programId) async {
    try {
      final doc = await _firestore
          .collection('distribution_programs')
          .doc(programId)
          .get();
      if (doc.exists) {
        return DistributionProgram.fromFirestore(doc);
      }
      return null;
    } catch (e, stackTrace) {
      Logger.error(
        'Error getting program',
        error: e,
        stackTrace: stackTrace,
        tag: 'DistributionService',
      );
      return null;
    }
  }

  /// Update program status
  Future<bool> updateProgramStatus(String programId, String status) async {
    try {
      await _firestore
          .collection('distribution_programs')
          .doc(programId)
          .update({'status': status, 'updatedAt': Timestamp.now()});
      Fluttertoast.showToast(msg: 'Program status updated');
      return true;
    } catch (e, stackTrace) {
      Logger.error(
        'Error updating program status',
        error: e,
        stackTrace: stackTrace,
        tag: 'DistributionService',
      );
      Fluttertoast.showToast(msg: 'Failed to update status');
      return false;
    }
  }

  /// Get eligible beneficiaries for a program
  Future<List<BeneficiaryModel>> getEligibleBeneficiaries(
    DistributionProgram program,
  ) async {
    try {
      Query query = _firestore.collection('beneficiaries');

      // Filter by region if specified
      if (program.region != null && program.region!.isNotEmpty) {
        query = query.where('region', isEqualTo: program.region);
      }

      final snapshot = await query.get();
      final allBeneficiaries = snapshot.docs
          .map((doc) => BeneficiaryModel.fromFirestore(doc))
          .toList();

      // Filter by target categories (beneficiary must have at least one matching category)
      final eligible = allBeneficiaries.where((beneficiary) {
        return beneficiary.vulnerableCategories.any(
          (category) => program.targetCategories.contains(category),
        );
      }).toList();

      // Sort by urgency score (highest first)
      eligible.sort((a, b) => b.urgencyScore.compareTo(a.urgencyScore));

      return eligible;
    } catch (e, stackTrace) {
      Logger.error(
        'Error getting eligible beneficiaries',
        error: e,
        stackTrace: stackTrace,
        tag: 'DistributionService',
      );
      return [];
    }
  }

  // ==================== DISTRIBUTION OPERATIONS ====================

  /// Check if beneficiary already received from this program
  Future<bool> hasAlreadyReceived(
    String programId,
    String beneficiaryId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('distribution_records')
          .where('programId', isEqualTo: programId)
          .where('beneficiaryId', isEqualTo: beneficiaryId)
          .limit(1)
          .get();
      return snapshot.docs.isNotEmpty;
    } catch (e, stackTrace) {
      Logger.error(
        'Error checking distribution',
        error: e,
        stackTrace: stackTrace,
        tag: 'DistributionService',
      );
      return false; // Allow distribution on error (fail open)
    }
  }

  /// Record a distribution (with double-distribution prevention)
  Future<String?> recordDistribution(DistributionRecord record) async {
    try {
      // Check for double distribution
      final alreadyReceived = await hasAlreadyReceived(
        record.programId,
        record.beneficiaryId,
      );

      if (alreadyReceived) {
        Fluttertoast.showToast(
          msg: 'This beneficiary already received aid from this program!',
        );
        return null;
      }

      // Use batch write to ensure atomicity - both operations succeed or both fail
      final batch = _firestore.batch();

      // Create the distribution record
      final docRef = _firestore.collection('distribution_records').doc();
      batch.set(docRef, record.toMap());

      // Update program counters
      final programRef = _firestore
          .collection('distribution_programs')
          .doc(record.programId);
      batch.update(programRef, {
        'distributedCount': FieldValue.increment(1),
        'distributedQuantity': FieldValue.increment(record.quantity),
        'updatedAt': Timestamp.now(),
      });

      // Commit the batch - both writes succeed or both fail
      await batch.commit();

      Fluttertoast.showToast(msg: 'Distribution recorded successfully');
      return docRef.id;
    } catch (e, stackTrace) {
      Logger.error(
        'Error recording distribution',
        error: e,
        stackTrace: stackTrace,
        tag: 'DistributionService',
      );
      Fluttertoast.showToast(msg: 'Failed to record distribution');
      return null;
    }
  }

  /// Get all distributions for a program (sorted in memory to avoid index requirement)
  Stream<List<DistributionRecord>> getDistributionsByProgram(String programId) {
    return _firestore
        .collection('distribution_records')
        .where('programId', isEqualTo: programId)
        .snapshots()
        .map((snapshot) {
          final records = snapshot.docs
              .map((doc) => DistributionRecord.fromFirestore(doc))
              .toList();
          // Sort in memory to avoid needing composite index
          records.sort((a, b) => b.distributedAt.compareTo(a.distributedAt));
          return records;
        });
  }

  /// Get all distributions for a beneficiary (sorted in memory)
  Stream<List<DistributionRecord>> getDistributionsByBeneficiary(
    String beneficiaryId,
  ) {
    return _firestore
        .collection('distribution_records')
        .where('beneficiaryId', isEqualTo: beneficiaryId)
        .snapshots()
        .map((snapshot) {
          final records = snapshot.docs
              .map((doc) => DistributionRecord.fromFirestore(doc))
              .toList();
          records.sort((a, b) => b.distributedAt.compareTo(a.distributedAt));
          return records;
        });
  }

  /// Get recent distributions (for dashboard)
  Stream<List<DistributionRecord>> getRecentDistributions({int limit = 10}) {
    return _firestore.collection('distribution_records').snapshots().map((
      snapshot,
    ) {
      final records = snapshot.docs
          .map((doc) => DistributionRecord.fromFirestore(doc))
          .toList();
      records.sort((a, b) => b.distributedAt.compareTo(a.distributedAt));
      return records.take(limit).toList();
    });
  }

  /// Get distributions by staff member (sorted in memory)
  Stream<List<DistributionRecord>> getDistributionsByStaff(String staffUid) {
    return _firestore
        .collection('distribution_records')
        .where('distributedBy', isEqualTo: staffUid)
        .snapshots()
        .map((snapshot) {
          final records = snapshot.docs
              .map((doc) => DistributionRecord.fromFirestore(doc))
              .toList();
          records.sort((a, b) => b.distributedAt.compareTo(a.distributedAt));
          return records;
        });
  }

  // ==================== STATISTICS ====================

  /// Get distribution statistics
  Future<Map<String, dynamic>> getDistributionStatistics() async {
    try {
      // Get all programs
      final programsSnapshot = await _firestore
          .collection('distribution_programs')
          .get();

      // Get all distribution records
      final recordsSnapshot = await _firestore
          .collection('distribution_records')
          .get();

      // Calculate stats
      int totalPrograms = programsSnapshot.docs.length;
      int activePrograms = programsSnapshot.docs
          .where((doc) => doc.data()['status'] == 'active')
          .length;
      int totalDistributions = recordsSnapshot.docs.length;

      Set<String> uniqueBeneficiaries = {};

      for (var doc in recordsSnapshot.docs) {
        final data = doc.data();
        uniqueBeneficiaries.add(data['beneficiaryId'] ?? '');
      }

      // Count by aid type
      Map<String, int> byAidType = {};
      for (var doc in recordsSnapshot.docs) {
        final aidType = doc.data()['aidType'] ?? 'other';
        byAidType[aidType] = (byAidType[aidType] ?? 0) + 1;
      }

      return {
        'totalPrograms': totalPrograms,
        'activePrograms': activePrograms,
        'totalDistributions': totalDistributions,
        'uniqueBeneficiariesReached': uniqueBeneficiaries.length,
        'byAidType': byAidType,
      };
    } catch (e, stackTrace) {
      Logger.error(
        'Error getting distribution stats',
        error: e,
        stackTrace: stackTrace,
        tag: 'DistributionService',
      );
      return {
        'totalPrograms': 0,
        'activePrograms': 0,
        'totalDistributions': 0,
        'uniqueBeneficiariesReached': 0,
        'byAidType': {},
      };
    }
  }

  // ==================== EXPORT ====================

  /// Get all distribution records for export (sorted in memory)
  Future<List<DistributionRecord>> getAllDistributionsForExport() async {
    try {
      final snapshot = await _firestore
          .collection('distribution_records')
          .get();
      final records = snapshot.docs
          .map((doc) => DistributionRecord.fromFirestore(doc))
          .toList();
      records.sort((a, b) => b.distributedAt.compareTo(a.distributedAt));
      return records;
    } catch (e, stackTrace) {
      Logger.error(
        'Error getting distributions for export',
        error: e,
        stackTrace: stackTrace,
        tag: 'DistributionService',
      );
      return [];
    }
  }

  /// Get program distributions for export (sorted in memory)
  Future<List<DistributionRecord>> getProgramDistributionsForExport(
    String programId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('distribution_records')
          .where('programId', isEqualTo: programId)
          .get();
      final records = snapshot.docs
          .map((doc) => DistributionRecord.fromFirestore(doc))
          .toList();
      records.sort((a, b) => b.distributedAt.compareTo(a.distributedAt));
      return records;
    } catch (e, stackTrace) {
      Logger.error(
        'Error getting program distributions for export',
        error: e,
        stackTrace: stackTrace,
        tag: 'DistributionService',
      );
      return [];
    }
  }
}

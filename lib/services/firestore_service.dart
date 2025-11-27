import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all users (admin only)
  Stream<List<UserModel>> getAllUsers() {
    return _firestore
        .collection('users')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
    });
  }

  // Get user by ID
  Future<UserModel?> getUserById(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting user: $e');
      return null;
    }
  }

  // Update user
  Future<bool> updateUser(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(uid).update(data);
      Fluttertoast.showToast(msg: 'User updated successfully');
      return true;
    } catch (e) {
      Fluttertoast.showToast(msg: 'Failed to update user');
      return false;
    }
  }

  // Toggle user active status
  Future<bool> toggleUserStatus(String uid, bool currentStatus) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'isActive': !currentStatus,
      });
      Fluttertoast.showToast(
        msg: currentStatus ? 'User deactivated' : 'User activated',
      );
      return true;
    } catch (e) {
      Fluttertoast.showToast(msg: 'Failed to update user status');
      return false;
    }
  }

  // Delete user (admin only - note: this only deletes Firestore data)
  Future<bool> deleteUserData(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).delete();
      Fluttertoast.showToast(msg: 'User data deleted');
      return true;
    } catch (e) {
      Fluttertoast.showToast(msg: 'Failed to delete user');
      return false;
    }
  }

  // Get user statistics (admin only)
  Future<Map<String, int>> getUserStatistics() async {
    try {
      QuerySnapshot allUsers = await _firestore.collection('users').get();
      QuerySnapshot admins = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'admin')
          .get();
      QuerySnapshot staff = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'staff')
          .get();
      QuerySnapshot activeUsers = await _firestore
          .collection('users')
          .where('isActive', isEqualTo: true)
          .get();

      return {
        'total': allUsers.docs.length,
        'admins': admins.docs.length,
        'staff': staff.docs.length,
        'active': activeUsers.docs.length,
      };
    } catch (e) {
      print('Error getting statistics: $e');
      return {
        'total': 0,
        'admins': 0,
        'staff': 0,
        'active': 0,
      };
    }
  }

  // Check if user has admin role
  Future<bool> isAdmin(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return (doc.data() as Map<String, dynamic>)['role'] == 'admin';
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}


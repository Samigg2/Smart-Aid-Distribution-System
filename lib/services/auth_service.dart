import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  Future<UserModel?> signInWithEmailPassword(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;

      if (user != null) {
        // Get user data from Firestore
        DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
        
        if (!userDoc.exists) {
          await signOut();
          Fluttertoast.showToast(msg: 'User data not found');
          return null;
        }

        UserModel userModel = UserModel.fromFirestore(userDoc);

        // Check if user is active
        if (!userModel.isActive) {
          await signOut();
          Fluttertoast.showToast(msg: 'Your account has been deactivated');
          return null;
        }

        // Update last login
        await _firestore.collection('users').doc(user.uid).update({
          'lastLogin': FieldValue.serverTimestamp(),
        });

        Fluttertoast.showToast(msg: 'Login successful');
        return userModel;
      }
      return null;
    } on FirebaseAuthException catch (e) {
      String message = 'An error occurred';
      if (e.code == 'user-not-found') {
        message = 'No user found with this email';
      } else if (e.code == 'wrong-password') {
        message = 'Incorrect password';
      } else if (e.code == 'invalid-email') {
        message = 'Invalid email address';
      } else if (e.code == 'user-disabled') {
        message = 'This account has been disabled';
      }
      Fluttertoast.showToast(msg: message);
      return null;
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error: ${e.toString()}');
      return null;
    }
  }

  // Create new user (admin only)
  Future<bool> createUser({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String role,
  }) async {
    try {
      // Create user in Firebase Auth
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;

      if (user != null) {
        // Create user document in Firestore
        await _firestore.collection('users').doc(user.uid).set({
          'email': email,
          'fullName': fullName,
          'phone': phone,
          'role': role,
          'isActive': true,
          'createdAt': FieldValue.serverTimestamp(),
          'lastLogin': null,
        });

        Fluttertoast.showToast(msg: 'User created successfully');
        return true;
      }
      return false;
    } on FirebaseAuthException catch (e) {
      String message = 'Failed to create user';
      if (e.code == 'email-already-in-use') {
        message = 'This email is already registered';
      } else if (e.code == 'weak-password') {
        message = 'Password is too weak';
      } else if (e.code == 'invalid-email') {
        message = 'Invalid email address';
      }
      Fluttertoast.showToast(msg: message);
      return false;
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error: ${e.toString()}');
      return false;
    }
  }

  // Get current user data
  Future<UserModel?> getCurrentUserData() async {
    try {
      User? user = currentUser;
      if (user == null) return null;

      DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
      
      if (!userDoc.exists) return null;

      return UserModel.fromFirestore(userDoc);
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      Fluttertoast.showToast(msg: 'Logged out successfully');
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error signing out');
    }
  }

  // Reset password
  Future<bool> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      Fluttertoast.showToast(msg: 'Password reset email sent');
      return true;
    } on FirebaseAuthException catch (e) {
      String message = 'Failed to send reset email';
      if (e.code == 'user-not-found') {
        message = 'No user found with this email';
      } else if (e.code == 'invalid-email') {
        message = 'Invalid email address';
      }
      Fluttertoast.showToast(msg: message);
      return false;
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error: ${e.toString()}');
      return false;
    }
  }
}


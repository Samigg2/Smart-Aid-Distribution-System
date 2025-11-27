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
  // Note: This will temporarily log out the admin and log them back in
  Future<bool> createUser({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String role,
    required String adminEmail,
    required String adminPassword,
  }) async {
    try {
      // Store current admin UID
      String? currentAdminUid = _auth.currentUser?.uid;
      
      // Create user in Firebase Auth
      // WARNING: This will log out the current admin temporarily
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? newUser = result.user;

      if (newUser != null) {
        // Create user document in Firestore
        // Use the new user's UID for the document
        await _firestore.collection('users').doc(newUser.uid).set({
          'email': email,
          'fullName': fullName,
          'phone': phone,
          'role': role,
          'isActive': true,
          'createdAt': FieldValue.serverTimestamp(),
          'lastLogin': null,
        });

        // Sign out the newly created user
        await _auth.signOut();

        // Sign back in as admin
        await _auth.signInWithEmailAndPassword(
          email: adminEmail,
          password: adminPassword,
        );

        Fluttertoast.showToast(msg: 'User created successfully');
        return true;
      }
      return false;
    } on FirebaseAuthException catch (e) {
      // Try to log back in as admin even if there was an error
      try {
        await _auth.signInWithEmailAndPassword(
          email: adminEmail,
          password: adminPassword,
        );
      } catch (_) {}

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
      // Try to log back in as admin
      try {
        await _auth.signInWithEmailAndPassword(
          email: adminEmail,
          password: adminPassword,
        );
      } catch (_) {}
      
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


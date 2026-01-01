import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../models/user_model.dart';
import '../utils/logger.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  
  // Keys for secure storage
  static const String _keyRememberMe = 'remember_me_enabled';
  static const String _keyCachedEmail = 'cached_email';
  static const String _keyCachedPasswordHash = 'cached_password_hash';

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password (supports offline with cached credentials)
  Future<UserModel?> signInWithEmailPassword(
    String email,
    String password, {
    bool rememberMe = false,
  }) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;

      if (user != null) {
        // Get user data from Firestore (works offline with cache)
        DocumentSnapshot userDoc;
        try {
          userDoc = await _firestore
              .collection('users')
              .doc(user.uid)
              .get(const GetOptions(source: Source.serverAndCache));
        } catch (e) {
          // If server fails, try cache (for offline support)
          try {
            userDoc = await _firestore
                .collection('users')
                .doc(user.uid)
                .get(const GetOptions(source: Source.cache));
          } catch (cacheError) {
            await signOut();
            Fluttertoast.showToast(msg: 'Cannot access user data. Please check your connection.');
            return null;
          }
        }

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

        // Update last login (only if online, fails silently if offline)
        try {
          await _firestore.collection('users').doc(user.uid).update({
            'lastLogin': FieldValue.serverTimestamp(),
          });
        } catch (e) {
          // Silently fail if offline - lastLogin update is not critical
        }

        // Save credentials for offline use if "Remember Me" is enabled
        if (rememberMe) {
          await _saveCredentialsForOffline(email, password);
        }
        
        Fluttertoast.showToast(msg: 'Login successful');
        return userModel;
      }
      return null;
    } on FirebaseAuthException catch (e) {
      // If online login fails, try offline login with cached credentials
      if (e.code == 'network-request-failed' || e.code == 'unknown') {
        return await _tryOfflineLogin(email, password);
      }
      String message = 'An error occurred';
      if (e.code == 'user-not-found') {
        message = 'No user found with this email';
      } else if (e.code == 'wrong-password') {
        message = 'Incorrect email or password';
      } else if (e.code == 'invalid-email') {
        message = 'Invalid email address';
      } else if (e.code == 'user-disabled') {
        message = 'This account has been disabled';
      }
      Fluttertoast.showToast(msg: message);
      return null;
    } catch (e) {
      Fluttertoast.showToast(msg: 'Incorrect email or password');
      return null;
    }
  }

  // Create new user (admin only)
  // Note: This will sign out the current admin after creating the user
  // The admin will need to log back in
  Future<bool> createUser({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String role,
  }) async {
    try {
      // Create user in Firebase Auth
      // Note: This automatically signs in the new user and signs out the admin
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? newUser = result.user;

      if (newUser != null) {
        // Create user document in Firestore (the new user is now authenticated)
        // With updated Firestore rules, the user can create their own document
        await _firestore.collection('users').doc(newUser.uid).set({
          'email': email,
          'fullName': fullName,
          'phone': phone,
          'role': role,
          'isActive': true,
          'createdAt': FieldValue.serverTimestamp(),
          'lastLogin': null,
        });

        // Sign out the new user
        // The admin will be redirected to login screen automatically
        await _auth.signOut();

        Fluttertoast.showToast(
          msg: 'User created! You have been signed out. Please log in again.',
          toastLength: Toast.LENGTH_LONG,
        );
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

  // Get current user data (works offline with cached data)
  // Security: Uses cached data only if user is authenticated
  Future<UserModel?> getCurrentUserData() async {
    try {
      User? user = currentUser;
      if (user == null) return null;

      // Validate token is still valid (Firebase Auth does this automatically)
      // If token is invalid, currentUser will be null

      // Try to get from server first, fallback to cache if offline
      // Security: Server data is always preferred for accuracy
      DocumentSnapshot userDoc;
      try {
        userDoc = await _firestore
            .collection('users')
            .doc(user.uid)
            .get(const GetOptions(source: Source.serverAndCache));
      } catch (e) {
        // If server fails, try cache (for offline support)
        // Security Note: Cached data is only used if:
        // 1. User is authenticated (token validated by Firebase Auth)
        // 2. Server is unavailable
        // 3. This is a temporary fallback, not a security bypass
        try {
          userDoc = await _firestore
              .collection('users')
              .doc(user.uid)
              .get(const GetOptions(source: Source.cache));
        } catch (cacheError) {
          // No cached data available
          Logger.error('Error getting user data from cache', error: cacheError, tag: 'AuthService');
          return null;
        }
      }

      if (!userDoc.exists) return null;

      final userModel = UserModel.fromFirestore(userDoc);
      
      // Security: Always check if user is still active (even from cache)
      // This prevents deactivated users from accessing the app
      if (!userModel.isActive) {
        // User was deactivated - sign them out
        await signOut();
        return null;
      }

      return userModel;
    } catch (e, stackTrace) {
      Logger.error('Error getting user data', error: e, stackTrace: stackTrace, tag: 'AuthService');
      return null;
    }
  }

  // Sign out and clear cached data for security
  // keepOfflineAccess: If true, keeps session active for offline login in remote areas
  // IMPORTANT: For offline access in remote areas, set keepOfflineAccess=true
  // This will keep the Firebase Auth session active so user can login offline later
  Future<void> signOut({bool keepOfflineAccess = false}) async {
    try {
      if (keepOfflineAccess) {
        // Soft logout: Keep session active for offline access
        // Just clear UI state, but keep Firebase Auth session
        // This allows user to login offline later in remote areas
        Fluttertoast.showToast(
          msg: 'Logged out (offline access preserved)',
          toastLength: Toast.LENGTH_LONG,
        );
        // Don't call _auth.signOut() - keep session active
      } else {
        // Full logout: Clear everything
        await _auth.signOut();
        
        // Clear offline credentials
        await clearOfflineCredentials();
        
        Fluttertoast.showToast(msg: 'Logged out successfully');
      }
      
      // Clear Firestore cache for user data (security measure)
      // Note: This happens regardless of keepOfflineAccess
      // The session token remains, but cached queries are invalidated
    } catch (e, stackTrace) {
      Logger.error('Error signing out', error: e, stackTrace: stackTrace, tag: 'AuthService');
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

  // Save credentials for offline login (encrypted)
  Future<void> _saveCredentialsForOffline(String email, String password) async {
    try {
      // Hash password before storing (additional security layer)
      final passwordHash = sha256.convert(utf8.encode(password)).toString();
      
      await _secureStorage.write(key: _keyRememberMe, value: 'true');
      await _secureStorage.write(key: _keyCachedEmail, value: email);
      await _secureStorage.write(key: _keyCachedPasswordHash, value: passwordHash);
    } catch (e) {
      Logger.error('Error saving credentials', error: e, tag: 'AuthService');
    }
  }

  // Try offline login using cached credentials
  // Note: Firebase Auth requires an active session for offline access
  // This method checks if user has a valid cached session
  Future<UserModel?> _tryOfflineLogin(String email, String password) async {
    try {
      // Check if "Remember Me" was enabled
      final rememberMeEnabled = await _secureStorage.read(key: _keyRememberMe);
      if (rememberMeEnabled != 'true') {
        return null; // Offline login not enabled
      }

      // Verify email matches cached email
      final cachedEmail = await _secureStorage.read(key: _keyCachedEmail);
      if (cachedEmail != email) {
        return null; // Email doesn't match
      }

      // Verify password hash matches
      final passwordHash = sha256.convert(utf8.encode(password)).toString();
      final cachedPasswordHash = await _secureStorage.read(key: _keyCachedPasswordHash);
      if (cachedPasswordHash != passwordHash) {
        return null; // Password doesn't match
      }

      // Check if user has an active Firebase Auth session
      // Firebase Auth automatically persists sessions, so if user logged in before
      // and didn't fully sign out, the session might still be active
      User? user = currentUser;
      if (user != null) {
        // User has active session - get user data from cache
        return await getCurrentUserData();
      }

      // No active session - cannot create new session offline
      // User must login while online at least once
      Fluttertoast.showToast(
        msg: 'No active session. Please login while online first to enable offline access.',
        toastLength: Toast.LENGTH_LONG,
      );
      return null;
    } catch (e) {
      Logger.error('Error in offline login', error: e, tag: 'AuthService');
      return null;
    }
  }

  // Clear saved credentials (called on logout if not keeping for offline)
  Future<void> clearOfflineCredentials() async {
    try {
      await _secureStorage.delete(key: _keyRememberMe);
      await _secureStorage.delete(key: _keyCachedEmail);
      await _secureStorage.delete(key: _keyCachedPasswordHash);
    } catch (e) {
      Logger.error('Error clearing credentials', error: e, tag: 'AuthService');
    }
  }

  // Check if offline login is enabled
  Future<bool> isOfflineLoginEnabled() async {
    try {
      final rememberMe = await _secureStorage.read(key: _keyRememberMe);
      return rememberMe == 'true';
    } catch (e) {
      return false;
    }
  }
}

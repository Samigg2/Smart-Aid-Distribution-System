# 🚀 Step-by-Step Guide: Migrating to Admin SDK + Cloud Functions

## ⏰ When You're Ready to Migrate

**Estimated Time:** 1-2 hours  
**Difficulty:** Medium  
**Prerequisites:** Basic understanding of JavaScript/Node.js  

---

## 📋 Pre-Migration Checklist

Before you start, make sure:
- ✅ Your app is working perfectly with Firestore
- ✅ You have Node.js installed (v18 or higher recommended)
- ✅ You're comfortable with basic JavaScript
- ✅ You have time to complete the migration
- ✅ You've tested your current setup thoroughly

---

## 🎯 Part 1: Environment Setup

### Step 1: Install Node.js (if not installed)

**Windows:**
```bash
# Download from: https://nodejs.org/
# Install the LTS version (Long Term Support)
# Verify installation:
node --version  # Should show v18.x.x or higher
npm --version   # Should show v9.x.x or higher
```

### Step 2: Install Firebase CLI

```bash
# Open PowerShell or Command Prompt
npm install -g firebase-tools

# Verify installation
firebase --version

# Login to Firebase
firebase login
# This will open your browser to authenticate
```

### Step 3: Verify Firebase Project

```bash
# Navigate to your project
cd e:\smartaid

# List your Firebase projects
firebase projects:list

# Should show: smartaid-aef0b
```

---

## 🔧 Part 2: Initialize Cloud Functions

### Step 1: Initialize Functions

```bash
# In your project directory (e:\smartaid)
firebase init functions

# Answer the prompts:
# ? Please select an option: Use an existing project
# ? Select a default Firebase project: smartaid-aef0b
# ? What language would you like to use? JavaScript
# ? Do you want to use ESLint? No (unless you want it)
# ? Do you want to install dependencies now? Yes
```

**This creates:**
```
e:\smartaid\
  ├── functions\
  │   ├── index.js          ← Your Cloud Functions code
  │   ├── package.json      ← Node.js dependencies
  │   └── node_modules\     ← Installed packages
  ├── firebase.json         ← Firebase config
  └── .firebaserc           ← Project alias
```

### Step 2: Navigate to Functions Folder

```bash
cd functions
```

---

## 💻 Part 3: Write Cloud Functions

### Step 1: Open functions/index.js

Open the file: `e:\smartaid\functions\index.js`

### Step 2: Replace Content with This Code

```javascript
// functions/index.js
const functions = require('firebase-functions');
const admin = require('firebase-admin');

// Initialize Firebase Admin SDK
admin.initializeApp();

// ============================================
// Cloud Function: Create Staff User
// ============================================
exports.createStaffUser = functions.https.onCall(async (data, context) => {
  // Step 1: Verify the caller is authenticated
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'You must be logged in to create users'
    );
  }

  // Step 2: Get caller's information
  const callerUid = context.auth.uid;
  
  try {
    // Step 3: Verify caller is an admin
    const callerDoc = await admin.firestore()
      .collection('users')
      .doc(callerUid)
      .get();

    if (!callerDoc.exists) {
      throw new functions.https.HttpsError(
        'not-found',
        'Caller user document not found'
      );
    }

    const callerData = callerDoc.data();
    
    if (callerData.role !== 'admin') {
      throw new functions.https.HttpsError(
        'permission-denied',
        'Only administrators can create users'
      );
    }

    // Step 4: Validate input data
    if (!data.email || !data.password || !data.fullName || !data.phone || !data.role) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Missing required fields'
      );
    }

    // Validate email format
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(data.email)) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Invalid email format'
      );
    }

    // Validate password length
    if (data.password.length < 6) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Password must be at least 6 characters'
      );
    }

    // Validate role
    if (!['admin', 'staff'].includes(data.role)) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Role must be either admin or staff'
      );
    }

    // Step 5: Create user in Firebase Authentication
    const newUser = await admin.auth().createUser({
      email: data.email,
      password: data.password,
      emailVerified: false,
      disabled: false,
    });

    console.log(`Created user with UID: ${newUser.uid}`);

    // Step 6: Set custom claims (optional but recommended)
    await admin.auth().setCustomUserClaims(newUser.uid, {
      role: data.role,
      admin: data.role === 'admin',
    });

    // Step 7: Create user document in Firestore
    await admin.firestore()
      .collection('users')
      .doc(newUser.uid)
      .set({
        email: data.email,
        fullName: data.fullName,
        phone: data.phone,
        role: data.role,
        isActive: true,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        lastLogin: null,
        createdBy: callerUid, // Track who created this user
      });

    // Step 8: Return success
    return {
      success: true,
      uid: newUser.uid,
      message: 'User created successfully',
    };

  } catch (error) {
    console.error('Error creating user:', error);
    
    // Handle specific Firebase Auth errors
    if (error.code === 'auth/email-already-exists') {
      throw new functions.https.HttpsError(
        'already-exists',
        'This email is already registered'
      );
    }
    
    if (error.code === 'auth/invalid-email') {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Invalid email address'
      );
    }
    
    if (error.code === 'auth/weak-password') {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Password is too weak'
      );
    }

    // Re-throw HttpsErrors
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }

    // Generic error
    throw new functions.https.HttpsError(
      'internal',
      'Failed to create user: ' + error.message
    );
  }
});

// ============================================
// Cloud Function: Delete User (Optional)
// ============================================
exports.deleteUser = functions.https.onCall(async (data, context) => {
  // Verify authentication
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated');
  }

  const callerUid = context.auth.uid;

  try {
    // Verify caller is admin
    const callerDoc = await admin.firestore()
      .collection('users')
      .doc(callerUid)
      .get();

    if (!callerDoc.exists || callerDoc.data().role !== 'admin') {
      throw new functions.https.HttpsError(
        'permission-denied',
        'Only administrators can delete users'
      );
    }

    // Delete from Authentication
    await admin.auth().deleteUser(data.uid);

    // Delete from Firestore
    await admin.firestore()
      .collection('users')
      .doc(data.uid)
      .delete();

    return { success: true, message: 'User deleted successfully' };

  } catch (error) {
    console.error('Error deleting user:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});

// ============================================
// Cloud Function: Update User Role (Optional)
// ============================================
exports.updateUserRole = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated');
  }

  const callerUid = context.auth.uid;

  try {
    // Verify caller is admin
    const callerDoc = await admin.firestore()
      .collection('users')
      .doc(callerUid)
      .get();

    if (!callerDoc.exists || callerDoc.data().role !== 'admin') {
      throw new functions.https.HttpsError('permission-denied');
    }

    // Update custom claims
    await admin.auth().setCustomUserClaims(data.uid, {
      role: data.newRole,
      admin: data.newRole === 'admin',
    });

    // Update Firestore
    await admin.firestore()
      .collection('users')
      .doc(data.uid)
      .update({
        role: data.newRole,
      });

    return { success: true, message: 'User role updated' };

  } catch (error) {
    console.error('Error updating role:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});
```

### Step 3: Update package.json (Optional but Recommended)

Open `functions/package.json` and ensure you have:

```json
{
  "name": "functions",
  "description": "Cloud Functions for Firebase",
  "engines": {
    "node": "18"
  },
  "main": "index.js",
  "dependencies": {
    "firebase-admin": "^12.0.0",
    "firebase-functions": "^4.5.0"
  }
}
```

---

## 🚀 Part 4: Deploy Cloud Functions

### Step 1: Test Locally (Optional)

```bash
# In functions folder
cd functions

# Run emulator (optional)
firebase emulators:start --only functions

# This starts local testing environment
# Keep this running in a separate terminal if testing
```

### Step 2: Deploy to Firebase

```bash
# From project root (e:\smartaid)
cd ..

# Deploy functions
firebase deploy --only functions

# Wait for deployment (2-5 minutes)
# You should see:
# ✔ functions[createStaffUser(us-central1)] Successful create operation.
# ✔ Deploy complete!
```

### Step 3: Verify Deployment

```bash
# List deployed functions
firebase functions:list

# Should show:
# createStaffUser(us-central1)
```

---

## 📱 Part 5: Update Flutter App

### Step 1: Add Cloud Functions Package

Open terminal in project root:

```bash
cd e:\smartaid

# Add cloud_functions package
flutter pub add cloud_functions

# Verify it's added to pubspec.yaml
```

### Step 2: Update auth_service.dart

Open `lib/services/auth_service.dart` and update the `createUser` method:

```dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';  // ← ADD THIS
import 'package:fluttertoast/fluttertoast.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;  // ← ADD THIS

  // ... (keep existing methods) ...

  // REPLACE the old createUser method with this:
  Future<bool> createUser({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String role,
  }) async {
    try {
      // Call Cloud Function instead of creating user directly
      final callable = _functions.httpsCallable('createStaffUser');
      
      final result = await callable.call({
        'email': email,
        'password': password,
        'fullName': fullName,
        'phone': phone,
        'role': role,
      });

      // ✅ Admin stays logged in!
      Fluttertoast.showToast(
        msg: result.data['message'] ?? 'User created successfully',
        toastLength: Toast.LENGTH_SHORT,
      );
      
      return true;
    } on FirebaseFunctionsException catch (e) {
      String message = 'Failed to create user';
      
      switch (e.code) {
        case 'already-exists':
          message = 'This email is already registered';
          break;
        case 'invalid-argument':
          message = e.message ?? 'Invalid input';
          break;
        case 'permission-denied':
          message = 'Only administrators can create users';
          break;
        case 'unauthenticated':
          message = 'You must be logged in';
          break;
        default:
          message = e.message ?? 'An error occurred';
      }
      
      Fluttertoast.showToast(msg: message);
      return false;
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error: ${e.toString()}');
      return false;
    }
  }

  // ... (keep all other existing methods) ...
}
```

### Step 3: Update admin_dashboard.dart

Open `lib/screens/admin_dashboard.dart` and update the create user dialog:

```dart
// In the _showCreateUserDialog method, update the ElevatedButton onPressed:

ElevatedButton(
  onPressed: () async {
    if (formKey.currentState!.validate()) {
      Navigator.pop(context);
      
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
      
      bool success = await _authService.createUser(
        email: emailController.text.trim(),
        password: passwordController.text,
        fullName: nameController.text.trim(),
        phone: phoneController.text.trim(),
        role: selectedRole,
      );
      
      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }
      
      // ✅ If successful, admin stays logged in!
      // ✅ Can create another user immediately!
      if (success && mounted) {
        _loadStatistics(); // Refresh stats
      }
    }
  },
  child: const Text('Create'),
),
```

---

## 🧪 Part 6: Testing

### Step 1: Rebuild App

```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter run
```

### Step 2: Test User Creation

1. **Login as Admin**
   ```
   Email: admin@example.com
   Password: [your admin password]
   ```

2. **Navigate to Admin Dashboard**
   - Click "Create New Staff"

3. **Fill in Details**
   ```
   Full Name: Test User
   Email: test@example.com
   Password: test123
   Phone: +1234567890
   Role: Staff
   ```

4. **Click Create**
   - ✅ Should see: "User created successfully"
   - ✅ Admin should STAY logged in (no signout!)
   - ✅ Statistics should update

5. **Verify in Firebase Console**
   - Go to Authentication → Users
   - Should see the new user
   - Go to Firestore → users collection
   - Should see the new document

### Step 3: Test New User Login

1. **Logout as Admin**
2. **Login as New User**
   ```
   Email: test@example.com
   Password: test123
   ```
3. ✅ Should login successfully
4. ✅ Should see Staff Dashboard

---

## 🔍 Part 7: Troubleshooting

### Issue 1: Function Not Found

**Error:** `Cloud function not found`

**Solution:**
```bash
# Verify deployment
firebase functions:list

# Redeploy if needed
firebase deploy --only functions
```

### Issue 2: Permission Denied

**Error:** `permission-denied`

**Solution:**
- Make sure you're logged in as admin
- Check Firestore rules allow admin to read user documents

### Issue 3: Firebase Functions Not Imported

**Error:** `cloud_functions not found`

**Solution:**
```bash
flutter pub add cloud_functions
flutter pub get
flutter clean
flutter run
```

### Issue 4: CORS Error (Web)

**Error:** `CORS policy` error

**Solution:**
```javascript
// In functions/index.js, add at the top:
const cors = require('cors')({origin: true});

// Wrap your function:
exports.createStaffUser = functions.https.onRequest((req, res) => {
  cors(req, res, async () => {
    // your function code
  });
});
```

### Issue 5: Function Timeout

**Error:** `Function execution took too long`

**Solution:**
```javascript
// In functions/index.js
exports.createStaffUser = functions
  .runWith({ timeoutSeconds: 120 }) // Increase timeout
  .https.onCall(async (data, context) => {
    // your code
  });
```

---

## 💰 Part 8: Cost Monitoring

### Check Usage

```bash
# View function logs
firebase functions:log

# Check usage in Firebase Console
# Go to: Functions → Usage
```

### Free Tier Limits

```
✅ 2,000,000 invocations/month
✅ 400,000 GB-seconds/month
✅ 200,000 GHz-seconds/month
✅ 5GB network egress/month

Your app will likely use:
- 100-1000 invocations/month
- Well within free tier! ✅
```

---

## 🎯 Part 9: Rollback Plan (If Needed)

If something goes wrong, you can easily rollback:

### Step 1: Restore Old createUser Method

In `auth_service.dart`, replace with the old method:

```dart
// Old method (from backup)
Future<bool> createUser({
  required String email,
  required String password,
  required String fullName,
  required String phone,
  required String role,
}) async {
  try {
    UserCredential result = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    User? newUser = result.user;

    if (newUser != null) {
      await _firestore.collection('users').doc(newUser.uid).set({
        'email': email,
        'fullName': fullName,
        'phone': phone,
        'role': role,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': null,
      });

      await _auth.signOut();
      
      Fluttertoast.showToast(
        msg: 'User created! You have been signed out. Please log in again.',
        toastLength: Toast.LENGTH_LONG,
      );
      return true;
    }
    return false;
  } catch (e) {
    Fluttertoast.showToast(msg: 'Error: ${e.toString()}');
    return false;
  }
}
```

### Step 2: Remove cloud_functions

```bash
flutter pub remove cloud_functions
flutter pub get
```

### Step 3: Rebuild

```bash
flutter clean
flutter run
```

---

## 📝 Part 10: Post-Migration Checklist

After successful migration:

- ✅ Test creating multiple users
- ✅ Verify admin stays logged in
- ✅ Test all user roles (admin, staff)
- ✅ Check Firebase console for users
- ✅ Monitor function logs for errors
- ✅ Verify Firestore documents are created
- ✅ Test editing existing users
- ✅ Update documentation
- ✅ Train team on new flow (if applicable)

---

## 🎬 Summary

### Before Migration:
```
Admin creates user → Gets signed out → Must log back in
```

### After Migration:
```
Admin creates user → STAYS LOGGED IN ✅ → Can create more users immediately
```

### Total Time:
- Setup: 30 minutes
- Coding: 30 minutes  
- Testing: 30 minutes
- **Total: ~1-2 hours**

### Benefits:
- ✅ Admin stays logged in
- ✅ Can create multiple users quickly
- ✅ More professional workflow
- ✅ Backend validation
- ✅ Better error handling

### Cost:
- **Still FREE!** ✅ (within Firebase free tier)

---

## 📚 Additional Resources

- [Firebase Cloud Functions Docs](https://firebase.google.com/docs/functions)
- [Admin SDK Documentation](https://firebase.google.com/docs/admin/setup)
- [Cloud Functions for Flutter](https://firebase.flutter.dev/docs/functions/overview)
- [Pricing Calculator](https://firebase.google.com/pricing)

---

## 🆘 Need Help?

If you encounter issues during migration:

1. Check function logs: `firebase functions:log`
2. Review error messages carefully
3. Verify all steps were completed
4. Check Firebase console for deployment status
5. Test in emulator first if possible
6. Rollback if needed (see Part 9)

---

## ✅ Migration Complete!

Once everything works:
1. **Celebrate!** 🎉
2. Document the changes
3. Update team (if applicable)
4. Monitor for the first few days
5. Enjoy the improved workflow!

---

**Remember:** You can do this migration anytime! Your current setup works perfectly, so there's no rush! 🎯

# Recent Updates - Smart Aid App

## Date: November 28, 2025

### Issues Fixed

#### 1. ✅ Button Overflow in Admin Dashboard Statistics
**Problem:** Button was overflowing by 28 pixels in the user statistics section.

**Solution:**
- Adjusted `childAspectRatio` from `1.5` to `1.3` in the GridView
- Reduced padding in stat cards from `16.0` to `12.0`
- Reduced icon size from `36` to `32`
- Reduced font sizes to prevent overflow
- Adjusted spacing between elements

**Files Modified:**
- `lib/screens/admin_dashboard.dart`

---

#### 2. ✅ Added Google Sign-In Functionality
**Problem:** Login page didn't have "Continue with Google" option.

**Solution:**
- Added `google_sign_in: ^6.2.1` package to dependencies
- Implemented `signInWithGoogle()` method in `AuthService`
- Added Google Sign-in button to login screen with proper UI
- Added Google Sign-out in the logout method
- Google Sign-in only works for existing users (staff/admin accounts created by admin)

**Features:**
- Beautiful Google Sign-in button with Google logo
- Proper error handling
- Checks if user exists and is active
- Updates last login timestamp
- Navigates to appropriate dashboard based on role

**Files Modified:**
- `pubspec.yaml` - Added google_sign_in package
- `lib/services/auth_service.dart` - Added signInWithGoogle method
- `lib/screens/login_screen.dart` - Added Google Sign-in button and handler

---

#### 3. ✅ Fixed Permission-Denied Error When Creating Users
**Problem:** When admin created a staff user from the admin dashboard, it threw `cloud-firestore/permission-denied` error.

**Root Cause:**
- Firebase's `createUserWithEmailAndPassword()` automatically signs out the current user (admin) and signs in the newly created user
- The newly created user didn't have admin permissions to write their document to Firestore
- The old Firestore rules only allowed admins to create user documents

**Solution:**
- Updated Firestore security rules to allow users to create their own documents
  ```javascript
  allow create: if isAuthenticated() && (isAdmin() || request.auth.uid == userId);
  ```
- Modified the `createUser()` method to:
  1. Create the user in Firebase Auth (new user gets auto-signed in)
  2. Create the Firestore document (new user can now create their own document)
  3. Sign out the new user
  4. Show message that user was created and admin needs to log back in
- The `AuthWrapper` automatically redirects to login screen when admin is signed out
- Added loading dialog during user creation

**Files Modified:**
- `firestore.rules` - Updated user creation rules
- `lib/services/auth_service.dart` - Simplified createUser method with better flow
- `lib/screens/admin_dashboard.dart` - Added loading dialog and better UX

**Note:** After creating a user, the admin will be signed out and will need to log back in. This is a Firebase limitation when not using Firebase Admin SDK.

---

### Testing Checklist

- [ ] Test admin dashboard statistics display without overflow
- [ ] Test Google Sign-in with existing admin account
- [ ] Test Google Sign-in with existing staff account
- [ ] Test Google Sign-in with non-existent account (should fail gracefully)
- [ ] Test creating a new staff user from admin dashboard
- [ ] Test creating a new admin user from admin dashboard
- [ ] Verify admin is redirected to login screen after creating user
- [ ] Verify newly created user can login successfully
- [ ] Test that inactive users cannot login via Google Sign-in
- [ ] Test email/password login still works

---

### Configuration Required

#### For Google Sign-In to work properly:

1. **Firebase Console Configuration:**
   - Go to Firebase Console > Authentication > Sign-in method
   - Enable Google as a sign-in provider
   - Configure OAuth consent screen

2. **Android Configuration:**
   - Get SHA-1 certificate fingerprint: `cd android && ./gradlew signingReport`
   - Add SHA-1 to Firebase Console > Project Settings > Your apps
   - Download and replace `google-services.json`

3. **iOS Configuration:**
   - Add reversed client ID to Info.plist:
     ```xml
     <key>CFBundleURLTypes</key>
     <array>
       <dict>
         <key>CFBundleTypeRole</key>
         <string>Editor</string>
         <key>CFBundleURLSchemes</key>
         <array>
           <string>YOUR_REVERSED_CLIENT_ID</string>
         </array>
       </dict>
     </array>
     ```
   - Download and replace `GoogleService-Info.plist`

---

### Known Behavior

1. **Admin Sign-out After User Creation:**
   - This is expected behavior due to Firebase Auth limitations
   - To avoid this, would need to implement Firebase Admin SDK or Cloud Functions
   - Current solution is simpler and works well for the use case

2. **Google Sign-In Restrictions:**
   - Only existing users (created by admin) can sign in with Google
   - New users cannot self-register via Google Sign-in
   - This is by design for security and user management

---

### Dependencies Added

```yaml
google_sign_in: ^6.2.1
```

Run `flutter pub get` to install (already done).

---

### Firestore Rules Updated

Deployed to Firebase on November 28, 2025.

---

### Future Improvements

1. **User Creation Without Sign-Out:**
   - Implement Firebase Cloud Functions for user creation
   - Use Firebase Admin SDK
   - This would allow admins to create users without being signed out

2. **Google Sign-In Logo:**
   - Consider adding Google logo as a local asset instead of loading from network
   - This would work better offline and load faster

3. **Batch User Creation:**
   - Add ability to create multiple users at once
   - Import users from CSV file

---

### Support

If you encounter any issues:
1. Make sure Firebase rules are deployed: `firebase deploy --only firestore:rules`
2. Check Firebase Console for authentication errors
3. Verify Google Sign-in is enabled in Firebase Console
4. Check that SHA-1 fingerprint is added for Android






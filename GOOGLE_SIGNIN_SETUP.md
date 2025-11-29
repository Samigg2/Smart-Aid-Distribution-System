# Google Sign-In Setup Guide - Smart Aid App

## Prerequisites
- Flutter app with Firebase already configured
- Firebase project created
- google_sign_in package installed ✅ (already done)

---

## Step 1: Enable Google Sign-In in Firebase Console

### 1.1 Go to Firebase Console
1. Open your browser and go to: https://console.firebase.google.com
2. Select your project: **smartaid-aef0b**

### 1.2 Navigate to Authentication
1. Click on **"Authentication"** in the left sidebar
2. Click on the **"Sign-in method"** tab at the top

### 1.3 Enable Google Provider
1. Find **"Google"** in the list of sign-in providers
2. Click on **"Google"**
3. Toggle the **"Enable"** switch to ON
4. You'll see two fields:
   - **Public-facing name for project**: `Smart Aid` (or your app name)
   - **Project support email**: Select your email from the dropdown
5. Click **"Save"**

✅ **Done!** Google Sign-in is now enabled on the backend.

---

## Step 2: Get SHA-1 Fingerprint for Android

### 2.1 What is SHA-1?
SHA-1 is a unique fingerprint of your app's signing certificate. Firebase needs this to verify that Google Sign-in requests are coming from your legitimate app.

### 2.2 Get Debug SHA-1 (for testing)

**Option A: Using Android Studio (Easiest)**
1. Open Android Studio
2. Open your project
3. On the right side, click **"Gradle"** tab
4. Navigate to: `smartaid > android > Tasks > android > signingReport`
5. Double-click `signingReport`
6. Wait for the task to complete
7. In the "Run" console at the bottom, look for:
   ```
   Variant: debug
   Config: debug
   Store: C:\Users\samuel\.android\debug.keystore
   Alias: AndroidDebugKey
   MD5: XX:XX:XX...
   SHA1: A1:B2:C3:D4:E5:F6:...  ← COPY THIS!
   SHA-256: XX:XX:XX...
   ```
8. Copy the **SHA1** value

**Option B: Using Command Line**
```bash
# Navigate to android folder
cd android

# Windows PowerShell
./gradlew signingReport

# Look for the SHA1 under "Variant: debug"
```

**Option C: Using keytool (Alternative)**
```bash
# Windows
keytool -list -v -keystore C:\Users\samuel\.android\debug.keystore -alias androiddebugkey -storepass android -keypass android

# Look for "SHA1:" in the output
```

### 2.3 Get Release SHA-1 (for production)
When you're ready to publish to Play Store:

```bash
# If you have a release keystore
keytool -list -v -keystore YOUR_RELEASE_KEYSTORE.jks -alias YOUR_ALIAS
```

---

## Step 3: Add SHA-1 to Firebase

### 3.1 Add the Fingerprint
1. In Firebase Console, click the **gear icon** ⚙️ next to "Project Overview"
2. Click **"Project settings"**
3. Scroll down to **"Your apps"** section
4. Find your Android app (package name: `com.example.firs_app` or similar)
5. Scroll down to **"SHA certificate fingerprints"**
6. Click **"Add fingerprint"**
7. Paste your SHA-1 fingerprint
8. Click **"Save"**

### 3.2 Download New google-services.json
1. After adding SHA-1, click **"Download google-services.json"**
2. Replace the old file at: `android/app/google-services.json`
3. **Important:** Make sure to replace it!

---

## Step 4: Configure OAuth Consent Screen

### 4.1 Why is this needed?
When users click "Sign in with Google", they see a consent screen. You need to configure what information it shows.

### 4.2 Access Google Cloud Console
1. In Firebase Console, go to **Project settings** (gear icon)
2. Click on **"Service accounts"** tab
3. Click **"Manage service account permissions"**
   - OR directly go to: https://console.cloud.google.com
4. Select your project: **smartaid-aef0b**

### 4.3 Configure OAuth Consent Screen
1. In Google Cloud Console, go to: **APIs & Services > OAuth consent screen**
   - Or use this link: https://console.cloud.google.com/apis/credentials/consent
2. Choose **"External"** (if asked) and click **"Create"**
3. Fill in the **App Information**:
   ```
   App name: Smart Aid
   User support email: [your email]
   App logo: (optional - upload your app icon)
   ```
4. **App domain** (optional but recommended):
   ```
   Application home page: (optional)
   Application privacy policy link: (optional)
   Application terms of service link: (optional)
   ```
5. **Developer contact information**:
   ```
   Email addresses: [your email]
   ```
6. Click **"Save and Continue"**

### 4.4 Scopes (Step 2)
1. Click **"Add or Remove Scopes"**
2. Select these scopes (should be pre-selected):
   - `./auth/userinfo.email`
   - `./auth/userinfo.profile`
   - `openid`
3. Click **"Update"**
4. Click **"Save and Continue"**

### 4.5 Test Users (Step 3)
1. Click **"Add Users"**
2. Add your test email addresses (the ones you'll use to test)
3. Click **"Save and Continue"**

### 4.6 Summary
1. Review the summary
2. Click **"Back to Dashboard"**

✅ **Done!** OAuth consent screen is configured.

---

## Step 5: Test Google Sign-In

### 5.1 Run the App
```bash
# Make sure you've installed dependencies
flutter pub get

# Run on your Android device/emulator
flutter run
```

### 5.2 Test the Flow
1. Open the app
2. On the login screen, click **"Continue with Google"**
3. Select your Google account
4. If prompted, allow permissions
5. **Expected behavior**:
   - ✅ If account exists in Firestore → Signs in successfully
   - ❌ If account doesn't exist → Shows error: "No account found. Please contact admin..."

### 5.3 Create Test Account
1. Log in as admin (email/password)
2. Go to Admin Dashboard
3. Click **"Create New Staff"**
4. Enter details using **the same email as your Google account**
5. Create the user
6. Log back in as admin
7. Now try Google Sign-in again → Should work! ✅

---

## Step 6: iOS Setup (If you plan to support iOS)

### 6.1 Get iOS Client ID
1. Firebase Console > Project Settings > Your apps
2. Find your iOS app
3. Copy the **iOS URL scheme** (starts with `com.googleusercontent.apps`)

### 6.2 Update Info.plist
1. Open `ios/Runner/Info.plist`
2. Add this before the last `</dict>`:

```xml
<!-- Google Sign-In -->
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleTypeRole</key>
    <string>Editor</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <!-- Paste your REVERSED_CLIENT_ID here -->
      <string>com.googleusercontent.apps.123456789-abcdefgh</string>
    </array>
  </dict>
</array>
```

3. Replace with your actual REVERSED_CLIENT_ID from Firebase

---

## Troubleshooting

### Error: "PlatformException(sign_in_failed)"
**Solution:**
- Make sure SHA-1 is added correctly
- Download new `google-services.json` after adding SHA-1
- Uninstall app and reinstall: `flutter clean && flutter run`

### Error: "Developer Error"
**Solution:**
- OAuth consent screen not configured properly
- Go back to Google Cloud Console and complete OAuth setup

### Error: "API not enabled"
**Solution:**
```bash
# Enable Google Sign-In API
# Go to: https://console.cloud.google.com/apis/library/
# Search for: "Google Sign-In API"
# Click "Enable"
```

### Google Sign-In works but shows "No account found"
**Solution:**
- This is expected! Google Sign-in only works for existing users
- Admin must first create the user account with that email
- Then the user can sign in with Google

### SHA-1 not found in signingReport
**Solution:**
```bash
# Make sure you're in the android directory
cd android

# Clean and try again
./gradlew clean
./gradlew signingReport
```

---

## Summary Checklist

- [ ] Enable Google Sign-in in Firebase Console
- [ ] Get SHA-1 fingerprint using `./gradlew signingReport`
- [ ] Add SHA-1 to Firebase Project Settings
- [ ] Download new `google-services.json`
- [ ] Configure OAuth consent screen in Google Cloud Console
- [ ] Add test users to OAuth consent screen
- [ ] Run `flutter clean && flutter pub get`
- [ ] Test Google Sign-in
- [ ] Create staff account via admin dashboard
- [ ] Test Google Sign-in with created account

---

## Quick Commands Reference

```bash
# Get SHA-1 fingerprint
cd android
./gradlew signingReport

# Clean and rebuild
flutter clean
flutter pub get
flutter run

# Uninstall and reinstall (if needed)
adb uninstall com.example.firs_app
flutter run
```

---

## Important Notes

1. **For Development**: Use debug SHA-1
2. **For Production**: Get release SHA-1 from your release keystore
3. **Both SHA-1s**: You can add both debug and release SHA-1 to Firebase
4. **Google Account**: The Google account email must match an existing user in your Firestore database
5. **Offline Testing**: Google Sign-in requires internet connection

---

## Need Help?

Common issues and solutions:
- **SHA-1 issues**: Make sure you copied the complete SHA-1 (includes colons)
- **OAuth errors**: Complete all steps in OAuth consent screen
- **API errors**: Enable "Google Sign-In API" in Google Cloud Console
- **No account found**: Admin must create user first with that email

Firebase Auth Documentation: https://firebase.google.com/docs/auth/android/google-signin
Flutter Google Sign-In Package: https://pub.dev/packages/google_sign_in



# Smart Aid Distribution - Firebase Setup Guide

This guide will help you set up Firebase for your Smart Aid Distribution app.

## Prerequisites

- Flutter SDK installed
- Firebase account (free tier is sufficient)
- Node.js installed (for Firebase CLI)

## Step 1: Install Flutter Dependencies

Run the following command in your project directory:

```bash
flutter pub get
```

## Step 2: Install Firebase CLI and FlutterFire CLI

```bash
# Install Firebase CLI
npm install -g firebase-tools

# Install FlutterFire CLI
dart pub global activate flutterfire_cli
```

## Step 3: Login to Firebase

```bash
firebase login
```

## Step 4: Create a Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project"
3. Enter project name: "smart-aid-distribution" (or your preferred name)
4. Disable Google Analytics (optional for this app)
5. Click "Create project"

## Step 5: Configure FlutterFire

Run this command in your project directory:

```bash
flutterfire configure
```

This will:
- Prompt you to select your Firebase project
- Automatically register your Flutter app
- Generate `firebase_options.dart` file
- Configure Android and iOS apps

Select the platforms you want to support (Android/iOS/Web).

## Step 6: Enable Firebase Authentication

1. Go to Firebase Console > Your Project
2. Click "Authentication" in the left sidebar
3. Click "Get started"
4. Click "Sign-in method" tab
5. Enable "Email/Password" provider
6. Click "Save"

## Step 7: Enable Cloud Firestore

1. Go to Firebase Console > Your Project
2. Click "Firestore Database" in the left sidebar
3. Click "Create database"
4. Select "Start in production mode"
5. Choose your Firestore location (choose closest to your users)
6. Click "Enable"

## Step 8: Deploy Firestore Security Rules

The project includes a `firestore.rules` file with security rules. Deploy it:

```bash
firebase init firestore
```

- Select your Firebase project
- Accept the default `firestore.rules` file path
- Accept the default `firestore.indexes.json` file path

Then deploy:

```bash
firebase deploy --only firestore:rules
```

## Step 9: Create the First Admin Account

Since staff accounts are created by admins, you need to manually create the first admin account:

### Option A: Using Firebase Console (Recommended for First Admin)

1. Go to Firebase Console > Authentication > Users
2. Click "Add user"
3. Enter email: `admin@example.com` (use your email)
4. Enter password: (choose a strong password)
5. Click "Add user"
6. Copy the User UID (you'll need it)

7. Go to Firestore Database
8. Click "Start collection"
9. Collection ID: `users`
10. Document ID: (paste the User UID you copied)
11. Add fields:
    - `email` (string): your admin email
    - `fullName` (string): your full name
    - `phone` (string): your phone number
    - `role` (string): `admin`
    - `isActive` (boolean): `true`
    - `createdAt` (timestamp): click "Insert value" > "timestamp" > select current date/time
    - `lastLogin` (timestamp): leave null or add current timestamp
12. Click "Save"

### Option B: Using Firebase CLI (Alternative)

Create a script to add the admin user. See `create_admin.js` example.

## Step 10: Test the Application

1. Run your Flutter app:

```bash
flutter run
```

2. Login with your admin credentials
3. You should see the Admin Dashboard
4. Create a staff account from the Admin Dashboard

## Firestore Database Structure

```
users/
  {userId}/
    - email: string
    - fullName: string
    - phone: string
    - role: string ('admin' | 'staff')
    - isActive: boolean
    - createdAt: timestamp
    - lastLogin: timestamp
```

## Security Rules Summary

- **Admins** can:
  - Read all user data
  - Create, update, and delete any user
  - Access all application features

- **Staff** can:
  - Read their own user data
  - Update their own profile (except role and isActive)
  - Access assigned features

## Troubleshooting

### Firebase Initialization Error

If you see "Firebase not initialized" error:
1. Make sure `flutterfire configure` ran successfully
2. Check that `firebase_options.dart` exists in `lib/`
3. Restart your app

### Authentication Errors

If login fails:
1. Check that Email/Password auth is enabled in Firebase Console
2. Verify the user exists in Authentication > Users
3. Check the user's data exists in Firestore > users collection

### Permission Denied Errors

If you see "permission-denied" errors:
1. Verify Firestore security rules are deployed
2. Check that the user's role is correctly set in Firestore
3. Ensure the user's `isActive` field is `true`

## Next Steps

1. ✅ Test admin login
2. ✅ Create staff accounts from Admin Dashboard
3. ✅ Test staff login
4. 🔄 Implement beneficiary registration (coming soon)
5. 🔄 Add more features as needed

## Important Security Notes

- Never share your Firebase project credentials
- Use strong passwords for all accounts
- Regularly review your Firestore security rules
- Monitor Firebase usage in the Console
- Set up billing alerts to avoid unexpected charges

## Support

If you encounter issues:
1. Check Flutter and Firebase documentation
2. Verify all steps were completed correctly
3. Check Firebase Console for errors
4. Review app logs for error messages

---

**Your Smart Aid Distribution app is now ready to use!**


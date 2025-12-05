# 🚀 Firebase Setup - Copy & Paste Commands

## Quick Setup (5-10 minutes)

Copy and paste these commands one by one:

### Step 1: Install Tools
```bash
# Install Firebase CLI
npm install -g firebase-tools

# Install FlutterFire CLI
dart pub global activate flutterfire_cli
```
### Step 2: Login to Firebase
```bash
firebase login
```
- Your browser will open
- Login with your Google account
- Return to terminal

### Step 3: Configure Firebase
```bash
flutterfire configure
```
- Select "Create a new project" or choose existing
- Name it: `smart-aid-distribution`
- Select platforms (Android, iOS, etc.)
- This generates `firebase_options.dart` automatically

### Step 4: Initialize Firestore
```bash
firebase init firestore
```
- Select your project
- Press Enter to accept `firestore.rules`
- Press Enter to accept `firestore.indexes.json`

### Step 5: Deploy Security Rules
```bash
firebase deploy --only firestore:rules
```

## ✅ Setup Complete!

Now go to Firebase Console to:
1. Enable Authentication (Email/Password)
2. Enable Firestore Database
3. Create first admin account

**Firebase Console**: https://console.firebase.google.com

---

## Create First Admin (Firebase Console)

### Part 1: Create Auth User
1. Go to: **Authentication** → **Users**
2. Click: **Add user**
3. Email: `admin@yourdomain.com`
4. Password: `YourSecurePassword123`
5. Click: **Add user**
6. **COPY THE USER UID** (important!)

### Part 2: Create Firestore Document
1. Go to: **Firestore Database**
2. Click: **Start collection**
3. Collection ID: `users`
4. Document ID: *paste the UID you copied*
5. Add fields (click "Add field" for each):

| Field | Type | Value |
|-------|------|-------|
| email | string | admin@yourdomain.com |
| fullName | string | Admin User |
| phone | string | +1234567890 |
| role | string | admin |
| isActive | boolean | true |
| createdAt | timestamp | *click timestamp button, select now* |
| lastLogin | timestamp | *leave as null* |

6. Click: **Save**

---

## Test Your App

```bash
flutter run
```

Login with:
- Email: `admin@yourdomain.com`
- Password: `YourSecurePassword123`

You should see the **Admin Dashboard**! 🎉

---

## If Something Goes Wrong

### Firebase not found?
```bash
flutterfire configure
flutter clean
flutter pub get
flutter run
```

### Permission denied?
```bash
firebase deploy --only firestore:rules
```

### User data not found?
- Check Firestore document exists
- Document ID must match Auth UID
- All fields must be present

---

## Quick Reference URLs

- **Firebase Console**: https://console.firebase.google.com
- **Flutter Firebase Docs**: https://firebase.flutter.dev
- **Firebase CLI Docs**: https://firebase.google.com/docs/cli

---

**That's it! Your app should now be fully functional.**


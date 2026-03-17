Smart Aid Distribution
A Flutter web and mobile app we built for managing humanitarian aid distribution with intelligent beneficiary prioritization.

📱 Overview
We created this app to help aid organizations register beneficiaries, figure out who needs help the most, and track distributions. It works offline on mobile (super important for field work) and syncs when you're back online. The web version is perfect for office work - admins can manage everything from a desktop browser.

✨ What It Does
Beneficiary Management - Register people with photos, GPS location, and vulnerability info

Priority Scoring - Automatically calculates who needs aid most urgently

Distribution Programs - Create and manage aid programs with budgets

QR Code System - Each beneficiary gets a scannable code for quick lookup

Reports & Export - Export data to Excel for reporting

User Roles - Admins and staff have different permissions

🛠️ Built With
Flutter + Riverpod (state management) - runs on web and mobile from same codebase

Firebase (Auth + Firestore)

Cloudinary (image storage)

QR code generation + scanning

📸 App Screenshots (14 Screens)
Here's a complete tour of the app (works same on web and mobile):

<div align="center">
1. Login Page	2. Admin Dashboard	3. Beneficiary Form (Page 1)
<img src="diagrams/login.jpg" width="250" alt="Login screen">	<img src="diagrams/dashboard.jpg" width="250" alt="Admin dashboard">	<img src="diagrams/beneficiary_form1.jpg" width="250" alt="Beneficiary form page 1">
4. Beneficiary Form (Page 2)	5. Beneficiary Form (Page 3)	6. Beneficiary Form (Page 4)
<img src="diagrams/beneficiary_form2.jpg" width="250" alt="Beneficiary form page 2">	<img src="diagrams/beneficiary_form3.jpg" width="250" alt="Beneficiary form page 3">	<img src="diagrams/beneficiary_form4.jpg" width="250" alt="Beneficiary form page 4">
7. Beneficiary QR Code	8. Distribution Programs	9. Program Details
<img src="diagrams/qr_code.jpg" width="250" alt="QR code">	<img src="diagrams/programs_list.jpg" width="250" alt="Programs list">	<img src="diagrams/program_details.jpg" width="250" alt="Program details">
10. Distributed List	11. User Management	12. Reports Page
<img src="diagrams/distributions.jpg" width="250" alt="Distributions">	<img src="diagrams/user_management.jpg" width="250" alt="User management">	<img src="diagrams/reports.jpg" width="250" alt="Reports">
13. Export Screen	14. [Your 14th screen]	
<img src="diagrams/export.jpg" width="250" alt="Export">	<img src="diagrams/screen14.jpg" width="250" alt="Screen 14">	
</div>
🚀 Getting Started
Prerequisites
Flutter SDK (^3.9.2)

Firebase project

Cloudinary account (free tier works)

Quick Setup
Clone and install

bash
git clone <your-repo>
cd smartaid
flutter pub get
Environment variables

bash
cp .env.example .env
# Add your Cloudinary and API keys
Firebase setup

Create project at Firebase Console

Enable Email/Password auth

Set up Firestore

Download config files

Run flutterfire configure

Run it

bash
# For mobile
flutter run

# For web
flutter run -d chrome
📁 Project Structure (how we organized it)
text
lib/
├── screens/     # All UI screens (login, dashboard, forms, etc)
├── widgets/     # Reusable buttons, cards, etc
├── models/      # Data classes
├── providers/   # Riverpod state
├── services/    # Firebase, API calls
├── utils/       # Helper functions
└── config/      # Environment configs
🧪 Testing
bash
flutter test
📱 Works On
✅ Android (main target for field workers)

✅ iOS (works great)

✅ Web (perfect for office/admin work)

⚠️ Windows (most features work)

🤝 Contributing
Found a bug? Want to add something? PRs welcome!

Fork it

Create branch (git checkout -b feature/cool-stuff)

Commit (git commit -m 'Added cool stuff')

Push (git push origin feature/cool-stuff)

Open PR

📄 License
Private project for now.

---

# Smart Aid Distribution

A **Flutter web and mobile application** for managing humanitarian aid distribution with intelligent beneficiary prioritization.

---

# Overview

Smart Aid Distribution helps aid organizations:

* Register beneficiaries
* Prioritize the most vulnerable people
* Track aid distributions
* Manage programs and reporting

The system supports **offline mobile usage**, which is critical for field workers. Data automatically **syncs when internet becomes available**.

The **web version** is designed for administrators to manage operations from a desktop browser.

---

# Features

### Beneficiary Management

Register beneficiaries with:

* Photos
* GPS location
* Vulnerability information

### Priority Scoring

Automatically calculates **who should receive aid first** based on vulnerability factors.

### Distribution Programs

Create and manage aid programs with budgets and beneficiary lists.

### QR Code System

Each beneficiary receives a **unique QR code** for fast identification during aid distribution.

### Reports & Data Export

Export distribution data to **Excel for reporting and auditing**.

### User Roles

Different permissions for:

* Admin users
* Field staff

---

# Technology Stack

| Technology     | Purpose                                   |
| -------------- | ----------------------------------------- |
| Flutter        | Cross-platform mobile and web development |
| Riverpod       | State management                          |
| Firebase Auth  | User authentication                       |
| Firestore      | Database                                  |
| Cloudinary     | Image storage                             |
| QR Code System | Beneficiary identification                |

---

# Application Screenshots

| Login                                      | Admin Dashboard                            | Beneficiary Form (Page 1)                |
| ------------------------------------------ | ------------------------------------------ | ---------------------------------------- |
| <img src="diagrams/login.jpg" width="250"> | <img src="diagrams/admin.jpg" width="250"> | <img src="diagrams/fr1.jpg" width="250"> |

| Beneficiary Form (Page 2)                | Beneficiary Form (Page 3)                | Beneficiary Form (Page 4)                |
| ---------------------------------------- | ---------------------------------------- | ---------------------------------------- |
| <img src="diagrams/fr2.jpg" width="250"> | <img src="diagrams/fr3.jpg" width="250"> | <img src="diagrams/fr4.jpg" width="250"> |

| User Management                           | QR Code Generation                          | QR Code Scan                            |
| ----------------------------------------- | ------------------------------------------- | --------------------------------------- |
| <img src="diagrams/user.jpg" width="250"> | <img src="diagrams/qrcode.jpg" width="250"> | <img src="diagrams/qr.jpg" width="250"> |

| Export Screen                               | Distributed List                                 | Program Details                              |
| ------------------------------------------- | ------------------------------------------------ | -------------------------------------------- |
| <img src="diagrams/export.jpg" width="250"> | <img src="diagrams/destributed.jpg" width="250"> | <img src="diagrams/details.jpg" width="250"> |

| Distribution Programs                         |
| --------------------------------------------- |
| <img src="diagrams/programs.jpg" width="250"> |

---

# Getting Started

## Prerequisites

* Flutter SDK **^3.9.2**
* Firebase project
* Cloudinary account *(free tier works)*

---

# Installation

### 1. Clone the Repository

```bash
git clone <your-repo>
cd smartaid
flutter pub get
```

### 2. Environment Variables

```bash
cp .env.example .env
```

Add your **Cloudinary credentials and API keys** inside `.env`.

---

### 3. Firebase Setup

1. Create a project in **Firebase Console**
2. Enable **Email/Password Authentication**
3. Create a **Firestore Database**
4. Download configuration files
5. Run:

```bash
flutterfire configure
```

---

# Run the Application

### Mobile

```bash
flutter run
```

### Web

```bash
flutter run -d chrome
```

---

# Project Structure

```
lib/
├── screens/      # UI screens (login, dashboard, forms)
├── widgets/      # Reusable components
├── models/       # Data models
├── providers/    # Riverpod state management
├── services/     # Firebase and API services
├── utils/        # Helper utilities
└── config/       # Environment configurations
```

---

# Testing

Run automated tests:

```bash
flutter test
```

---

# Platform Support

| Platform | Status                          |
| -------- | ------------------------------- |
| Android  | ✅ Main target for field workers |
| iOS      | ✅ Fully supported               |
| Web      | ✅ Ideal for admin use           |
| Windows  | ⚠️ Most features supported      |

---

# License

Private project.

---

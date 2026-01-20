# Smart Aid Distribution

A Flutter-based mobile and web application for managing humanitarian aid distribution with intelligent priority classification and beneficiary management.

## 📱 Overview

Smart Aid Distribution is a comprehensive solution for managing aid distribution programs. It helps organizations efficiently register beneficiaries, classify them based on vulnerability criteria, create distribution programs, and track aid distribution records.

### Key Features

- **Beneficiary Management**
  - Comprehensive beneficiary registration with photo capture
  - Multiple vulnerable category classification (pregnant women, lactating mothers, children under 5, elderly, disabled, chronically ill)
  - Location tracking with GPS coordinates
  - QR code generation for easy beneficiary identification

- **Priority Classification**
  - AI-powered priority scoring (optional)
  - Rule-based vulnerability assessment
  - Automatic urgency score calculation

- **Distribution Program Management**
  - Create and manage distribution programs
  - Target specific vulnerable categories
  - Track budgets and beneficiary limits
  - Program status management (draft, active, paused, completed, cancelled)

- **Distribution Tracking**
  - Record aid distributions
  - Link distributions to beneficiaries and programs
  - QR code scanning for quick beneficiary lookup
  - Comprehensive distribution history

- **User Management**
  - Role-based access control (Admin/Staff)
  - User authentication with Firebase Auth
  - User activity tracking

- **Data Export**
  - Export beneficiary and distribution data
  - Excel/CSV format support
  - Offline data access

- **Offline Support**
  - Firebase Firestore offline persistence
  - Works without internet connection
  - Automatic data synchronization

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (^3.9.2 or higher)
- Dart SDK
- Firebase project with Firestore enabled
- Cloudinary account (for photo storage)
- (Optional) Priority AI API access

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd smartaid
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Set up environment variables**
   
   Create a `.env` file in the root directory (see `.env.example` for template):
   ```bash
   cp .env.example .env
   ```
   
   Edit `.env` with your credentials:
   ```env
   CLOUDINARY_CLOUD_NAME=your_cloud_name
   CLOUDINARY_API_KEY=your_api_key
   CLOUDINARY_API_SECRET=your_api_secret
   PRIORITY_AI_BASE_URL=https://your-api-url.com (optional)
   PRIORITY_AI_API_KEY=your_api_key (optional)
   ```

   For detailed setup instructions, see [SETUP_ENV.md](SETUP_ENV.md)

4. **Configure Firebase**
   
   - Create a Firebase project at [Firebase Console](https://console.firebase.google.com/)
   - Enable Authentication (Email/Password)
   - Enable Firestore Database
   - Add your app to Firebase and download `google-services.json` (Android) or `GoogleService-Info.plist` (iOS)
   - Run `flutterfire configure` to generate Firebase configuration files

5. **Run the application**
   ```bash
   flutter run
   ```

## 📁 Project Structure

```
lib/
├── config/          # Configuration files (env, app config)
├── models/          # Data models
├── providers/       # Riverpod providers for state management
├── screens/         # UI screens
├── services/        # Business logic services
├── utils/           # Utility functions and validators
└── widgets/         # Reusable widgets
```

## 🛠️ Technology Stack

- **Framework**: Flutter (Dart)
- **State Management**: Riverpod
- **Backend**: Firebase (Firestore, Authentication)
- **Image Storage**: Cloudinary
- **Location Services**: Geolocator
- **QR Code**: qr_flutter, mobile_scanner
- **Environment Variables**: flutter_dotenv

## 🧪 Testing

Run tests with:
```bash
flutter test
```

For test coverage:
```bash
flutter test --coverage
```

See [TESTING_SETUP.md](TESTING_SETUP.md) for detailed testing guidelines.

## 📱 Platform Support

- ✅ Android
- ✅ iOS
- ✅ Web
- ✅ Windows (partial)
- ✅ Linux (partial)
- ✅ macOS (partial)

## 🔒 Security

- Environment variables for sensitive API keys
- Firebase Security Rules for data access control
- Role-based access control (RBAC)
- Secure storage for offline credentials
- Input validation and sanitization

## 📖 Documentation

- [SETUP_ENV.md](SETUP_ENV.md) - Environment setup guide
- [TESTING_SETUP.md](TESTING_SETUP.md) - Testing documentation
- [PROJECT_DEFENSE_TECHNICAL_ANALYSIS.md](PROJECT_DEFENSE_TECHNICAL_ANALYSIS.md) - Technical analysis

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📝 Code Style

This project follows Dart/Flutter best practices:
- Use meaningful variable and function names
- Keep functions short and focused
- Follow SOLID principles
- Write unit tests for business logic
- Document complex code sections

## 🐛 Known Issues

- Some features may require internet connection for first-time setup
- QR code scanning works best on mobile devices
- Large beneficiary lists may require pagination for optimal performance

## 📄 License

This project is private and proprietary.

## 👥 Authors

Smart Aid Development Team

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Firebase for backend services
- Cloudinary for image storage
- All open-source contributors

---

**Note**: This application is designed for humanitarian aid organizations. Ensure compliance with data protection regulations (GDPR, local privacy laws) when handling beneficiary information.


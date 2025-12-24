# KandLink Mobile App

A comprehensive mobile application for KandLink communication platform connecting candidates with PICs (Person In Charge).

## 🚀 Features

- **Real-time Chat**: Personal and group messaging with Socket.IO
- **Push Notifications**: Firebase-powered notifications
- **Offline Support**: Message synchronization when offline
- **File Sharing**: Multi-format file upload/download
- **Role-based Access**: Separate interfaces for Candidates and PICs
- **Area Selection**: Location-based PIC assignment using Round Robin algorithm

## 🛠️ Setup Instructions

### Prerequisites
- Flutter 3.x
- Dart 3.x
- Android Studio / VS Code
- Android/iOS device or emulator

### Firebase Setup (Required for Production)

1. **Create Firebase Project:**
   - Go to [Firebase Console](https://console.firebase.google.com/)
   - Create a new project called "kandlink"

2. **Android Configuration:**
   - Download `google-services.json` from Firebase Console
   - Place it in `android/app/google-services.json`
   - Update Firebase options in `lib/main.dart` with real values

3. **iOS Configuration:**
   - Download `GoogleService-Info.plist` from Firebase Console
   - Place it in `ios/Runner/GoogleService-Info.plist`

4. **Enable Services:**
   - **Authentication**: Email/Password
   - **Firestore Database**: For user data
   - **Cloud Messaging**: For push notifications
   - **Storage**: For file uploads

### Development Setup (Without Firebase)

The app includes dummy Firebase configuration for development testing. For full functionality, complete Firebase setup above.

## 🏃‍♂️ Running the App

```bash
# Install dependencies
flutter pub get

# Run on Android
flutter run

# Run on iOS (macOS only)
flutter run --ios

# Run tests
flutter test
```

## 📱 App Architecture

### Tech Stack
- **Framework**: Flutter 3.x
- **Language**: Dart 3.x
- **State Management**: Provider (MVVM)
- **Database**: Drift SQLite (local storage)
- **Real-time**: Socket.IO
- **Notifications**: Firebase + Local Notifications
- **Navigation**: GoRouter

### Project Structure
```
lib/
├── core/
│   ├── config/          # App configuration
│   ├── constants/       # API endpoints, constants
│   ├── database/        # Drift database schema
│   ├── models/          # Data models (Freezed)
│   ├── providers/       # State management
│   ├── services/        # Business logic
│   └── utils/           # Helper utilities
├── ui/
│   ├── router/          # App navigation
│   ├── screens/         # UI screens
│   ├── widgets/         # Reusable widgets
│   └── theme/           # App theming
└── main.dart            # App entry point
```

## 🔧 Development Commands

```bash
# Generate database code
flutter pub run build_runner build

# Generate models and serialization
flutter pub run build_runner build --delete-conflicting-outputs

# Clean and rebuild
flutter clean && flutter pub get && flutter run
```

## 📋 Features Overview

### Authentication
- Email/password registration
- WhatsApp verification
- JWT token management
- Secure local storage

### Chat System
- Real-time messaging with Socket.IO
- Personal and group conversations
- Message persistence with SQLite
- Typing indicators and read receipts

### User Roles
- **Candidates**: Area selection, PIC communication
- **PICs**: Candidate management, group creation
- Role-based UI and permissions

### Offline Support
- Message queuing when offline
- Automatic sync when online
- Local data persistence

### File Sharing
- Image, PDF, document upload
- File compression and optimization
- Secure file handling

## 🔒 Security Features

- JWT token authentication
- Secure local storage (encrypted)
- API request/response encryption
- Role-based access control
- Input validation and sanitization

## 📊 Performance

- Lazy loading for large lists
- Efficient database queries
- Image caching and optimization
- Background task processing
- Memory management optimization

## 🧪 Testing

The app includes comprehensive testing setup:
- Unit tests for services and providers
- Integration tests for API calls
- Widget tests for UI components
- End-to-end testing capabilities

## 🚀 Deployment

### Android
```bash
flutter build apk --release
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
```

### Code Signing
- Configure signing certificates in respective stores
- Update app identifiers and provisioning profiles

## 📞 Support

For issues and questions:
- Check existing GitHub issues
- Create new issue with detailed description
- Include device/emulator logs
- Specify Flutter version and platform

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

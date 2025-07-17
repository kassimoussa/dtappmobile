# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Flutter mobile application for DT Mobile (Djibouti Telecom) that provides telecommunication services including:
- Phone number authentication via OTP
- Balance checking and management
- Forfait (package) purchasing and management
- Money transfers and credit transfers
- USSD code integration for telecom operations

## Development Commands

### Flutter Commands
```bash
# Install dependencies
flutter pub get

# Run the app in debug mode
flutter run

# Build for Android
flutter build apk

# Build for iOS
flutter build ios

# Run tests
flutter test

# Analyze code
flutter analyze

# Format code
dart format .
```

### Linting and Code Quality
The project uses `flutter_lints` for code analysis. Configuration is in `analysis_options.yaml`.

## Architecture

### Project Structure
```
lib/
├── constants/          # App-wide constants (themes, colors)
├── extensions/         # Dart extensions (color utilities)
├── models/            # Data models (Forfait, Transaction, etc.)
├── routes/            # Custom route transitions
├── screens/           # UI screens organized by feature
├── services/          # Business logic and API services
├── utils/             # Utility functions (validation, responsive)
├── widgets/           # Reusable UI components
└── main.dart          # App entry point
```

### Key Services
- **UserSession** (`lib/services/user_session.dart`): Manages user authentication state with automatic session expiration (10 minutes of inactivity)
- **UserService** (`lib/services/user_service.dart`): Handles phone number persistence
- **UssdService** (`lib/services/ussd_service.dart`): Manages USSD code communication with native platform
- **BalanceService** (`lib/services/balance_service.dart`): Handles balance checking and management
- **ForfaitService** (`lib/services/forfait_service.dart`): Manages package purchasing
- **OtpService** (`lib/services/otp_service.dart`): Handles OTP verification

### State Management
The app uses Flutter's built-in state management with StatefulWidget. User session state is managed through SharedPreferences with caching for performance.

### Navigation Flow
1. **SplashScreen** → **LoginScreen** (phone number input)
2. **LoginScreen** → **OtpScreen** (OTP verification)
3. **OtpScreen** → **HomeScreen** (main dashboard)
4. Various feature screens branch from HomeScreen

### Theme and Styling
- Primary colors: DT Blue (#002464), DT Yellow (#F8C02C)
- Consistent spacing and border radius constants in `AppTheme`
- Responsive design using `ResponsiveSize` utility
- Portrait orientation enforced

### Key Dependencies
- `shared_preferences`: Local data persistence
- `permission_handler`: Phone and SMS permissions
- `http`: HTTP requests
- `flutter_contacts`: Contact access
- `sms_autofill`: OTP auto-fill
- `percent_indicator`: Progress indicators
- `provider`: State management (if used)

### Platform-Specific Features
- USSD integration requires native Android/iOS implementations
- Phone and SMS permissions are required
- Auto-fill OTP functionality for better UX

### Session Management
- Sessions expire after 10 minutes of app inactivity
- App lifecycle events trigger session state updates
- Automatic logout on session expiration
- Phone number caching for performance

### Security Considerations
- OTP-based authentication
- Session timeout for security
- Phone number validation
- Secure storage of user data

## Development Notes

### Working with USSD
The app integrates with telecom USSD codes through platform channels. When working with USSD-related features, ensure native platform implementations are updated accordingly.

### Responsive Design
Use `ResponsiveSize` utility for consistent sizing across devices. Initialize it in the main app widget before use.

### Error Handling
Services implement try-catch blocks with appropriate error messages. When adding new services, follow the existing error handling patterns.

### Performance
- User session data is cached to avoid frequent SharedPreferences reads
- Responsive utilities are initialized once and reused
- Image assets are optimized and located in `assets/` directory

### Testing
Run `flutter test` for unit tests. When adding new features, ensure corresponding tests are included in the `test/` directory.
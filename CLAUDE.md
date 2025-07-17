# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Flutter mobile application for DT Mobile (Djibouti Telecom) that provides telecommunication services including:
- Phone number authentication via OTP
- Balance checking and management
- Forfait (package) purchasing and management
- Money transfers and credit transfers
- USSD code integration for telecom operations
- Refill services via voucher codes

The app is built for the Djibouti telecommunications market with specific integrations for Djibouti Telecom's backend systems.

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

# Analyze code for linting issues
flutter analyze

# Format code
dart format .
```

### Linting and Code Quality
The project uses `flutter_lints` for code analysis. Configuration is in `analysis_options.yaml`.

## Architecture Overview

### Core Architecture Patterns
- **Service Layer Pattern**: Business logic is separated into service classes in `lib/services/`
- **Session Management**: Sophisticated user session handling with automatic expiration (10 minutes of inactivity)
- **Responsive Design**: Custom responsive sizing system that adapts to different screen sizes
- **State Management**: Built-in Flutter state management with StatefulWidget pattern
- **API Integration**: HTTP-based API calls to backend services with proper error handling

### Project Structure
```
lib/
├── constants/          # App-wide constants (themes, colors, spacing)
├── enums/             # Enumerations for type safety
├── extensions/        # Dart extensions (color utilities)
├── models/            # Data models (Forfait, Transaction, etc.)
├── routes/            # Custom route transitions and navigation
├── screens/           # UI screens organized by feature
├── services/          # Business logic and API services
├── utils/             # Utility functions (validation, responsive)
├── widgets/           # Reusable UI components
└── main.dart          # App entry point with lifecycle management
```

### Key Architectural Components

#### Session Management System
The app implements a sophisticated session management system in `UserSession` (`lib/services/user_session.dart`):
- **Automatic Expiration**: Sessions expire after 10 minutes of inactivity
- **App Lifecycle Integration**: Tracks when app goes to background/foreground
- **Cached Data**: Uses in-memory caching for performance optimization
- **SharedPreferences**: Persistent storage for session data

#### Responsive Design System
Custom responsive sizing system in `ResponsiveSize` (`lib/utils/responsive_size.dart`):
- **Adaptive Scaling**: Automatically adapts to different screen sizes
- **Design-First Approach**: Uses 375x812 as base design dimensions
- **Device Detection**: Handles tablets, small phones, and regular phones differently
- **Font Scaling**: Intelligent font size scaling based on screen width

#### API Integration Architecture
- **Base URL Configuration**: `http://10.39.230.106/api/` (configurable)
- **RESTful Services**: HTTP-based API calls with proper error handling
- **Phone Number Formatting**: Automatic formatting to include country code (253)
- **Request/Response Patterns**: Consistent error handling and response parsing

## Key Services

### UserSession (`lib/services/user_session.dart`)
Manages user authentication state with automatic session expiration:
- **Session Creation**: `createSession(phoneNumber)` after successful OTP verification
- **Activity Tracking**: `updateActivity()` called throughout app usage
- **Lifecycle Management**: `appResumed()`, `appPaused()`, `appTerminated()` for state transitions
- **Authentication Check**: `isAuthenticated()` verifies session validity
- **Cache Optimization**: In-memory caching to reduce SharedPreferences reads

### BalanceService (`lib/services/balance_service.dart`)
Handles balance checking and management:
- **API Integration**: Connects to `/api/air/balance` endpoint
- **Session Validation**: Ensures user is authenticated before API calls
- **Phone Number Processing**: Automatically formats numbers with country code
- **Error Handling**: Comprehensive error handling with user-friendly messages

### UssdService (`lib/services/ussd_service.dart`)
Manages USSD code communication with native platform:
- **Platform Channel**: Uses method channel `com.example.dtapp2/ussd`
- **Balance Checking**: Specific USSD codes for Djibouti Telecom (*168#)
- **Response Parsing**: Extracts balance, expiration dates, and bonus information
- **Cross-Platform**: Works on both Android and iOS with native implementations

### OtpService (`lib/services/otp_service.dart`)
Handles OTP verification for authentication:
- **SMS Integration**: Works with `sms_autofill` package for automatic OTP detection
- **API Integration**: Connects to backend OTP verification endpoints
- **Session Integration**: Creates user sessions upon successful verification

### ForfaitService (`lib/services/forfait_service.dart`)
Manages package purchasing and management:
- **Purchase Logic**: Handles forfait purchasing with balance validation
- **API Integration**: Connects to backend for package operations
- **Error Handling**: Validates sufficient balance before purchases

## Theme and Design System

### Color Scheme
Primary colors are defined in `AppTheme` (`lib/constants/app_theme.dart`):
- **DT Blue**: `#002464` (Primary brand color)
- **DT Blue 2**: `#003B7F` (Secondary blue)
- **DT Yellow**: `#F8C02C` (Accent color)
- **Background Grey**: `#F5F5F5`
- **Text Colors**: Primary (`#212121`) and Secondary (`#757575`)

### Spacing and Typography
- **Consistent Spacing**: XS (4px), S (8px), M (16px), L (24px), XL (32px)
- **Border Radius**: XS (4px), S (8px), M (12px), L (24px), XL (32px)
- **Typography**: Roboto font family with defined heading, subheading, and body styles
- **Responsive Text**: Font sizes adapt based on screen dimensions

### Navigation and UX
- **Portrait Only**: App enforces portrait orientation
- **Custom Transitions**: Smooth route transitions in `CustomRouteTransitions`
- **Gradient Backgrounds**: Primary gradient from DT Blue to DT Blue 2
- **Card Design**: Consistent card styling with shadows and rounded corners

## Key Dependencies and Integrations

### Core Dependencies
- **shared_preferences**: Persistent local storage for user data and session management
- **provider**: State management (though primarily uses StatefulWidget)
- **permission_handler**: Phone and SMS permissions for OTP functionality
- **http**: HTTP client for API communication
- **flutter_contacts**: Contact access for phone number selection
- **sms_autofill**: Automatic OTP detection and filling
- **percent_indicator**: Progress indicators for data usage and loading states

### Phone Number Validation
The app includes sophisticated phone number validation in `PhoneNumberValidator`:
- **Djibouti Format**: 8 digits starting with 77, 78, 70, 75, 76, or 33
- **International Format**: 253 country code prefix
- **Regex Patterns**: Comprehensive validation for local and international formats

## Development Patterns

### Error Handling
- **Try-Catch Blocks**: Comprehensive error handling in all service methods
- **User-Friendly Messages**: Translated error messages for better UX
- **Logging**: Debug prints for development and troubleshooting
- **Graceful Degradation**: App continues to function even with API failures

### State Management
- **StatefulWidget Pattern**: Primary state management approach
- **Service Layer**: Business logic separated from UI components
- **Caching Strategy**: In-memory caching for frequently accessed data
- **Lifecycle Awareness**: Proper widget lifecycle management

### API Integration Patterns
- **Consistent Headers**: Standard JSON headers for all API requests
- **Response Parsing**: Structured response handling with proper error checking
- **Phone Number Formatting**: Automatic country code handling
- **Session Integration**: All API calls validate user session first

## Navigation Flow

1. **SplashScreen** → **LoginScreen** (phone number input)
2. **LoginScreen** → **OtpScreen** (OTP verification via SMS)
3. **OtpScreen** → **HomeScreen** (main dashboard after successful authentication)
4. **HomeScreen** serves as the main hub with bottom navigation to:
   - Balance and account information
   - Forfait purchasing screens
   - Money transfer functionality
   - Refill services

## Security Considerations

- **OTP-Based Authentication**: Secure phone number verification
- **Session Timeout**: Automatic logout after 10 minutes of inactivity
- **Data Validation**: Input validation for all user inputs
- **API Security**: Proper error handling without exposing sensitive information
- **Local Storage**: Secure storage of user session data

## Testing and Quality Assurance

### Test Structure
- Unit tests should be placed in `test/` directory
- Widget tests for UI components
- Integration tests for API services
- Use `flutter test` command to run tests

### Code Quality
- Follow Flutter/Dart style guidelines
- Use `flutter analyze` to check for linting issues
- Implement proper error handling in all services
- Use `dart format .` to maintain consistent formatting

## Platform-Specific Considerations

### Android
- **USSD Integration**: Native Android implementation required for USSD functionality
- **SMS Permissions**: Required for OTP auto-fill
- **Phone State Permissions**: For phone number detection

### iOS
- **USSD Limitations**: iOS has restricted USSD access
- **SMS Integration**: Uses native iOS SMS handling
- **Privacy Permissions**: Proper permission handling for contacts and SMS

## Performance Optimization

- **Responsive Caching**: UserSession and ResponsiveSize use caching
- **Image Assets**: Optimized images in `assets/` directory
- **Memory Management**: Proper widget disposal and cleanup
- **Network Efficiency**: Minimal API calls with proper error handling

## API Documentation References

The project includes comprehensive API documentation:
- **AIR_API_INTEGRATION_GUIDE.md**: Detailed AIR API integration guide
- **MOBILE_INTEGRATION_GUIDE.md**: Mobile-specific integration patterns
- **INVOICE_API_INTEGRATION_GUIDE.md**: Invoice API documentation
- **TOPUP_API_INTEGRATION_GUIDE.md**: Top-up service documentation

These guides provide detailed information about backend API endpoints, request/response formats, and integration patterns.
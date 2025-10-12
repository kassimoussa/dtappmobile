# Project Overview

This is a Flutter mobile application called "DTServices" for Djibouti Telecom customers. It allows users to manage their mobile accounts, including checking their balance, buying data plans, and transferring credit. The application uses Firebase for push notifications and includes features like biometric authentication.

## Building and Running

### Prerequisites

*   Flutter SDK: [https://flutter.dev/docs/get-started/install](https://flutter.dev/docs/get-started/install)
*   An editor like Visual Studio Code or Android Studio.

### Setup

1.  Clone the repository.
2.  Install dependencies:
    ```bash
    flutter pub get
    ```

### Running the app

```bash
flutter run
```

### Building the app

To build the app for a specific platform, use the following commands:

*   **Android:**
    ```bash
    flutter build apk --release
    ```
*   **iOS:**
    ```bash
    flutter build ios --release
    ```

## Development Conventions

*   **State Management:** The project uses `provider` for state management.
*   **Routing:** Custom route transitions are defined in `lib/routes/custom_route_transitions.dart`.
*   **Services:** The business logic is separated into services in the `lib/services` directory.
*   **UI:** The UI is built using Flutter's Material Design widgets.
*   **Authentication:** The app uses OTP-based authentication and supports biometric authentication.
*   **Error Handling:** The app uses a combination of `try-catch` blocks and displays user-friendly error messages.
*   **Code Style:** The code follows the standard Dart and Flutter coding conventions.

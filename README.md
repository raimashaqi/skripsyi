# Flutter Premium Setup

This is a professional-grade Flutter project setup using **Clean Architecture** principles. It's designed to be scalable, testable, and maintainable.

## 📁 Folder Structure

```text
lib/
├── app.dart              # Main App entry / Root Widget
├── main.dart             # Application initialization
├── core/                 # Shared logic, themes, and constants
│   ├── constants/        # API endpoints, Strings, etc.
│   ├── error/            # Exception & Failure classes
│   ├── theme/            # Global theme configuration
│   ├── utils/            # Helper functions & extension methods
│   └── widgets/          # Reusable UI components
└── features/             # Feature-based business logic
    └── home/             # Example Home feature
        ├── data/         # Models, Repositories, DataSources
        ├── domain/       # Entities, Use Cases
        └── presentation/ # BLoCs/Providers, Screens, Widgets
```

## 🛠️ Tech Stack

- **State Management**: [flutter_bloc](https://pub.dev/packages/flutter_bloc)
- **Networking**: [dio](https://pub.dev/packages/dio)
- **DI**: [get_it](https://pub.dev/packages/get_it)
- **Aesthetics**: [google_fonts](https://pub.dev/packages/google_fonts)
- **Icons**: [flutter_svg](https://pub.dev/packages/flutter_svg)

## 🚀 How to Run

1. Make sure you have Flutter installed.
2. Run `flutter pub get` to install dependencies.
3. Run `flutter run` to start the application.

## 🎨 Styling

The app uses a custom dark theme with gradients and a glassmorphism design approach to provide a premium feel.

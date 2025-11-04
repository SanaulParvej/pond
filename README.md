# Pond Management

A polished Flutter application for tracking feed, medicine, and other expenses across multiple ponds. The UI is built with Material 3 and powered by GetX for state management and navigation.

## Features

- Dashboard overview of every pond with usage counts and total spend
- Quick actions for recording feed, medicine, and ad-hoc expenses
- Inventory management for feed and medicine products with unit-aware pricing
- Detailed pond summaries with category breakdowns and drill-down actions
- Exportable PDF reports that summarise totals and category details
- Firebase initialized for persistence (Android configured out of the box)

## Tech Stack

- Flutter 3.x with Material 3 theming
- GetX for bindings, routing, and reactive controllers
- Firebase Core (Android configured; add `GoogleService-Info.plist` for iOS)
- `pdf` and `printing` packages for report generation

## Getting Started

### Prerequisites

- Flutter SDK 3.x
- Dart 3.x
- (Android) A configured Firebase project with `google-services.json` placed at `android/app/google-services.json`
- (iOS) Supply a `GoogleService-Info.plist` and enable Firebase in Xcode if deploying to iOS

### Installation

```bash
flutter pub get
```

### Running the App

```bash
flutter run
```

### Running Tests

```bash
flutter test
```

## Project Structure

```
lib/
	bindings/        # Global GetX bindings (controllers)
	controllers/     # Pond controller exposing reactive state
	models/          # Data models for products and usage entries
	repository/      # In-memory repository (swap in Firestore when ready)
	routes/          # Named routes and page configuration
	screens/         # UI screens (dashboard, details, forms, splash)
	widgets/         # Shared UI components
assets/
	fonts/           # PDF font assets
	pond_background.jpg
	pond.png
	logo.png
```

## Firebase Notes

- Android is configured to read `google-services.json`; ensure the package name `com.example.pond` exists in your Firebase project.
- To enable iOS, add `GoogleService-Info.plist` to `ios/Runner`, update bundle identifiers, and run `flutterfire configure` if desired.
- Repository persistence is currently in-memory. Replace `PondRepository` with Firestore CRUD operations once your Firestore security rules are in place.

## License

This project is provided as-is without an explicit license. Please add one before public distribution if required.

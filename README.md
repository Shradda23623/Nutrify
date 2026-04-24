# Nutrify

A cross-platform nutrition, fitness, and wellness tracker built with Flutter and Firebase. Nutrify combines food scanning, calorie and micronutrient tracking, activity monitoring, and habit tools (water, sleep, fasting, reminders) into a single app.

## Features

**Nutrition tracking**
- Barcode scanner and nutrition-label OCR (via ML Kit Text Recognition) for fast food logging
- Calorie, macro, and micronutrient tracking
- Custom food database for items not covered by the scanner
- Meal planner and glycemic-load insights
- Intermittent fasting tracker

**Body and health**
- BMI and TDEE (Total Daily Energy Expenditure) calculators
- Weight, body measurements, and progress charts (fl_chart)
- Water intake logging
- Sleep tracking

**Activity**
- Step counting via the device pedometer
- Workout logging
- Optional Bluetooth connection to wearables (flutter_blue_plus)

**Engagement**
- Onboarding flow with smooth page indicators
- Local push notifications with custom tones for reminders
- Firebase Cloud Messaging for remote notifications
- Lottie animations throughout the UI

**Account and sync**
- Email/password auth and Google Sign-In
- Cloud sync via Cloud Firestore
- Profile photos stored in Firebase Storage

## Tech Stack

- **Framework:** Flutter (Dart SDK ^3.11.4)
- **State management:** Provider
- **Backend:** Firebase (Auth, Cloud Firestore, Storage, Cloud Messaging)
- **ML / Vision:** Google ML Kit Text Recognition, mobile_scanner
- **Charts:** fl_chart
- **Sensors:** pedometer, flutter_blue_plus (BLE)
- **Notifications:** flutter_local_notifications, timezone
- **Storage:** shared_preferences, path_provider

## Getting Started

### Prerequisites

- Flutter SDK 3.11 or newer (`flutter --version`)
- Android Studio or Xcode for device deployment
- A Firebase project (free tier is fine)

### 1. Clone the repo

```bash
git clone https://github.com/Shradda23623/Nutrify.git
cd Nutrify
```

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Configure Firebase

This repo includes the Firebase client configuration (`android/app/google-services.json`, `lib/firebase_options.dart`) wired to the project's own Firebase backend. If you are forking this project, replace those files with your own generated via the FlutterFire CLI:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

Make sure the following Firebase services are enabled in your project: Authentication (Email/Password + Google), Cloud Firestore, Storage, and Cloud Messaging.

### 4. Generate app icons (optional)

```bash
flutter pub run flutter_launcher_icons
```

### 5. Run the app

```bash
flutter run
```

## Project Structure

```
lib/
├── core/
│   ├── constants/        # app-wide constants
│   ├── data/             # static data (food DB, etc.)
│   ├── routes/           # named routes
│   ├── services/         # Firebase, notifications, BLE, etc.
│   ├── theme/            # colors, typography
│   ├── utils/            # helpers
│   └── widgets/          # shared UI components
├── features/
│   ├── auth/             # sign-in, sign-up
│   ├── onboarding/       # first-run walkthrough
│   ├── home/             # dashboard
│   ├── scanner/          # barcode + label OCR
│   ├── calories/         # calorie tracking
│   ├── micronutrients/   # vitamins and minerals
│   ├── meal_plan/        # meal planner
│   ├── custom_food/      # custom food entries
│   ├── glycemic/         # glycemic load
│   ├── fasting/          # intermittent fasting
│   ├── water/            # hydration log
│   ├── sleep/            # sleep tracking
│   ├── steps/            # pedometer
│   ├── workout/          # workout log
│   ├── weight/           # weight log
│   ├── measurements/     # body measurements
│   ├── bmi/              # BMI calculator
│   ├── tdee/             # TDEE calculator
│   ├── progress/         # charts and trends
│   ├── reminders/        # local notifications
│   ├── device/           # wearable / BLE
│   ├── profile/          # user profile
│   ├── settings/         # app settings
│   └── splash/           # splash screen
├── firebase_options.dart
└── main.dart
```

## Permissions

Nutrify requests the following permissions at runtime:

- **Camera** — for barcode and nutrition-label scanning
- **Activity recognition** — for step counting
- **Bluetooth** — for optional wearable device connection
- **Notifications** — for reminders and FCM messages
- **Photos / storage** — for profile pictures

## Roadmap

- Recipe builder with automatic nutrition calculation
- Richer wearable integrations (Fitbit, Apple Health, Google Fit)
- Weekly and monthly nutrition reports
- Social / accountability features

## Contributing

Contributions are welcome. Please open an issue describing the change you would like to make before submitting a pull request.

## License

This project is released under the MIT License. See `LICENSE` for details.

## Author

Built by **Shradda** — [github.com/Shradda23623](https://github.com/Shradda23623)

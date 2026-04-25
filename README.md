# Nutrify

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.11-0175C2?logo=dart&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-Auth%20%7C%20Firestore%20%7C%20Storage-FFCA28?logo=firebase&logoColor=black)
![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web-lightgrey)
![License](https://img.shields.io/badge/License-MIT-green.svg)

A cross-platform nutrition, fitness, and wellness tracker built with Flutter and Firebase. Nutrify combines food scanning, calorie and micronutrient tracking, activity monitoring, and habit tools (water, sleep, fasting, reminders) into a single app.

## Screenshots

### Onboarding & Profile

<p align="center">
  <img src="docs/screenshots/splashscreen.jpeg" width="220" alt="Splash screen" />
  <img src="docs/screenshots/login.jpeg" width="220" alt="Login" />
  <img src="docs/screenshots/myprofile.jpeg" width="220" alt="My profile" />
</p>

### Home & Tools

<p align="center">
  <img src="docs/screenshots/home.jpeg" width="220" alt="Home dashboard" />
  <img src="docs/screenshots/tools_and_features.jpeg" width="220" alt="Tools and features" />
  <img src="docs/screenshots/app_icon.jpeg" width="220" alt="App icon" />
</p>

### Food & Nutrition Tracking

<p align="center">
  <img src="docs/screenshots/myfood.jpeg" width="220" alt="My food" />
  <img src="docs/screenshots/calories_tracker.jpeg" width="220" alt="Calories tracker" />
  <img src="docs/screenshots/micronutrients_tracker.jpeg" width="220" alt="Micronutrients tracker" />
</p>
<p align="center">
  <img src="docs/screenshots/glycemic_tracker.jpeg" width="220" alt="Glycemic tracker" />
  <img src="docs/screenshots/fasting_tracker.jpeg" width="220" alt="Intermittent fasting tracker" />
</p>

### Body & Wellness

<p align="center">
  <img src="docs/screenshots/weight_tracker.jpeg" width="220" alt="Weight tracker" />
  <img src="docs/screenshots/measurements_tracker.jpeg" width="220" alt="Body measurements" />
  <img src="docs/screenshots/sleep_tracker.jpeg" width="220" alt="Sleep tracker" />
</p>
<p align="center">
  <img src="docs/screenshots/BMI_calculator.jpeg" width="220" alt="BMI calculator" />
  <img src="docs/screenshots/TDEE_calculator.jpeg" width="220" alt="TDEE calculator" />
</p>

### Activity

<p align="center">
  <img src="docs/screenshots/step_tracker.jpeg" width="220" alt="Step tracker" />
  <img src="docs/screenshots/workout.jpeg" width="220" alt="Workout" />
  <img src="docs/screenshots/workout_tracker.jpeg" width="220" alt="Workout tracker" />
</p>

### Progress, Reminders & Devices

<p align="center">
  <img src="docs/screenshots/progress_tracker.jpeg" width="220" alt="Progress tracker" />
  <img src="docs/screenshots/reminder.jpeg" width="220" alt="Reminders" />
  <img src="docs/screenshots/connected_devices.jpeg" width="220" alt="Connected devices" />
</p>

### Settings

<p align="center">
  <img src="docs/screenshots/settings_1.jpeg" width="220" alt="Settings" />
  <img src="docs/screenshots/settings_2.jpeg" width="220" alt="Settings (more)" />
</p>

## Demo

- **Download APK:** see the [Releases](https://github.com/Shradda23623/Nutrify/releases) page.
- **Demo video:** _(add a YouTube or Loom link here once recorded)_

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

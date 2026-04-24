import 'package:flutter/material.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/water/screens/water_screen.dart';
import '../../features/steps/screens/step_screen.dart';
import '../../features/scanner/screens/scanner_screen.dart';
import '../../features/reminders/screens/reminder_screen.dart';
import '../../features/calories/screens/calorie_screen.dart';
import '../../features/calories/screens/food_search_screen.dart';
import '../../features/bmi/screens/bmi_screen.dart';
import '../../features/device/screens/device_screen.dart';
import '../../features/splash/screens/splash_screen.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/progress/screens/progress_screen.dart';
import '../../features/tdee/screens/tdee_screen.dart';
import '../../features/weight/screens/weight_screen.dart';
import '../../features/auth/screens/auth_screen.dart';
import '../../features/auth/screens/profile_setup_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/custom_food/screens/custom_food_screen.dart';
import '../../features/measurements/screens/measurements_screen.dart';
import '../../features/meal_plan/screens/meal_plan_screen.dart';
import '../../features/micronutrients/screens/micronutrient_screen.dart';
import '../../features/fasting/screens/fasting_screen.dart';
import '../../features/glycemic/screens/glycemic_screen.dart';
import '../../features/sleep/screens/sleep_screen.dart';
import '../../features/workout/screens/workout_screen.dart';

class AppRoutes {
  static const splash        = '/splash';
  static const onboarding    = '/onboarding';
  static const auth          = '/auth';
  static const profileSetup  = '/profile-setup';
  static const home          = '/';
  static const water         = '/water';
  static const steps         = '/steps';
  static const scanner       = '/scanner';
  static const reminders     = '/reminders';
  static const calories      = '/calories';
  static const foodSearch    = '/food-search';
  static const bmi           = '/bmi';
  static const device        = '/device';
  static const profile       = '/profile';
  static const progress      = '/progress';
  static const tdee          = '/tdee';
  static const weight        = '/weight';
  static const settings      = '/settings';
  // ── New features ────────────────────────────────────────────
  static const customFoods    = '/custom-foods';
  static const measurements   = '/measurements';
  static const mealPlan       = '/meal-plan';
  static const micronutrients = '/micronutrients';
  static const fasting        = '/fasting';
  static const glycemic       = '/glycemic';
  static const sleep          = '/sleep';
  static const workout        = '/workout';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());

      case onboarding:
        return MaterialPageRoute(builder: (_) => const OnboardingScreen());

      case auth:
        return MaterialPageRoute(builder: (_) => const AuthScreen());

      case profileSetup:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const ProfileSetupScreen(),
        );

      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());

      case water:
        return MaterialPageRoute(builder: (_) => const WaterScreen());

      case steps:
        return MaterialPageRoute(builder: (_) => const StepScreen());

      case scanner:
        return MaterialPageRoute(builder: (_) => const ScannerScreen());

      case reminders:
        return MaterialPageRoute(builder: (_) => const ReminderScreen());

      case calories:
        return MaterialPageRoute(builder: (_) => const CalorieScreen());

      case foodSearch:
        return MaterialPageRoute(builder: (_) => const FoodSearchScreen());

      case bmi:
        return MaterialPageRoute(builder: (_) => const BmiScreen());

      case device:
        return MaterialPageRoute(builder: (_) => const DeviceScreen());

      case profile:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());

      case progress:
        return MaterialPageRoute(builder: (_) => const ProgressScreen());

      case tdee:
        return MaterialPageRoute(builder: (_) => const TdeeScreen());

      case weight:
        return MaterialPageRoute(builder: (_) => const WeightScreen());

      case AppRoutes.settings:
        return MaterialPageRoute(builder: (_) => const SettingsScreen());

      case customFoods:
        return MaterialPageRoute(builder: (_) => const CustomFoodScreen());

      case measurements:
        return MaterialPageRoute(builder: (_) => const MeasurementsScreen());

      case mealPlan:
        return MaterialPageRoute(builder: (_) => const MealPlanScreen());

      case micronutrients:
        return MaterialPageRoute(builder: (_) => const MicronutrientScreen());

      case fasting:
        return MaterialPageRoute(builder: (_) => const FastingScreen());

      case glycemic:
        return MaterialPageRoute(builder: (_) => const GlycemicScreen());

      case sleep:
        return MaterialPageRoute(builder: (_) => const SleepScreen());

      case workout:
        return MaterialPageRoute(builder: (_) => const WorkoutScreen());

      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Page not found')),
          ),
        );
    }
  }
}

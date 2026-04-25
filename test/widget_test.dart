// Tests for the BMI feature.
//
// We test the pure-Dart BmiModel directly so the suite stays fast and
// deterministic — no Flutter widget tree, no Firebase, no async setup.
// This is intentional: business logic in models should be testable in
// isolation, and the BMI screen's calculate flow ultimately delegates
// to BmiModel for every value the user sees.

import 'package:flutter_test/flutter_test.dart';
import 'package:nutrify/features/bmi/models/bmi_model.dart';

void main() {
  group('BmiModel.bmi', () {
    test('computes BMI for a typical adult', () {
      // 170 cm, 65 kg -> 65 / (1.70 * 1.70) = 22.49
      final model = BmiModel(heightCm: 170, weightKg: 65);
      expect(model.bmi, closeTo(22.49, 0.01));
    });

    test('returns 0 when height is zero (avoids divide-by-zero)', () {
      final model = BmiModel(heightCm: 0, weightKg: 65);
      expect(model.bmi, 0);
    });

    test('returns 0 when height is negative', () {
      final model = BmiModel(heightCm: -10, weightKg: 65);
      expect(model.bmi, 0);
    });
  });

  group('BmiModel.category', () {
    test('underweight (BMI < 18.5)', () {
      // 170 cm, 50 kg -> BMI 17.30
      final model = BmiModel(heightCm: 170, weightKg: 50);
      expect(model.category, 'Underweight');
    });

    test('normal weight (18.5 <= BMI < 25.0)', () {
      // 170 cm, 65 kg -> BMI 22.49
      final model = BmiModel(heightCm: 170, weightKg: 65);
      expect(model.category, 'Normal weight');
    });

    test('overweight (25.0 <= BMI < 30.0)', () {
      // 170 cm, 80 kg -> BMI 27.68
      final model = BmiModel(heightCm: 170, weightKg: 80);
      expect(model.category, 'Overweight');
    });

    test('obese (BMI >= 30.0)', () {
      // 170 cm, 95 kg -> BMI 32.87
      final model = BmiModel(heightCm: 170, weightKg: 95);
      expect(model.category, 'Obese');
    });

    test('returns em-dash placeholder when BMI is 0', () {
      final model = BmiModel(heightCm: 0, weightKg: 65);
      expect(model.category, '—');
    });

    test('boundary 18.5 falls into Normal weight', () {
      // height 100 cm, weight 18.5 kg -> BMI exactly 18.5
      final model = BmiModel(heightCm: 100, weightKg: 18.5);
      expect(model.bmi, closeTo(18.5, 0.0001));
      expect(model.category, 'Normal weight');
    });

    test('boundary 25.0 falls into Overweight', () {
      // height 100 cm, weight 25 kg -> BMI exactly 25.0
      final model = BmiModel(heightCm: 100, weightKg: 25);
      expect(model.bmi, closeTo(25.0, 0.0001));
      expect(model.category, 'Overweight');
    });

    test('boundary 30.0 falls into Obese', () {
      // height 100 cm, weight 30 kg -> BMI exactly 30.0
      final model = BmiModel(heightCm: 100, weightKg: 30);
      expect(model.bmi, closeTo(30.0, 0.0001));
      expect(model.category, 'Obese');
    });
  });

  group('BmiModel.gaugePosition', () {
    test('clamps below the visible range to 0.0', () {
      // BMI 5 -> below the 10–40 visible range
      final model = BmiModel(heightCm: 200, weightKg: 20);
      expect(model.bmi, lessThan(10));
      expect(model.gaugePosition, 0.0);
    });

    test('clamps above the visible range to 1.0', () {
      // 100 cm, 50 kg -> BMI 50, way above 40
      final model = BmiModel(heightCm: 100, weightKg: 50);
      expect(model.bmi, greaterThan(40));
      expect(model.gaugePosition, 1.0);
    });

    test('maps BMI 25 to the middle of the gauge (0.5)', () {
      // height 100 cm, weight 25 kg -> BMI exactly 25
      final model = BmiModel(heightCm: 100, weightKg: 25);
      expect(model.gaugePosition, closeTo(0.5, 0.001));
    });
  });

  group('BmiModel.advice', () {
    test('returns onboarding hint when BMI is 0', () {
      final model = BmiModel(heightCm: 0, weightKg: 0);
      expect(model.advice, contains('Enter your height and weight'));
    });

    test('advice is non-empty for every category', () {
      final cases = <BmiModel>[
        BmiModel(heightCm: 170, weightKg: 50), // underweight
        BmiModel(heightCm: 170, weightKg: 65), // normal
        BmiModel(heightCm: 170, weightKg: 80), // overweight
        BmiModel(heightCm: 170, weightKg: 95), // obese
      ];
      for (final m in cases) {
        expect(m.advice, isNotEmpty);
        expect(m.advice.length, greaterThan(20));
      }
    });
  });

  group('BmiModel.emoji', () {
    test('returns a non-empty emoji for every category', () {
      final cases = <BmiModel>[
        BmiModel(heightCm: 0, weightKg: 0),    // zero
        BmiModel(heightCm: 170, weightKg: 50), // underweight
        BmiModel(heightCm: 170, weightKg: 65), // normal
        BmiModel(heightCm: 170, weightKg: 80), // overweight
        BmiModel(heightCm: 170, weightKg: 95), // obese
      ];
      for (final m in cases) {
        expect(m.emoji, isNotEmpty);
      }
    });
  });
}

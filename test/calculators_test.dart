import 'package:calbalance/core/calculators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GoalCalculator', () {
    test('uses Mifflin St Jeor and lose delta', () {
      final r = GoalCalculator.calculate(
        gender: 'male',
        age: 30,
        heightCm: 180,
        weightKg: 80,
        activity: 'sedentary',
        goal: 'lose',
      );
      expect(r.bmr, 1780);
      expect(r.tdee, 2136);
      expect(r.calories, 1640);
      expect(r.protein, 130);
      expect(r.water, 2800);
    });
    test('maintenance has no calorie delta', () {
      final r = GoalCalculator.calculate(
        gender: 'female',
        age: 30,
        heightCm: 165,
        weightKg: 60,
        activity: 'light',
        goal: 'maintain',
      );
      expect(r.calories, closeTo(r.tdee, 5));
    });
  });
  group('HealthCalculators', () {
    test(
      'BMI is calculated in metric units',
      () => expect(HealthCalculators.bmi(80, 180), closeTo(24.69, .01)),
    );
    test('step calories increase with steps', () {
      final low = HealthCalculators.stepCalories(
        steps: 1000,
        heightCm: 180,
        weightKg: 80,
        gender: 'male',
      );
      final high = HealthCalculators.stepCalories(
        steps: 10000,
        heightCm: 180,
        weightKg: 80,
        gender: 'male',
      );
      expect(high, closeTo(low * 10, .001));
    });
    test(
      'body fat returns null for invalid measurements',
      () => expect(
        HealthCalculators.bodyFat(
          gender: 'male',
          heightCm: 180,
          waistCm: 30,
          neckCm: 40,
        ),
        isNull,
      ),
    );
  });
}

import 'dart:math' as math;

class GoalResult {
  const GoalResult(
    this.bmr,
    this.tdee,
    this.calories,
    this.protein,
    this.water,
  );
  final double bmr, tdee;
  final int calories, water;
  final double protein;
}

class GoalCalculator {
  static GoalResult calculate({
    required String gender,
    required int age,
    required double heightCm,
    required double weightKg,
    required String activity,
    required String goal,
  }) {
    final sexOffset = gender == 'male' ? 5 : -161;
    final bmr = 10 * weightKg + 6.25 * heightCm - 5 * age + sexOffset;
    final factor =
        {
          'sedentary': 1.2,
          'light': 1.375,
          'active': 1.55,
          'veryActive': 1.725,
        }[activity] ??
        1.2;
    final tdee = bmr * factor;
    final delta = goal == 'lose'
        ? -500
        : goal == 'gain'
        ? 300
        : 0;
    final calories = ((tdee + delta) / 10).round() * 10;
    final protein = (weightKg * 1.6 / 5).round() * 5.0;
    final water = (weightKg * 35 / 50).round() * 50;
    return GoalResult(bmr, tdee, calories, protein, water);
  }
}

class HealthCalculators {
  static double bmi(double weightKg, double heightCm) =>
      weightKg / math.pow(heightCm / 100, 2);
  static double stepCalories({
    required int steps,
    required double heightCm,
    required double weightKg,
    required String gender,
  }) {
    final strideM = heightCm / 100 * (gender == 'male' ? .415 : .413);
    return steps * strideM / 1000 * weightKg * .5;
  }

  static double? bodyFat({
    required String gender,
    required double heightCm,
    required double waistCm,
    required double neckCm,
    double? hipCm,
  }) {
    final h = heightCm / 2.54, w = waistCm / 2.54, n = neckCm / 2.54;
    if (gender == 'male' && w > n)
      return 86.010 * _log10(w - n) - 70.041 * _log10(h) + 36.76;
    if (gender != 'male' && hipCm != null && w + hipCm / 2.54 > n)
      return 163.205 * _log10(w + hipCm / 2.54 - n) -
          97.684 * _log10(h) -
          78.387;
    return null;
  }

  static double _log10(double x) => math.log(x) / math.ln10;
}

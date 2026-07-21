import 'package:calbalance/core/database/app_database.dart';
import 'package:calbalance/core/repository.dart';
import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late AppRepository repo;
  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = AppRepository(db);
    await db.seedCategories();
  });
  tearDown(() => db.close());

  test(
    'daily summary combines nutrition, water, steps and activities',
    () async {
      final day = DateTime(2026, 7, 21, 12);
      await repo.addNutrition(
        title: 'Test',
        categoryId: 'meal',
        calories: 720,
        protein: 42,
        at: day,
      );
      await repo.addWater(500, day);
      await repo.setSteps(day, 6000, 240);
      await repo.addActivity('Gym', 300, day);
      final summary = (await repo.summaries(day, day)).single;
      expect(summary.calories, 720);
      expect(summary.protein, 42);
      expect(summary.water, 500);
      expect(summary.steps, 6000);
      expect(summary.activityCalories, 300);
    },
  );

  test('deleting custom category moves entries to other atomically', () async {
    await repo.addCategory('Öğle', 0xe892, 0xff21a7ff);
    final category = (await db.select(db.nutritionCategories).get()).firstWhere(
      (e) => e.customName == 'Öğle',
    );
    await repo.addNutrition(
      title: 'Test',
      categoryId: category.id,
      calories: 300,
    );
    await repo.deleteCategory(category);
    final entry = (await db.select(db.nutritionEntries).get()).single;
    expect(entry.categoryId, 'other');
    expect(
      (await db.select(db.nutritionCategories).get()).any(
        (e) => e.id == category.id,
      ),
      isFalse,
    );
  });

  test('goal change records goal history', () async {
    await repo.saveProfile(
      ProfilesCompanion.insert(
        id: const Value(1),
        gender: 'male',
        birthDate: DateTime(1990),
        heightCm: 180,
        currentWeightKg: 80,
        targetWeightKg: 75,
        activityLevel: 'light',
        goalType: 'lose',
        calorieTarget: 2000,
        proteinTarget: 130,
        waterTargetMl: 2800,
      ),
    );
    expect(await repo.getProfile(), isNotNull);
    expect(await db.select(db.goalHistory).get(), hasLength(1));
  });

  test('restore rejects unsupported schema without deleting data', () async {
    await repo.addNutrition(title: 'Keep', categoryId: 'other', calories: 100);
    expect(
      () => repo.restoreJson('{"schemaVersion":99}'),
      throwsFormatException,
    );
    expect(await db.select(db.nutritionEntries).get(), hasLength(1));
  });
}

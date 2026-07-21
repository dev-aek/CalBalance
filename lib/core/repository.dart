import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import 'database/app_database.dart';

const _uuid = Uuid();
String dayKey(DateTime d) => DateFormat('yyyy-MM-dd').format(d.toLocal());
DateTime startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);

class DailySummary {
  const DailySummary({
    this.calories = 0,
    this.protein = 0,
    this.water = 0,
    this.steps = 0,
    this.stepCalories = 0,
    this.activityCalories = 0,
  });
  final int calories, water, steps, activityCalories;
  final double protein, stepCalories;
}

class AppRepository {
  AppRepository(this.db);
  final AppDatabase db;

  Stream<Profile?> watchProfile() =>
      (db.select(db.profiles)..limit(1)).watchSingleOrNull();
  Future<Profile?> getProfile() =>
      (db.select(db.profiles)..limit(1)).getSingleOrNull();
  Stream<List<NutritionCategory>> watchCategories() => (db.select(
    db.nutritionCategories,
  )..orderBy([(t) => OrderingTerm.asc(t.sortOrder)])).watch();

  Stream<List<NutritionEntry>> watchNutrition(DateTime day) {
    final start = startOfDay(day), end = start.add(const Duration(days: 1));
    return (db.select(db.nutritionEntries)
          ..where(
            (t) =>
                t.occurredAt.isBiggerOrEqualValue(start) &
                t.occurredAt.isSmallerThanValue(end),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.occurredAt)]))
        .watch();
  }

  Stream<List<WaterEntry>> watchWater(DateTime day) {
    final start = startOfDay(day), end = start.add(const Duration(days: 1));
    return (db.select(db.waterEntries)
          ..where(
            (t) =>
                t.occurredAt.isBiggerOrEqualValue(start) &
                t.occurredAt.isSmallerThanValue(end),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.occurredAt)]))
        .watch();
  }

  Stream<DailyStep?> watchSteps(DateTime day) => (db.select(
    db.dailySteps,
  )..where((t) => t.dayKey.equals(dayKey(day)))).watchSingleOrNull();
  Stream<List<ActivityEntry>> watchActivities(DateTime day) {
    final start = startOfDay(day), end = start.add(const Duration(days: 1));
    return (db.select(db.activityEntries)..where(
          (t) =>
              t.occurredAt.isBiggerOrEqualValue(start) &
              t.occurredAt.isSmallerThanValue(end),
        ))
        .watch();
  }

  Stream<List<BodyMeasurement>> watchMeasurements() => (db.select(
    db.bodyMeasurements,
  )..orderBy([(t) => OrderingTerm.desc(t.measuredAt)])).watch();

  Future<void> saveProfile(ProfilesCompanion profile) async {
    await db.into(db.profiles).insertOnConflictUpdate(profile);
    final p = await getProfile();
    if (p != null)
      await db
          .into(db.goalHistory)
          .insert(
            GoalHistoryCompanion.insert(
              id: _uuid.v4(),
              effectiveFrom: DateTime.now(),
              calorieTarget: p.calorieTarget,
              proteinTarget: p.proteinTarget,
              waterTargetMl: p.waterTargetMl,
              stepTarget: p.stepTarget,
            ),
          );
  }

  Future<void> addNutrition({
    required String title,
    required String categoryId,
    int? calories,
    double? protein,
    String? note,
    DateTime? at,
  }) => db
      .into(db.nutritionEntries)
      .insert(
        NutritionEntriesCompanion.insert(
          id: _uuid.v4(),
          title: title.trim(),
          categoryId: categoryId,
          calories: Value(calories),
          proteinGrams: Value(protein),
          note: Value(note?.trim()),
          occurredAt: at ?? DateTime.now(),
        ),
      );
  Future<void> deleteNutrition(String id) =>
      (db.delete(db.nutritionEntries)..where((t) => t.id.equals(id))).go();
  Future<void> updateNutrition(
    NutritionEntry entry, {
    required String title,
    required String categoryId,
    int? calories,
    double? protein,
    String? note,
    required DateTime occurredAt,
  }) => (db.update(db.nutritionEntries)..where((t) => t.id.equals(entry.id)))
      .write(
        NutritionEntriesCompanion(
          title: Value(title.trim()),
          categoryId: Value(categoryId),
          calories: Value(calories),
          proteinGrams: Value(protein),
          note: Value(note?.trim()),
          occurredAt: Value(occurredAt),
          updatedAt: Value(DateTime.now()),
        ),
      );
  Future<void> toggleFavorite(NutritionEntry e) =>
      (db.update(db.nutritionEntries)..where((t) => t.id.equals(e.id))).write(
        NutritionEntriesCompanion(
          isFavorite: Value(!e.isFavorite),
          updatedAt: Value(DateTime.now()),
        ),
      );
  Future<void> repeatNutrition(NutritionEntry e, DateTime day) => addNutrition(
    title: e.title,
    categoryId: e.categoryId,
    calories: e.calories,
    protein: e.proteinGrams,
    note: e.note,
    at: DateTime(
      day.year,
      day.month,
      day.day,
      DateTime.now().hour,
      DateTime.now().minute,
    ),
  );
  Future<void> addWater(int ml, DateTime day) => db
      .into(db.waterEntries)
      .insert(
        WaterEntriesCompanion.insert(
          id: _uuid.v4(),
          amountMl: ml,
          occurredAt: DateTime(
            day.year,
            day.month,
            day.day,
            DateTime.now().hour,
            DateTime.now().minute,
          ),
        ),
      );
  Future<void> deleteWater(String id) =>
      (db.delete(db.waterEntries)..where((t) => t.id.equals(id))).go();
  Future<bool> deleteLatestWater(DateTime day) async {
    final start = startOfDay(day), end = start.add(const Duration(days: 1));
    final latest =
        await (db.select(db.waterEntries)
              ..where(
                (t) =>
                    t.occurredAt.isBiggerOrEqualValue(start) &
                    t.occurredAt.isSmallerThanValue(end),
              )
              ..orderBy([(t) => OrderingTerm.desc(t.occurredAt)])
              ..limit(1))
            .getSingleOrNull();
    if (latest == null) return false;
    await deleteWater(latest.id);
    return true;
  }

  Future<void> setSteps(DateTime day, int steps, double calories) => db
      .into(db.dailySteps)
      .insertOnConflictUpdate(
        DailyStepsCompanion.insert(
          dayKey: dayKey(day),
          stepCount: steps,
          estimatedCalories: calories,
        ),
      );
  Future<void> addActivity(String title, int calories, DateTime day) => db
      .into(db.activityEntries)
      .insert(
        ActivityEntriesCompanion.insert(
          id: _uuid.v4(),
          title: title,
          caloriesBurned: calories,
          occurredAt: day,
        ),
      );
  Future<void> deleteActivity(String id) =>
      (db.delete(db.activityEntries)..where((t) => t.id.equals(id))).go();
  Future<void> addCategory(String name, int iconCode, int accentValue) async {
    final count = await db.select(db.nutritionCategories).get();
    await db
        .into(db.nutritionCategories)
        .insert(
          NutritionCategoriesCompanion.insert(
            id: _uuid.v4(),
            customName: Value(name.trim()),
            iconCode: iconCode,
            accentValue: accentValue,
            sortOrder: Value(count.length),
          ),
        );
  }

  Future<void> renameCategory(NutritionCategory category, String name) =>
      (db.update(db.nutritionCategories)
            ..where((t) => t.id.equals(category.id)))
          .write(NutritionCategoriesCompanion(customName: Value(name.trim())));
  Future<void> deleteCategory(NutritionCategory category) async {
    if (category.isSystem) return;
    await db.transaction(() async {
      await (db.update(db.nutritionEntries)
            ..where((t) => t.categoryId.equals(category.id)))
          .write(const NutritionEntriesCompanion(categoryId: Value('other')));
      await (db.delete(
        db.nutritionCategories,
      )..where((t) => t.id.equals(category.id))).go();
    });
  }

  Stream<List<ReminderSetting>> watchReminders() =>
      db.select(db.reminderSettings).watch();
  Future<void> saveReminder({
    required String id,
    required String type,
    required bool enabled,
    required int hour,
    required int minute,
    int? weekday,
    required String locale,
  }) => db
      .into(db.reminderSettings)
      .insertOnConflictUpdate(
        ReminderSettingsCompanion.insert(
          id: id,
          type: type,
          isEnabled: Value(enabled),
          hour: hour,
          minute: minute,
          weekday: Value(weekday),
          localeCode: locale,
        ),
      );
  Future<void> addMeasurement({
    required double weight,
    double? waist,
    double? neck,
    double? hip,
    double? chest,
    String? note,
    DateTime? at,
  }) async {
    await db.transaction(() async {
      await db
          .into(db.bodyMeasurements)
          .insert(
            BodyMeasurementsCompanion.insert(
              id: _uuid.v4(),
              measuredAt: at ?? DateTime.now(),
              weightKg: weight,
              waistCm: Value(waist),
              neckCm: Value(neck),
              hipCm: Value(hip),
              chestCm: Value(chest),
              note: Value(note),
            ),
          );
      await (db.update(db.profiles)..where((t) => t.id.equals(1))).write(
        ProfilesCompanion(
          currentWeightKg: Value(weight),
          updatedAt: Value(DateTime.now()),
        ),
      );
    });
  }

  Future<void> updateMeasurement(
    BodyMeasurement measurement, {
    required double weight,
    double? waist,
    double? neck,
    double? hip,
    double? chest,
    String? note,
  }) async {
    await db.transaction(() async {
      await (db.update(
        db.bodyMeasurements,
      )..where((t) => t.id.equals(measurement.id))).write(
        BodyMeasurementsCompanion(
          weightKg: Value(weight),
          waistCm: Value(waist),
          neckCm: Value(neck),
          hipCm: Value(hip),
          chestCm: Value(chest),
          note: Value(note),
        ),
      );
      final newest =
          await (db.select(db.bodyMeasurements)
                ..orderBy([(t) => OrderingTerm.desc(t.measuredAt)])
                ..limit(1))
              .getSingleOrNull();
      if (newest != null)
        await (db.update(db.profiles)..where((t) => t.id.equals(1))).write(
          ProfilesCompanion(
            currentWeightKg: Value(newest.weightKg),
            updatedAt: Value(DateTime.now()),
          ),
        );
    });
  }

  Future<void> deleteMeasurement(BodyMeasurement measurement) async {
    await db.transaction(() async {
      await (db.delete(
        db.bodyMeasurements,
      )..where((t) => t.id.equals(measurement.id))).go();
      final newest =
          await (db.select(db.bodyMeasurements)
                ..orderBy([(t) => OrderingTerm.desc(t.measuredAt)])
                ..limit(1))
              .getSingleOrNull();
      if (newest != null)
        await (db.update(db.profiles)..where((t) => t.id.equals(1))).write(
          ProfilesCompanion(
            currentWeightKg: Value(newest.weightKg),
            updatedAt: Value(DateTime.now()),
          ),
        );
    });
  }

  Future<List<DailySummary>> summaries(DateTime from, DateTime to) async {
    final result = <DailySummary>[];
    for (
      var d = startOfDay(from);
      !d.isAfter(to);
      d = d.add(const Duration(days: 1))
    ) {
      final end = d.add(const Duration(days: 1));
      final n = await (db.select(
        db.nutritionEntries,
      )..where((t) => t.occurredAt.isBetweenValues(d, end))).get();
      final w = await (db.select(
        db.waterEntries,
      )..where((t) => t.occurredAt.isBetweenValues(d, end))).get();
      final a = await (db.select(
        db.activityEntries,
      )..where((t) => t.occurredAt.isBetweenValues(d, end))).get();
      final s = await (db.select(
        db.dailySteps,
      )..where((t) => t.dayKey.equals(dayKey(d)))).getSingleOrNull();
      result.add(
        DailySummary(
          calories: n.fold(0, (v, e) => v + (e.calories ?? 0)),
          protein: n.fold(0.0, (v, e) => v + (e.proteinGrams ?? 0)),
          water: w.fold(0, (v, e) => v + e.amountMl),
          steps: s?.stepCount ?? 0,
          stepCalories: s?.estimatedCalories ?? 0,
          activityCalories: a.fold(0, (v, e) => v + e.caloriesBurned),
        ),
      );
    }
    return result;
  }

  Future<List<DailySummary>> summariesForDays(int days) async {
    var from = DateTime.now().subtract(Duration(days: days - 1));
    if (days == 0) {
      final candidates = <DateTime>[];
      final n =
          await (db.select(db.nutritionEntries)
                ..orderBy([(t) => OrderingTerm.asc(t.occurredAt)])
                ..limit(1))
              .getSingleOrNull();
      if (n != null) candidates.add(n.occurredAt);
      final w =
          await (db.select(db.waterEntries)
                ..orderBy([(t) => OrderingTerm.asc(t.occurredAt)])
                ..limit(1))
              .getSingleOrNull();
      if (w != null) candidates.add(w.occurredAt);
      final a =
          await (db.select(db.activityEntries)
                ..orderBy([(t) => OrderingTerm.asc(t.occurredAt)])
                ..limit(1))
              .getSingleOrNull();
      if (a != null) candidates.add(a.occurredAt);
      final m =
          await (db.select(db.bodyMeasurements)
                ..orderBy([(t) => OrderingTerm.asc(t.measuredAt)])
                ..limit(1))
              .getSingleOrNull();
      if (m != null) candidates.add(m.measuredAt);
      candidates.sort();
      from = candidates.isEmpty ? DateTime.now() : candidates.first;
    }
    return summaries(from, DateTime.now());
  }

  Future<File> exportJson() async {
    final data = <String, dynamic>{
      'schemaVersion': 1,
      'appVersion': '1.0.0',
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'profile': (await db.select(db.profiles).get())
          .map((e) => e.toJson())
          .toList(),
      'categories': (await db.select(db.nutritionCategories).get())
          .map((e) => e.toJson())
          .toList(),
      'nutrition': (await db.select(db.nutritionEntries).get())
          .map((e) => e.toJson())
          .toList(),
      'water': (await db.select(db.waterEntries).get())
          .map((e) => e.toJson())
          .toList(),
      'steps': (await db.select(db.dailySteps).get())
          .map((e) => e.toJson())
          .toList(),
      'activities': (await db.select(db.activityEntries).get())
          .map((e) => e.toJson())
          .toList(),
      'measurements': (await db.select(db.bodyMeasurements).get())
          .map((e) => e.toJson())
          .toList(),
    };
    final dir = await getTemporaryDirectory();
    return File(
      '${dir.path}${Platform.pathSeparator}calbalance-${dayKey(DateTime.now())}.json',
    ).writeAsString(const JsonEncoder.withIndent('  ').convert(data));
  }

  Future<void> restoreJson(String content) async {
    final decoded = jsonDecode(content);
    if (decoded is! Map<String, dynamic> || decoded['schemaVersion'] != 1) {
      throw const FormatException('Desteklenmeyen CalBalance yedeği');
    }
    List<Map<String, dynamic>> rows(String key) {
      final value = decoded[key];
      if (value is! List) throw FormatException('$key alanı eksik');
      return value.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }

    final profiles = rows('profile').map(Profile.fromJson).toList();
    final categories = rows(
      'categories',
    ).map(NutritionCategory.fromJson).toList();
    final nutrition = rows('nutrition').map(NutritionEntry.fromJson).toList();
    final water = rows('water').map(WaterEntry.fromJson).toList();
    final steps = rows('steps').map(DailyStep.fromJson).toList();
    final activities = rows('activities').map(ActivityEntry.fromJson).toList();
    final measurements = rows(
      'measurements',
    ).map(BodyMeasurement.fromJson).toList();
    if (profiles.length != 1)
      throw const FormatException('Yedekte geçerli profil yok');
    await db.transaction(() async {
      await db.delete(db.nutritionEntries).go();
      await db.delete(db.waterEntries).go();
      await db.delete(db.dailySteps).go();
      await db.delete(db.activityEntries).go();
      await db.delete(db.bodyMeasurements).go();
      await db.delete(db.goalHistory).go();
      await db.delete(db.profiles).go();
      await db.delete(db.nutritionCategories).go();
      for (final e in categories) {
        await db.into(db.nutritionCategories).insert(e);
      }
      for (final e in profiles) {
        await db.into(db.profiles).insert(e);
      }
      for (final e in nutrition) {
        await db.into(db.nutritionEntries).insert(e);
      }
      for (final e in water) {
        await db.into(db.waterEntries).insert(e);
      }
      for (final e in steps) {
        await db.into(db.dailySteps).insert(e);
      }
      for (final e in activities) {
        await db.into(db.activityEntries).insert(e);
      }
      for (final e in measurements) {
        await db.into(db.bodyMeasurements).insert(e);
      }
    });
  }

  Future<void> deleteAllData() async {
    await db.transaction(() async {
      await db.delete(db.nutritionEntries).go();
      await db.delete(db.waterEntries).go();
      await db.delete(db.dailySteps).go();
      await db.delete(db.activityEntries).go();
      await db.delete(db.bodyMeasurements).go();
      await db.delete(db.goalHistory).go();
      await db.delete(db.reminderSettings).go();
      await db.delete(db.profiles).go();
      await db.delete(db.nutritionCategories).go();
      await db.seedCategories();
    });
  }
}

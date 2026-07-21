import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

class Profiles extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();
  TextColumn get gender => text()();
  DateTimeColumn get birthDate => dateTime()();
  RealColumn get heightCm => real()();
  RealColumn get currentWeightKg => real()();
  RealColumn get targetWeightKg => real()();
  TextColumn get activityLevel => text()();
  TextColumn get goalType => text()();
  IntColumn get calorieTarget => integer()();
  RealColumn get proteinTarget => real()();
  IntColumn get waterTargetMl => integer()();
  IntColumn get stepTarget => integer().withDefault(const Constant(10000))();
  TextColumn get localeCode => text().withDefault(const Constant('tr'))();
  BoolColumn get includeActivityInBalance =>
      boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  @override
  Set<Column<Object>> get primaryKey => {id};
}

class GoalHistory extends Table {
  TextColumn get id => text()();
  DateTimeColumn get effectiveFrom => dateTime()();
  IntColumn get calorieTarget => integer()();
  RealColumn get proteinTarget => real()();
  IntColumn get waterTargetMl => integer()();
  IntColumn get stepTarget => integer()();
  @override
  Set<Column<Object>> get primaryKey => {id};
}

class NutritionCategories extends Table {
  TextColumn get id => text()();
  TextColumn get localizedKey => text().nullable()();
  TextColumn get customName => text().nullable()();
  IntColumn get iconCode => integer()();
  IntColumn get accentValue => integer()();
  BoolColumn get isSystem => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  @override
  Set<Column<Object>> get primaryKey => {id};
}

class NutritionEntries extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get categoryId => text().references(NutritionCategories, #id)();
  IntColumn get calories => integer().nullable()();
  RealColumn get proteinGrams => real().nullable()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get occurredAt => dateTime()();
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  @override
  Set<Column<Object>> get primaryKey => {id};
}

class WaterEntries extends Table {
  TextColumn get id => text()();
  IntColumn get amountMl => integer()();
  DateTimeColumn get occurredAt => dateTime()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  @override
  Set<Column<Object>> get primaryKey => {id};
}

class DailySteps extends Table {
  TextColumn get dayKey => text()();
  IntColumn get stepCount => integer()();
  RealColumn get estimatedCalories => real()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  @override
  Set<Column<Object>> get primaryKey => {dayKey};
}

class ActivityEntries extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  IntColumn get caloriesBurned => integer()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get occurredAt => dateTime()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  @override
  Set<Column<Object>> get primaryKey => {id};
}

class BodyMeasurements extends Table {
  TextColumn get id => text()();
  DateTimeColumn get measuredAt => dateTime()();
  RealColumn get weightKg => real()();
  RealColumn get waistCm => real().nullable()();
  RealColumn get neckCm => real().nullable()();
  RealColumn get hipCm => real().nullable()();
  RealColumn get chestCm => real().nullable()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  @override
  Set<Column<Object>> get primaryKey => {id};
}

class ReminderSettings extends Table {
  TextColumn get id => text()();
  TextColumn get type => text()();
  BoolColumn get isEnabled => boolean().withDefault(const Constant(false))();
  IntColumn get hour => integer()();
  IntColumn get minute => integer()();
  IntColumn get weekday => integer().nullable()();
  TextColumn get localeCode => text()();
  @override
  Set<Column<Object>> get primaryKey => {id};
}

class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  @override
  Set<Column<Object>> get primaryKey => {key};
}

@DriftDatabase(
  tables: [
    Profiles,
    GoalHistory,
    NutritionCategories,
    NutritionEntries,
    WaterEntries,
    DailySteps,
    ActivityEntries,
    BodyMeasurements,
    ReminderSettings,
    AppSettings,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.forTesting(super.executor);
  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await seedCategories();
    },
    beforeOpen: (details) async => customStatement('PRAGMA foreign_keys = ON'),
  );

  Future<void> seedCategories() async {
    const seeds = [
      ('meal', 'meal', 0xe532, 0xffff7a1a, 0),
      ('drink', 'drink', 0xe798, 0xff2f9cff, 1),
      ('snack', 'snack', 0xeb41, 0xff8b5cf6, 2),
      ('other', 'other', 0xe892, 0xff21a7ff, 3),
    ];
    await batch((b) {
      for (final s in seeds) {
        b.insert(
          nutritionCategories,
          NutritionCategoriesCompanion.insert(
            id: s.$1,
            localizedKey: Value(s.$2),
            iconCode: s.$3,
            accentValue: s.$4,
            isSystem: const Value(true),
            sortOrder: Value(s.$5),
          ),
          mode: InsertMode.insertOrIgnore,
        );
      }
    });
  }
}

LazyDatabase _openConnection() => LazyDatabase(() async {
  final dir = await getApplicationDocumentsDirectory();
  return NativeDatabase.createInBackground(
    File(p.join(dir.path, 'calbalance.sqlite')),
  );
});

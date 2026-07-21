import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/database/app_database.dart';
import 'core/repository.dart';
import 'core/reminder_scheduler.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});
final repositoryProvider = Provider<AppRepository>(
  (ref) => AppRepository(ref.watch(databaseProvider)),
);
final reminderSchedulerProvider = Provider<ReminderScheduler>(
  (ref) => ReminderScheduler(),
);
final selectedTab = ValueNotifier<int>(0);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  final scheduler = ReminderScheduler();
  await scheduler.initialize(onToday: () => selectedTab.value = 0);
  runApp(
    ProviderScope(
      overrides: [reminderSchedulerProvider.overrideWithValue(scheduler)],
      child: const CalBalanceApp(),
    ),
  );
}

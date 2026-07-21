import 'package:drift/drift.dart' hide Column;
import 'package:file_selector/file_selector.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import 'core/calculators.dart';
import 'core/database/app_database.dart';
import 'core/repository.dart';
import 'core/reminder_scheduler.dart';
import 'main.dart';
import 'l10n/app_localizations.dart';

const orange = Color(0xFFFF7A1A),
    green = Color(0xFF73DB45),
    blue = Color(0xFF219CFF),
    purple = Color(0xFF965BFF),
    bg = Color(0xFF020914),
    card = Color(0xFF071423),
    line = Color(0xFF1A2C40),
    muted = Color(0xFF9BA9BD);

String tx(BuildContext context, String tr, String en) =>
    Localizations.localeOf(context).languageCode == 'en' ? en : tr;

class CalBalanceApp extends ConsumerWidget {
  const CalBalanceApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<Profile?>(
      stream: ref.read(repositoryProvider).watchProfile(),
      builder: (context, snap) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'CalBalance',
        locale: Locale(snap.data?.localeCode ?? 'tr'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: bg,
          colorScheme: ColorScheme.fromSeed(
            seedColor: blue,
            brightness: Brightness.dark,
            surface: card,
          ),
          useMaterial3: true,
          visualDensity: VisualDensity.compact,
          fontFamily: 'Roboto',
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            toolbarHeight: 62,
            titleTextStyle: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: .6,
            ),
          ),
          cardTheme: CardThemeData(
            color: card.withValues(alpha: .9),
            elevation: 0,
            margin: const EdgeInsets.symmetric(vertical: 4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: const BorderSide(color: line),
            ),
          ),
          navigationBarTheme: NavigationBarThemeData(
            height: 72,
            backgroundColor: const Color(0xF2071322),
            indicatorColor: Colors.transparent,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            iconTheme: WidgetStateProperty.resolveWith(
              (states) => IconThemeData(
                color: states.contains(WidgetState.selected) ? blue : muted,
                size: 25,
              ),
            ),
            labelTextStyle: WidgetStateProperty.resolveWith(
              (states) => TextStyle(
                color: states.contains(WidgetState.selected) ? blue : muted,
                fontSize: 11,
                fontWeight: states.contains(WidgetState.selected)
                    ? FontWeight.w700
                    : FontWeight.w500,
              ),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: const Color(0xFF09182A),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF24354A)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF24354A)),
            ),
          ),
          bottomSheetTheme: const BottomSheetThemeData(
            backgroundColor: Color(0xFF06111F),
            modalBackgroundColor: Color(0xFF06111F),
            showDragHandle: true,
            dragHandleColor: Color(0xFF64748B),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              side: BorderSide(color: line),
            ),
          ),
          segmentedButtonTheme: SegmentedButtonThemeData(
            style: ButtonStyle(
              visualDensity: VisualDensity.compact,
              foregroundColor: WidgetStateProperty.resolveWith(
                (states) =>
                    states.contains(WidgetState.selected) ? blue : muted,
              ),
              backgroundColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.selected)
                    ? blue.withValues(alpha: .1)
                    : Colors.transparent,
              ),
              side: WidgetStateProperty.resolveWith(
                (states) => BorderSide(
                  color: states.contains(WidgetState.selected) ? blue : line,
                ),
              ),
              textStyle: const WidgetStatePropertyAll(
                TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              backgroundColor: blue,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
              textStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
        home: snap.connectionState == ConnectionState.waiting
            ? const Scaffold(body: Center(child: CircularProgressIndicator()))
            : snap.data == null
            ? const OnboardingScreen()
            : HomeShell(profile: snap.data!),
      ),
    );
  }
}

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});
  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingState();
}

class _OnboardingState extends ConsumerState<OnboardingScreen> {
  int step = 0;
  String gender = 'male', activity = 'light', goal = 'lose', locale = 'tr';
  DateTime birth = DateTime(1995, 1, 1);
  final height = TextEditingController(text: '175'),
      weight = TextEditingController(text: '80'),
      target = TextEditingController(text: '72');
  GoalResult? result;
  String _t(String tr, String en) => locale == 'en' ? en : tr;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Row(
        children: [
          Image.asset('assets/brand/app-logo.png', width: 36, height: 36),
          const SizedBox(width: 10),
          const Text('CalBalance'),
        ],
      ),
    ),
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LinearProgressIndicator(value: (step + 1) / 3),
            const SizedBox(height: 28),
            Expanded(child: _body()),
            FilledButton(
              onPressed: _next,
              child: Text(
                step == 2
                    ? _t('Kullanmaya başla', 'Get started')
                    : _t('Devam', 'Continue'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
  Widget _body() {
    if (step == 0)
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _t(
              'Hedeflerine dengeli ilerle',
              'Move toward your goals in balance',
            ),
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            _t(
              'Kalori, protein, su, aktivite ve vücut değişimini cihazında, çevrimdışı takip et.',
              'Track calories, protein, water, activity, and body changes privately on your device.',
            ),
          ),
          const SizedBox(height: 32),
          Text(_t('Dil', 'Language')),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'tr', label: Text('Türkçe')),
              ButtonSegment(value: 'en', label: Text('English')),
            ],
            selected: {locale},
            onSelectionChanged: (v) => setState(() => locale = v.first),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.lock_outline, color: blue),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _t(
                        'Verilerin yalnızca bu cihazda saklanır. Hesap veya internet gerekmez.',
                        'Your data stays on this device. No account or internet connection is required.',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    if (step == 1)
      return ListView(
        children: [
          Text(
            _t('Seni tanıyalım', 'Tell us about yourself'),
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          SegmentedButton<String>(
            segments: [
              ButtonSegment(value: 'male', label: Text(_t('Erkek', 'Male'))),
              ButtonSegment(
                value: 'female',
                label: Text(_t('Kadın', 'Female')),
              ),
            ],
            selected: {gender},
            onSelectionChanged: (v) => setState(() => gender = v.first),
          ),
          const SizedBox(height: 12),
          ListTile(
            title: Text(_t('Doğum tarihi', 'Date of birth')),
            subtitle: Text(DateFormat.yMMMd(locale).format(birth)),
            trailing: const Icon(Icons.calendar_month),
            onTap: () async {
              final v = await showDatePicker(
                context: context,
                firstDate: DateTime(1920),
                lastDate: DateTime.now(),
                initialDate: birth,
                locale: Locale(locale),
              );
              if (v != null) setState(() => birth = v);
            },
          ),
          Row(
            children: [
              Expanded(child: _field(height, _t('Boy (cm)', 'Height (cm)'))),
              const SizedBox(width: 12),
              Expanded(child: _field(weight, _t('Kilo (kg)', 'Weight (kg)'))),
            ],
          ),
          const SizedBox(height: 12),
          _field(target, _t('Hedef kilo (kg)', 'Target weight (kg)')),
          const SizedBox(height: 12),
          DropdownButtonFormField(
            initialValue: activity,
            items: [
              DropdownMenuItem(
                value: 'sedentary',
                child: Text(_t('Hareketsiz', 'Sedentary')),
              ),
              DropdownMenuItem(
                value: 'light',
                child: Text(_t('Az aktif', 'Lightly active')),
              ),
              DropdownMenuItem(
                value: 'active',
                child: Text(_t('Aktif', 'Active')),
              ),
              DropdownMenuItem(
                value: 'veryActive',
                child: Text(_t('Çok aktif', 'Very active')),
              ),
            ],
            onChanged: (v) => activity = v!,
            decoration: InputDecoration(
              labelText: _t('Aktivite seviyesi', 'Activity level'),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField(
            initialValue: goal,
            items: [
              DropdownMenuItem(
                value: 'lose',
                child: Text(_t('Kilo vermek', 'Lose weight')),
              ),
              DropdownMenuItem(
                value: 'maintain',
                child: Text(_t('Kiloyu korumak', 'Maintain weight')),
              ),
              DropdownMenuItem(
                value: 'gain',
                child: Text(_t('Kilo almak', 'Gain weight')),
              ),
            ],
            onChanged: (v) => goal = v!,
            decoration: InputDecoration(labelText: _t('Hedef', 'Goal')),
          ),
        ],
      );
    final r = result!;
    return ListView(
      children: [
        Text(
          _t('Günlük hedeflerin', 'Your daily targets'),
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          _t(
            'Bunları daha sonra Ayarlar’dan değiştirebilirsin.',
            'You can change these later in Settings.',
          ),
        ),
        const SizedBox(height: 22),
        _target(
          _t('Kalori', 'Calories'),
          r.calories.toString(),
          'kcal',
          orange,
          Icons.local_fire_department,
        ),
        _target(
          _t('Protein', 'Protein'),
          r.protein.toStringAsFixed(0),
          'g',
          green,
          Icons.fitness_center,
        ),
        _target(
          _t('Su', 'Water'),
          r.water.toString(),
          'ml',
          blue,
          Icons.water_drop,
        ),
        const SizedBox(height: 12),
        Text(
          '${_t('Tahmini bazal metabolizma', 'Estimated basal metabolic rate')}: ${r.bmr.round()} kcal\n${_t('Tahmini günlük harcama', 'Estimated daily expenditure')}: ${r.tdee.round()} kcal',
          style: const TextStyle(color: Colors.white60),
        ),
      ],
    );
  }

  Widget _field(TextEditingController c, String label) => TextField(
    controller: c,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    decoration: InputDecoration(labelText: label),
  );
  Widget _target(String n, String v, String u, Color c, IconData i) => Card(
    child: ListTile(
      leading: CircleAvatar(
        backgroundColor: c.withValues(alpha: .15),
        child: Icon(i, color: c),
      ),
      title: Text(n),
      trailing: Text(
        '$v $u',
        style: TextStyle(color: c, fontSize: 22, fontWeight: FontWeight.bold),
      ),
    ),
  );
  Future<void> _next() async {
    if (step < 1) {
      setState(() => step++);
      return;
    }
    if (step == 1) {
      final h = double.tryParse(height.text), w = double.tryParse(weight.text);
      if (h == null || w == null) {
        return;
      }
      result = GoalCalculator.calculate(
        gender: gender,
        age: DateTime.now().year - birth.year,
        heightCm: h,
        weightKg: w,
        activity: activity,
        goal: goal,
      );
      setState(() => step++);
      return;
    }
    final r = result!;
    await ref
        .read(repositoryProvider)
        .saveProfile(
          ProfilesCompanion.insert(
            id: const Value(1),
            gender: gender,
            birthDate: birth,
            heightCm: double.parse(height.text),
            currentWeightKg: double.parse(weight.text),
            targetWeightKg: double.parse(target.text),
            activityLevel: activity,
            goalType: goal,
            calorieTarget: r.calories,
            proteinTarget: r.protein,
            waterTargetMl: r.water,
            localeCode: Value(locale),
          ),
        );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.profile});
  final Profile profile;
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int index = 0;
  @override
  void initState() {
    super.initState();
    selectedTab.addListener(_syncTab);
  }

  void _syncTab() {
    if (mounted && index != selectedTab.value)
      setState(() => index = selectedTab.value);
  }

  @override
  void dispose() {
    selectedTab.removeListener(_syncTab);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final pages = [
      TodayScreen(profile: widget.profile),
      HistoryScreen(profile: widget.profile),
      ProgressScreen(profile: widget.profile),
      SettingsScreen(profile: widget.profile),
    ];
    return Scaffold(
      body: IndexedStack(index: index, children: pages),
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: line, width: .7)),
        ),
        child: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: (v) {
            selectedTab.value = v;
            setState(() => index = v);
          },
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.radio_button_unchecked),
              selectedIcon: const Icon(Icons.adjust),
              label: l.today,
            ),
            NavigationDestination(
              icon: const Icon(Icons.calendar_month_outlined),
              selectedIcon: const Icon(Icons.calendar_month),
              label: l.history,
            ),
            NavigationDestination(
              icon: const Icon(Icons.trending_up),
              label: l.progress,
            ),
            NavigationDestination(
              icon: const Icon(Icons.settings_outlined),
              selectedIcon: const Icon(Icons.settings),
              label: l.settings,
            ),
          ],
        ),
      ),
    );
  }
}

class TodayScreen extends ConsumerStatefulWidget {
  const TodayScreen({super.key, required this.profile});
  final Profile profile;
  @override
  ConsumerState<TodayScreen> createState() => _TodayState();
}

class _TodayState extends ConsumerState<TodayScreen> {
  DateTime day = DateTime.now();
  @override
  Widget build(BuildContext context) {
    final repo = ref.read(repositoryProvider);
    final l = AppLocalizations.of(context);
    return Scaffold(
      body: StreamBuilder<List<NutritionEntry>>(
        stream: repo.watchNutrition(day),
        builder: (context, nSnap) {
          return StreamBuilder<List<WaterEntry>>(
            stream: repo.watchWater(day),
            builder: (context, wSnap) {
              return StreamBuilder<DailyStep?>(
                stream: repo.watchSteps(day),
                builder: (context, sSnap) {
                  return StreamBuilder<List<ActivityEntry>>(
                    stream: repo.watchActivities(day),
                    builder: (context, aSnap) {
                      final entries = nSnap.data ?? <NutritionEntry>[];
                      final waters = wSnap.data ?? <WaterEntry>[];
                      final acts = aSnap.data ?? <ActivityEntry>[];
                      final steps = sSnap.data;
                      final cal = entries.fold(
                        0,
                        (v, e) => v + (e.calories ?? 0),
                      );
                      final protein = entries.fold(
                        0.0,
                        (v, e) => v + (e.proteinGrams ?? 0),
                      );
                      final water = waters.fold(0, (v, e) => v + e.amountMl);
                      final activity =
                          acts.fold(0, (v, e) => v + e.caloriesBurned) +
                          (steps?.estimatedCalories.round() ?? 0);
                      final balance =
                          cal -
                          widget.profile.calorieTarget -
                          (widget.profile.includeActivityInBalance
                              ? activity
                              : 0);
                      return CustomScrollView(
                        slivers: [
                          SliverToBoxAdapter(child: _dashboardHeader(l)),
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(14, 2, 14, 24),
                            sliver: SliverList.list(
                              children: [
                                BalanceHero(balance: balance),
                                const SizedBox(height: 10),
                                GridView.count(
                                  crossAxisCount: 2,
                                  shrinkWrap: true,
                                  primary: false,
                                  padding: EdgeInsets.zero,
                                  physics: const NeverScrollableScrollPhysics(),
                                  childAspectRatio: 1.5,
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 10,
                                  children: [
                                    MetricCard(
                                      l.calories,
                                      cal,
                                      widget.profile.calorieTarget,
                                      'kcal',
                                      orange,
                                      Icons.local_fire_department,
                                      onAdd: () => showNutritionSheet(
                                        context,
                                        repo,
                                        day,
                                      ),
                                    ),
                                    MetricCard(
                                      l.protein,
                                      protein,
                                      widget.profile.proteinTarget,
                                      'g',
                                      green,
                                      Icons.fitness_center,
                                      onAdd: () => showNutritionSheet(
                                        context,
                                        repo,
                                        day,
                                      ),
                                    ),
                                    MetricCard(
                                      l.water,
                                      water,
                                      widget.profile.waterTargetMl,
                                      'ml',
                                      blue,
                                      Icons.water_drop,
                                      quickAction: () =>
                                          repo.addWater(250, day),
                                      onAdd: () => _customWater(repo),
                                    ),
                                    MetricCard(
                                      l.steps,
                                      steps?.stepCount ?? 0,
                                      widget.profile.stepTarget,
                                      '',
                                      purple,
                                      Icons.directions_walk,
                                      onAdd: () => _steps(repo),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                _activity(repo, steps, activity),
                                const SizedBox(height: 18),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      tx(
                                        context,
                                        'BUGÜNKÜ KAYITLAR',
                                        "TODAY'S ENTRIES",
                                      ),
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: .5,
                                      ),
                                    ),
                                    TextButton.icon(
                                      onPressed: () => showNutritionSheet(
                                        context,
                                        repo,
                                        day,
                                      ),
                                      icon: const Icon(Icons.add, size: 18),
                                      label: Text(l.addEntry.toUpperCase()),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                if (entries.isEmpty)
                                  EmptyCard(
                                    icon: Icons.restaurant,
                                    title: tx(
                                      context,
                                      'Henüz kayıt yok',
                                      'No entries yet',
                                    ),
                                    body: tx(
                                      context,
                                      'Kalori veya protein ekleyerek gününü kaydetmeye başla.',
                                      'Start your day by adding calories or protein.',
                                    ),
                                  ),
                                Column(
                                  children: entries
                                      .map(
                                        (e) => EntryTile(
                                          key: ValueKey('nutrition-${e.id}'),
                                          entry: e,
                                          onEdit: () => showNutritionSheet(
                                            context,
                                            repo,
                                            day,
                                            existing: e,
                                          ),
                                          onDelete: () =>
                                              repo.deleteNutrition(e.id),
                                          onFavorite: () =>
                                              repo.toggleFavorite(e),
                                          onRepeat: () =>
                                              repo.repeatNutrition(e, day),
                                        ),
                                      )
                                      .toList(),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _dashboardHeader(AppLocalizations l) => SafeArea(
    bottom: false,
    child: SizedBox(
      height: 64,
      child: Row(
        children: [
          const SizedBox(width: 14),
          const Icon(Icons.local_fire_department, color: orange, size: 30),
          Expanded(
            child: Text(
              dayKey(day) == dayKey(DateTime.now())
                  ? l.today.toUpperCase()
                  : DateFormat.MMMMd(
                      Localizations.localeOf(context).languageCode,
                    ).format(day),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: .7,
              ),
            ),
          ),
          IconButton(
            onPressed: _pickDay,
            icon: const Icon(Icons.calendar_month_outlined, color: muted),
          ),
          const SizedBox(width: 4),
        ],
      ),
    ),
  );

  Widget _activity(AppRepository repo, DailyStep? steps, int calories) => Card(
    child: ListTile(
      leading: const CircleAvatar(
        child: Icon(Icons.directions_walk, color: purple),
      ),
      title: Text(
        '${steps?.stepCount ?? 0} ${tx(context, 'adım', 'steps')} · $calories kcal',
      ),
      subtitle: Text(
        tx(context, 'Adım ve ekstra aktivite', 'Steps and extra activity'),
      ),
      trailing: const Icon(Icons.add),
      onTap: () => _activityActions(repo),
    ),
  );
  Future<void> _pickDay() async {
    final d = await showDatePicker(
      context: context,
      initialDate: day,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (d != null) setState(() => day = d);
  }

  Future<void> _customWater(AppRepository r) async {
    final c = TextEditingController();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (x) => Padding(
        padding: EdgeInsets.fromLTRB(
          18,
          4,
          18,
          MediaQuery.viewInsetsOf(x).bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              tx(x, 'SU EKLE', 'ADD WATER'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 18),
            TextField(
              autofocus: true,
              controller: c,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.water_drop, color: blue),
                labelText: tx(x, 'Miktar (ml)', 'Amount (ml)'),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                for (final amount in [250, 500, 1000]) ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => c.text = amount.toString(),
                      child: Text('$amount ml'),
                    ),
                  ),
                  if (amount != 1000) const SizedBox(width: 7),
                ],
              ],
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: () {
                final v = int.tryParse(c.text);
                if (v != null && v > 0) r.addWater(v, day);
                Navigator.pop(x);
              },
              icon: const Icon(Icons.add),
              label: Text(tx(x, 'Ekle', 'Add')),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _steps(AppRepository r) async {
    final c = TextEditingController();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (x) => Padding(
        padding: EdgeInsets.fromLTRB(
          18,
          4,
          18,
          MediaQuery.viewInsetsOf(x).bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              tx(x, 'ADIM SAYISI', 'STEP COUNT'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 18),
            TextField(
              autofocus: true,
              controller: c,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.directions_walk, color: purple),
                labelText: tx(x, 'Bugünkü toplam adım', "Today's total steps"),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                for (final amount in [2500, 5000, 10000]) ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => c.text = amount.toString(),
                      child: Text(switch (amount) {
                        2500 => '2.5K',
                        5000 => '5K',
                        _ => '10K',
                      }),
                    ),
                  ),
                  if (amount != 10000) const SizedBox(width: 7),
                ],
              ],
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: () async {
                final v = int.tryParse(c.text);
                if (v == null || v < 0) {
                  ScaffoldMessenger.of(x).showSnackBar(
                    SnackBar(
                      content: Text(
                        tx(
                          x,
                          'Geçerli bir adım sayısı gir.',
                          'Enter a valid step count.',
                        ),
                      ),
                    ),
                  );
                  return;
                }
                await r.setSteps(
                  day,
                  v,
                  HealthCalculators.stepCalories(
                    steps: v,
                    heightCm: widget.profile.heightCm,
                    weightKg: widget.profile.currentWeightKg,
                    gender: widget.profile.gender,
                  ),
                );
                if (x.mounted) Navigator.pop(x);
              },
              icon: const Icon(Icons.check),
              label: Text(tx(x, 'Kaydet', 'Save')),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _activityActions(AppRepository repo) async {
    await showModalBottomSheet(
      context: context,
      builder: (sheet) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.directions_walk, color: purple),
              title: Text(
                tx(context, 'Adım sayısını düzenle', 'Edit step count'),
              ),
              onTap: () {
                Navigator.pop(sheet);
                _steps(repo);
              },
            ),
            ListTile(
              leading: const Icon(Icons.fitness_center, color: purple),
              title: Text(
                tx(context, 'Ekstra aktivite ekle', 'Add extra activity'),
              ),
              onTap: () {
                Navigator.pop(sheet);
                _addActivity(repo);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addActivity(AppRepository repo) async {
    final title = TextEditingController(), calories = TextEditingController();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheet) => Padding(
        padding: EdgeInsets.fromLTRB(
          18,
          4,
          18,
          MediaQuery.viewInsetsOf(sheet).bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              tx(sheet, 'EKSTRA AKTİVİTE', 'EXTRA ACTIVITY'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 18),
            TextField(
              autofocus: true,
              controller: title,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.fitness_center, color: purple),
                labelText: tx(sheet, 'Aktivite adı', 'Activity name'),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: calories,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                prefixIcon: const Icon(
                  Icons.local_fire_department,
                  color: orange,
                ),
                labelText: tx(sheet, 'Harcanan kalori', 'Calories burned'),
                suffixText: 'kcal',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                for (final amount in [100, 250, 500]) ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => calories.text = amount.toString(),
                      child: Text('$amount kcal'),
                    ),
                  ),
                  if (amount != 500) const SizedBox(width: 7),
                ],
              ],
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: () async {
                final value = int.tryParse(calories.text);
                if (title.text.trim().isEmpty || value == null || value <= 0) {
                  ScaffoldMessenger.of(sheet).showSnackBar(
                    SnackBar(
                      content: Text(
                        tx(
                          sheet,
                          'Aktivite adı ve geçerli bir kalori miktarı gir.',
                          'Enter an activity name and a valid calorie amount.',
                        ),
                      ),
                    ),
                  );
                  return;
                }
                await repo.addActivity(
                  title.text.trim(),
                  value,
                  DateTime(
                    day.year,
                    day.month,
                    day.day,
                    DateTime.now().hour,
                    DateTime.now().minute,
                  ),
                );
                if (sheet.mounted) Navigator.pop(sheet);
              },
              icon: const Icon(Icons.add),
              label: Text(tx(sheet, 'Aktivite ekle', 'Add activity')),
            ),
          ],
        ),
      ),
    );
  }
}

class BalanceHero extends StatelessWidget {
  const BalanceHero({super.key, required this.balance});
  final int balance;
  @override
  Widget build(BuildContext context) => Container(
    height: 216,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      gradient: const RadialGradient(
        center: Alignment(0, -.15),
        radius: .9,
        colors: [Color(0xFF0A2E58), Color(0xFF07182D), Color(0xFF040D19)],
      ),
      border: Border.all(color: line),
      boxShadow: [BoxShadow(color: blue.withValues(alpha: .1), blurRadius: 28)],
    ),
    child: Stack(
      alignment: Alignment.center,
      children: [
        Positioned.fill(child: CustomPaint(painter: const _WavePainter())),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 142,
              height: 142,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: blue.withValues(alpha: .32),
                          blurRadius: 24,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                  Positioned.fill(
                    child: TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 900),
                      curve: Curves.easeOutCubic,
                      tween: Tween(end: .78),
                      builder: (context, value, _) => CircularProgressIndicator(
                        value: value,
                        strokeWidth: 6,
                        strokeCap: StrokeCap.round,
                        backgroundColor: blue.withValues(alpha: .12),
                        color: blue,
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 700),
                        curve: Curves.easeOutCubic,
                        tween: Tween(end: balance.toDouble()),
                        builder: (context, value, _) => Text(
                          '${value > 0 ? '+' : ''}${value.round()}',
                          style: const TextStyle(
                            fontSize: 38,
                            height: 1,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              tx(context, 'Günlük Denge', 'Daily Balance'),
              style: const TextStyle(
                color: muted,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _WavePainter extends CustomPainter {
  const _WavePainter();
  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < 5; i++) {
      final paint = Paint()
        ..color = blue.withValues(alpha: .18 - i * .025)
        ..style = PaintingStyle.stroke
        ..strokeWidth = .8;
      final y = size.height * (.76 + i * .035);
      final path = Path()
        ..moveTo(0, y)
        ..cubicTo(
          size.width * .23,
          y - 27 + i * 2,
          size.width * .34,
          y + 22,
          size.width * .5,
          y,
        )
        ..cubicTo(
          size.width * .68,
          y - 22,
          size.width * .78,
          y + 25 - i * 2,
          size.width,
          y - 3,
        );
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class MetricCard extends StatelessWidget {
  const MetricCard(
    this.name,
    this.value,
    this.target,
    this.unit,
    this.color,
    this.icon, {
    super.key,
    this.onAdd,
    this.quickAction,
  });
  final String name, unit;
  final num value, target;
  final Color color;
  final IconData icon;
  final VoidCallback? onAdd, quickAction;
  @override
  Widget build(BuildContext context) {
    final p = target == 0 ? 0.0 : (value / target).clamp(0, 1).toDouble();
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0A192A), Color(0xFF06111F)],
        ),
        border: Border.all(color: line),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 11, 11, 11),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: .1),
                    border: Border.all(color: color.withValues(alpha: .5)),
                  ),
                  child: Icon(icon, color: color, size: 17),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (quickAction != null) ...[
                  Tooltip(
                    message: tx(
                      context,
                      'Hızlıca 250 ml ekle',
                      'Quick add 250 ml',
                    ),
                    child: Semantics(
                      button: true,
                      label: tx(
                        context,
                        'Hızlıca 250 ml su ekle',
                        'Quick add 250 ml water',
                      ),
                      child: InkResponse(
                        onTap: quickAction,
                        radius: 18,
                        child: Container(
                          width: 27,
                          height: 27,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: .1),
                            borderRadius: BorderRadius.circular(9),
                            border: Border.all(
                              color: color.withValues(alpha: .3),
                            ),
                          ),
                          child: Icon(
                            Icons.local_drink,
                            size: 15,
                            color: color,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),
                ],
                if (onAdd != null)
                  InkResponse(
                    onTap: onAdd,
                    radius: 18,
                    child: Container(
                      width: 27,
                      height: 27,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: .13),
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(color: color.withValues(alpha: .35)),
                      ),
                      child: Icon(Icons.add, size: 17, color: color),
                    ),
                  ),
              ],
            ),
            const Spacer(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: FittedBox(
                    alignment: Alignment.centerLeft,
                    fit: BoxFit.scaleDown,
                    child: TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOut,
                      tween: Tween(end: value.toDouble()),
                      builder: (context, animated, _) => Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: '${animated.round()}',
                              style: TextStyle(
                                color: color,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            TextSpan(
                              text: ' / ${target.toStringAsFixed(0)} $unit',
                              style: const TextStyle(
                                color: muted,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Text(
                  '${(p * 100).round()}%',
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 650),
              curve: Curves.easeOutCubic,
              tween: Tween(end: p),
              builder: (context, animated, _) => LinearProgressIndicator(
                value: animated,
                color: color,
                backgroundColor: color.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(8),
                minHeight: 5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EmptyCard extends StatelessWidget {
  const EmptyCard({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
  });
  final IconData icon;
  final String title, body;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        children: [
          Icon(icon, size: 36, color: Colors.white38),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(
            body,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white54),
          ),
        ],
      ),
    ),
  );
}

class EntryTile extends StatelessWidget {
  const EntryTile({
    super.key,
    required this.entry,
    required this.onEdit,
    required this.onDelete,
    required this.onFavorite,
    required this.onRepeat,
  });
  final NutritionEntry entry;
  final VoidCallback onEdit, onDelete, onFavorite, onRepeat;
  @override
  Widget build(BuildContext context) {
    final accent = switch (entry.categoryId) {
      'meal' => orange,
      'drink' => green,
      'snack' => purple,
      _ => blue,
    };
    final icon = switch (entry.categoryId) {
      'drink' => Icons.local_drink,
      'snack' => Icons.cake,
      'other' => Icons.sell,
      _ => Icons.restaurant,
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF09192A), Color(0xFF06111F)],
        ),
        border: Border.all(color: line),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.only(left: 11, right: 4),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: accent.withValues(alpha: .08),
            border: Border.all(color: accent.withValues(alpha: .75)),
          ),
          child: Icon(icon, color: accent, size: 21),
        ),
        title: Text(
          entry.title.isEmpty || entry.title == 'Besin kaydı'
              ? tx(context, 'İsimsiz kayıt', 'Untitled entry')
              : entry.title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          [
            if (entry.calories != null) '${entry.calories} kcal',
            if (entry.proteinGrams != null)
              '${entry.proteinGrams!.toStringAsFixed(0)} g',
          ].join(' · '),
          style: const TextStyle(color: muted, fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              DateFormat.Hm().format(entry.occurredAt),
              style: const TextStyle(color: muted, fontSize: 11),
            ),
            PopupMenuButton<String>(
              iconColor: muted,
              onSelected: (v) {
                if (v == 'edit') onEdit();
                if (v == 'delete') onDelete();
                if (v == 'favorite') onFavorite();
                if (v == 'repeat') onRepeat();
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Text(tx(context, 'Düzenle', 'Edit')),
                ),
                PopupMenuItem(
                  value: 'favorite',
                  child: Text(
                    entry.isFavorite
                        ? tx(context, 'Favoriden çıkar', 'Remove favorite')
                        : tx(context, 'Favorile', 'Add favorite'),
                  ),
                ),
                PopupMenuItem(
                  value: 'repeat',
                  child: Text(tx(context, 'Tekrar ekle', 'Add again')),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Text(tx(context, 'Sil', 'Delete')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> showNutritionSheet(
  BuildContext context,
  AppRepository repo,
  DateTime day, {
  NutritionEntry? existing,
}) async {
  final l = AppLocalizations.of(context);
  final title = TextEditingController(
        text: existing?.title == 'Besin kaydı' ? '' : existing?.title,
      ),
      cal = TextEditingController(text: existing?.calories?.toString()),
      protein = TextEditingController(text: existing?.proteinGrams?.toString()),
      note = TextEditingController(text: existing?.note);
  String category = existing?.categoryId ?? 'other';
  var occurredAt =
      existing?.occurredAt ??
      DateTime(
        day.year,
        day.month,
        day.day,
        DateTime.now().hour,
        DateTime.now().minute,
      );
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, set) => Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          4,
          16,
          MediaQuery.viewInsetsOf(ctx).bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const SizedBox(width: 40),
                  Expanded(
                    child: Text(
                      (existing == null
                              ? l.addEntry
                              : (Localizations.localeOf(context).languageCode ==
                                        'en'
                                    ? 'Edit entry'
                                    : 'Kaydı düzenle'))
                          .toUpperCase(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: .5,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: card,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: line),
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: title,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(
                          Icons.edit_outlined,
                          color: blue,
                        ),
                        labelText: tx(
                          ctx,
                          'Başlık (isteğe bağlı)',
                          'Title (optional)',
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: cal,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              prefixIcon: const Icon(
                                Icons.local_fire_department,
                                color: orange,
                              ),
                              labelText: l.calories,
                              suffixText: 'kcal',
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: protein,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: InputDecoration(
                              prefixIcon: const Icon(
                                Icons.fitness_center,
                                color: green,
                              ),
                              labelText: l.protein,
                              suffixText: 'g',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.calendar_month_outlined),
                            label: Text(
                              DateFormat(
                                'd MMM y',
                                Localizations.localeOf(ctx).languageCode,
                              ).format(occurredAt),
                            ),
                            onPressed: () async {
                              final selected = await showDatePicker(
                                context: ctx,
                                initialDate: occurredAt,
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now(),
                              );
                              if (selected != null) {
                                set(
                                  () => occurredAt = DateTime(
                                    selected.year,
                                    selected.month,
                                    selected.day,
                                    occurredAt.hour,
                                    occurredAt.minute,
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.schedule),
                            label: Text(DateFormat.Hm().format(occurredAt)),
                            onPressed: () async {
                              final selected = await showTimePicker(
                                context: ctx,
                                initialTime: TimeOfDay.fromDateTime(occurredAt),
                              );
                              if (selected != null) {
                                set(
                                  () => occurredAt = DateTime(
                                    occurredAt.year,
                                    occurredAt.month,
                                    occurredAt.day,
                                    selected.hour,
                                    selected.minute,
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(
                tx(ctx, 'KATEGORİ', 'CATEGORY'),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              StreamBuilder<List<NutritionCategory>>(
                stream: repo.watchCategories(),
                builder: (context, snapshot) => Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: (snapshot.data ?? <NutritionCategory>[])
                      .map(
                        (e) => ChoiceChip(
                          avatar: Icon(
                            e.id == 'meal'
                                ? Icons.restaurant
                                : e.id == 'drink'
                                ? Icons.local_drink
                                : e.id == 'snack'
                                ? Icons.cake
                                : Icons.sell,
                            size: 17,
                          ),
                          label: Text(
                            e.customName ??
                                {
                                  'meal': tx(ctx, 'Yemek', 'Meal'),
                                  'drink': tx(ctx, 'İçecek', 'Drink'),
                                  'snack': tx(ctx, 'Atıştırmalık', 'Snack'),
                                  'other': tx(ctx, 'Diğer', 'Other'),
                                }[e.localizedKey] ??
                                tx(ctx, 'Diğer', 'Other'),
                          ),
                          selected: category == e.id,
                          onSelected: (_) => set(() => category = e.id),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: note,
                decoration: InputDecoration(
                  labelText: tx(ctx, 'Not (isteğe bağlı)', 'Note (optional)'),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  final c = int.tryParse(cal.text),
                      p = double.tryParse(protein.text.replaceAll(',', '.'));
                  if (c == null && p == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          tx(
                            ctx,
                            'Kalori veya protein alanlarından biri zorunludur.',
                            'Calories or protein is required.',
                          ),
                        ),
                      ),
                    );
                    return;
                  }
                  if (existing == null) {
                    repo.addNutrition(
                      title: title.text,
                      categoryId: category,
                      calories: c,
                      protein: p,
                      note: note.text,
                      at: occurredAt,
                    );
                  } else {
                    repo.updateNutrition(
                      existing,
                      title: title.text,
                      categoryId: category,
                      calories: c,
                      protein: p,
                      note: note.text,
                      occurredAt: occurredAt,
                    );
                  }
                  Navigator.pop(ctx);
                },
                child: Text(l.save),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key, required this.profile});
  final Profile profile;
  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  int days = 30;
  @override
  Widget build(BuildContext context) {
    final repo = ref.read(repositoryProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).history.toUpperCase()),
        actions: [
          IconButton(
            tooltip: tx(context, 'Tarihe git', 'Go to date'),
            icon: const Icon(Icons.calendar_month_outlined),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
                initialDate: DateTime.now(),
              );
              if (picked != null && context.mounted) {
                _showDay(context, repo, picked);
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: SegmentedButton<int>(
              segments: [
                ButtonSegment(
                  value: 7,
                  label: Text(tx(context, '7 Gün', '7 Days')),
                ),
                ButtonSegment(
                  value: 30,
                  label: Text(tx(context, '30 Gün', '30 Days')),
                ),
                ButtonSegment(
                  value: 0,
                  label: Text(tx(context, 'Tümü', 'All')),
                ),
              ],
              selected: {days},
              onSelectionChanged: (value) => setState(() => days = value.first),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<DailySummary>>(
              future: repo.summariesForDays(days),
              builder: (context, s) {
                if (!s.hasData)
                  return const Center(child: CircularProgressIndicator());
                final data = s.data!;
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 90),
                  itemCount: data.length,
                  itemBuilder: (context, i) {
                    final index = data.length - 1 - i,
                        d = DateTime.now().subtract(Duration(days: i)),
                        v = data[index],
                        balance = v.calories - widget.profile.calorieTarget;
                    return _historyCard(context, repo, d, v, balance);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _historyCard(
    BuildContext context,
    AppRepository repo,
    DateTime date,
    DailySummary value,
    int balance,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => _showDay(context, repo, date),
      child: Ink(
        padding: const EdgeInsets.fromLTRB(12, 9, 8, 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            colors: [Color(0xFF0A192A), Color(0xFF06111F)],
          ),
          border: Border.all(color: line),
        ),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.calendar_month, color: blue, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    DateFormat(
                      'd MMMM EEEE',
                      Localizations.localeOf(context).languageCode,
                    ).format(date),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right, color: muted),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _historyMetric(
                  Icons.local_fire_department,
                  'Kalori',
                  '${value.calories}',
                  orange,
                ),
                _historyMetric(
                  Icons.fitness_center,
                  'Protein',
                  '${value.protein.round()} g',
                  green,
                ),
                _historyMetric(
                  Icons.water_drop,
                  'Su',
                  '${value.water} ml',
                  blue,
                ),
                _historyMetric(
                  Icons.adjust,
                  'Denge',
                  '${balance > 0 ? '+' : ''}$balance',
                  balance <= 0 ? blue : orange,
                  last: true,
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  Widget _historyMetric(
    IconData icon,
    String label,
    String value,
    Color color, {
    bool last = false,
  }) => Expanded(
    child: Container(
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(right: BorderSide(color: line, width: .7)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 17),
              const SizedBox(width: 5),
              Flexible(
                child: FittedBox(
                  child: Text(
                    value,
                    style: TextStyle(
                      color: color,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  Future<void> _showDay(
    BuildContext context,
    AppRepository repo,
    DateTime day,
  ) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheet) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: .82,
        maxChildSize: .95,
        builder: (context, controller) => StreamBuilder<List<NutritionEntry>>(
          stream: repo.watchNutrition(day),
          builder: (context, n) => StreamBuilder<List<WaterEntry>>(
            stream: repo.watchWater(day),
            builder: (context, w) => StreamBuilder<List<ActivityEntry>>(
              stream: repo.watchActivities(day),
              builder: (context, a) {
                final entries = n.data ?? <NutritionEntry>[];
                final waters = w.data ?? <WaterEntry>[];
                final activities = a.data ?? <ActivityEntry>[];
                return ListView(
                  controller: controller,
                  padding: const EdgeInsets.all(16),
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            DateFormat(
                              'd MMMM EEEE',
                              Localizations.localeOf(context).languageCode,
                            ).format(day),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () =>
                              showNutritionSheet(context, repo, day),
                          icon: const Icon(Icons.add),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      tx(context, 'BESİN KAYITLARI', 'NUTRITION ENTRIES'),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    if (entries.isEmpty)
                      Text(
                        tx(context, 'Kayıt yok', 'No entries'),
                        style: const TextStyle(color: Colors.white54),
                      ),
                    ...entries.map(
                      (e) => EntryTile(
                        entry: e,
                        onEdit: () =>
                            showNutritionSheet(context, repo, day, existing: e),
                        onDelete: () => repo.deleteNutrition(e.id),
                        onFavorite: () => repo.toggleFavorite(e),
                        onRepeat: () => repo.repeatNutrition(e, day),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      tx(context, 'SU KAYITLARI', 'WATER ENTRIES'),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    ...waters.map(
                      (e) => ListTile(
                        leading: const Icon(Icons.water_drop, color: blue),
                        title: Text('${e.amountMl} ml'),
                        subtitle: Text(DateFormat.Hm().format(e.occurredAt)),
                        trailing: IconButton(
                          onPressed: () => repo.deleteWater(e.id),
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      tx(context, 'AKTİVİTELER', 'ACTIVITIES'),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    ...activities.map(
                      (e) => ListTile(
                        leading: const Icon(
                          Icons.fitness_center,
                          color: purple,
                        ),
                        title: Text(e.title),
                        subtitle: Text('${e.caloriesBurned} kcal'),
                        trailing: IconButton(
                          onPressed: () => repo.deleteActivity(e.id),
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key, required this.profile});
  final Profile profile;
  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> {
  int days = 30;
  String metric = 'balance';
  String section = 'progress';
  @override
  Widget build(BuildContext context) {
    final repo = ref.read(repositoryProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).progress.toUpperCase()),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 10),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<String>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(
                    value: 'progress',
                    label: Text(tx(context, 'İlerleme', 'Progress')),
                  ),
                  ButtonSegment(
                    value: 'measurements',
                    label: Text(tx(context, 'Ölçümler', 'Measurements')),
                  ),
                  ButtonSegment(
                    value: 'weekly',
                    label: Text(tx(context, 'Haftalık', 'Weekly')),
                  ),
                ],
                selected: {section},
                onSelectionChanged: (value) =>
                    setState(() => section = value.first),
              ),
            ),
          ),
          Expanded(
            child: switch (section) {
              'measurements' => _measurementsContent(repo),
              'weekly' => _weeklyContent(repo),
              _ => _progressContent(repo),
            },
          ),
        ],
      ),
    );
  }

  Widget _progressContent(AppRepository repo) => ListView(
    padding: const EdgeInsets.fromLTRB(14, 2, 14, 90),
    children: [
      SegmentedButton<int>(
        showSelectedIcon: false,
        segments: [
          ButtonSegment(value: 7, label: Text(tx(context, '7 Gün', '7 Days'))),
          ButtonSegment(
            value: 30,
            label: Text(tx(context, '30 Gün', '30 Days')),
          ),
          ButtonSegment(
            value: 90,
            label: Text(tx(context, '90 Gün', '90 Days')),
          ),
          ButtonSegment(value: 0, label: Text(tx(context, 'Tümü', 'All'))),
        ],
        selected: {days},
        onSelectionChanged: (value) => setState(() => days = value.first),
      ),
      const SizedBox(height: 10),
      SegmentedButton<String>(
        showSelectedIcon: false,
        segments: [
          ButtonSegment(
            value: 'balance',
            label: Text(tx(context, 'Denge', 'Balance')),
          ),
          ButtonSegment(
            value: 'protein',
            label: Text(tx(context, 'Protein', 'Protein')),
          ),
          ButtonSegment(
            value: 'water',
            label: Text(tx(context, 'Su', 'Water')),
          ),
          ButtonSegment(
            value: 'steps',
            label: Text(tx(context, 'Adım', 'Steps')),
          ),
        ],
        selected: {metric},
        onSelectionChanged: (value) => setState(() => metric = value.first),
      ),
      const SizedBox(height: 10),
      _periodSummary(repo),
    ],
  );

  Widget _measurementsContent(
    AppRepository repo,
  ) => StreamBuilder<List<BodyMeasurement>>(
    stream: repo.watchMeasurements(),
    builder: (context, snapshot) {
      final measurements = snapshot.data ?? [];
      final current = measurements.firstOrNull;
      return ListView(
        padding: const EdgeInsets.fromLTRB(14, 2, 14, 90),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const RadialGradient(
                colors: [Color(0xFF0A315C), Color(0xFF061321)],
              ),
              border: Border.all(color: line),
            ),
            child: current == null
                ? EmptyCard(
                    icon: Icons.monitor_weight_outlined,
                    title: tx(
                      context,
                      'Henüz ölçüm yok',
                      'No measurements yet',
                    ),
                    body: tx(
                      context,
                      'İlk ölçümünü ekleyerek değişimi takip et.',
                      'Add your first measurement to track changes.',
                    ),
                  )
                : Wrap(
                    alignment: WrapAlignment.spaceAround,
                    spacing: 18,
                    runSpacing: 16,
                    children: [
                      _stat(
                        tx(context, 'Kilo', 'Weight'),
                        '${current.weightKg.toStringAsFixed(1)} kg',
                        blue,
                      ),
                      if (current.waistCm != null)
                        _stat(
                          tx(context, 'Bel', 'Waist'),
                          '${current.waistCm!.toStringAsFixed(1)} cm',
                          orange,
                        ),
                      if (current.neckCm != null)
                        _stat(
                          tx(context, 'Boyun', 'Neck'),
                          '${current.neckCm!.toStringAsFixed(1)} cm',
                          green,
                        ),
                      _stat(
                        'BMI',
                        HealthCalculators.bmi(
                          current.weightKg,
                          widget.profile.heightCm,
                        ).toStringAsFixed(1),
                        purple,
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => _measurement(context, repo),
            icon: const Icon(Icons.add_circle_outline),
            label: Text(tx(context, 'Yeni ölçüm ekle', 'Add measurement')),
          ),
          const SizedBox(height: 14),
          Text(
            tx(context, 'GEÇMİŞ ÖLÇÜMLER', 'MEASUREMENT HISTORY'),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          ...measurements.map(
            (entry) => Card(
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0x19219CFF),
                  child: Icon(Icons.monitor_weight, color: blue),
                ),
                title: Text('${entry.weightKg.toStringAsFixed(1)} kg'),
                subtitle: Text(
                  DateFormat.yMMMd(
                    Localizations.localeOf(context).languageCode,
                  ).format(entry.measuredAt),
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit')
                      _measurement(context, repo, existing: entry);
                    if (value == 'delete') repo.deleteMeasurement(entry);
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Text(tx(context, 'Düzenle', 'Edit')),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text(tx(context, 'Sil', 'Delete')),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            tx(
              context,
              'Bu değerler tahminidir ve tıbbi ölçüm yerine geçmez.',
              'These values are estimates and do not replace medical measurements.',
            ),
            style: const TextStyle(color: muted, fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ],
      );
    },
  );

  Widget _weeklyContent(
    AppRepository repo,
  ) => FutureBuilder<List<DailySummary>>(
    future: repo.summariesForDays(7),
    builder: (context, snapshot) {
      final values = snapshot.data;
      if (values == null)
        return const Center(child: CircularProgressIndicator());
      final divisor = values.isEmpty ? 1 : values.length;
      final avgCal = values.fold(0, (sum, e) => sum + e.calories) / divisor;
      final avgProtein =
          values.fold(0.0, (sum, e) => sum + e.protein) / divisor;
      final avgWater = values.fold(0, (sum, e) => sum + e.water) / divisor;
      final avgSteps = values.fold(0, (sum, e) => sum + e.steps) / divisor;
      final balance = values.fold(
        0,
        (sum, e) => sum + e.calories - widget.profile.calorieTarget,
      );
      final proteinDays = values
          .where((e) => e.protein >= widget.profile.proteinTarget)
          .length;
      final waterDays = values
          .where((e) => e.water >= widget.profile.waterTargetMl)
          .length;
      return ListView(
        padding: const EdgeInsets.fromLTRB(14, 2, 14, 90),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 25,
                    backgroundColor: Color(0x19219CFF),
                    child: Icon(Icons.check, color: blue),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tx(context, 'Haftalık özetin', 'Your weekly summary'),
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          tx(
                            context,
                            'Son 7 gündeki ritmini gör.',
                            'See your rhythm over the last 7 days.',
                          ),
                          style: const TextStyle(color: muted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          _weeklyRow(
            Icons.local_fire_department,
            tx(context, 'Kalori', 'Calories'),
            '${avgCal.round()} kcal',
            '${balance > 0 ? '+' : ''}$balance kcal',
            orange,
          ),
          _weeklyRow(
            Icons.fitness_center,
            tx(context, 'Protein', 'Protein'),
            '${avgProtein.round()} g',
            '$proteinDays/7',
            green,
          ),
          _weeklyRow(
            Icons.water_drop,
            tx(context, 'Su', 'Water'),
            '${avgWater.round()} ml',
            '$waterDays/7',
            blue,
          ),
          _weeklyRow(
            Icons.directions_walk,
            tx(context, 'Aktivite', 'Activity'),
            '${avgSteps.round()}',
            tx(context, 'ort. adım', 'avg. steps'),
            purple,
          ),
        ],
      );
    },
  );

  Widget _weeklyRow(
    IconData icon,
    String title,
    String primary,
    String secondary,
    Color color,
  ) => Card(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          CircleAvatar(
            radius: 23,
            backgroundColor: color.withValues(alpha: .1),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  tx(context, 'Günlük ortalama', 'Daily average'),
                  style: const TextStyle(color: muted, fontSize: 11),
                ),
              ],
            ),
          ),
          Text(
            primary,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 14),
          Text(secondary, style: const TextStyle(color: muted, fontSize: 12)),
        ],
      ),
    ),
  );

  Widget _stat(String a, String b, Color c) => Column(
    children: [
      Text(a, style: const TextStyle(color: Colors.white60)),
      Text(
        b,
        style: TextStyle(color: c, fontSize: 20, fontWeight: FontWeight.bold),
      ),
    ],
  );

  Widget _periodSummary(AppRepository repo) =>
      FutureBuilder<List<DailySummary>>(
        future: repo.summariesForDays(days),
        builder: (context, snapshot) {
          final values = snapshot.data;
          if (values == null)
            return const Card(
              child: SizedBox(
                height: 180,
                child: Center(child: CircularProgressIndicator()),
              ),
            );
          final divisor = values.isEmpty ? 1 : values.length;
          final chartValues = values.length > 90
              ? values.sublist(values.length - 90)
              : values;
          final avgCal = values.fold(0, (v, e) => v + e.calories) / divisor;
          final avgProtein =
              values.fold(0.0, (v, e) => v + e.protein) / divisor;
          final avgWater = values.fold(0, (v, e) => v + e.water) / divisor;
          final totalBalance = values.fold(
            0,
            (v, e) => v + e.calories - widget.profile.calorieTarget,
          );
          double metricValue(DailySummary value) => switch (metric) {
            'protein' => value.protein,
            'water' => value.water.toDouble(),
            'steps' => value.steps.toDouble(),
            _ => (value.calories - widget.profile.calorieTarget).toDouble(),
          };
          final metricColor = switch (metric) {
            'protein' => green,
            'water' => blue,
            'steps' => purple,
            _ => orange,
          };
          final metricTitle = switch (metric) {
            'protein' => tx(context, 'Günlük protein', 'Daily protein'),
            'water' => tx(context, 'Günlük su', 'Daily water'),
            'steps' => tx(context, 'Günlük adım', 'Daily steps'),
            _ => tx(context, 'Günlük kalori dengesi', 'Daily calorie balance'),
          };
          final maxMetric = chartValues.fold<double>(
            1,
            (max, item) =>
                metricValue(item).abs() > max ? metricValue(item).abs() : max,
          );
          final labelStep = chartValues.length <= 7
              ? 1
              : (chartValues.length / 3).ceil();
          final proteinGoalDays = values
              .where((e) => e.protein >= widget.profile.proteinTarget)
              .length;
          final waterGoalDays = values
              .where((e) => e.water >= widget.profile.waterTargetMl)
              .length;
          var streak = 0;
          for (final value in values.reversed) {
            if (value.calories > 0 ||
                value.protein > 0 ||
                value.water > 0 ||
                value.steps > 0) {
              streak++;
            } else {
              break;
            }
          }
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    days == 0
                        ? tx(context, 'TÜM ZAMAN', 'ALL TIME')
                        : tx(context, 'SON $days GÜN', 'LAST $days DAYS'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    metricTitle,
                    style: TextStyle(color: metricColor, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 130,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: maxMetric * 1.15,
                        minY: metric == 'balance' ? -maxMetric * 1.15 : 0,
                        barTouchData: BarTouchData(enabled: true),
                        titlesData: FlTitlesData(
                          leftTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval: 1,
                              getTitlesWidget: (v, m) {
                                final i = v.toInt();
                                if (i < 0 || i >= chartValues.length)
                                  return const SizedBox.shrink();
                                if (chartValues.length > 7 &&
                                    i != 0 &&
                                    i != chartValues.length - 1 &&
                                    i % labelStep != 0) {
                                  return const SizedBox.shrink();
                                }
                                final date = DateTime.now().subtract(
                                  Duration(days: chartValues.length - 1 - i),
                                );
                                return Text(
                                  DateFormat('d MMM').format(date),
                                  style: const TextStyle(fontSize: 9),
                                );
                              },
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        gridData: const FlGridData(show: false),
                        barGroups: [
                          for (var i = 0; i < chartValues.length; i++)
                            BarChartGroupData(
                              x: i,
                              barRods: [
                                BarChartRodData(
                                  toY: metricValue(chartValues[i]),
                                  color: metricColor,
                                  width: chartValues.length <= 7
                                      ? 14
                                      : chartValues.length <= 30
                                      ? 7
                                      : 3,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      _stat(
                        tx(context, 'Ort. kalori', 'Avg. calories'),
                        '${avgCal.round()} kcal',
                        orange,
                      ),
                      _stat(
                        tx(context, 'Toplam denge', 'Total balance'),
                        '${totalBalance > 0 ? '+' : ''}$totalBalance kcal',
                        blue,
                      ),
                      _stat(
                        tx(context, 'Ort. protein', 'Avg. protein'),
                        '${avgProtein.round()} g',
                        green,
                      ),
                      _stat(
                        tx(context, 'Ort. su', 'Avg. water'),
                        '${avgWater.round()} ml',
                        blue,
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Wrap(
                    spacing: 14,
                    runSpacing: 8,
                    children: [
                      _stat(
                        tx(context, 'Kayıt serisi', 'Logging streak'),
                        '$streak ${tx(context, 'gün', 'days')}',
                        orange,
                      ),
                      _stat(
                        tx(context, 'Protein hedefi', 'Protein goal'),
                        '$proteinGoalDays ${tx(context, 'gün', 'days')}',
                        green,
                      ),
                      _stat(
                        tx(context, 'Su hedefi', 'Water goal'),
                        '$waterGoalDays ${tx(context, 'gün', 'days')}',
                        blue,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
  Future<void> _measurement(
    BuildContext context,
    AppRepository repo, {
    BodyMeasurement? existing,
  }) async {
    final w = TextEditingController(text: existing?.weightKg.toString()),
        waist = TextEditingController(text: existing?.waistCm?.toString()),
        neck = TextEditingController(text: existing?.neckCm?.toString()),
        hip = TextEditingController(text: existing?.hipCm?.toString()),
        chest = TextEditingController(text: existing?.chestCm?.toString()),
        note = TextEditingController(text: existing?.note);
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (x) => Padding(
        padding: EdgeInsets.fromLTRB(
          18,
          4,
          18,
          MediaQuery.viewInsetsOf(x).bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                tx(
                  x,
                  existing == null ? 'YENİ ÖLÇÜM' : 'ÖLÇÜMÜ DÜZENLE',
                  existing == null ? 'NEW MEASUREMENT' : 'EDIT MEASUREMENT',
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: w,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.monitor_weight, color: blue),
                  labelText: tx(x, 'Kilo (kg)', 'Weight (kg)'),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _measurementField(
                      x,
                      waist,
                      'Bel (cm)',
                      'Waist (cm)',
                      Icons.accessibility_new,
                      orange,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _measurementField(
                      x,
                      neck,
                      'Boyun (cm)',
                      'Neck (cm)',
                      Icons.person_outline,
                      green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _measurementField(
                      x,
                      hip,
                      'Kalça (cm)',
                      'Hip (cm)',
                      Icons.accessibility,
                      purple,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _measurementField(
                      x,
                      chest,
                      'Göğüs (cm)',
                      'Chest (cm)',
                      Icons.straighten,
                      blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: note,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.edit_note, color: muted),
                  labelText: tx(x, 'Not (isteğe bağlı)', 'Note (optional)'),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () {
                  final value = double.tryParse(w.text.replaceAll(',', '.'));
                  if (value == null) return;
                  final waistValue = double.tryParse(
                        waist.text.replaceAll(',', '.'),
                      ),
                      neckValue = double.tryParse(
                        neck.text.replaceAll(',', '.'),
                      ),
                      hipValue = double.tryParse(hip.text.replaceAll(',', '.')),
                      chestValue = double.tryParse(
                        chest.text.replaceAll(',', '.'),
                      );
                  if (existing == null) {
                    repo.addMeasurement(
                      weight: value,
                      waist: waistValue,
                      neck: neckValue,
                      hip: hipValue,
                      chest: chestValue,
                      note: note.text,
                    );
                  } else {
                    repo.updateMeasurement(
                      existing,
                      weight: value,
                      waist: waistValue,
                      neck: neckValue,
                      hip: hipValue,
                      chest: chestValue,
                      note: note.text,
                    );
                  }
                  Navigator.pop(x);
                },
                icon: const Icon(Icons.check),
                label: Text(tx(x, 'Kaydet', 'Save')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _measurementField(
    BuildContext context,
    TextEditingController controller,
    String tr,
    String en,
    IconData icon,
    Color color,
  ) => TextField(
    controller: controller,
    keyboardType: TextInputType.number,
    decoration: InputDecoration(
      prefixIcon: Icon(icon, color: color, size: 20),
      labelText: tx(context, tr, en),
    ),
  );
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key, required this.profile});
  final Profile profile;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(repositoryProvider);
    final scheduler = ref.read(reminderSchedulerProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).settings.toUpperCase()),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            AppLocalizations.of(context).goals.toUpperCase(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Card(
            child: Column(
              children: [
                _goalRow(
                  AppLocalizations.of(context).calories,
                  '${profile.calorieTarget} kcal',
                  orange,
                  Icons.local_fire_department,
                ),
                _goalRow(
                  AppLocalizations.of(context).protein,
                  '${profile.proteinTarget.toStringAsFixed(0)} g',
                  green,
                  Icons.fitness_center,
                ),
                _goalRow(
                  AppLocalizations.of(context).water,
                  '${profile.waterTargetMl} ml',
                  blue,
                  Icons.water_drop,
                  last: true,
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => _editGoals(context, repo),
              icon: const Icon(Icons.edit),
              label: Text(tx(context, 'Hedefleri düzenle', 'Edit goals')),
            ),
          ),
          SwitchListTile(
            title: Text(
              tx(
                context,
                'Aktivite kalorilerini dengeye kat',
                'Include activity calories in balance',
              ),
            ),
            subtitle: Text(
              tx(
                context,
                'Kapalı tutmak çift sayım riskini azaltır.',
                'Keeping this off reduces the risk of double counting.',
              ),
            ),
            value: profile.includeActivityInBalance,
            onChanged: (v) => repo.saveProfile(
              ProfilesCompanion(
                id: const Value(1),
                gender: Value(profile.gender),
                birthDate: Value(profile.birthDate),
                heightCm: Value(profile.heightCm),
                currentWeightKg: Value(profile.currentWeightKg),
                targetWeightKg: Value(profile.targetWeightKg),
                activityLevel: Value(profile.activityLevel),
                goalType: Value(profile.goalType),
                calorieTarget: Value(profile.calorieTarget),
                proteinTarget: Value(profile.proteinTarget),
                waterTargetMl: Value(profile.waterTargetMl),
                stepTarget: Value(profile.stepTarget),
                localeCode: Value(profile.localeCode),
                includeActivityInBalance: Value(v),
                createdAt: Value(profile.createdAt),
                updatedAt: Value(DateTime.now()),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            tx(context, 'DİL', 'LANGUAGE'),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'tr', label: Text('Türkçe')),
              ButtonSegment(value: 'en', label: Text('English')),
            ],
            selected: {profile.localeCode},
            onSelectionChanged: (value) =>
                _updateProfile(repo, locale: value.first),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context).notifications.toUpperCase(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          StreamBuilder<List<ReminderSetting>>(
            stream: repo.watchReminders(),
            builder: (context, snapshot) {
              final values = {
                for (final r in snapshot.data ?? <ReminderSetting>[]) r.id: r,
              };
              return Card(
                child: Column(
                  children: [
                    _reminderTile(
                      context,
                      repo,
                      scheduler,
                      values['dailyLog'],
                      id: 'dailyLog',
                      type: 'dailyLog',
                      notificationId: 100,
                      title: tx(context, 'Günlük kayıt', 'Daily log'),
                      body: tx(
                        context,
                        'Kalori, protein, su ve adım bilgilerini eklemeyi unutma.',
                        "Don't forget to add calories, protein, water, and steps.",
                      ),
                      hour: 21,
                      minute: 30,
                      icon: Icons.local_fire_department,
                    ),
                    _reminderTile(
                      context,
                      repo,
                      scheduler,
                      values['water'],
                      id: 'water',
                      type: 'water',
                      notificationId: 101,
                      title: tx(context, 'Su hatırlatması', 'Water reminder'),
                      body: tx(
                        context,
                        'Bir bardak su içmenin tam zamanı.',
                        'Time for a glass of water.',
                      ),
                      hour: 14,
                      minute: 0,
                      icon: Icons.water_drop,
                    ),
                    _reminderTile(
                      context,
                      repo,
                      scheduler,
                      values['steps'],
                      id: 'steps',
                      type: 'steps',
                      notificationId: 102,
                      title: tx(context, 'Adım girişi', 'Step entry'),
                      body: tx(
                        context,
                        'Bugünkü adım sayını kaydet.',
                        "Log today's step count.",
                      ),
                      hour: 21,
                      minute: 0,
                      icon: Icons.directions_walk,
                    ),
                    _reminderTile(
                      context,
                      repo,
                      scheduler,
                      values['weeklyWeight'],
                      id: 'weeklyWeight',
                      type: 'weeklyWeight',
                      notificationId: 103,
                      title: tx(
                        context,
                        'Haftalık tartılma',
                        'Weekly weigh-in',
                      ),
                      body: tx(
                        context,
                        'İlerlemeni görmek için ölçümünü kaydet.',
                        'Log your measurement to see your progress.',
                      ),
                      hour: 9,
                      minute: 0,
                      weekday: DateTime.sunday,
                      icon: Icons.monitor_weight,
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context).categories.toUpperCase(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          StreamBuilder<List<NutritionCategory>>(
            stream: repo.watchCategories(),
            builder: (context, snapshot) => Card(
              child: Column(
                children: [
                  for (final c in snapshot.data ?? <NutritionCategory>[])
                    ListTile(
                      leading: Icon(Icons.label, color: Color(c.accentValue)),
                      title: Text(
                        c.customName ?? _categoryLabel(context, c.localizedKey),
                      ),
                      trailing: c.isSystem
                          ? const Icon(Icons.lock_outline, size: 18)
                          : PopupMenuButton<String>(
                              onSelected: (v) {
                                if (v == 'delete') repo.deleteCategory(c);
                                if (v == 'rename')
                                  _renameCategory(context, repo, c);
                              },
                              itemBuilder: (_) => [
                                PopupMenuItem(
                                  value: 'rename',
                                  child: Text(
                                    tx(context, 'Yeniden adlandır', 'Rename'),
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Text(tx(context, 'Sil', 'Delete')),
                                ),
                              ],
                            ),
                    ),
                  ListTile(
                    leading: const Icon(Icons.add, color: blue),
                    title: Text(tx(context, 'Kategori ekle', 'Add category')),
                    onTap: () => _addCategory(context, repo),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context).data.toUpperCase(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.file_upload_outlined),
                  title: Text(
                    tx(context, 'JSON yedeği oluştur', 'Create JSON backup'),
                  ),
                  subtitle: Text(
                    tx(
                      context,
                      'Tüm verilerini paylaşılabilir dosyaya aktar.',
                      'Export all your data to a shareable file.',
                    ),
                  ),
                  onTap: () async {
                    final subject = tx(
                      context,
                      'CalBalance yedeği',
                      'CalBalance backup',
                    );
                    final f = await repo.exportJson();
                    await SharePlus.instance.share(
                      ShareParams(files: [XFile(f.path)], subject: subject),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.file_download_outlined),
                  title: Text(
                    tx(
                      context,
                      'JSON yedeğini geri yükle',
                      'Restore JSON backup',
                    ),
                  ),
                  subtitle: Text(
                    tx(
                      context,
                      'Mevcut verilerin seçilen yedekle değiştirilir.',
                      'Your current data will be replaced by the selected backup.',
                    ),
                  ),
                  onTap: () async {
                    final file = await openFile(
                      acceptedTypeGroups: const [
                        XTypeGroup(
                          label: 'CalBalance JSON',
                          extensions: ['json'],
                        ),
                      ],
                    );
                    if (file == null || !context.mounted) return;
                    final confirmed =
                        await showDialog<bool>(
                          context: context,
                          builder: (c) => AlertDialog(
                            title: Text(
                              tx(
                                context,
                                'Yedeği geri yükle?',
                                'Restore backup?',
                              ),
                            ),
                            content: Text(
                              tx(
                                context,
                                'Mevcut verilerin yedekteki verilerle tamamen değiştirilecek.',
                                'Your current data will be completely replaced with the backup.',
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(c, false),
                                child: Text(tx(context, 'Vazgeç', 'Cancel')),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.pop(c, true),
                                child: Text(
                                  tx(context, 'Geri yükle', 'Restore'),
                                ),
                              ),
                            ],
                          ),
                        ) ??
                        false;
                    if (!confirmed) return;
                    try {
                      await repo.restoreJson(await file.readAsString());
                      if (context.mounted)
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              tx(
                                context,
                                'Yedek geri yüklendi.',
                                'Backup restored.',
                              ),
                            ),
                          ),
                        );
                    } on FormatException {
                      if (context.mounted)
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              tx(
                                context,
                                'Geçersiz veya desteklenmeyen yedek dosyası.',
                                'Invalid or unsupported backup file.',
                              ),
                            ),
                          ),
                        );
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.delete_forever,
                    color: Colors.redAccent,
                  ),
                  title: Text(
                    tx(context, 'Tüm verileri sil', 'Delete all data'),
                  ),
                  subtitle: Text(
                    tx(
                      context,
                      'Bu işlem geri alınamaz.',
                      'This action cannot be undone.',
                    ),
                  ),
                  onTap: () async {
                    final first =
                        await showDialog<bool>(
                          context: context,
                          builder: (d) => AlertDialog(
                            title: Text(
                              tx(
                                context,
                                'Tüm veriler silinsin mi?',
                                'Delete all data?',
                              ),
                            ),
                            content: Text(
                              tx(
                                context,
                                'Profilin ve bütün kayıtların cihazdan kaldırılacak.',
                                'Your profile and all entries will be removed from this device.',
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(d, false),
                                child: Text(tx(context, 'Vazgeç', 'Cancel')),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.pop(d, true),
                                child: Text(tx(context, 'Devam', 'Continue')),
                              ),
                            ],
                          ),
                        ) ??
                        false;
                    if (!first || !context.mounted) return;
                    final second =
                        await showDialog<bool>(
                          context: context,
                          builder: (d) => AlertDialog(
                            title: Text(
                              tx(context, 'Son onay', 'Final confirmation'),
                            ),
                            content: Text(
                              tx(
                                context,
                                'Bu işlem geri alınamaz. Varsa önce JSON yedeği oluştur.',
                                'This cannot be undone. Create a JSON backup first if needed.',
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(d, false),
                                child: Text(tx(context, 'Vazgeç', 'Cancel')),
                              ),
                              FilledButton(
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                onPressed: () => Navigator.pop(d, true),
                                child: Text(
                                  tx(
                                    context,
                                    'Her şeyi sil',
                                    'Delete everything',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ) ??
                        false;
                    if (second) await repo.deleteAllData();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.lock_outline),
                  title: Text(
                    tx(
                      context,
                      'Cihazda ve çevrimdışı',
                      'On-device and offline',
                    ),
                  ),
                  subtitle: Text(
                    tx(
                      context,
                      'Verilerin sunucuya gönderilmez.',
                      'Your data is never sent to a server.',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _goalRow(
    String title,
    String value,
    Color color,
    IconData icon, {
    bool last = false,
  }) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
    decoration: BoxDecoration(
      border: last ? null : const Border(bottom: BorderSide(color: line)),
    ),
    child: Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: color.withValues(alpha: .1),
          child: Icon(icon, color: color, size: 19),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );

  Widget _reminderTile(
    BuildContext context,
    AppRepository repo,
    ReminderScheduler scheduler,
    ReminderSetting? current, {
    required String id,
    required String type,
    required int notificationId,
    required String title,
    required String body,
    required int hour,
    required int minute,
    int? weekday,
    required IconData icon,
  }) {
    final enabled = current?.isEnabled ?? false;
    return SwitchListTile(
      secondary: Icon(icon, color: blue),
      title: Text(title),
      subtitle: InkWell(
        onTap: () async {
          final selected = await showTimePicker(
            context: context,
            initialTime: TimeOfDay(
              hour: current?.hour ?? hour,
              minute: current?.minute ?? minute,
            ),
          );
          if (selected == null) return;
          await repo.saveReminder(
            id: id,
            type: type,
            enabled: enabled,
            hour: selected.hour,
            minute: selected.minute,
            weekday: weekday,
            locale: profile.localeCode,
          );
          if (enabled)
            await scheduler.schedule(
              id: notificationId,
              hour: selected.hour,
              minute: selected.minute,
              title: title,
              body: body,
              weekday: weekday,
            );
        },
        child: Text(
          '${(current?.hour ?? hour).toString().padLeft(2, '0')}:${(current?.minute ?? minute).toString().padLeft(2, '0')}  ·  ${tx(context, 'Değiştir', 'Change')}',
          style: const TextStyle(color: Colors.white60),
        ),
      ),
      value: enabled,
      onChanged: (value) async {
        if (value) {
          final granted = await scheduler.requestPermission();
          if (!granted) {
            if (context.mounted)
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    tx(
                      context,
                      'Bildirim izni verilmedi. Sistem ayarlarından açabilirsin.',
                      'Notification permission was denied. You can enable it in system settings.',
                    ),
                  ),
                ),
              );
            return;
          }
          await scheduler.schedule(
            id: notificationId,
            hour: current?.hour ?? hour,
            minute: current?.minute ?? minute,
            title: title,
            body: body,
            weekday: weekday,
          );
        } else {
          await scheduler.cancel(notificationId);
        }
        await repo.saveReminder(
          id: id,
          type: type,
          enabled: value,
          hour: current?.hour ?? hour,
          minute: current?.minute ?? minute,
          weekday: weekday,
          locale: profile.localeCode,
        );
      },
    );
  }

  String _categoryLabel(BuildContext context, String? key) =>
      {
        'meal': tx(context, 'Yemek', 'Meal'),
        'drink': tx(context, 'İçecek', 'Drink'),
        'snack': tx(context, 'Atıştırmalık', 'Snack'),
        'other': tx(context, 'Diğer', 'Other'),
      }[key] ??
      tx(context, 'Diğer', 'Other');

  Future<void> _updateProfile(
    AppRepository repo, {
    int? calories,
    double? protein,
    int? water,
    String? locale,
    bool? includeActivity,
  }) => repo.saveProfile(
    ProfilesCompanion(
      id: const Value(1),
      gender: Value(profile.gender),
      birthDate: Value(profile.birthDate),
      heightCm: Value(profile.heightCm),
      currentWeightKg: Value(profile.currentWeightKg),
      targetWeightKg: Value(profile.targetWeightKg),
      activityLevel: Value(profile.activityLevel),
      goalType: Value(profile.goalType),
      calorieTarget: Value(calories ?? profile.calorieTarget),
      proteinTarget: Value(protein ?? profile.proteinTarget),
      waterTargetMl: Value(water ?? profile.waterTargetMl),
      stepTarget: Value(profile.stepTarget),
      localeCode: Value(locale ?? profile.localeCode),
      includeActivityInBalance: Value(
        includeActivity ?? profile.includeActivityInBalance,
      ),
      createdAt: Value(profile.createdAt),
      updatedAt: Value(DateTime.now()),
    ),
  );

  Future<void> _editGoals(BuildContext context, AppRepository repo) async {
    final calories = TextEditingController(
          text: profile.calorieTarget.toString(),
        ),
        protein = TextEditingController(
          text: profile.proteinTarget.toStringAsFixed(0),
        ),
        water = TextEditingController(text: profile.waterTargetMl.toString());
    await showDialog(
      context: context,
      builder: (d) => AlertDialog(
        title: Text(tx(context, 'Hedefleri düzenle', 'Edit goals')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: calories,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: tx(context, 'Kalori hedefi', 'Calorie target'),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: protein,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: tx(context, 'Protein hedefi', 'Protein target'),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: water,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: tx(context, 'Su hedefi', 'Water target'),
              ),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () {
              final c = int.tryParse(calories.text),
                  p = double.tryParse(protein.text),
                  w = int.tryParse(water.text);
              if (c != null &&
                  c > 0 &&
                  p != null &&
                  p > 0 &&
                  w != null &&
                  w > 0) {
                _updateProfile(repo, calories: c, protein: p, water: w);
                Navigator.pop(d);
              }
            },
            child: Text(tx(context, 'Kaydet', 'Save')),
          ),
        ],
      ),
    );
  }

  Future<void> _addCategory(BuildContext context, AppRepository repo) async {
    final c = TextEditingController();
    await showDialog(
      context: context,
      builder: (x) => AlertDialog(
        title: Text(tx(context, 'Kategori ekle', 'Add category')),
        content: TextField(
          controller: c,
          decoration: InputDecoration(
            labelText: tx(context, 'Kategori adı', 'Category name'),
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () {
              if (c.text.trim().isNotEmpty) {
                repo.addCategory(
                  c.text,
                  Icons.label.codePoint,
                  blue.toARGB32(),
                );
                Navigator.pop(x);
              }
            },
            child: Text(tx(context, 'Ekle', 'Add')),
          ),
        ],
      ),
    );
  }

  Future<void> _renameCategory(
    BuildContext context,
    AppRepository repo,
    NutritionCategory category,
  ) async {
    final c = TextEditingController(text: category.customName);
    await showDialog(
      context: context,
      builder: (x) => AlertDialog(
        title: Text(tx(context, 'Kategoriyi adlandır', 'Rename category')),
        content: TextField(controller: c),
        actions: [
          FilledButton(
            onPressed: () {
              if (c.text.trim().isNotEmpty) {
                repo.renameCategory(category, c.text);
                Navigator.pop(x);
              }
            },
            child: Text(tx(context, 'Kaydet', 'Save')),
          ),
        ],
      ),
    );
  }
}

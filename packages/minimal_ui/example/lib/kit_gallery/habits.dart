/// The gallery's habit tracker's data, one source for the Today, Habit and
/// New habit screens and for the example's Habits app: the habits, whether
/// each is kept today, and the changes a person makes (mark, add, pause,
/// archive), each one undoable.
library;

import 'package:flutter/foundation.dart';

import 'kit_words.dart';

/// Friday 28 August 2026, the day the tracker shows.
final DateTime kitHabitsToday = DateTime(2026, 8, 28);

/// Where Friday falls in a week, Monday first.
const int kitTodayIndex = 4;

/// The times of day a habit belongs to, in the list's order.
List<String> get kitHabitGroups => [
  ar('Morning', 'الصباح'),
  ar('Evening', 'المساء'),
  ar('Weekends', 'نهاية الأسبوع'),
];

/// How often a habit repeats, as the New habit form and the habit page
/// offer it.
List<String> get kitHabitRepeats => [
  ar('Every day', 'كل يوم'),
  ar('Weekdays', 'أيام العمل'),
  ar('Weekends', 'نهاية الأسبوع'),
  ar('Every morning', 'كل صباح'),
  ar('Every evening', 'كل مساء'),
];

/// One habit.
class KitHabit {
  KitHabit({
    required this.id,
    required this.name,
    required this.group,
    required this.week,
    required this.carried,
    this.note = '',
    String? repeat,
    this.reminder,
    this.best = 0,
    DateTime? started,
    this.record = const [],
    this.paused = false,
  }) : started = started ?? kitHabitsToday,
       repeat = repeat ?? ar('Every day', 'كل يوم');

  /// `HAB-4`.
  final String id;
  final String name;
  final String group;
  final String note;
  String repeat;

  /// `07:00`; null for no reminder.
  final String? reminder;

  /// Monday to Sunday of this week; today's entry is the store's.
  final List<bool> week;

  /// The streak carried into today: kept today, it grows by one.
  final int carried;

  /// The longest streak so far.
  final int best;
  final DateTime started;

  /// The last twelve weeks, column by column (Monday first), up to today:
  /// 0 missed, 1 partly, 2 kept. Empty for a habit started today.
  final List<int> record;
  bool paused;
}

/// Morning run's last twelve weeks, one line per weekday (Monday first),
/// oldest week first; today is the Friday of the last week.
const List<List<int>> _runWeekdays = [
  [2, 2, 2, 0, 1, 1, 0, 1, 0, 2, 2, 2],
  [2, 2, 1, 2, 2, 2, 2, 2, 1, 1, 0, 2],
  [0, 1, 2, 2, 2, 1, 1, 2, 2, 2, 1, 2],
  [1, 1, 1, 0, 1, 1, 2, 0, 2, 2, 2, 2],
  [1, 2, 2, 1, 1, 2, 2, 1, 2, 0, 2, 2],
  [2, 2, 2, 2, 2, 1, 1, 2, 1, 1, 2],
  [0, 0, 1, 1, 1, 1, 2, 0, 1, 1, 2],
];

/// [weekdays] read column by column, as the heat map takes it.
List<int> _columns(List<List<int>> weekdays) => [
  for (var week = 0; week < 12; week++)
    for (var day = 0; day < 7; day++)
      if (week < weekdays[day].length) weekdays[day][week],
];

/// A record for a habit kept about [rate] in ten days, the same for the
/// same [seed] every time.
List<int> _record(int seed, int rate) => [
  for (var i = 0; i <= 11 * 7 + kitTodayIndex; i++)
    (i * 7 + seed * 13) % 10 < rate
        ? 2
        : (i + seed) % 5 == 0
        ? 1
        : 0,
];

/// The habits the tracker starts with.
List<KitHabit> kitSeedHabits() => [
  KitHabit(
    id: 'HAB-2',
    name: ar('Meditate', 'التأمل'),
    group: ar('Morning', 'الصباح'),
    note: ar('Ten minutes, before the phone.', 'عشر دقائق، قبل الهاتف.'),
    reminder: '06:45',
    week: [false, true, true, true, true, false, false],
    carried: 3,
    best: 14,
    started: DateTime(2026, 3, 9),
    record: _record(2, 6),
  ),
  KitHabit(
    id: 'HAB-4',
    name: ar('Morning run', 'جري الصباح'),
    group: ar('Morning', 'الصباح'),
    note: ar(
      'Out the door before 8. Any distance counts.',
      'الخروج قبل الثامنة. أي مسافة تُحسب.',
    ),
    reminder: '07:00',
    week: [true, true, true, true, true, false, false],
    carried: 11,
    best: 21,
    started: DateTime(2026, 6, 2),
    record: _columns(_runWeekdays),
  ),
  KitHabit(
    id: 'HAB-5',
    name: ar('Drink water', 'شرب الماء'),
    group: ar('Morning', 'الصباح'),
    note: ar('A glass before coffee.', 'كوب قبل القهوة.'),
    week: [true, true, true, true, false, false, false],
    carried: 10,
    best: 32,
    started: DateTime(2026, 2, 16),
    record: _record(5, 8),
  ),
  KitHabit(
    id: 'HAB-7',
    name: ar('Journal', 'اليوميات'),
    group: ar('Evening', 'المساء'),
    note: ar('Three lines about the day.', 'ثلاثة أسطر عن اليوم.'),
    repeat: ar('Every evening', 'كل مساء'),
    reminder: '21:30',
    week: [false, true, true, true, false, false, false],
    carried: 3,
    best: 9,
    started: DateTime(2026, 5, 4),
    record: _record(7, 5),
  ),
  KitHabit(
    id: 'HAB-8',
    name: ar('Read 20 pages', 'قراءة 20 صفحة'),
    group: ar('Evening', 'المساء'),
    note: ar('Paper, not a screen.', 'ورق، لا شاشة.'),
    repeat: ar('Every evening', 'كل مساء'),
    reminder: '22:00',
    week: [true, true, true, true, true, false, false],
    carried: 5,
    best: 18,
    started: DateTime(2026, 4, 20),
    record: _record(8, 7),
  ),
  KitHabit(
    id: 'HAB-9',
    name: ar('Water the plants', 'سقي النباتات'),
    group: ar('Weekends', 'نهاية الأسبوع'),
    repeat: ar('Weekends', 'نهاية الأسبوع'),
    week: [false, false, false, false, false, false, false],
    carried: 2,
    best: 6,
    started: DateTime(2026, 7, 4),
    record: _record(9, 2),
    paused: true,
  ),
];

/// The tracker's state: the habits in their order and whether each is kept
/// today. Every change notifies, and the ones a person may regret return
/// what undoes them.
class KitHabits extends ChangeNotifier {
  KitHabits() : habits = kitSeedHabits();

  final List<KitHabit> habits;
  late final Map<String, bool> _kept = {
    for (final h in habits) h.id: h.week[kitTodayIndex],
  };
  int _next = 10;

  bool kept(KitHabit habit) => _kept[habit.id] ?? false;

  KitHabit? byId(String id) {
    for (final h in habits) {
      if (h.id == id) return h;
    }
    return null;
  }

  /// Marks [habit] kept today, or not.
  void toggle(KitHabit habit) {
    _kept[habit.id] = !kept(habit);
    notifyListeners();
  }

  /// A new habit, at the end of its group; returns it.
  KitHabit add({
    required String name,
    required String group,
    String note = '',
    String? repeat,
    String? reminder,
  }) {
    final habit = KitHabit(
      id: 'HAB-${_next++}',
      name: name,
      group: group,
      note: note,
      repeat: repeat,
      reminder: reminder,
      week: List.filled(7, false),
      carried: 0,
    );
    habits.add(habit);
    _kept[habit.id] = false;
    notifyListeners();
    return habit;
  }

  /// Takes [habit] off the list; the returned call puts it back where it
  /// stood.
  VoidCallback remove(KitHabit habit) {
    final at = habits.indexOf(habit);
    habits.removeAt(at);
    notifyListeners();
    return () {
      habits.insert(at, habit);
      notifyListeners();
    };
  }

  /// Pauses [habit] or resumes it; the returned call undoes it.
  VoidCallback setPaused(KitHabit habit, bool paused) {
    final was = habit.paused;
    habit.paused = paused;
    notifyListeners();
    return () {
      habit.paused = was;
      notifyListeners();
    };
  }

  /// Takes every habit off; the returned call puts them all back.
  VoidCallback clear() {
    final all = [...habits];
    habits.clear();
    notifyListeners();
    return () {
      habits
        ..clear()
        ..addAll(all);
      notifyListeners();
    };
  }

  /// Sets how often [habit] repeats.
  void setRepeat(KitHabit habit, String repeat) {
    habit.repeat = repeat;
    notifyListeners();
  }

  /// The streak [habit] stands at today.
  int streak(KitHabit habit) => habit.carried + (kept(habit) ? 1 : 0);
}

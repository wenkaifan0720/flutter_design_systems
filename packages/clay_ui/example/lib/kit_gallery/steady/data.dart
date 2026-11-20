/// Steady's habits: what Today, the habit list, a habit's page and the
/// editor show.
library;

import 'package:flutter/widgets.dart';
import 'package:clay_ui/clay_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// When in the day a habit is done.
enum SteadyTime {
  /// Before noon.
  morning,

  /// Noon to six.
  afternoon,

  /// After six.
  evening;

  /// Its name, as a header says it.
  String get label => switch (this) {
    morning => 'Morning',
    afternoon => 'Afternoon',
    evening => 'Evening',
  };

  /// Its glyph.
  IconData get icon => switch (this) {
    morning => LucideIcons.sunrise,
    afternoon => LucideIcons.sun,
    evening => LucideIcons.moon,
  };
}

/// One habit.
class SteadyHabit {
  /// A habit named [name].
  SteadyHabit({
    required this.id,
    required this.name,
    required this.tint,
    required this.icon,
    required this.time,
    required this.repeat,
    required this.goal,
    required this.unit,
    required this.progress,
    required this.streak,
    required this.best,
    required this.history,
    this.reminder,
    this.note = '',
    this.paused = false,
  });

  /// Its key.
  final String id;

  /// Its name.
  String name;

  /// Its pastel.
  ClayTint tint;

  /// Its glyph.
  IconData icon;

  /// When it is done.
  SteadyTime time;

  /// How often: a [steadyRepeats] key.
  String repeat;

  /// How many a day (8 glasses, 20 pages; 1 for a yes-or-no habit).
  int goal;

  /// What is counted ('glasses', 'pages'); empty for a yes-or-no habit.
  String unit;

  /// How many today.
  int progress;

  /// Days in a row.
  int streak;

  /// The longest run.
  int best;

  /// The last 35 days, oldest first: whether it was done.
  final List<bool> history;

  /// The reminder's time, minutes after midnight; none when null.
  int? reminder;

  /// Why it matters.
  String note;

  /// Whether it is paused (not on Today).
  bool paused;

  /// Whether today's goal is met.
  bool get done => progress >= goal;

  /// Today's progress in words.
  String get today =>
      goal == 1 ? (done ? 'Done' : 'Not yet') : '$progress of $goal $unit';

  /// This month's share of days done, 0 to 1.
  double get month =>
      history.where((d) => d).length / (history.isEmpty ? 1 : history.length);
}

/// How often a habit repeats, by key.
const steadyRepeats = {
  'daily': 'Every day',
  'weekdays': 'Weekdays',
  'weekends': 'Weekends',
  'three': '3 times a week',
};

List<bool> _days(int seed, double share) {
  var x = seed;
  return [
    for (var i = 0; i < 35; i++)
      () {
        x = (x * 1103515245 + 12345) & 0x7fffffff;
        return (x % 1000) / 1000 < share;
      }(),
  ];
}

/// Steady's habits, fresh.
List<SteadyHabit> steadyHabits() => [
  SteadyHabit(
    id: 'water',
    name: 'Drink water',
    tint: ClayTint.sky,
    icon: LucideIcons.droplets,
    time: SteadyTime.morning,
    repeat: 'daily',
    goal: 8,
    unit: 'glasses',
    progress: 5,
    streak: 12,
    best: 31,
    history: _days(3, 0.86),
    reminder: 9 * 60,
    note: 'Headaches went away when I kept this up.',
  ),
  SteadyHabit(
    id: 'walk',
    name: 'Morning walk',
    tint: ClayTint.mint,
    icon: LucideIcons.footprints,
    time: SteadyTime.morning,
    repeat: 'daily',
    goal: 1,
    unit: '',
    progress: 1,
    streak: 8,
    best: 19,
    history: _days(7, 0.78),
    reminder: 7 * 60 + 30,
  ),
  SteadyHabit(
    id: 'stretch',
    name: 'Stretch',
    tint: ClayTint.peach,
    icon: LucideIcons.personStanding,
    time: SteadyTime.afternoon,
    repeat: 'weekdays',
    goal: 1,
    unit: '',
    progress: 0,
    streak: 4,
    best: 12,
    history: _days(11, 0.64),
  ),
  SteadyHabit(
    id: 'read',
    name: 'Read 20 pages',
    tint: ClayTint.lilac,
    icon: LucideIcons.bookOpen,
    time: SteadyTime.evening,
    repeat: 'daily',
    goal: 20,
    unit: 'pages',
    progress: 12,
    streak: 21,
    best: 21,
    history: _days(5, 0.92),
    reminder: 21 * 60,
  ),
  SteadyHabit(
    id: 'meditate',
    name: 'Meditate',
    tint: ClayTint.butter,
    icon: LucideIcons.flower2,
    time: SteadyTime.morning,
    repeat: 'daily',
    goal: 1,
    unit: '',
    progress: 0,
    streak: 0,
    best: 9,
    history: _days(13, 0.48),
  ),
  SteadyHabit(
    id: 'journal',
    name: 'Journal',
    tint: ClayTint.rose,
    icon: LucideIcons.penLine,
    time: SteadyTime.evening,
    repeat: 'three',
    goal: 1,
    unit: '',
    progress: 0,
    streak: 3,
    best: 14,
    history: _days(17, 0.58),
  ),
  SteadyHabit(
    id: 'phone',
    name: 'No phone after 10',
    tint: ClayTint.sky,
    icon: LucideIcons.moonStar,
    time: SteadyTime.evening,
    repeat: 'weekdays',
    goal: 1,
    unit: '',
    progress: 0,
    streak: 0,
    best: 6,
    history: _days(19, 0.4),
    paused: true,
  ),
];

/// The person using Steady.
const steadyOwner = (name: 'Mara Ilunga', email: 'mara@example.com');

/// A time of day as a clock says it: `7:30`, `21:00`.
String steadyClock(int minutes) =>
    '${minutes ~/ 60}:${(minutes % 60).toString().padLeft(2, '0')}';

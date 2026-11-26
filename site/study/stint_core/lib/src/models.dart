import 'dart:ui' show Color;

import 'package:flutter/foundation.dart';

import 'words.dart' show StintLanguage;

/// Seed content in English, Arabic, Japanese and German. A teammate's own
/// text is shown as entered ([TranslatedText.asEntered]).
typedef TeamText = (String, String, String, String);

extension TranslatedText on TeamText {
  /// Text a teammate typed: the same in every language.
  static TeamText asEntered(String input) => (input, input, input, input);

  String inLanguage(StintLanguage language) => switch (language) {
    StintLanguage.en => $1,
    StintLanguage.ar => $2,
    StintLanguage.ja => $3,
    StintLanguage.de => $4,
  };
  TeamText edit(String input, StintLanguage language) =>
      input == inLanguage(language) ? this : asEntered(input);
}

typedef Person = ({String id, TeamText name});
typedef Project = ({String id, TeamText name});

enum Priority { low, normal, high }

enum Label { planning, review, fieldwork }

enum TaskStatus { all, open, done }

enum TaskSort { due, priority, title }

enum Appearance { system, day, night }

/// The seed colours the Material and Cupertino reference editions offer
/// beside their own; a look's edition offers its look's named palettes
/// instead ([StintPalette]).
enum StintAccent {
  navy('Navy', Color(0xFF1F3A68)),
  green('Green', Color(0xFF2E7D32)),
  gold('Black + gold', Color(0xFFC9A227)),
  purple('Purple', Color(0xFF6D28D9)),
  pastel('Pastel', Color(0xFFF4A7B9));

  const StintAccent(this.label, this.color);

  /// What a menu shows.
  final String label;

  /// The seed colour.
  final Color color;

  /// These seeds as palettes, after the edition's own ([own]).
  static List<StintPalette> palettesAfter(StintPalette own) => [
    own,
    for (final a in values) StintPalette(a.name, a.color, label: a.label),
  ];
}

/// One palette an edition offers a host's menu: one of its look's named
/// presets, the look's own first.
@immutable
class StintPalette {
  const StintPalette(this.id, this.swatch, {this.label});

  /// What an address and a host pass (`accent=mint`): the look's preset id.
  final String id;

  /// The palette's brand colour, for a menu's dot.
  final Color swatch;

  /// The name a menu shows where the id alone won't do ("Black + gold").
  final String? label;

  /// What a menu shows: [label], else the id with a capital ("mint" is
  /// "Mint"), as the looks' own foundations pages name their presets.
  String get name => label ?? '${id[0].toUpperCase()}${id.substring(1)}';

  @override
  bool operator ==(Object other) =>
      other is StintPalette &&
      other.id == id &&
      other.swatch == swatch &&
      other.name == name;

  @override
  int get hashCode => Object.hash(id, swatch, name);
}

enum Place { today, tasks, time, settings }

enum DataState { loading, ready, error }

@immutable
class Task {
  const Task({
    required this.id,
    required this.title,
    required this.notes,
    required this.project,
    required this.assignee,
    required this.due,
    required this.estimate,
    required this.priority,
    required this.labels,
    required this.done,
    required this.reminder,
    required this.reminderMinute,
  });

  final String id;
  final TeamText title, notes;
  final String project, assignee;
  final DateTime due;

  /// Estimated work in minutes.
  final int estimate;
  final Priority priority;
  final Set<Label> labels;
  final bool done, reminder;
  final int reminderMinute;

  Task copyWith({
    TeamText? title,
    TeamText? notes,
    String? project,
    String? assignee,
    DateTime? due,
    int? estimate,
    Priority? priority,
    Set<Label>? labels,
    bool? done,
    bool? reminder,
    int? reminderMinute,
  }) => Task(
    id: id,
    title: title ?? this.title,
    notes: notes ?? this.notes,
    project: project ?? this.project,
    assignee: assignee ?? this.assignee,
    due: due ?? this.due,
    estimate: estimate ?? this.estimate,
    priority: priority ?? this.priority,
    labels: Set.unmodifiable(labels ?? this.labels),
    done: done ?? this.done,
    reminder: reminder ?? this.reminder,
    reminderMinute: reminderMinute ?? this.reminderMinute,
  );
}

typedef TimeEntry = ({
  String id,
  DateTime date,
  int start,
  int end,
  String project,
  TeamText note,
});

typedef RunningTimer = ({String taskId, DateTime start});

enum ActivityKind { finished, started, commented, logged }

typedef StudioEvent = ({
  String person,
  ActivityKind kind,
  TeamText subject,
  DateTime at,
  int minutes,
});

DateTime calendarDay(DateTime value) =>
    DateTime(value.year, value.month, value.day);
DateTime addDays(DateTime value, int count) =>
    DateTime(value.year, value.month, value.day + count);
DateTime mondayOf(DateTime day) => addDays(day, 1 - day.weekday);
DateTime atMinute(DateTime date, int minute) =>
    DateTime(date.year, date.month, date.day, minute ~/ 60, minute % 60);
int minuteOfDay(DateTime value) => value.hour * 60 + value.minute;

/// The Screen · Habit gallery group: one habit's page pushed off the list —
/// the derived back button and the `Habits / HAB-4` breadcrumb, the name
/// and its note, the property list (status, repeats, reminder, streak,
/// start), the last twelve weeks as a heatmap with today outlined, and the
/// audit trail of what happened to it. Status and repeats edit in place
/// from their rows.
library;

import 'package:flutter/material.dart';
import 'package:minimal_ui/minimal_host.dart';

import '../kit.dart';

Widget kitScreenHabitDemo(Brightness brightness) => MinimalPreview(
  light: kitTheme(Brightness.light),
  dark: kitTheme(Brightness.dark),
  brightness: brightness,
  presentation: MinimalPresentation.pushed,
  child: const KitHabitPage(),
);

/// The Screen · New habit gallery group: the compact create modal raised as
/// a page sheet over the dimmed Today — the card header (the quiet title,
/// the close), the name as the page's own field, a note, the property pills
/// (repeat, reminder, group, then the unset goal), and the footer's "Create
/// another" switch beside Cancel and Create habit. MinimalPreview's `under:`
/// stands the same Today page the Today screen shows, with its tabs,
/// beneath the raised card; like every preview, the card stays up when it
/// is closed.
library;

import 'package:flutter/material.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:minimal_ui/minimal_host.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../kit.dart';

Widget kitScreenNewHabitDemo(Brightness brightness) => MinimalPreview(
  light: kitTheme(Brightness.light),
  dark: kitTheme(Brightness.dark),
  brightness: brightness,
  presentation: MinimalPresentation.sheet,
  tabs: _tabs,
  // The very page the Today screen shows, dimmed under the card.
  under: const KitTodayPage(),
  child: const KitNewHabitPage(name: 'Stretch before bed'),
);

const List<MinimalNavItem> _tabs = [
  MinimalNavItem(LucideIcons.calendarCheck, 'Today'),
  MinimalNavItem(LucideIcons.listChecks, 'Habits'),
  MinimalNavItem(LucideIcons.activity, 'Trends'),
  MinimalNavItem(LucideIcons.settings, 'Settings'),
];

/// The Screen · Today gallery group: Ritual's first tab as a nav root over
/// the docked tab bar — the day's summary bar, count filters, then the
/// habits grouped by time of day, each row a status glyph that marks it
/// kept, the name, the week in squares and the mono streak. The bar holds
/// search and the solid `+`, the one create act, as on every root of the
/// system. Marking a habit moves the summary, the group counts and the
/// filters with it.
library;

import 'package:flutter/material.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:minimal_ui/minimal_host.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../kit.dart';

Widget kitScreenTodayDemo(Brightness brightness) => MinimalPreview(
  light: kitTheme(Brightness.light),
  dark: kitTheme(Brightness.dark),
  brightness: brightness,
  tabs: _tabs,
  child: Builder(
    builder: (context) => KitTodayPage(
      onNew: () => showMinimalSnackBar(
        context,
        'New habit opens as a sheet',
        icon: LucideIcons.plus,
      ),
    ),
  ),
);

/// The Today screen on a laptop: the shell's rail, the day's list and
/// Morning run's page beside it (master and detail), the open habit marked
/// in the list. The phone pushes the same page off the list
/// ([kitScreenHabitDemo]).
Widget kitScreenTodayDeskDemo(Brightness brightness) => MinimalPreview(
  light: kitTheme(Brightness.light),
  dark: kitTheme(Brightness.dark),
  brightness: brightness,
  tabs: _tabs,
  child: Builder(
    builder: (context) {
      final t = context.minimalTheme;
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: _masterWidth,
            child: KitTodayPage(
              selected: 'HAB-4',
              onNew: () => showMinimalSnackBar(
                context,
                'New habit opens as a sheet',
                icon: LucideIcons.plus,
              ),
            ),
          ),
          MinimalDivider.vertical(space: t.hairline),
          const Expanded(child: KitHabitPage()),
        ],
      );
    },
  ),
);

/// The list's width beside the detail: a phone's, so its rows read as they
/// do there.
const double _masterWidth = 400;

const List<MinimalNavItem> _tabs = [
  MinimalNavItem(LucideIcons.calendarCheck, 'Today'),
  MinimalNavItem(LucideIcons.listChecks, 'Habits'),
  MinimalNavItem(LucideIcons.activity, 'Trends'),
  MinimalNavItem(LucideIcons.settings, 'Settings'),
];

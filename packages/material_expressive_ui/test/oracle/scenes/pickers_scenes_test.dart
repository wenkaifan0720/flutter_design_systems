/// The `pickers` oracle group (Compose twin: `PickersScenes.kt`): the date
/// picker with its header (calendar and typed), without it (the docked
/// calendar), the range picker, and the time picker's dial on the 12- and
/// 24-hour clocks, the vibrant dial and the time input (CONTRACT §7 "every
/// picker"). Dates are in March 2031, far from the device's today, so no
/// day is outlined on either side; the headline reads the kit's
/// "12 Mar 2031" (the Compose twin passes a formatter that writes it so).
/// Each picker is tagged whole.
library;

import 'package:material_ui/material_ui.dart' show DefaultMaterialLocalizations;
import 'package:flutter/widgets.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';
import 'package:material_expressive_ui/material_expressive_host.dart';

import '../harness/oracle.dart';

void _ignore(DateTime _) {}

void _ignoreRange(DateTime? _, DateTime? _) {}

/// A "today" outside every scene's month.
final DateTime _today = DateTime(2026, 9, 26);

final DateTime _selected = DateTime(2031, 3, 12);

ExpressiveTimePickerController _time(
  int hour,
  int minute, {
  bool is24Hour = false,
}) => ExpressiveTimePickerController(
  hour: hour,
  minute: minute,
  is24Hour: is24Hour,
);

final OracleGroup pickersScenes = OracleGroup(
  id: 'pickers',
  // The typed faces hold text fields, which read the Material strings.
  frame: (context, scene) => Localizations(
    locale: const Locale('en', 'US'),
    delegates: const <LocalizationsDelegate<Object>>[
      DefaultMaterialLocalizations.delegate,
      DefaultWidgetsLocalizations.delegate,
    ],
    child: ExpressiveHost(
      light: context.expressiveTheme,
      dark: context.expressiveTheme,
      brightness: context.expressiveTheme.brightness,
      child: scene,
    ),
  ),
  scenes: [
    OracleScene(
      key: 'pickers/date-modal',
      size: const Size(376, 528),
      build: (context) => OracleTag(
        'picker',
        child: SizedBox(
          width: 360,
          child: ExpressiveDatePicker(
            selected: _selected,
            currentDate: _today,
            onChanged: _ignore,
          ),
        ),
      ),
    ),
    OracleScene(
      key: 'pickers/date-input',
      size: const Size(376, 240),
      build: (context) => OracleTag(
        'picker',
        child: SizedBox(
          width: 360,
          child: ExpressiveDatePicker(
            selected: _selected,
            currentDate: _today,
            initialMode: ExpressiveDatePickerMode.input,
            onChanged: _ignore,
          ),
        ),
      ),
    ),
    OracleScene(
      key: 'pickers/date-docked',
      size: const Size(376, 408),
      build: (context) => OracleTag(
        'picker',
        child: SizedBox(
          width: 360,
          child: ExpressiveDatePicker(
            selected: _selected,
            currentDate: _today,
            showHeader: false,
            onChanged: _ignore,
          ),
        ),
      ),
    ),
    OracleScene(
      key: 'pickers/date-range',
      size: const Size(376, 536),
      build: (context) => OracleTag(
        'picker',
        child: SizedBox(
          width: 360,
          height: 520,
          child: ExpressiveDateRangePicker(
            start: DateTime(2031, 3, 10),
            end: DateTime(2031, 3, 17),
            currentDate: _today,
            onChanged: _ignoreRange,
          ),
        ),
      ),
    ),
    OracleScene(
      key: 'pickers/time-dial',
      size: const Size(288, 408),
      build: (context) => OracleTag(
        'picker',
        child: ExpressiveTimePicker(
          controller: _time(9, 30),
          layout: ExpressiveTimePickerLayout.vertical,
        ),
      ),
    ),
    OracleScene(
      key: 'pickers/time-dial-24h',
      size: const Size(288, 408),
      build: (context) => OracleTag(
        'picker',
        child: ExpressiveTimePicker(
          controller: _time(18, 45, is24Hour: true),
          layout: ExpressiveTimePickerLayout.vertical,
        ),
      ),
    ),
    OracleScene(
      key: 'pickers/time-vibrant',
      size: const Size(312, 408),
      build: (context) => OracleTag(
        'picker',
        child: ExpressiveTimePicker(
          controller: _time(9, 30),
          vibrant: true,
          layout: ExpressiveTimePickerLayout.vertical,
        ),
      ),
    ),
    OracleScene(
      key: 'pickers/time-input',
      size: const Size(288, 128),
      build: (context) => OracleTag(
        'picker',
        child: ExpressiveTimeInput(controller: _time(9, 30)),
      ),
    ),
  ],
);

void main() => runOracleGroup(pickersScenes);

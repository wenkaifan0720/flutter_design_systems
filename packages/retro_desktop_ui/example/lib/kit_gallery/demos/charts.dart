/// Figures through time and against a limit: the sky and its hours, a range of days, hatched bars, gauges, a month.
library;

import 'package:flutter/material.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../kit.dart';

Widget kitChartsDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Charts and gauges',
  sections: [
    kitSection('A thumb gauge', children: [kitSpecimenThumbGauge()]),
    kitSection('A gauge with figures', children: [kitSpecimenGaugeBlock()]),
    kitSection('A month', children: [kitSpecimenMonthGrid()]),
    kitSection('A month head', children: [kitSpecimenMonthHead()]),
    kitSection('A legend', children: [kitSpecimenLegend()]),
    kitSection('A pixel sky', children: [kitSpecimenPixelSky()]),
    kitSection('An hour strip', children: [kitSpecimenHourStrip()]),
    kitSection('A range of days', children: [kitSpecimenRangeShape()]),
    kitSection('Hatched bars', children: [kitSpecimenHatchBars()]),
    kitSection('Day bars', children: [kitSpecimenDayBars()]),
    kitSection('A scale', children: [kitSpecimenScaleBar()]),
    kitSection('A span', children: [kitSpecimenSpanBar()]),
  ],
);

Widget kitSpecimenThumbGauge() => const RetroDesktopThumbGauge(share: .28);

Widget kitSpecimenGaugeBlock() => const RetroDesktopGaugeBlock(
  value: '1.4 GB',
  of: 'of 5 GB',
  share: .28,
  endLabel: '28%',
  footStart: 'Used',
  footEnd: '3.6 GB free',
);

Widget kitSpecimenMonthGrid() => kitValue(
  DateTime(2026, 6),
  (value, change) => RetroDesktopColumn(
    children: [
      _monthHead(value, change),
      RetroDesktopMonthGrid(
        year: value.year,
        month: value.month,
        today: value.month == 6 && value.year == 2026 ? 10 : null,
        days: value.month == 6 && value.year == 2026
            ? const {
                3: RetroDesktopDayMarks(remaining: 2),
                9: RetroDesktopDayMarks(remaining: 1, overdue: true),
                8: RetroDesktopDayMarks(completed: 3),
                10: RetroDesktopDayMarks(remaining: 2, completed: 1),
              }
            : const {},
      ),
      const RetroDesktopLegend([
        (RetroDesktopLegendMark.solid, 'open'),
        (RetroDesktopLegendMark.outline, 'done'),
        (RetroDesktopLegendMark.tint, 'this week'),
      ]),
    ],
  ),
);

Widget _monthHead(DateTime value, ValueChanged<DateTime> change) => Builder(
  builder: (context) => RetroDesktopMonthHead(
    RetroDesktopLocalizations.of(context).formatMonthYear(value),
    onPrevious: () => change(DateTime(value.year, value.month - 1)),
    onToday: () => change(DateTime(2026, 6)),
    onNext: () => change(DateTime(value.year, value.month + 1)),
  ),
);

Widget kitSpecimenMonthHead() => kitValue(
  DateTime(2026, 6),
  (value, change) => Builder(
    builder: (context) => RetroDesktopMonthHead(
      RetroDesktopLocalizations.of(context).formatMonthYear(value),
      onPrevious: () => change(DateTime(value.year, value.month - 1)),
      onToday: () => change(DateTime(2026, 6)),
      onNext: () => change(DateTime(value.year, value.month + 1)),
    ),
  ),
);

Widget kitSpecimenLegend() => const RetroDesktopLegend([
  (RetroDesktopLegendMark.solid, 'open'),
  (RetroDesktopLegendMark.outline, 'done'),
  (RetroDesktopLegendMark.tint, 'this week'),
  (RetroDesktopLegendMark.send, 'sent'),
]);

// At its own height (168 on a desk, whose sky is drawn in 6 px cells: at 72 its
// clouds and suns stood cut by the ground). Bare: the hour strip frames it.
Widget kitSpecimenPixelSky() => const RetroDesktopPixelSky(
  kinds: [
    RetroDesktopSkyCondition.rain,
    RetroDesktopSkyCondition.cloud,
    RetroDesktopSkyCondition.partSun,
    RetroDesktopSkyCondition.sun,
    RetroDesktopSkyCondition.sunset,
    RetroDesktopSkyCondition.clearNight,
  ],
);

Widget kitSpecimenHourStrip() => const RetroDesktopHourStrip(
  hours: [
    RetroDesktopHour(
      label: 'Now',
      icon: LucideIcons.cloudRain,
      value: 8,
      reading: '8°',
      kind: RetroDesktopSkyCondition.rain,
      share: .6,
    ),
    RetroDesktopHour(
      label: '10',
      icon: LucideIcons.cloudDrizzle,
      value: 9,
      reading: '9°',
      kind: RetroDesktopSkyCondition.drizzle,
      share: .5,
    ),
    RetroDesktopHour(
      label: '11',
      icon: LucideIcons.cloud,
      value: 10,
      reading: '10°',
      kind: RetroDesktopSkyCondition.cloud,
      share: .3,
    ),
    RetroDesktopHour(
      label: '12',
      icon: LucideIcons.sun,
      value: 11,
      reading: '11°',
      kind: RetroDesktopSkyCondition.sun,
    ),
  ],
);

Widget kitSpecimenRangeShape() => const RetroDesktopRangeShape(
  keyLabel: 'Chance, amount',
  dry: 'dry',
  wet: 'wet',
  days: [
    RetroDesktopDayRange(
      weekday: 'Today',
      date: '11',
      icon: LucideIcons.cloudRain,
      low: 4,
      high: 11,
      share: .8,
      amount: '6.4',
    ),
    RetroDesktopDayRange(
      weekday: 'Thu',
      date: '12',
      icon: LucideIcons.cloud,
      low: 6,
      high: 10,
      share: .4,
      amount: '1.2',
    ),
    RetroDesktopDayRange(
      weekday: 'Fri',
      date: '13',
      icon: LucideIcons.sun,
      low: 3,
      high: 9,
      share: .1,
      amount: '0',
    ),
    RetroDesktopDayRange(
      weekday: 'Sat',
      date: '14',
      icon: LucideIcons.sun,
      low: 1,
      high: 8,
      amount: '0',
    ),
  ],
);

Widget kitSpecimenHatchBars() => const RetroDesktopHatchBars(
  values: [.8, 1.4, .6, .2, 0, 0, .3, .5, .9, 1.2],
  max: 1.5,
  axis: ['1.5', '1.0', '0.5', '0'],
  labels: ['09', '', '', '12', '', '', '15', '', '', '18'],
  notes: [RetroDesktopBarNote(1, '1.4 at 10:00')],
);

Widget kitSpecimenDayBars() => const RetroDesktopDayBars(
  values: [41, 52, 33, 24, 28],
  labels: ['Sat\n7', 'Sun\n8', 'Mon\n9', 'Tue\n10', 'Wed\n11'],
  limit: 50,
  max: 62,
);

Widget kitSpecimenScaleBar() => const RetroDesktopScaleBar(
  at: .14,
  bands: ['Good\n0–50', 'Fair\n51–100', 'Poor\n101–150', 'Bad\n151+'],
  fine: 'For those who care',
);

Widget kitSpecimenSpanBar() => const RetroDesktopSpanBar(
  from: .31,
  to: .68,
  at: .39,
  fromLabel: '07:22',
  toLabel: '16:21',
  startLabel: '00',
  endLabel: '24',
);

/// The look's devices on plain data: Ben-Day dots, action lines, multi-layer lettering and drawn marks. Each paints once, in a RepaintBoundary, on whole device pixels.
library;

import 'package:flutter/material.dart';
import 'package:comic_ui/comic_ui.dart';

import '../kit.dart';
// The demo art is the example's; a test or page that draws it reads it from there.
// ignore: avoid_relative_lib_imports
import '../../demo_art.dart';

Widget kitPrintDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'The print: dots, lines and lettering',
  sections: [
    kitSection('Ben-Day dots', children: [kitSpecimenBenDay()]),
    kitSection('Action lines', children: [kitSpecimenActionLines()]),
    kitSection('A cover print', children: [kitSpecimenCoverPrint()]),
    kitSection('Lettering', children: [kitSpecimenLettering()]),
    kitSection('A sound effect', children: [kitSpecimenSfx()]),
    kitSection('A drawn object', children: [kitSpecimenMark()]),
    kitSection('A portrait slot', children: [kitSpecimenPortrait()]),
  ],
);

Widget kitSpecimenBenDay() => Builder(
  builder: (context) {
    final c = ComicTheme.of(context).colors;
    return SizedBox(
      height: 96,
      child: ComicEqualRow(
        flex: const [1, 1],
        gap: 10,
        children: [
          SizedBox(height: 96, child: ComicBenDay(color: c.shade)),
          SizedBox(
            height: 96,
            child: ComicBenDay(color: c.drama, pitch: 12, radius: 3),
          ),
        ],
      ),
    );
  },
);

Widget kitSpecimenActionLines() => Builder(
  builder: (context) {
    final c = ComicTheme.of(context).colors;
    return SizedBox(
      height: 140,
      child: ComicActionLines(
        color: c.ray,
        ground: c.caption,
        origin: const Offset(320, 80),
      ),
    );
  },
);

Widget kitSpecimenCoverPrint() =>
    const SizedBox(height: 180, child: ComicCoverPrint());

Widget kitSpecimenLettering() => Builder(
  builder: (context) {
    final c = ComicTheme.of(context).colors;
    return ComicColumn(
      gap: 10,
      children: [
        ComicLettering(
          'Masthead',
          size: 72,
          fill: c.caption,
          style: ComicLetteringStyle.masthead,
        ),
        ComicLettering(
          'A splash title',
          size: 48,
          fill: c.paper,
          style: ComicLetteringStyle.title,
        ),
      ],
    );
  },
);

Widget kitSpecimenSfx() => Builder(
  builder: (context) {
    final c = ComicTheme.of(context).colors;
    return Wrap(
      spacing: 18,
      children: [
        ComicSfx('Pop!', size: 26, fill: c.caption),
        ComicSfx('Krash!', size: 40, fill: c.caption, big: true),
      ],
    );
  },
);

Widget kitSpecimenMark() => const Wrap(
  spacing: 8,
  children: [
    ComicMark(ComicMarks.mug, size: 72),
    ComicMark(ComicMarks.peak, size: 72),
    ComicMark(ComicMarks.tent, size: 72),
    ComicMark(ComicMarks.dice, size: 72),
  ],
);

// The portrait keeps its own size at the column's start, as the marks beside it do (design6 P).
Widget kitSpecimenPortrait() => const Align(
  alignment: AlignmentDirectional.centerStart,
  child: SizedBox(width: 120, height: 140, child: ComicPortrait(ComicBust.bob)),
);

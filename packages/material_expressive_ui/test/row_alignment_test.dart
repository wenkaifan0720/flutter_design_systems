// ui_core's alignment contract over Material Expressive (design6 I2, I3):
// the controls that share a line, one row per size, each as Android, iOS and
// macOS at every density the look offers, read from the drawn pixels with
// the look's own fonts; and every one-line text entry through
// DesignTextEntryCheck, at each density, at text scale 1.5 and under a host
// whose InputDecorationTheme leaves uneven padding and a minimum height.
// With EXPRESSIVE_DESIGN_REVIEW_OUT set, the review page's "Rows" sheet is
// drawn there too.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart'
    show
        BoxConstraints,
        EdgeInsets,
        InputDecorationTheme,
        MaterialApp,
        ThemeData;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/alignment.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';
import 'package:material_expressive_ui/material_expressive_host.dart';

import 'gallery_support.dart';

const _densities = {
  'standard': ExpressiveDensity.standard,
  'comfortable': ExpressiveDensity.comfortable,
  'compact': ExpressiveDensity.compact,
};

/// The look as an app's page gets it, at [density], [scale] and under a
/// host [theme]: Material's app, then the look's host.
DesignAlignmentTheme _under(
  ExpressiveDensity density, {
  double scale = 1,
  ThemeData? theme,
}) =>
    (context, child) => MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: theme,
      home: MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: ExpressiveHost(
          light: ExpressiveThemeData.preset(
            'baseline',
            Brightness.light,
          ).copyWith(density: density),
          brightness: Brightness.light,
          child: child,
        ),
      ),
    );

void _none() {}

const _options = [
  ExpressiveSelectOption('TEXT', 'TEXT'),
  ExpressiveSelectOption('other', 'Other'),
];

final DesignAlignmentMatrix expressiveAlignment = DesignAlignmentMatrix(
  look: 'Material Expressive',
  themes: {
    for (final MapEntry(key: name, value: density) in _densities.entries)
      name: _under(density),
  },
  rows: [
    // Material's 56dp line: the M button, the fields, the search bar's
    // field, the list item and the labelled controls.
    DesignAlignmentRow(
      size: 'medium (56dp)',
      entries: [
        DesignAlignmentEntry(
          DesignInlineControl.button,
          (context, label) => ExpressiveFilledButton(
            label,
            size: ExpressiveButtonSize.medium,
            onPressed: _none,
          ),
        ),
        DesignAlignmentEntry(
          DesignInlineControl.iconButton,
          (context, label) => const ExpressiveIconButton(
            ExpressiveSymbols.add,
            size: ExpressiveIconButtonSize.medium,
            semanticLabel: 'Add',
            onPressed: _none,
          ),
        ),
        DesignAlignmentEntry(
          DesignInlineControl.textField,
          (context, label) => ExpressiveTextField(hintText: label),
        ),
        DesignAlignmentEntry(
          DesignInlineControl.select,
          (context, label) => ExpressiveSelect<String>(
            options: _options,
            value: label,
            onChanged: (_) {},
          ),
        ),
        DesignAlignmentEntry(
          DesignInlineControl.searchField,
          (context, label) => ExpressiveSearchField(hintText: label),
        ),
        DesignAlignmentEntry(
          DesignInlineControl.listTile,
          (context, label) => ExpressiveListTile(
            leading: const Icon(ExpressiveSymbols.map),
            title: Text(label),
            trailing: const Icon(ExpressiveSymbols.chevronRight),
            onTap: _none,
          ),
        ),
        DesignAlignmentEntry(
          DesignInlineControl.labeledCheckbox,
          (context, label) => ExpressiveCheckboxRow(
            label: label,
            value: true,
            onChanged: (_) {},
          ),
        ),
        DesignAlignmentEntry(
          DesignInlineControl.labeledSwitch,
          (context, label) =>
              ExpressiveSwitchRow(label: label, value: true, onChanged: (_) {}),
        ),
      ],
    ),
    // The 40dp line: the S button (the default), the icon button, the
    // segmented button, the number field's steppers and the chip.
    DesignAlignmentRow(
      size: 'small (40dp)',
      entries: [
        DesignAlignmentEntry(
          DesignInlineControl.button,
          (context, label) => ExpressiveFilledButton(
            label,
            size: ExpressiveButtonSize.small,
            onPressed: _none,
          ),
        ),
        DesignAlignmentEntry(
          DesignInlineControl.iconButton,
          (context, label) => const ExpressiveIconButton(
            ExpressiveSymbols.add,
            semanticLabel: 'Add',
            onPressed: _none,
          ),
        ),
        DesignAlignmentEntry(
          DesignInlineControl.segmentedButton,
          (context, label) => ExpressiveSegmentedButton<String>(
            expand: false,
            segments: [
              ExpressiveButtonSegment('a', label),
              const ExpressiveButtonSegment('b', 'Other'),
            ],
            value: 'a',
            onChanged: (_) {},
          ),
        ),
        DesignAlignmentEntry(
          DesignInlineControl.numberField,
          (context, label) =>
              ExpressiveNumberField(value: 2, onChanged: (_) {}),
        ),
        DesignAlignmentEntry(
          DesignInlineControl.chip,
          (context, label) => ExpressiveChip(label, onPressed: _none),
        ),
      ],
      heightExceptions: {
        DesignInlineControl.chip:
            "Material's chip is 32dp (ChipTokens.height), centred on the "
            'line; its touch target is 48dp',
      },
    ),
  ],
);

/// Every one-line text entry the look has.
final Map<String, DesignTextEntryBuilder> _entries = {
  for (final kind in ExpressiveTextFieldKind.values) ...{
    'Text field, ${kind.name}': (context, controller, hint) =>
        ExpressiveTextField(kind: kind, controller: controller, hintText: hint),
    'Password, ${kind.name}': (context, controller, hint) =>
        ExpressivePasswordField(
          kind: kind,
          controller: controller,
          hintText: hint,
        ),
  },
  'Search field': (context, controller, hint) =>
      ExpressiveSearchField(controller: controller, hintText: hint),
  'Input group': (context, controller, hint) => ExpressiveInputGroup(
    controller: controller,
    hintText: hint,
    leading: [ExpressiveInputGroup.text('https://')],
  ),
};

/// What the row check reads off the row's baseline that is not a fault, with
/// why; null for anything else (the coordinator's interim rule,
/// msg_80aedc5a5309). A face's label is drawn by its capitals on the face's
/// middle (DesignCapCenter, the label check's rule); a field's line is
/// centred by its box (the entry check's rule), its capitals 0.7 px above
/// the middle by the engine's whole-pixel baseline. The two rules part by
/// that much, and only the label's side is moved.
String? _rowMisread(String problem) {
  final m = RegExp(
    r"· (Button|List tile): its label's baseline is ([\d.]+) px below the "
    "row's",
  ).firstMatch(problem);
  if (m == null || double.parse(m.group(2)!) > 1) return null;
  return 'capitals on the face\'s middle; the row\'s fields by their line box';
}

void main() {
  setUpAll(loadExpressiveFonts);

  test('the matrix names every kind once, or says why it is absent', () {
    expect(expressiveAlignment.problems, isEmpty);
  });

  testWidgets('controls that share a line have one height, centre and '
      'baseline, on Android, iOS and macOS at every density', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(2400, 600);
    addTearDown(tester.view.reset);
    final report = await expressiveAlignment.check(
      pump: tester.pumpWidget,
      runAsync: tester.runAsync,
    );
    final faults = [
      for (final p in report.problems)
        if (_rowMisread(p) == null) p,
    ];
    // ignore: avoid_print
    print(
      [
        'ROW-CHECK: ${report.problems.length} read, ${faults.length} faults',
        for (final p in report.problems)
          '  ${_rowMisread(p) == null ? '!' : '~ ${_rowMisread(p)}:'} $p',
      ].join('\n'),
    );
    expect(faults, isEmpty, reason: faults.join('\n'));
    // The matrix reads the drawn pixels, the rasterizer's as a golden's
    // are: macOS runs it.
  }, tags: const ['goldens']);

  testWidgets('every text entry: its line on its box, its hint on its text, '
      'whatever the platform, density, text size or host theme', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 600);
    addTearDown(tester.view.reset);
    final report = await DesignTextEntryCheck(
      look: 'Material Expressive',
      themes: {
        for (final MapEntry(key: name, value: density) in _densities.entries)
          name: _under(density),
        'standard ×1.5': _under(ExpressiveDensity.standard, scale: 1.5),
        'standard, a host decoration theme': _under(
          ExpressiveDensity.standard,
          theme: ThemeData(
            inputDecorationTheme: const InputDecorationTheme(
              contentPadding: EdgeInsets.fromLTRB(12, 24, 12, 8),
              constraints: BoxConstraints(minHeight: 72),
              isDense: true,
            ),
          ),
        ),
      },
      entries: _entries,
    ).check(pump: tester.pumpWidget);
    report.verify();
  });

  final output = Platform.environment['EXPRESSIVE_DESIGN_REVIEW_OUT'];
  testWidgets('the review page\'s "Rows" sheet', (tester) async {
    for (final name in _densities.keys) {
      // Twice size, wide enough for the whole 56dp row.
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(3800, 520);
      addTearDown(tester.view.reset);
      const capture = ValueKey('rows');
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: RepaintBoundary(
            key: capture,
            child: DesignAlignmentSheet(
              matrix: expressiveAlignment,
              theme: name,
              zoom: 2,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.takeException(), isNull);
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(capture),
      );
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 1);
        try {
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final root = Directory(output!)..createSync(recursive: true);
          File('${root.path}/rows_$name.png')
              .writeAsBytesSync(bytes!.buffer.asUint8List());
        } finally {
          image.dispose();
        }
      });
    }
  }, skip: output == null);
}

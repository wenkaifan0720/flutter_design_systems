// A date field's calendar drops as one solid panel, as a menu does: the
// look's rule round the panel's fill on the hard ink shadow, the month's
// ruled table inside at the look's inset. A popover over a form must read as
// a surface standing over it. In 0.5.0 the table was its own frame: on a
// phone the calendar that opened above Stint's Due date field ended partway
// into the Notes field, a strip of half-cut words above its top rule, its
// sides on the field's own rules.
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:brutal_ui/brutal_ui.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

Future<void> _loadFonts() async {
  final manifest = json.decode(
    await rootBundle.loadString('FontManifest.json'),
  ) as List<dynamic>;
  for (final entry in manifest.cast<Map<String, dynamic>>()) {
    final family = entry['family'] as String;
    final loader = FontLoader(
      family.startsWith('packages/') ? family : brutalRegisteredFamily(family),
    );
    for (final font
        in (entry['fonts'] as List<dynamic>).cast<Map<String, dynamic>>()) {
      loader.addFont(rootBundle.load(font['asset'] as String));
    }
    await loader.load();
  }
}

Future<void> _pump(
  WidgetTester tester,
  Widget home, {
  required double width,
  TextDirection direction = TextDirection.ltr,
  Brightness brightness = Brightness.light,
  RawInput? input,
}) async {
  tester.view.physicalSize = Size(width, width < 600 ? 844 : 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (context, navigator) => Directionality(
        textDirection: direction,
        child: BrutalTheme(
          data: brightness == Brightness.light
              ? BrutalThemeData.light()
              : BrutalThemeData.dark(),
          child: RawTapTargetScope(
            targets: BrutalTheme.tapTargets.copyWith(input: input),
            child: BrutalToaster(child: navigator!),
          ),
        ),
      ),
      home: home,
    ),
  );
  await tester.pumpAndSettle();
}

Widget _date() => BrutalDatePicker(
  labelText: 'Due date',
  value: DateTime(2026, 11, 20),
  firstDate: DateTime(2020),
  lastDate: DateTime(2040, 12, 31),
  onChanged: (_) {},
);

Widget _range() => BrutalDateRangePicker(
  labelText: 'Dates',
  value: BrutalDateRange(
    start: DateTime(2026, 11, 20),
    end: DateTime(2026, 11, 24),
  ),
  firstDate: DateTime(2020),
  lastDate: DateTime(2040, 12, 31),
  onChanged: (_) {},
);

/// The panel round the open calendar: the nearest surface it stands on.
Finder _panel() => find
    .ancestor(
      of: find.byType(BrutalCalendar),
      matching: find.byType(BrutalSurface),
    )
    .first;

/// What shows of the page in the row of pixels just above [edge], across
/// [panel] (inside its rules): the share of it that is not the row's ground.
/// A rule across the row shows whole (1), the page's ground none (0); the
/// letters of a line the panel cuts show in part.
Future<double> _inkAbove(WidgetTester tester, Rect panel, double edge) async {
  final view = tester.binding.renderViews.first;
  final layer = view.debugLayer! as OffsetLayer;
  final size = view.size;
  final bytes = (await tester.runAsync(() async {
    final image = await layer.toImage(Offset.zero & size);
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    image.dispose();
    return data;
  }))!;
  final width = size.width.round();
  final y = edge.round() - 1;
  final from = panel.left.round() + 6, to = panel.right.round() - 6;
  int at(int x) => bytes.getUint32((y * width + x) * 4);
  final counts = <int, int>{};
  for (var x = from; x < to; x++) {
    counts.update(at(x), (n) => n + 1, ifAbsent: () => 1);
  }
  final ground = counts.entries.reduce((a, b) => a.value >= b.value ? a : b);
  int channel(int p, int shift) => (p >> shift) & 0xff;
  bool near(int a, int b) =>
      (channel(a, 24) - channel(b, 24)).abs() +
          (channel(a, 16) - channel(b, 16)).abs() +
          (channel(a, 8) - channel(b, 8)).abs() <
      48;
  var shown = 0;
  for (var x = from; x < to; x++) {
    if (!near(at(x), ground.key)) shown++;
  }
  return shown / (to - from);
}

/// Stint's task form, its Due date field low enough on a phone that its
/// calendar opens above it.
Widget _form() => BrutalScreen(
  topBar: const BrutalAppBar(title: 'Task details'),
  footer: BrutalButton.filled('Save changes', onPressed: () {}),
  body: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: 16,
    children: [
      const Align(
        alignment: AlignmentDirectional.centerStart,
        child: BrutalTag('ST-101'),
      ),
      BrutalTextField(
        labelText: 'Title',
        controller: TextEditingController(text: 'Proof the studio map'),
      ),
      BrutalTextField(
        labelText: 'Notes',
        controller: TextEditingController(
          text:
              'Use the courtyard entrance on the public copy. Check the '
              'step-free route with Sam before sending it to print.',
        ),
        minLines: 3,
        maxLines: 5,
      ),
      BrutalCombobox<String>(
        labelText: 'Project',
        options: const ['Open studio', 'Field guide'],
        value: 'Open studio',
        displayStringForOption: (v) => v,
        onSelected: (_) {},
      ),
      BrutalCombobox<String>(
        labelText: 'Assignee',
        options: const ['Maya Reed', 'Sam Okafor'],
        value: 'Maya Reed',
        displayStringForOption: (v) => v,
        onSelected: (_) {},
      ),
      _date(),
      BrutalFormField(
        labelText: 'Estimate (minutes)',
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: BrutalStepper(
            value: 45,
            min: 5,
            max: 480,
            semanticLabel: 'Estimate',
            onChanged: (_) {},
          ),
        ),
      ),
      const SizedBox(height: 400),
    ],
  ),
);

void main() {
  setUpAll(_loadFonts);

  group('the calendar drops as one panel', () {
    for (final (kind, picker, icon) in [
      ('date', _date, LucideIcons.calendar),
      ('date range', _range, LucideIcons.calendarRange),
    ]) {
      for (final width in const [390.0, 1440.0]) {
        for (final brightness in Brightness.values) {
          for (final direction in TextDirection.values) {
            testWidgets('a $kind at ${width.round()}, ${brightness.name}, '
                '${direction.name}: the look\'s rule round its fill, the '
                'month at its inset', (tester) async {
              await _pump(
                tester,
                Align(
                  alignment: AlignmentDirectional.topStart,
                  child: Padding(
                    padding: const EdgeInsetsDirectional.only(
                      start: 16,
                      top: 24,
                    ),
                    child: SizedBox(width: 358, child: picker()),
                  ),
                ),
                width: width,
                direction: direction,
                brightness: brightness,
              );
              await tester.tap(find.byIcon(icon));
              await tester.pumpAndSettle();
              final theme = BrutalTheme.of(
                tester.element(find.byType(BrutalCalendar)),
              );
              final face = tester.widget<BrutalSurface>(_panel()).face;
              expect(face.border, theme.colors.ink, reason: 'its rule');
              expect(face.borderWidth, isNull, reason: "the look's rule");
              expect(face.shadow, theme.colors.ink, reason: 'its shadow');
              final panel = tester.getRect(_panel());
              final month = tester.getRect(find.byType(BrutalCalendar));
              const inset = BrutalSpacing.medium;
              final edge = theme.borderWidth + inset;
              expect(month.left - panel.left, moreOrLessEquals(edge));
              expect(panel.right - month.right, moreOrLessEquals(edge));
              expect(month.top - panel.top, moreOrLessEquals(edge));
              expect(panel.bottom - month.bottom, moreOrLessEquals(edge));
              // Every day still takes the finger's floor across.
              final day = tester.getSize(find.text('20').last);
              expect(month.width / 7, greaterThanOrEqualTo(44), reason: '$day');
            });
          }
        }
      }
    }
  });

  group('on a phone, the calendar that opens above its field', () {
    // A finger's floor (a phone) and a pointer's (the web on a desk, as
    // the shots were taken): the month stands 48 or 44 a week.
    for (final input in RawInput.values) {
      for (final direction in TextDirection.values) {
        for (final brightness in Brightness.values) {
          testWidgets(
            'cuts no line of the form\'s words under a ${input.name}, '
            '${direction.name}, ${brightness.name}',
            (tester) async {
              await _pump(
                tester,
                _form(),
                width: 390,
                direction: direction,
                brightness: brightness,
                input: input,
              );
              final field = tester.getRect(find.byIcon(LucideIcons.calendar));
              await tester.tap(find.byIcon(LucideIcons.calendar));
              await tester.pumpAndSettle();
              final panel = tester.getRect(_panel());
              expect(
                panel.bottom,
                lessThanOrEqualTo(field.top),
                reason: 'above',
              );
              // The row above the panel's edge is the page's ground or a
              // rule across it, never part of a line of words.
              final shown = await _inkAbove(tester, panel, panel.top);
              expect(
                shown == 0 || shown > .9,
                isTrue,
                reason:
                    'above the panel at ${panel.top}, $shown of the row '
                    'shows',
              );
            },
          );
        }
      }
    }
  });
}

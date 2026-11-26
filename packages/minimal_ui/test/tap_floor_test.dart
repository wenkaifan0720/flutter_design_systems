// Minimal's parts take ui_core's tap floor (40 by 40 for a finger, 24 for a
// pointer) where they held a finger's 44 of their own, and follow a floor an
// app declares round them (an Android app's 48, say). A day keeps its 32 px
// mark with 4 px of air each side, so a calendar's rhythm is 40 on every
// input. Chips and pills stand their spacing apart face to face, their
// targets taking the air between them. On a phone's width a date opens in
// the sheet, not over the fields under its pill.
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart'
    show debugDefaultTargetPlatformOverride;
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Shows [part] by day in a phone (or [view]), under a declared [touch]
/// floor (ui_core's own when null), in [theme] (the standard preset).
Future<void> _show(
  WidgetTester tester,
  Widget part, {
  double? touch,
  double width = 342,
  Size view = const Size(390, 900),
  MinimalThemeData? theme,
}) async {
  tester.view
    ..physicalSize = view
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, app) => MinimalTheme(
        data: theme ?? MinimalThemeData.standard(),
        child: touch == null
            ? app!
            : RawTapTargetScope(
                targets: RawTapTargets(touch: Size.square(touch)),
                child: app!,
              ),
      ),
      home: Align(
        alignment: Alignment.topLeft,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SizedBox(width: width, child: part),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// The floor a part reads on the platform under test: ui_core's, or a
/// declared [touch] floor's (a pointer's stays 24).
double _floor(double? touch) =>
    (touch == null
            ? RawTapTargets.fallback
            : RawTapTargets(touch: Size.square(touch)))
        .floorOn()
        .height;

/// The face [target] (a TapTargetPadding) lays out inside its tap target,
/// in global coordinates.
Rect _face(WidgetTester tester, Finder target) {
  final box = tester.renderObject<RenderTapTargetPadding>(target);
  final face = box.faceRect ?? Offset.zero & box.size;
  return box.localToGlobal(face.topLeft) & face.size;
}

void main() {
  const platforms = TargetPlatformVariant({
    TargetPlatform.android,
    TargetPlatform.macOS,
  });

  testWidgets(
    'a calendar\'s days stand 40 apart on every input',
    variant: platforms,
    (tester) async {
      await _show(
        tester,
        MinimalCalendar(
          firstDate: DateTime(2026),
          lastDate: DateTime(2026, 12, 31),
          value: DateTime(2026, 3, 18),
          onChanged: (_) {},
        ),
      );
      final ten = tester.getCenter(find.text('10'));
      final eleven = tester.getCenter(find.text('11'));
      expect(ten.dy, eleven.dy);
      expect((eleven.dx - ten.dx).abs(), 40);
    },
  );

  testWidgets(
    "a date picker's weeks stand 40 apart on every input",
    variant: platforms,
    (tester) async {
      await _show(
        tester,
        MinimalDatePicker(
          labelText: 'Due',
          value: DateTime(2026, 3, 18),
          mode: MinimalDatePickerMode.date,
          presentation: MinimalDatePickerPresentation.inline,
          onChanged: (_) {},
        ),
      );
      final ten = tester.getCenter(find.text('10').last);
      final week = tester.getCenter(find.text('17').last);
      expect(week.dx, moreOrLessEquals(ten.dx, epsilon: 0.01));
      expect(week.dy - ten.dy, 40);
    },
  );

  for (final declared in const [null, 48.0]) {
    final named = declared == null ? 'the floor in force' : 'a declared 48';

    testWidgets('a slider\'s strip is $named tall', variant: platforms, (
      tester,
    ) async {
      await _show(
        tester,
        MinimalSlider(
          label: 'Volume',
          value: 0.5,
          showLabel: false,
          onChanged: (_) {},
        ),
        touch: declared,
      );
      final floor = _floor(declared);
      expect(tester.getSize(find.byType(MinimalSlider)).height, floor);
    });

    testWidgets('a range slider is $named tall', variant: platforms, (
      tester,
    ) async {
      await _show(
        tester,
        MinimalRangeSlider(
          label: 'Price',
          values: const RawRangeValues(0.2, 0.8),
          showLabel: false,
          onChanged: (_) {},
        ),
        touch: declared,
      );
      final floor = _floor(declared);
      expect(tester.getSize(find.byType(MinimalRangeSlider)).height, floor);
    });
  }

  testWidgets("a colour picker's strips reach past its column by ui_core's "
      'thumb target, so a thumb stops half a thumb inside the edge', (
    tester,
  ) async {
    await _show(
      tester,
      MinimalColorPicker(value: const Color(0xFFFF0000), onChanged: (_) {}),
    );
    final column = tester.getRect(find.byType(MinimalColorPicker));
    final strip = tester.getRect(find.byType(RawColorSlider).first);
    final target = tester.widget<RawColorSlider>(
      find.byType(RawColorSlider).first,
    );
    // A 16 px thumb whose target's centre travels from half a thumb inside
    // one edge of the column to half a thumb inside the other.
    expect(column.left - strip.left, target.thumbSize.width / 2 - 8);
  });

  for (final (name, group) in [
    (
      'a chip row',
      MinimalChipRow(
        children: [
          for (final f in const ['Planning', 'Design', 'Review', 'Launch'])
            MinimalChip(f, onPressed: () {}),
        ],
      ),
    ),
    (
      'a property bar',
      MinimalPropertyBar(
        pills: [
          for (final f in const ['Every evening', 'Goal', 'Reminder', 'Area'])
            MinimalPropertyPill(
              icon: LucideIcons.repeat,
              label: f,
              onPressed: () {},
            ),
        ],
      ),
    ),
  ]) {
    testWidgets(
      '$name stands its runs 6 apart face to face, or as far as '
      'the targets need',
      variant: platforms,
      (tester) async {
        await _show(tester, group, width: 180);
        final pressables = find.descendant(
          of: find.byWidget(group),
          matching: find.byType(TapTargetPadding),
        );
        final faces = [
          for (var i = 0; i < pressables.evaluate().length; i++)
            _face(tester, pressables.at(i)),
        ];
        final first = faces.first;
        final below = faces.firstWhere((f) => f.top > first.bottom);
        final floor = _floor(null);
        expect(
          below.top - first.bottom,
          moreOrLessEquals(math.max(6, floor - first.height), epsilon: 0.01),
        );
      },
    );
  }

  testWidgets(
    "a sheet's header stands at the floor at a finger, never at 44",
    variant: platforms,
    (tester) async {
      await _show(tester, const SizedBox());
      final context = tester.element(find.byType(SizedBox).last);
      unawaited(
        showMinimalBottomSheet<void>(
          context,
          title: 'Comments',
          builder: (_) => const SizedBox(height: 120),
        ),
      );
      await tester.pumpAndSettle();
      final band = find.ancestor(
        of: find.text('Comments'),
        matching: find.byWidgetPredicate(
          (w) => w is SizedBox && w.height != null && w.child is Padding,
        ),
      );
      final height = tester.getSize(band.first).height;
      // A finger's floor of 40; at a pointer, the close's square with 4 px of
      // air each side.
      if (debugDefaultTargetPlatformOverride == TargetPlatform.android) {
        expect(height, 40);
      }
      expect(height, lessThan(44));
      expect(height, greaterThanOrEqualTo(_floor(null)));
    },
  );

  testWidgets(
    "a reorderable row's grip is the floor square, never less than "
    'its 28 px face',
    variant: platforms,
    (tester) async {
      await _show(
        tester,
        MinimalReorderableListView<String>(
          items: const ['Inbox', 'Today'],
          onReorder: (_, _) {},
          labelOf: (s) => s,
          itemBuilder: (context, item) => Text(item),
        ),
      );
      final grip = find.ancestor(
        of: find.byWidgetPredicate(
          (w) => w is MinimalIcon && w.icon == LucideIcons.gripVertical,
        ),
        matching: find.byWidgetPredicate(
          (w) => w is SizedBox && w.width != null && w.child is Center,
        ),
      );
      final side = math.max(_floor(null), 28.0);
      expect(tester.getSize(grip.first), Size(side, side));
    },
  );

  testWidgets(
    "a path with a way back stands in the floor's band",
    variant: platforms,
    (tester) async {
      await _show(
        tester,
        MinimalBreadcrumb(
          crumbs: [
            MinimalBreadcrumbItem('Projects', onPressed: () {}),
            const MinimalBreadcrumbItem('Atlas'),
          ],
        ),
      );
      final height = tester.getSize(find.byType(MinimalBreadcrumb)).height;
      expect(height, lessThan(44));
      expect(height, greaterThanOrEqualTo(_floor(null)));
    },
  );

  for (final (width, sheet) in const [(390.0, true), (1024.0, false)]) {
    testWidgets('at ${width.round()} a date opens '
        '${sheet ? 'in the sheet' : 'in the anchored calendar'}', (
      tester,
    ) async {
      DateTime? chosen;
      await _show(
        tester,
        MinimalDatePicker(
          labelText: 'Due date',
          value: DateTime(2026, 11, 20),
          mode: MinimalDatePickerMode.date,
          onChanged: (v) => chosen = v,
        ),
        view: Size(width, 900),
      );
      await tester.tap(find.text(MinimalFormat.date(DateTime(2026, 11, 20))));
      await tester.pumpAndSettle();
      expect(find.text('November 2026'), findsOneWidget);
      expect(find.text('Done'), sheet ? findsOneWidget : findsNothing);
      await tester.tap(find.text('24').last);
      await tester.pumpAndSettle();
      if (sheet) {
        // The sheet commits on Done, as Material's dialog does.
        expect(chosen, isNull);
        await tester.tap(find.text('Done'));
        await tester.pumpAndSettle();
      }
      expect(chosen, DateTime(2026, 11, 24));
    });
  }

  testWidgets(
    "a multi-select's runs of tags stand far enough apart that each remove "
    'key takes taps half the floor above and below its middle',
    variant: platforms,
    (tester) async {
      const labels = [
        'design',
        'web',
        'mobile',
        'research',
        'urgent',
        'later',
        'backend',
        'docs',
      ];
      final removed = <String>[];
      await _show(
        tester,
        MinimalMultiSelect<String>(
          options: labels,
          values: labels,
          onChanged: (v) => removed.addAll(labels.where((l) => !v.contains(l))),
        ),
      );
      final floor = _floor(null);
      Rect key(String l) =>
          tester.getRect(find.bySemanticsLabel(RegExp('Remove $l\$')));
      final runs = {for (final l in labels) key(l).top}.toList()..sort();
      expect(
        runs.length,
        greaterThanOrEqualTo(3),
        reason: 'three runs of tags',
      );
      final middle = labels.firstWhere((l) => key(l).top == runs[1]);
      for (final dy in [-(floor / 2 - 1), floor / 2 - 1]) {
        removed.clear();
        await tester.tapAt(key(middle).center + Offset(0, dy));
        await tester.pumpAndSettle();
        expect(removed, [middle], reason: '$middle, $dy from its middle');
      }
    },
  );
}

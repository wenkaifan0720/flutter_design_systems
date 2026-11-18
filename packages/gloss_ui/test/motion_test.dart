// In motion (design6 O): every part that moves, drags, opens or previews,
// looked at mid-move on a phone by day and a desk by night. Mid-move nothing
// throws (no overflow), nothing is painted outside the part (its soft shadow
// and its focus ring aside), a range's preview ends on the day the pointer
// rests on, and what opens does not jump when it settles.
// ignore_for_file: avoid_relative_lib_imports
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gloss_ui/gloss_parts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../example/lib/kit_gallery/kit.dart';
import '../example/lib/kit_gallery/simmer/simmer.dart';

final _stage = GlobalKey();

/// A value a specimen changes, held for it.
class _Held<T> extends StatefulWidget {
  const _Held(this.initial, this.builder);

  final T initial;
  final Widget Function(BuildContext context, T value, ValueChanged<T> change)
  builder;

  @override
  State<_Held<T>> createState() => _HeldState<T>();
}

class _HeldState<T> extends State<_Held<T>> {
  late T _value = widget.initial;

  @override
  Widget build(BuildContext context) =>
      widget.builder(context, _value, (v) => setState(() => _value = v));
}

Widget _host(Brightness brightness, Widget child) => kitApp(
  brightness: brightness,
  home: Builder(
    builder: (context) {
      final width = MediaQuery.sizeOf(context).width;
      return RepaintBoundary(
        key: _stage,
        child: ColoredBox(
          color: context.glossTheme.colors.page,
          child: Padding(
            padding: const EdgeInsets.all(GlossSpacing.large),
            child: Align(
              alignment: Alignment.topCenter,
              child: SizedBox(width: math.min(480, width - 48), child: child),
            ),
          ),
        ),
      );
    },
  ),
);

Future<Uint8List> _pixels(WidgetTester tester) async {
  final boundary =
      _stage.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  return (await tester.runAsync(() async {
    final image = await boundary.toImage();
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    image.dispose();
    return data!.buffer.asUint8List();
  }))!;
}

/// How many pixels outside [part]'s box (grown by [slack] for its soft
/// shadow and its focus ring) are not the page.
Future<int> _strays(
  WidgetTester tester,
  Finder part, {
  double slack = 16,
}) async {
  final stage = tester.getRect(find.byKey(_stage));
  final box = tester.getRect(part).inflate(slack);
  final page = GlossTheme.of(tester.element(find.byKey(_stage))).colors.page
      .toARGB32();
  final pr = (page >> 16) & 0xFF, pg = (page >> 8) & 0xFF, pb = page & 0xFF;
  final data = await _pixels(tester);
  final w = stage.width.round();
  final h = stage.height.round();
  var strays = 0;
  for (var y = 0; y < h; y++) {
    final gy = stage.top + y + 0.5;
    for (var x = 0; x < w; x++) {
      final gx = stage.left + x + 0.5;
      if (box.contains(Offset(gx, gy))) continue;
      final i = (y * w + x) * 4;
      // A shadow's last breath (one step of 255) is not a stray.
      if ((data[i] - pr).abs() > 2 ||
          (data[i + 1] - pg).abs() > 2 ||
          (data[i + 2] - pb).abs() > 2) {
        strays++;
      }
    }
  }
  return strays;
}

/// The colour painted at [at], in the stage.
Future<int> _colourAt(WidgetTester tester, Offset at) async {
  final stage = tester.getRect(find.byKey(_stage));
  final data = await _pixels(tester);
  final w = stage.width.round();
  final x = (at.dx - stage.left).floor();
  final y = (at.dy - stage.top).floor();
  final i = (y * w + x) * 4;
  return 0xFF000000 | data[i] << 16 | data[i + 1] << 8 | data[i + 2];
}

/// Half a move: one frame to start it, then part of its way.
Future<void> _halfway(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 60));
}

Future<void> _clean(WidgetTester tester, String why) async {
  expect(tester.takeException(), isNull, reason: why);
}

void main() {
  const cases = [
    (name: 'phone by day', size: Size(390, 900), brightness: Brightness.light),
    (name: 'desk by night', size: Size(1440, 900), brightness: Brightness.dark),
  ];

  for (final c in cases) {
    Future<void> show(WidgetTester tester, Widget child) async {
      tester.view.physicalSize = c.size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_host(c.brightness, child));
      await tester.pumpAndSettle();
    }

    group(c.name, () {
      testWidgets('a carousel at 30% and 70% of a swipe', (tester) async {
        await show(
          tester,
          GlossCarousel(
            itemCount: 3,
            itemBuilder: (context, i) => ColoredBox(
              color: const Color(0xFFE9D9B8),
              child: Center(child: Text('Photo ${i + 1}')),
            ),
          ),
        );
        final part = find.byType(GlossCarousel);
        final width = tester.getSize(part).width;
        final drag = await tester.startGesture(
          tester.getCenter(find.text('Photo 1')),
        );
        for (final through in [0.3, 0.7]) {
          await drag.moveTo(
            tester.getCenter(part) - Offset(width * through, 0),
          );
          await tester.pump();
          await _clean(tester, 'carousel at $through');
          expect(await _strays(tester, part), 0, reason: 'carousel $through');
        }
        await drag.up();
        await tester.pumpAndSettle();
        expect(find.text('Photo 2'), findsOneWidget);
      });

      testWidgets('a swiped row, mid-drag and released', (tester) async {
        await show(
          tester,
          const GlossWell(
            children: [
              GlossSwipeRow(
                endActions: [
                  GlossSwipeAction(
                    label: 'Delete',
                    isDestructiveAction: true,
                    onPressed: _none,
                  ),
                ],
                child: GlossListTile(title: 'Lemon risotto'),
              ),
            ],
          ),
        );
        final part = find.byType(GlossWell);
        final drag = await tester.startGesture(
          tester.getCenter(find.byType(GlossSwipeRow)),
        );
        for (var i = 0; i < 6; i++) {
          await drag.moveBy(const Offset(-16, 0));
          await tester.pump();
        }
        await _clean(tester, 'row mid-drag');
        expect(await _strays(tester, part), 0, reason: 'row mid-drag');
        await drag.up();
        await _halfway(tester);
        expect(await _strays(tester, part), 0, reason: 'row released');
        await tester.pumpAndSettle();
      });

      testWidgets('a slider dragged past both ends', (tester) async {
        await show(
          tester,
          _Held<double>(
            0.4,
            (context, v, change) => GlossSlider(
              value: v,
              onChanged: change,
              semanticLabel: 'Spice',
            ),
          ),
        );
        final part = find.byType(GlossSlider);
        final drag = await tester.startGesture(tester.getCenter(part));
        for (final to in [-2000.0, 4000.0]) {
          await drag.moveBy(Offset(to / 4, 0));
          await tester.pump();
          await drag.moveBy(Offset(to * 3 / 4, 0));
          await tester.pump();
          await _clean(tester, 'slider at $to');
          expect(await _strays(tester, part), 0, reason: 'slider at $to');
        }
        await drag.up();
        await tester.pumpAndSettle();
      });

      testWidgets('a range slider with its beads meeting', (tester) async {
        await show(
          tester,
          _Held<GlossRangeValues>(
            const GlossRangeValues(0.2, 0.7),
            (context, v, change) =>
                GlossRangeSlider(values: v, onChanged: change),
          ),
        );
        final part = find.byType(GlossRangeSlider);
        final box = tester.getRect(part);
        final drag = await tester.startGesture(
          Offset(box.left + 17 + (box.width - 34) * 0.2, box.center.dy),
        );
        await drag.moveBy(Offset(box.width * 0.3, 0));
        await tester.pump();
        await drag.moveBy(Offset(box.width * 0.4, 0));
        await tester.pump();
        await _clean(tester, 'beads meeting');
        expect(await _strays(tester, part), 0, reason: 'beads meeting');
        await drag.up();
        await tester.pumpAndSettle();
      });

      final changes = <(String, Widget, Finder Function(), String)>[
        (
          'a switch',
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: _Held<bool>(
              false,
              (context, v, change) => GlossSwitch(
                value: v,
                onChanged: change,
                semanticLabel: 'Reminders',
              ),
            ),
          ),
          () => find.byType(GlossSwitch),
          '',
        ),
        (
          'a checkbox',
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: _Held<bool?>(
              false,
              (context, v, change) => GlossCheckbox(
                value: v,
                onChanged: change,
                semanticLabel: 'Bought',
              ),
            ),
          ),
          () => find.byType(GlossCheckbox),
          '',
        ),
        (
          'segments',
          _Held<int>(
            0,
            (context, v, change) => GlossSegmentedButton<int>(
              selected: v,
              onChanged: change,
              segments: const [
                GlossSegment(value: 0, label: 'Day'),
                GlossSegment(value: 1, label: 'Week'),
                GlossSegment(value: 2, label: 'Month'),
              ],
            ),
          ),
          () => find.byType(GlossSegmentedButton<int>),
          'Month',
        ),
        (
          'tabs',
          _Held<int>(
            0,
            (context, v, change) => GlossTabBar(
              tabs: const ['Method', 'Ingredients', 'Notes'],
              selectedIndex: v,
              onSelected: change,
            ),
          ),
          () => find.byType(GlossTabBar),
          'Notes',
        ),
      ];
      for (final (name, specimen, part, target) in changes) {
        testWidgets('$name half-way through a change', (tester) async {
          await show(tester, specimen);
          await tester.tap(target.isEmpty ? part() : find.text(target));
          await _halfway(tester);
          await _clean(tester, '$name half-way');
          expect(await _strays(tester, part()), 0, reason: '$name half-way');
          await tester.pumpAndSettle();
        });
      }

      testWidgets('a disclosure half-open and half-closed', (tester) async {
        await show(
          tester,
          const GlossDisclosure(
            title: 'Storage',
            child: Text(
              'Keeps three days in the fridge in a closed box. Freeze it '
              'before the lemon goes in, and stir the lemon in once it is hot.',
            ),
          ),
        );
        final part = find.byType(GlossDisclosure);
        for (final step in ['open', 'close']) {
          await tester.tap(find.text('Storage'));
          await _halfway(tester);
          await _clean(tester, 'disclosure half-way to $step');
          expect(await _strays(tester, part), 0, reason: 'disclosure $step');
          await tester.pumpAndSettle();
        }
      });

      testWidgets("a range's preview ends on the day the pointer rests on", (
        tester,
      ) async {
        await show(
          tester,
          _Held<GlossDateRange?>(
            null,
            (context, v, change) => GlossCalendar.range(
              firstDate: DateTime(2026, 11),
              lastDate: DateTime(2026, 12, 31),
              currentDate: DateTime(2026, 11, 2),
              selectedRange: v,
              onRangeChanged: change,
            ),
          ),
        );
        final glaze = c.brightness == Brightness.light
            ? 0xFFD9F1E7
            : 0xFF1E4136;
        // A day's glaze, read in its own cell's top start corner, inside the
        // band and clear of the round bead.
        Future<int> fill(int day) async {
          final cell = tester.getRect(
            find
                .ancestor(
                  of: find.text('$day').first,
                  matching: find.byType(Stack),
                )
                .first,
          );
          return _colourAt(tester, Offset(cell.left + 3, cell.top + 6));
        }

        await tester.tap(find.text('10').first);
        await tester.pump();
        final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
        await mouse.addPointer(location: Offset.zero);
        addTearDown(mouse.removePointer);
        // The same week, then a later one.
        for (final (end, middle, after) in [(13, 12, 14), (19, 16, 20)]) {
          await mouse.moveTo(tester.getCenter(find.text('$end').first));
          await tester.pumpAndSettle();
          expect(
            await fill(middle),
            glaze,
            reason: '$middle is inside the preview',
          );
          expect(
            await fill(after),
            isNot(glaze),
            reason: 'the preview stops at $end',
          );
        }
        // Before the start: nothing past the start is previewed.
        await mouse.moveTo(tester.getCenter(find.text('6').first));
        await tester.pumpAndSettle();
        expect(await fill(12), isNot(glaze));
        await _clean(tester, 'range preview');
      });

      testWidgets('a pull to refresh, mid-pull', (tester) async {
        await show(
          tester,
          SizedBox(
            height: 240,
            child: GlossPullToRefresh(
              onRefresh: () async {},
              child: ListView(
                children: const [
                  GlossListTile(title: 'Lemon risotto'),
                  GlossListTile(title: 'Green curry'),
                ],
              ),
            ),
          ),
        );
        final part = find.byType(GlossPullToRefresh);
        final drag = await tester.startGesture(tester.getCenter(part));
        for (var i = 0; i < 8; i++) {
          await drag.moveBy(const Offset(0, 12));
          await tester.pump();
        }
        await _clean(tester, 'mid-pull');
        expect(await _strays(tester, part), 0, reason: 'mid-pull');
        await drag.up();
        await tester.pumpAndSettle();
      });

      testWidgets('a lifted row, mid-move', (tester) async {
        await show(
          tester,
          _Held<List<String>>(
            const ['Toast the rice', 'Add the stock', 'Stir in the lemon'],
            (context, steps, change) => GlossReorderableList<String>(
              items: steps,
              labelOf: (s) => s,
              onReorder: (from, to) {
                final next = [...steps];
                next.insert(to, next.removeAt(from));
                change(next);
              },
              itemBuilder: (context, s) => Text(s),
            ),
          ),
        );
        final part = find.byType(GlossReorderableList<String>);
        // The row lifts by its grip.
        final drag = await tester.startGesture(
          tester.getCenter(find.byIcon(LucideIcons.gripVertical).first),
        );
        await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
        for (var i = 0; i < 4; i++) {
          await drag.moveBy(const Offset(0, 14));
          await tester.pump();
        }
        await _clean(tester, 'lifted row');
        expect(
          await _strays(tester, part, slack: 24),
          0,
          reason: 'the lifted row stays over its list',
        );
        await drag.up();
        await tester.pumpAndSettle();
      });

      testWidgets('a sheet and a dialog do not jump when they settle', (
        tester,
      ) async {
        await show(
          tester,
          Builder(
            builder: (context) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GlossButton(
                  'Open a sheet',
                  onPressed: () => showGlossSheet<void>(
                    context: context,
                    title: 'Filters',
                    builder: (context) => const Text('Courses'),
                  ),
                ),
                const SizedBox(height: GlossSpacing.regular),
                GlossButton(
                  'Ask',
                  onPressed: () => showGlossDialog<void>(
                    context: context,
                    builder: (context) => const GlossDialog(
                      title: 'Delete this plan?',
                      actions: [
                        GlossDialogAction(label: 'Keep', onPressed: _none),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
        for (final (opener, title) in [
          ('Open a sheet', 'Filters'),
          ('Ask', 'Delete this plan?'),
        ]) {
          await tester.tap(find.text(opener));
          await _halfway(tester);
          await _clean(tester, '$title half-open');
          final mid = tester.getRect(find.text(title));
          await tester.pumpAndSettle();
          final rest = tester.getRect(find.text(title));
          // A dialog grows from 96% about its centre, so its words come in
          // a few pixels toward it; neither slides sideways.
          expect(
            mid.center.dx,
            moreOrLessEquals(rest.center.dx, epsilon: 12),
            reason: '$title does not slide sideways',
          );
          expect(
            mid.top,
            greaterThanOrEqualTo(rest.top - 2),
            reason:
                '$title comes up into place, never past it by more than '
                'a settle',
          );
          await tester.tapAt(const Offset(4, 4));
          await _halfway(tester);
          await _clean(tester, '$title half-closed');
          await tester.pumpAndSettle();
          expect(find.text(title), findsNothing);
        }
      });

      testWidgets('a pushed page rises a short way into place and goes back '
          'the same way', (tester) async {
        Route<void> page() => MaterialPageRoute<void>(
          builder: (context) => ColoredBox(
            color: context.glossTheme.colors.page,
            child: const Center(child: Text('Lemon risotto')),
          ),
        );
        await show(
          tester,
          Builder(
            builder: (context) => GlossButton(
              'Open',
              onPressed: () => Navigator.of(context).push(page()),
            ),
          ),
        );
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        final rest = tester.getRect(find.text('Lemon risotto'));
        Navigator.of(tester.element(find.text('Lemon risotto'))).pop();
        await tester.pumpAndSettle();
        Navigator.of(tester.element(find.text('Open'))).push(page());
        for (final step in ['in', 'back']) {
          await _halfway(tester);
          await _clean(tester, 'a page half-way $step');
          final mid = tester.getRect(find.text('Lemon risotto'));
          expect(
            mid.left,
            moreOrLessEquals(rest.left, epsilon: 0.5),
            reason: '$step: it moves only up and down',
          );
          expect(
            mid.top - rest.top,
            inInclusiveRange(-4, 24),
            reason: '$step: it rises a short way into place',
          );
          await tester.pumpAndSettle();
          if (step == 'in') {
            expect(tester.getRect(find.text('Lemon risotto')), rest);
            Navigator.of(tester.element(find.text('Lemon risotto'))).pop();
          }
        }
        expect(find.text('Lemon risotto'), findsNothing);
      });
    });
  }

  // The example is written on Flutter's own material library, whose
  // MaterialPageRoute reads Flutter's Theme: the app gives Gloss's change to
  // its own ThemeData (glossPageTransitions), on every platform.
  testWidgets(
    "the example app's own routes, Flutter's MaterialPageRoute, change "
    "Gloss's way",
    (tester) async {
      tester.view.physicalSize = const Size(390, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        const SimmerApp(initialPlace: SimmerPlace.recipes),
      );
      await tester.pumpAndSettle();
      const name = 'Miso-glazed aubergine';
      await tester.tap(find.text(name).first);
      await tester.pumpAndSettle();
      final rest = tester.getRect(find.text('Add to this week'));
      Navigator.of(tester.element(find.text('Add to this week'))).pop();
      await tester.pumpAndSettle();
      await tester.tap(find.text(name).first);
      await _halfway(tester);
      await _clean(tester, 'the recipe page half-way in');
      final mid = tester.getRect(find.text('Add to this week'));
      expect(
        mid.left,
        moreOrLessEquals(rest.left, epsilon: 0.5),
        reason: 'it moves only up and down',
      );
      expect(
        mid.top - rest.top,
        inInclusiveRange(-4, 24),
        reason: 'it rises a short way into place',
      );
      await tester.pumpAndSettle();
    },
    variant: TargetPlatformVariant.all(),
  );
}

void _none() {}

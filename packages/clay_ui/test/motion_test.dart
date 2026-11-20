// Clay in motion: controls sampled half-way through a change paint nowhere but their own box (and its soft shadow),
// a range's preview follows the day under the pointer, and sheets, dialogs and pages settle without a jump.
// ignore_for_file: avoid_relative_lib_imports
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
// The example's own Material (its routes read its Theme).
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:clay_ui/clay_parts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../example/lib/kit_gallery/kit.dart';
import '../example/lib/kit_gallery/steady/steady.dart';

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
          color: context.clayTheme.colors.ground,
          child: Padding(
            padding: const EdgeInsets.all(ClaySpacing.large),
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
/// shadow: a raised card's falls about 36 px, a floating one's 64) are not
/// the page.
Future<int> _strays(
  WidgetTester tester,
  Finder part, {
  double slack = 40,
}) async {
  final stage = tester.getRect(find.byKey(_stage));
  final box = tester.getRect(part).inflate(slack);
  final page = ClayTheme.of(tester.element(find.byKey(_stage))).colors.ground
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

/// Whether colours [a] and [b] differ by more than a few levels in any
/// channel (a soft shading's dither is not a difference).
bool _differ(int a, int b) =>
    ((a >> 16 & 0xFF) - (b >> 16 & 0xFF)).abs() > 4 ||
    ((a >> 8 & 0xFF) - (b >> 8 & 0xFF)).abs() > 4 ||
    ((a & 0xFF) - (b & 0xFF)).abs() > 4;

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
          ClayCarousel(
            itemCount: 3,
            itemBuilder: (context, i) => ColoredBox(
              color: const Color(0xFFCFE3FF),
              child: Center(child: Text('Tip ${i + 1}')),
            ),
          ),
        );
        final part = find.byType(ClayCarousel);
        final width = tester.getSize(part).width;
        final drag = await tester.startGesture(
          tester.getCenter(find.text('Tip 1')),
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
        expect(find.text('Tip 2'), findsOneWidget);
      });

      testWidgets('a swiped row, mid-drag and released', (tester) async {
        await show(
          tester,
          const ClayGroup(
            children: [
              ClaySwipeRow(
                endActions: [
                  ClaySwipeAction(
                    label: 'Delete',
                    isDestructiveAction: true,
                    onPressed: _none,
                  ),
                ],
                child: ClayListTile(title: 'Drink water'),
              ),
            ],
          ),
        );
        final part = find.byType(ClayGroup);
        final drag = await tester.startGesture(
          tester.getCenter(find.byType(ClaySwipeRow)),
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
            (context, v, change) => ClaySlider(
              value: v,
              onChanged: change,
              semanticLabel: 'Energy',
            ),
          ),
        );
        final part = find.byType(ClaySlider);
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
          _Held<ClayRangeValues>(
            const ClayRangeValues(0.2, 0.7),
            (context, v, change) =>
                ClayRangeSlider(values: v, onChanged: change),
          ),
        );
        final part = find.byType(ClayRangeSlider);
        final box = tester.getRect(part);
        final drag = await tester.startGesture(
          Offset(box.left + 22 + (box.width - 44) * 0.2, box.center.dy),
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
              (context, v, change) => ClaySwitch(
                value: v,
                onChanged: change,
                semanticLabel: 'Reminders',
              ),
            ),
          ),
          () => find.byType(ClaySwitch),
          '',
        ),
        (
          'a checkbox',
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: _Held<bool?>(
              false,
              (context, v, change) => ClayCheckbox(
                value: v,
                onChanged: change,
                semanticLabel: 'Done',
              ),
            ),
          ),
          () => find.byType(ClayCheckbox),
          '',
        ),
        (
          'segments',
          _Held<int>(
            0,
            (context, v, change) => ClaySegmentedButton<int>(
              selected: v,
              onChanged: change,
              segments: const [
                ClaySegment(value: 0, label: 'Day'),
                ClaySegment(value: 1, label: 'Week'),
                ClaySegment(value: 2, label: 'Month'),
              ],
            ),
          ),
          () => find.byType(ClaySegmentedButton<int>),
          'Month',
        ),
        (
          'tabs',
          _Held<int>(
            0,
            (context, v, change) => ClayTabBar(
              tabs: const ['Week', 'Month', 'Year'],
              selectedIndex: v,
              onSelected: change,
            ),
          ),
          () => find.byType(ClayTabBar),
          'Year',
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
          const ClayDisclosure(
            title: 'Why it matters',
            child: Text(
              'A glass before coffee wakes you gently. Keep the bottle on the '
              'desk where you see it, and fill it again at lunch.',
            ),
          ),
        );
        final part = find.byType(ClayDisclosure);
        for (final step in ['open', 'close']) {
          await tester.tap(find.text('Why it matters'));
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
          _Held<ClayDateRange?>(
            null,
            (context, v, change) => ClayCalendar.range(
              firstDate: DateTime(2026, 11),
              lastDate: DateTime(2026, 12, 31),
              currentDate: DateTime(2026, 11, 2),
              selectedRange: v,
              onRangeChanged: change,
            ),
          ),
        );
        // A day's clay, read just inside its cell's top start corner, clear
        // of the raised ball an end stands on.
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

        // The band's clay: what a day far from any range is not.
        final bare = await fill(25);
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
            _differ(await fill(middle), bare),
            isTrue,
            reason: '$middle is inside the preview',
          );
          expect(
            _differ(await fill(after), bare),
            isFalse,
            reason: 'the preview stops at $end',
          );
        }
        // Before the start: nothing past the start is previewed.
        await mouse.moveTo(tester.getCenter(find.text('6').first));
        await tester.pumpAndSettle();
        expect(_differ(await fill(12), bare), isFalse);
        await _clean(tester, 'range preview');
      });

      testWidgets('a pull to refresh, mid-pull', (tester) async {
        await show(
          tester,
          SizedBox(
            height: 240,
            child: ClayPullToRefresh(
              onRefresh: () async {},
              child: ListView(
                children: const [
                  ClayListTile(title: 'Drink water'),
                  ClayListTile(title: 'Read'),
                ],
              ),
            ),
          ),
        );
        final part = find.byType(ClayPullToRefresh);
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
            const ['Drink water', 'Read', 'Stretch'],
            (context, steps, change) => ClayReorderableList<String>(
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
        final part = find.byType(ClayReorderableList<String>);
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
          await _strays(tester, part, slack: 64),
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
                ClayButton(
                  'Open a sheet',
                  onPressed: () => showClayBottomSheet<void>(
                    context: context,
                    title: 'Reminder time',
                    builder: (context) => const Text('8:00'),
                  ),
                ),
                const SizedBox(height: ClaySpacing.regular),
                ClayButton(
                  'Ask',
                  onPressed: () => showClayDialog<void>(
                    context: context,
                    builder: (context) => const ClayDialog(
                      title: 'Delete this habit?',
                      actions: [
                        ClayDialogAction(label: 'Keep', onPressed: _none),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
        for (final (opener, title) in [
          ('Open a sheet', 'Reminder time'),
          ('Ask', 'Delete this habit?'),
        ]) {
          await tester.tap(find.text(opener));
          await _halfway(tester);
          await _clean(tester, '$title half-open');
          final mid = tester.getRect(find.text(title));
          await tester.pumpAndSettle();
          final rest = tester.getRect(find.text(title));
          // A dialog inflates about its centre, so its words come in a few
          // pixels toward it; neither slides sideways.
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

      testWidgets('a pushed page inflates in place and goes back the same '
          'way', (tester) async {
        Route<void> page() => MaterialPageRoute<void>(
          builder: (context) => ColoredBox(
            color: context.clayTheme.colors.ground,
            child: const Center(child: Text('Drink water')),
          ),
        );
        await show(
          tester,
          Builder(
            builder: (context) => ClayButton(
              'Open',
              onPressed: () => Navigator.of(context).push(page()),
            ),
          ),
        );
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        final rest = tester.getRect(find.text('Drink water'));
        Navigator.of(tester.element(find.text('Drink water'))).pop();
        await tester.pumpAndSettle();
        Navigator.of(tester.element(find.text('Open'))).push(page());
        for (final step in ['in', 'back']) {
          await _halfway(tester);
          await _clean(tester, 'a page half-way $step');
          final mid = tester.getRect(find.text('Drink water'));
          expect(
            (mid.center - rest.center).distance,
            lessThan(2),
            reason: '$step: it grows about its own middle, not sliding',
          );
          expect(
            mid.height / rest.height,
            inInclusiveRange(0.93, 1.005),
            reason: '$step: it inflates from a little under its size',
          );
          await tester.pumpAndSettle();
          if (step == 'in') {
            expect(tester.getRect(find.text('Drink water')), rest);
            Navigator.of(tester.element(find.text('Drink water'))).pop();
          }
        }
        expect(find.text('Drink water'), findsNothing);
      });
    });
  }

  // The example is written on Flutter's own material library, whose
  // MaterialPageRoute reads Flutter's Theme: the app gives Clay's change to
  // its own ThemeData (clayPageTransitions), on every platform.
  testWidgets(
    "the example app's own routes, Flutter's MaterialPageRoute, change "
    "Clay's way",
    (tester) async {
      tester.view.physicalSize = const Size(390, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        const SteadyApp(initialPlace: SteadyPlace.habits),
      );
      await tester.pumpAndSettle();
      const name = 'Drink water';
      await tester.tap(find.text(name).first);
      await tester.pumpAndSettle();
      final rest = tester.getRect(find.text('Edit habit'));
      Navigator.of(tester.element(find.text('Edit habit'))).pop();
      await tester.pumpAndSettle();
      await tester.tap(find.text(name).first);
      await _halfway(tester);
      await _clean(tester, 'the habit page half-way in');
      final mid = tester.getRect(find.text('Edit habit'));
      expect(
        mid.height / rest.height,
        inInclusiveRange(0.93, 1.005),
        reason: 'it inflates from a little under its size',
      );
      await tester.pumpAndSettle();
    },
    variant: TargetPlatformVariant.all(),
  );
}

void _none() {}

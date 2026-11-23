// Check bounds during movement, range previews under the pointer, and
// the final positions of opened overlays.
// ignore_for_file: avoid_relative_lib_imports
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:brutal_ui/brutal_parts.dart';
import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../example/lib/kit_gallery/admit/admit.dart';
import '../example/lib/kit_gallery/kit.dart';
import 'tiers.dart';

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
          color: context.brutalTheme.colors.paper,
          child: Padding(
            padding: const EdgeInsets.all(BrutalSpacing.large),
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

/// How many pixels outside [part]'s box (grown by [slack] for the rule's
/// edge, the hard shadow and the focus line) are not the page's paper.
Future<int> _strays(
  WidgetTester tester,
  Finder part, {
  double slack = 8,
}) async {
  final stage = tester.getRect(find.byKey(_stage));
  final box = tester.getRect(part).inflate(slack);
  final paper = BrutalTheme.of(tester.element(find.byKey(_stage))).colors.paper
      .toARGB32();
  final pr = (paper >> 16) & 0xFF, pg = (paper >> 8) & 0xFF, pb = paper & 0xFF;
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
      if (data[i] != pr || data[i + 1] != pg || data[i + 2] != pb) strays++;
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

  for (final (ci, c) in cases.indexed) {
    // Each check every run in one case, the phone by day and the desk by
    // night taking turns; the other in the sweep.
    var k = 0;
    void check(String description, WidgetTesterCallback body) => testWidgets(
      description,
      body,
      tags: sweepUnless(k++ % cases.length == ci),
    );

    Future<void> show(WidgetTester tester, Widget child) async {
      tester.view.physicalSize = c.size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_host(c.brightness, child));
      await tester.pumpAndSettle();
    }

    group(c.name, () {
      check('a carousel at 30% and 70% of a swipe', (tester) async {
        await show(
          tester,
          BrutalCarousel(
            itemCount: 3,
            itemBuilder: (context, i) => Center(child: Text('Slide ${i + 1}')),
          ),
        );
        final part = find.byType(BrutalCarousel);
        final width = tester.getSize(part).width;
        final drag = await tester.startGesture(tester.getCenter(part));
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
        expect(find.text('Slide 2'), findsOneWidget);
      });

      check('a swiped row, mid-drag and released', (tester) async {
        await show(
          tester,
          const BrutalSwipeRow(
            endActions: [
              BrutalSwipeAction(
                label: 'Delete',
                isDestructiveAction: true,
                onPressed: _none,
              ),
            ],
            child: BrutalListTile(title: 'Low Tide'),
          ),
        );
        final part = find.byType(BrutalSwipeRow);
        final drag = await tester.startGesture(tester.getCenter(part));
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

      check('a slider dragged past both ends', (tester) async {
        await show(
          tester,
          _Held<double>(
            0.4,
            (context, v, change) =>
                BrutalSlider(value: v, onChanged: change, semanticLabel: 'Vol'),
          ),
        );
        final part = find.byType(BrutalSlider);
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

      check('a range slider with its thumbs meeting', (tester) async {
        await show(
          tester,
          _Held<BrutalRangeValues>(
            const BrutalRangeValues(0.2, 0.7),
            (context, v, change) =>
                BrutalRangeSlider(values: v, onChanged: change),
          ),
        );
        final part = find.byType(BrutalRangeSlider);
        final box = tester.getRect(part);
        final drag = await tester.startGesture(
          Offset(box.left + box.width * 0.2, box.center.dy),
        );
        await drag.moveBy(Offset(box.width * 0.3, 0));
        await tester.pump();
        await drag.moveBy(Offset(box.width * 0.4, 0));
        await tester.pump();
        await _clean(tester, 'thumbs meeting');
        expect(await _strays(tester, part), 0, reason: 'thumbs meeting');
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
              (context, v, change) => BrutalSwitch(
                value: v,
                onChanged: change,
                semanticLabel: 'Reminders',
              ),
            ),
          ),
          () => find.byType(BrutalSwitch),
          '',
        ),
        (
          'segments',
          _Held<int>(
            0,
            (context, v, change) => BrutalSegmentedButton<int>(
              value: v,
              onChanged: change,
              segments: const [
                BrutalSegment(value: 0, label: 'Week'),
                BrutalSegment(value: 1, label: 'Month'),
                BrutalSegment(value: 2, label: 'Year'),
              ],
            ),
          ),
          () => find.byType(BrutalSegmentedButton<int>),
          'Year',
        ),
        (
          'tabs',
          _Held<int>(
            0,
            (context, v, change) => BrutalTabBar(
              tabs: const ['Upcoming', 'Past', 'Saved'],
              selectedIndex: v,
              onTap: change,
            ),
          ),
          () => find.byType(BrutalTabBar),
          'Saved',
        ),
      ];
      for (final (name, specimen, part, target) in changes) {
        check('$name half-way through a change', (tester) async {
          await show(tester, specimen);
          await tester.tap(target.isEmpty ? part() : find.text(target));
          await _halfway(tester);
          await _clean(tester, '$name half-way');
          expect(await _strays(tester, part()), 0, reason: '$name half-way');
          await tester.pumpAndSettle();
        });
      }

      check('a disclosure half-open and half-closed', (tester) async {
        await show(
          tester,
          const BrutalDisclosure(
            title: 'Refunds',
            child: Text(
              'Up to a day before the doors open, to the card you paid '
              'with. After that, a ticket can be passed on to a friend.',
            ),
          ),
        );
        final part = find.byType(BrutalDisclosure);
        for (final step in ['open', 'close']) {
          await tester.tap(find.text('Refunds'));
          await _halfway(tester);
          await _clean(tester, 'disclosure half-way to $step');
          expect(await _strays(tester, part), 0, reason: 'disclosure $step');
          await tester.pumpAndSettle();
        }
      });

      check("a range's preview ends on the day the pointer rests on", (
        tester,
      ) async {
        await show(
          tester,
          _Held<BrutalDateRange?>(
            null,
            (context, v, change) => BrutalCalendar.range(
              firstDate: DateTime(2026, 11),
              lastDate: DateTime(2026, 12, 31),
              currentDate: DateTime(2026, 11, 2),
              selectedRange: v,
              onRangeChanged: change,
            ),
          ),
        );
        final colors = BrutalTheme.of(tester.element(find.byKey(_stage)))
            .colors;
        // A day's fill, read in its cell beside its figures.
        Future<int> fill(int day) async {
          final figures = tester.getRect(find.text('$day').first);
          return _colourAt(tester, Offset(figures.left - 6, figures.center.dy));
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
            await fill(end),
            colors.ink.toARGB32(),
            reason: 'the preview ends on $end with an end',
          );
          expect(
            await fill(middle),
            colors.lime.toARGB32(),
            reason: '$middle is inside the preview',
          );
          expect(
            await fill(after),
            isNot(colors.lime.toARGB32()),
            reason: 'the preview stops at $end',
          );
        }
        // Before the start: nothing past the start is previewed.
        await mouse.moveTo(tester.getCenter(find.text('6').first));
        await tester.pumpAndSettle();
        expect(await fill(12), isNot(colors.lime.toARGB32()));
        await _clean(tester, 'range preview');
      });

      check('a pull to refresh, mid-pull', (tester) async {
        await show(
          tester,
          SizedBox(
            height: 240,
            child: BrutalPullToRefresh(
              onRefresh: () async {},
              child: ListView(
                children: const [
                  BrutalListTile(title: 'Low Tide'),
                  BrutalListTile(title: 'Hall 4'),
                ],
              ),
            ),
          ),
        );
        final part = find.byType(BrutalPullToRefresh);
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

      check('a lifted row, mid-move', (tester) async {
        await show(
          tester,
          _Held<List<String>>(
            const ['Doors', 'Support', 'Headline'],
            (context, acts, change) => BrutalReorderableList<String>(
              items: acts,
              labelOf: (a) => a,
              onReorder: (from, to) {
                final next = [...acts];
                next.insert(to, next.removeAt(from));
                change(next);
              },
              itemBuilder: (context, a) => Text(a),
            ),
          ),
        );
        final part = find.byType(BrutalReorderableList<String>);
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
          await _strays(tester, part, slack: 16),
          0,
          reason: 'the lifted row stays over its list',
        );
        await drag.up();
        await tester.pumpAndSettle();
      });

      check('a sheet and a dialog do not jump when they settle', (
        tester,
      ) async {
        await show(
          tester,
          Builder(
            builder: (context) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BrutalButton(
                  'Open a sheet',
                  onPressed: () => showBrutalBottomSheet<void>(
                    context: context,
                    title: 'Filter',
                    builder: (context) => const Text('Venues'),
                  ),
                ),
                const SizedBox(height: BrutalSpacing.regular),
                BrutalButton(
                  'Ask',
                  icon: const Icon(LucideIcons.ticket),
                  onPressed: () => showBrutalDialog<void>(
                    context: context,
                    builder: (context) => const BrutalDialog(
                      title: 'Cancel this ticket?',
                      actions: [
                        BrutalDialogAction(label: 'Keep', onPressed: _none),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
        for (final (opener, title) in [
          ('Open a sheet', 'Filter'),
          ('Ask', 'Cancel this ticket?'),
        ]) {
          await tester.tap(find.text(opener));
          await _halfway(tester);
          await _clean(tester, '$title half-open');
          final mid = tester.getRect(find.text(title));
          await tester.pumpAndSettle();
          final rest = tester.getRect(find.text(title));
          expect(mid.left, rest.left, reason: '$title moves only upward');
          expect(mid.width, rest.width, reason: '$title keeps its size');
          expect(mid.top, greaterThanOrEqualTo(rest.top));
          await tester.tapAt(const Offset(4, 4));
          await _halfway(tester);
          await _clean(tester, '$title half-closed');
          await tester.pumpAndSettle();
          expect(find.text(title), findsNothing);
        }
      });

      check('a pushed page mid-change comes a short way, over a page '
          'that stays put, and goes back the same way', (tester) async {
        Route<void> page() => MaterialPageRoute<void>(
          builder: (context) => ColoredBox(
            color: context.brutalTheme.colors.paper,
            child: const Center(child: Text('Low Tide')),
          ),
        );
        await show(
          tester,
          Builder(
            builder: (context) => BrutalButton(
              'Open',
              onPressed: () => Navigator.of(context).push(page()),
            ),
          ),
        );
        final opener = tester.getRect(find.text('Open'));
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        final rest = tester.getRect(find.text('Low Tide'));
        Navigator.of(tester.element(find.text('Low Tide'))).pop();
        await tester.pumpAndSettle();
        // Pushed without a press, so the opener's own press is not read as
        // the page beneath moving.
        Navigator.of(tester.element(find.text('Open'))).push(page());
        for (final step in ['in', 'back']) {
          await _halfway(tester);
          await _clean(tester, 'a page half-way $step');
          final mid = tester.getRect(find.text('Low Tide'));
          final off = mid.left - rest.left;
          expect(mid.top, rest.top, reason: '$step: it moves only along');
          expect(
            off,
            inInclusiveRange(0, BrutalPageTransitionsBuilder.travel),
            reason: '$step: it comes from the end side, a short way',
          );
          expect(
            tester.getRect(find.text('Open')),
            opener,
            reason: '$step: the page beneath stays where it is',
          );
          await tester.pumpAndSettle();
          if (step == 'in') {
            expect(tester.getRect(find.text('Low Tide')), rest);
            Navigator.of(tester.element(find.text('Low Tide'))).pop();
          }
        }
        expect(find.text('Low Tide'), findsNothing);
      });
    });
  }

  // The example is written on Flutter's own material library, whose
  // MaterialPageRoute reads Flutter's Theme, never the material_ui one
  // BrutalTheme lays: the app gives Brutal's change to its own ThemeData
  // (brutalPageTransitions). Without it, macOS and the web on
  // a Mac slide Cupertino's whole width in. iOS takes Brutal's push too,
  // with its swipe back round it.
  // iOS (its swipe back round Brutal's push), Android and macOS (Cupertino's
  // slide without brutalPageTransitions) every run; the rest in the sweep.
  const pageChangePlatforms = {
    TargetPlatform.iOS,
    TargetPlatform.android,
    TargetPlatform.macOS,
  };
  for (final everyday in const [true, false]) {
    testWidgets(
      "the example app's own routes, Flutter's MaterialPageRoute, change "
      "Brutal's way",
      (tester) async {
        tester.view.physicalSize = const Size(390, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          const AdmitApp(initialPlace: AdmitPlace.events),
        );
        await tester.pumpAndSettle();
        final beneath = tester.getRect(find.text('Northern Lines'));
        await tester.tap(find.text('Low Tide'));
        await tester.pumpAndSettle();
        final rest = tester.getRect(find.text('Buy tickets'));
        Navigator.of(tester.element(find.text('Buy tickets'))).pop();
        await tester.pumpAndSettle();
        await tester.tap(find.text('Low Tide'));
        await _halfway(tester);
        await _clean(tester, 'the event page half-way in');
        final mid = tester.getRect(find.text('Buy tickets'));
        expect(mid.top, rest.top, reason: 'it moves only along');
        expect(
          mid.left - rest.left,
          inInclusiveRange(1, BrutalPageTransitionsBuilder.travel),
          reason: 'it comes from the end side, a short way',
        );
        expect(
          tester.getRect(find.text('Northern Lines')),
          beneath,
          reason: 'the page beneath stays where it is',
        );
        await tester.pumpAndSettle();
      },
      variant: TargetPlatformVariant(
        everyday
            ? pageChangePlatforms
            : TargetPlatform.values.toSet().difference(pageChangePlatforms),
      ),
      tags: sweepUnless(everyday),
    );
  }
}

void _none() {}

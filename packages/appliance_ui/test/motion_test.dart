// Controls retain their geometry during drags, presses and overlay transitions.
import 'dart:async';

import 'package:appliance_ui/appliance_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(Widget child, {Brightness brightness = Brightness.light}) =>
    MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (context, app) =>
          ApplianceHost(brightness: brightness, child: app!),
      home: ApplianceScreen(
        body: Align(
          alignment: AlignmentDirectional.topStart,
          child: SizedBox(width: 358, child: child),
        ),
      ),
    );

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// Pumps [frames] frames of 16 ms, checking nothing threw on any.
Future<void> _frames(WidgetTester tester, [int frames = 6]) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 16));
    expect(tester.takeException(), isNull);
  }
}

void main() {
  testWidgets('a carousel mid-swipe: the slides stay in the rounded window', (
    tester,
  ) async {
    _phone(tester);
    await tester.pumpWidget(
      _app(
        ApplianceCarousel(
          itemCount: 3,
          semanticLabel: 'Kettles',
          itemBuilder: (context, i) => ColoredBox(
            color: [Colors.teal, Colors.amber, Colors.indigo][i],
            child: Center(child: Text('Slide $i')),
          ),
        ),
      ),
    );
    await tester.pump();
    final scrollable = find
        .descendant(
          of: find.byType(ApplianceCarousel),
          matching: find.byType(Scrollable),
        )
        .first;
    final clip = find.ancestor(
      of: scrollable,
      matching: find.byType(ClipRRect),
    );
    expect(clip, findsWidgets, reason: 'the window clips the moving slides');
    final rounded = tester.widget<ClipRRect>(clip.first);
    expect(
      (rounded.borderRadius as BorderRadius).topLeft.x,
      greaterThan(0),
      reason: 'the window clips round, not square',
    );
    final window = tester.getRect(clip.first);
    final view = tester.getRect(scrollable);
    for (final fraction in [0.3, 0.7]) {
      final drag = await tester.startGesture(tester.getCenter(scrollable));
      await drag.moveBy(Offset(-view.width * fraction, 0));
      await _frames(tester);
      // Every slide that shows is cut by the window's rounded frame.
      for (final slide in find.byType(ColoredBox).evaluate()) {
        final box = slide.renderObject! as RenderBox;
        if (!box.hasSize) continue;
        final rect = box.localToGlobal(Offset.zero) & box.size;
        if (!rect.overlaps(window)) continue;
        // A drag rebuilds the carousel, so the window is matched by its
        // rounded cut rather than by the instance found before it.
        expect(
          find.ancestor(
            of: find.byWidget(slide.widget),
            matching: find.byWidgetPredicate(
              (w) => w is ClipRRect && w.borderRadius == rounded.borderRadius,
            ),
          ),
          findsOneWidget,
        );
      }
      await drag.up();
      await tester.pump(const Duration(seconds: 1));
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets("a range's preview ends on the hovered day, as an end", (
    tester,
  ) async {
    _phone(tester);
    final controller = RawCalendarController(
      firstDate: DateTime(2026),
      lastDate: DateTime(2027, 12, 31),
      initialMonth: DateTime(2026, 11),
      mode: RawCalendarMode.range,
    );
    addTearDown(controller.dispose);
    await tester.pumpWidget(_app(ApplianceCalendar(controller: controller)));
    await tester.pump();
    await tester.tap(find.text('10'));
    await tester.pump(const Duration(milliseconds: 300));
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: tester.getCenter(find.text('13')));
    addTearDown(mouse.removePointer);
    await mouse.moveTo(tester.getCenter(find.text('13')));
    await tester.pump(const Duration(milliseconds: 300));
    final trough = ApplianceThemeData.of(Brightness.light).colors.trough;
    final bands = find.byWidgetPredicate(
      (w) =>
          w is Container &&
          w.decoration is BoxDecoration &&
          (w.decoration! as BoxDecoration).color != null &&
          (w.decoration! as BoxDecoration).color!.r == trough.r &&
          (w.decoration! as BoxDecoration).color!.g == trough.g &&
          (w.decoration! as BoxDecoration).color!.b == trough.b,
    );
    final rects = [
      for (final e in bands.evaluate()) tester.getRect(find.byWidget(e.widget)),
    ];
    expect(rects, hasLength(4), reason: 'the band covers the 10th to the 13th');
    final right = rects.map((r) => r.right).reduce((a, b) => a > b ? a : b);
    final left = rects.map((r) => r.left).reduce((a, b) => a < b ? a : b);
    final start = tester.getCenter(find.text('10'));
    final end = tester.getCenter(find.text('13'));
    expect(left, lessThan(start.dx));
    expect(right, greaterThan(end.dx));
    expect(right - end.dx, lessThan(32), reason: 'the band stops at the 13th');
    // The band's ends are rounded as a finished range's are.
    final last = bands.evaluate().firstWhere(
      (e) => tester.getRect(find.byWidget(e.widget)).right == right,
    );
    final radius =
        ((last.widget as Container).decoration! as BoxDecoration).borderRadius!
            as BorderRadius;
    expect(radius.topRight.x, greaterThan(0));
  });

  testWidgets('a sheet and a dialog half-way open and half-way closed', (
    tester,
  ) async {
    _phone(tester);
    late BuildContext page;
    await tester.pumpWidget(
      _app(
        Builder(
          builder: (context) {
            page = context;
            return const SizedBox(height: 40);
          },
        ),
      ),
    );
    unawaited(
      showApplianceBottomSheet<void>(
        context: page,
        title: 'Filter',
        builder: (context) => const Column(
          mainAxisSize: MainAxisSize.min,
          children: [Text('In stock only'), Text('New this season')],
        ),
      ),
    );
    await _frames(tester, 8);
    Navigator.of(page).pop();
    await _frames(tester, 8);
    await tester.pumpAndSettle();

    unawaited(
      showApplianceDialog<void>(
        context: page,
        builder: (context) => ApplianceDialog(
          title: 'Remove from the basket?',
          content: const Text('It goes back on the shelf.'),
          actions: [
            ApplianceButton('Keep it', onPressed: () => Navigator.pop(context)),
          ],
        ),
      ),
    );
    await _frames(tester, 6);
    Navigator.of(page).pop();
    await _frames(tester, 6);
    await tester.pumpAndSettle();
  });

  testWidgets('a disclosure half-open, a switch half-way, a slider dragged', (
    tester,
  ) async {
    _phone(tester);
    var on = false;
    var level = 0.5;
    var range = const RawRangeValues(0.2, 0.8);
    await tester.pumpWidget(
      _app(
        StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ApplianceDisclosure(
                title: 'Care',
                child: Text(
                  'Descale monthly; wipe the outside with a damp cloth. '
                  'Dry the spout before you put it away.',
                ),
              ),
              ApplianceSwitch(
                value: on,
                semanticLabel: 'Order updates',
                onChanged: (v) => setState(() => on = v),
              ),
              ApplianceSlider(
                value: level,
                semanticLabel: 'Volume',
                onChanged: (v) => setState(() => level = v),
              ),
              ApplianceRangeSlider(
                values: range,
                onChanged: (v) => setState(() => range = v),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('Care'));
    await _frames(tester, 5);
    await tester.tap(find.byType(ApplianceSwitch));
    await _frames(tester, 5);
    await tester.pumpAndSettle();

    final slider = find.byType(ApplianceSlider);
    final rect = tester.getRect(slider);
    final drag = await tester.startGesture(rect.center);
    await drag.moveBy(Offset(rect.width, 0));
    await _frames(tester, 3);
    expect(level, greaterThan(0.9), reason: 'dragged past the end');
    await drag.moveBy(Offset(-rect.width * 2, 0));
    await _frames(tester, 3);
    expect(level, lessThan(0.1));
    await drag.up();
    await tester.pumpAndSettle();
  });

  testWidgets('a row swiped half-way and a row lifted', (tester) async {
    _phone(tester);
    var items = ['Kettle', 'Tea tin', 'Jars'];
    await tester.pumpWidget(
      _app(
        StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ApplianceSwipeActions(
                endActions: [
                  RawSwipeAction(
                    label: 'Remove',
                    destructive: true,
                    onPressed: () {},
                  ),
                ],
                child: const ApplianceListTile(title: 'Stovetop kettle'),
              ),
              ApplianceReorderableList<String>(
                items: items,
                labelOf: (s) => s,
                title: (s) => s,
                onReorder: (from, to) => setState(() {
                  items = [...items];
                  items.insert(to, items.removeAt(from));
                }),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    final row = find.text('Stovetop kettle');
    final swipe = await tester.startGesture(tester.getCenter(row));
    await swipe.moveBy(const Offset(-60, 0));
    await _frames(tester, 4);
    await swipe.moveBy(const Offset(-40, 0));
    await _frames(tester, 4);
    await swipe.up();
    await tester.pumpAndSettle();

    final lift = await tester.startGesture(
      tester.getCenter(find.text('Kettle')),
    );
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
    await lift.moveBy(const Offset(0, 30));
    await _frames(tester, 4);
    await lift.moveBy(const Offset(0, 40));
    await _frames(tester, 4);
    await lift.up();
    await tester.pumpAndSettle();
  });

  testWidgets('pull to refresh mid-pull', (tester) async {
    _phone(tester);
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        builder: (context, app) => ApplianceHost(child: app!),
        home: ApplianceScreen(
          scroll: false,
          body: ApplianceRefresh(
            onRefresh: () => Future<void>.delayed(const Duration(seconds: 1)),
            child: ListView(
              children: const [
                ApplianceListTile(title: 'Order 1048'),
                ApplianceListTile(title: 'Order 1045'),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    final pull = await tester.startGesture(
      tester.getCenter(find.text('Order 1048')),
    );
    for (var i = 0; i < 6; i++) {
      await pull.moveBy(const Offset(0, 24));
      await _frames(tester, 2);
    }
    await pull.up();
    await _frames(tester, 10);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
  });
}

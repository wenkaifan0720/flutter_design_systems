// An open list marks its value one way in every field that opens one. A
// combobox opened on its value by a pointer marks the value as a select's
// list does (its lamp, heavier words, the words unlit), and lights a row
// only once a key or the pointer moves. A combobox's list stands as clear of
// its field as a select's. By night each list stands in a lit aluminium rim,
// so it reads apart from a field's glass under it.
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studio_ui/studio_ui.dart';

const _projects = ['Open studio', 'Field guide', 'Workshop series'];

Widget _app(Brightness brightness, Widget child) => MaterialApp(
  builder: (context, page) => StudioTheme(
    data: brightness == Brightness.dark
        ? StudioThemeData.dark()
        : StudioThemeData.light(),
    child: page!,
  ),
  home: Builder(
    builder: (context) => ColoredBox(
      color: StudioTheme.of(context).colors.chassis,
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(padding: const EdgeInsets.all(24), child: child),
      ),
    ),
  ),
);

// The words of the open list's row reading [label].
TextStyle _row(WidgetTester tester, String label) => tester
    .widget<Text>(
      find.descendant(
        of: find.byType(StudioMenuRow),
        matching: find.text(label),
      ),
    )
    .style!;

void main() {
  for (final brightness in Brightness.values) {
    testWidgets(
      'by ${brightness.name} a combobox opened by a pointer marks its value '
      'as a select does',
      (tester) async {
        tester.view.physicalSize = const Size(800, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          _app(
            brightness,
            SizedBox(
              width: 360,
              child: Column(
                children: [
                  StudioSelect<String>(
                    labelText: 'Density',
                    value: _projects.first,
                    items: [
                      for (final p in _projects)
                        StudioSelectItem(value: p, label: p),
                    ],
                    onChanged: (_) {},
                  ),
                  const SizedBox(height: 300),
                  StudioCombobox<String>(
                    labelText: 'Project',
                    options: _projects,
                    labelOf: (p) => p,
                    value: _projects.first,
                    onSelected: (_) {},
                  ),
                ],
              ),
            ),
          ),
        );
        final colors = StudioTheme.of(
          tester.element(find.byType(StudioSelect<String>)),
        ).colors;

        await tester.tap(
          find.byType(StudioSelect<String>),
          kind: PointerDeviceKind.mouse,
        );
        await tester.pumpAndSettle();
        final select = _row(tester, _projects.first);
        expect(select.color, colors.onDisplay);
        expect(select.fontWeight, FontWeight.w600);
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();

        await tester.tap(
          find.descendant(
            of: find.byType(StudioCombobox<String>),
            matching: find.byType(EditableText),
          ),
          kind: PointerDeviceKind.mouse,
        );
        await tester.pumpAndSettle();
        expect(find.byType(StudioMenuRow), findsNWidgets(_projects.length));
        final combobox = _row(tester, _projects.first);
        expect(combobox.color, select.color);
        expect(combobox.fontWeight, select.fontWeight);

        // A key moves the light; back on the value, the value's row is lit.
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pumpAndSettle();
        expect(_row(tester, _projects[1]).color, isNot(colors.onDisplay));
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
        await tester.pumpAndSettle();
        expect(_row(tester, _projects.first).color, isNot(colors.onDisplay));
        expect(_row(tester, _projects[1]).color, colors.onDisplay);
      },
    );
  }

  testWidgets(
    "a combobox's list stands clear of its field by a select's gap, below "
    'it or above it',
    (tester) async {
      tester.view.physicalSize = const Size(800, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      Widget combobox() => StudioCombobox<String>(
        labelText: 'Project',
        options: _projects,
        labelOf: (p) => p,
        value: _projects.first,
        onSelected: (_) {},
      );
      Future<void> open(Finder field) async {
        await tester.tap(field, kind: PointerDeviceKind.mouse);
        await tester.pumpAndSettle();
      }

      Finder typed() => find.descendant(
        of: find.byType(StudioCombobox<String>),
        matching: find.byType(StudioTextField),
      );

      await tester.pumpWidget(
        _app(
          Brightness.dark,
          SizedBox(
            width: 360,
            child: Column(
              children: [
                StudioSelect<String>(
                  value: _projects.first,
                  items: [
                    for (final p in _projects)
                      StudioSelectItem(value: p, label: p),
                  ],
                  onChanged: (_) {},
                ),
                const SizedBox(height: 300),
                combobox(),
              ],
            ),
          ),
        ),
      );
      await open(find.byType(StudioSelect<String>));
      final selectGap =
          tester.getRect(find.byType(StudioListBezel)).top -
          tester.getRect(find.byType(StudioSelect<String>)).bottom;
      expect(selectGap, StudioSpacing.tight);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      await open(typed());
      expect(
        tester.getRect(find.byType(StudioListBezel)).top -
            tester.getRect(typed()).bottom,
        selectGap,
        reason: 'below',
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      // Low on the screen it opens above, clear of the field's top.
      await tester.pumpWidget(
        _app(
          Brightness.dark,
          SizedBox(
            width: 360,
            child: Column(
              children: [
                const SizedBox(height: 760),
                // A new field, not the one above kept with its focus.
                KeyedSubtree(key: const ValueKey('low'), child: combobox()),
              ],
            ),
          ),
        ),
      );
      await open(typed());
      final list = tester.getRect(find.byType(StudioListBezel));
      expect(list.bottom, lessThan(tester.getRect(typed()).top));
      expect(
        tester.getRect(typed()).top - list.bottom,
        selectGap,
        reason: 'above',
      );
    },
  );

  testWidgets(
    'by night an open list stands in a metal rim, apart from the glass '
    'under it',
    (tester) async {
      final stage = GlobalKey();
      await tester.pumpWidget(
        _app(
          Brightness.dark,
          RepaintBoundary(
            key: stage,
            child: const SizedBox(
              width: 300,
              child: StudioListBezel(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    StudioMenuRow(label: 'Open studio', chosen: true),
                    StudioMenuRow(label: 'Field guide'),
                    StudioMenuRow(label: 'Workshop series'),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final colors = StudioTheme.of(
        tester.element(find.byType(StudioListBezel)),
      ).colors;
      final box = tester.getSize(find.byKey(stage));
      final pixels = (await tester.runAsync(() async {
        final boundary =
            stage.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await boundary.toImage();
        final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
        image.dispose();
        return data!.buffer.asUint8List();
      }))!;
      Color at(int x, int y) {
        final i = (y * box.width.round() + x) * 4;
        return Color.fromARGB(255, pixels[i], pixels[i + 1], pixels[i + 2]);
      }

      double distance(Color a, Color b) =>
          ((a.r - b.r).abs() + (a.g - b.g).abs() + (a.b - b.b).abs()) * 255;
      final middle = (box.height / 2).round();
      // The rim, on both sides, is the caps' aluminium (halfway down, a
      // quarter of the way to their lower tone), clearly apart from the glass
      // inside (as dark as a field's glass under the list).
      for (final x in [0, box.width.round() - 1]) {
        final rim = at(x, middle);
        final glass = at(x == 0 ? 8 : x - 8, middle);
        expect(
          distance(rim, Color.lerp(colors.cap, colors.capLow, 0.25)!),
          lessThan(distance(rim, glass)),
          reason: 'x $x',
        );
        expect(distance(rim, glass), greaterThan(12), reason: 'x $x');
      }
    },
  );
}

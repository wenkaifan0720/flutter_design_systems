// ignore_for_file: avoid_relative_lib_imports
// The Foundations page names every preset the look ships, each by day and
// by night: a tile on the preset's own ground, its ink and its accent.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';

import '../example/lib/kit_gallery/demos/foundations.dart';
import '../example/lib/kit_gallery/kit.dart';
import 'flutter_test_config.dart' show longWalkLeakTesting;

void main() {
  // Decoded marks stay in the image cache past their test: cleared, so leak
  // tracking sees them disposed.
  tearDown(
    () => imageCache
      ..clear()
      ..clearLiveImages(),
  );
  testWidgets(
    'the Foundations page shows every preset by day and by night',
    experimentalLeakTesting: longWalkLeakTesting,
    (tester) async {
      tester.view
        ..physicalSize = const Size(390, 844)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      kitEmbedded = true;
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MinimalHost(
            light: kitTheme(Brightness.light),
            dark: kitTheme(Brightness.dark),
            brightness: Brightness.light,
            child: child!,
          ),
          home: SingleChildScrollView(
            child: kitFoundationsDemo(Brightness.light),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('PRESETS'), findsOneWidget);
      expect([
        for (final palette in MinimalThemeData.palettes) palette.id,
      ], hasLength(greaterThanOrEqualTo(3)));
      for (final id in [
        for (final palette in MinimalThemeData.palettes) palette.id,
      ]) {
        expect(find.text(id), findsOneWidget, reason: id);
        for (final b in Brightness.values) {
          final preset = MinimalThemeData.preset(id, b);
          final tile = find.bySemanticsLabel(
            '$id, ${b == Brightness.dark ? 'night' : 'day'}',
          );
          expect(tile, findsOneWidget, reason: '$id ${b.name}');
          Color? fill(Finder f) =>
              (tester.widget<Container>(f).decoration as ShapeDecoration?)
                  ?.color;
          final boxes = find.descendant(
            of: tile,
            matching: find.byType(Container),
            matchRoot: true,
          );
          final colours = [
            for (var i = 0; i < boxes.evaluate().length; i++) fill(boxes.at(i)),
          ];
          expect(colours, contains(preset.background), reason: '$id ground');
          expect(colours, contains(preset.primary), reason: '$id accent');
          final ink = tester
              .widgetList<Text>(
                find.descendant(of: tile, matching: find.byType(Text)),
              )
              .single
              .style
              ?.color;
          expect(ink, preset.foreground, reason: '$id ink');
        }
      }
    },
  );
}

/// Expressive in ui_core's shared inventory (looks/INVENTORY.md): it answers
/// every row once, each live specimen is the row's own class
/// (`Expressive<Stem>`), and each one builds and lays out on a phone and a
/// desktop, light and dark, without an error.
library;

import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';
import 'package:material_expressive_ui/material_expressive_host.dart';

Widget _host(
  WidgetBuilder builder, {
  Brightness brightness = Brightness.light,
  double width = 390,
}) => MaterialApp(
  home: ExpressiveHost(
    light: ExpressiveThemeData.preset('baseline', Brightness.light),
    dark: ExpressiveThemeData.preset('baseline', Brightness.dark),
    brightness: brightness,
    child: Align(
      alignment: AlignmentDirectional.topStart,
      // As the inventory gallery stands each one: in a card's column.
      child: SizedBox(
        width: width,
        child: Align(
          alignment: AlignmentDirectional.topStart,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560, maxHeight: 560),
            child: Builder(builder: builder),
          ),
        ),
      ),
    ),
  ),
);

void main() {
  testWidgets('every row answered once, each specimen the row\'s class', (
    tester,
  ) async {
    late BuildContext context;
    await tester.pumpWidget(
      _host((c) {
        context = c;
        return const SizedBox();
      }),
    );
    expect(expressiveInventory.problems, isEmpty);
    expressiveInventory.verify();
    // 83 rows live; six are not Material components and say what Material
    // uses instead (the CHANGELOG's list), each with its reason.
    expect(
      expressiveInventory.presentCount + expressiveInventory.absentCount,
      expressiveInventory.entries.length,
    );
    expect(expressiveInventory.absentCount, 6);
    for (final entry in expressiveInventory.entries) {
      expect(entry.isPresent || (entry.absentReason ?? '').isNotEmpty, isTrue);
    }
    // The kit names no classes; this look still gives each row its stem:
    // the row's class, or one of Flutter's kinds of it (the Button row's
    // specimen is an ExpressiveFilledButton, an ExpressiveButton).
    for (final entry in expressiveInventory.entries.where((e) => e.isPresent)) {
      final name = entry.builder!(context).runtimeType
          .toString()
          .split('<')
          .first;
      expect(
        name == 'Expressive${entry.row}' ||
            (name.startsWith('Expressive') && name.endsWith(entry.row)),
        isTrue,
        reason: '${entry.row}: $name',
      );
    }
  });

  for (final (width, brightness) in <(double, Brightness)>[
    (390, Brightness.light),
    (1280, Brightness.dark),
  ]) {
    testWidgets('every specimen builds at ${width.toInt()}dp, '
        '${brightness.name}', (tester) async {
      final faults = <String>[];
      for (final entry in expressiveInventory.entries.where(
        (e) => e.isPresent,
      )) {
        final before = FlutterError.onError;
        FlutterError.onError = (details) =>
            faults.add('${entry.row}: ${details.exceptionAsString()}');
        await tester.pumpWidget(
          _host(entry.builder!, brightness: brightness, width: width),
        );
        await tester.pump(const Duration(seconds: 1));
        FlutterError.onError = before;
        // A fresh tree for the next row: its timers and controllers go.
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 2));
      }
      expect(faults, isEmpty);
    });
  }

  testWidgets('the gallery heads each group with what it carries', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: ExpressiveHost(
          light: ExpressiveThemeData.preset('baseline', Brightness.light),
          brightness: Brightness.light,
          child: const ExpressiveInventoryGallery(),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    // Kbd is the Actions row Material has no part for.
    expect(find.text('Actions · 7 of 8'), findsOneWidget);
    expect(find.text('Button (filled/outlined/text/danger)'), findsOneWidget);
    expect(find.text('ExpressiveButton'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));
  });
}

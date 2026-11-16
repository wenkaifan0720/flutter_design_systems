// Brutal in ui_core's shared inventory (DesignInventory): every row answered once, none left out, and every live
// specimen building and laying out on a phone and a desk, by day and by night, right to left, and at 200% text on a
// phone, with nothing thrown.
// ignore_for_file: avoid_relative_lib_imports
import 'package:brutal_ui/brutal_parts.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import '../example/lib/kit_gallery/kit.dart';

/// [builder]'s specimen on a page's column in the look's app.
Widget _host(
  WidgetBuilder builder, {
  required Brightness brightness,
  required TextDirection direction,
  required double textScale,
}) => kitApp(
  brightness: brightness,
  home: Builder(
    builder: (context) => Directionality(
      textDirection: direction,
      child: MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: ColoredBox(
          color: context.brutalTheme.colors.paper,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(BrutalSpacing.regular),
            child: Align(
              alignment: AlignmentDirectional.topStart,
              child: Builder(builder: builder),
            ),
          ),
        ),
      ),
    ),
  ),
);

void main() {
  test('every row is answered with a live specimen', () {
    final inventory = BrutalInventory.registry;
    inventory.verify();
    expect(inventory.absentCount, 0);
    expect(inventory.presentCount, DesignInventoryRow.all.length);
  });

  const cases = [
    (name: 'phone by day', width: 390.0, dark: false, rtl: false, scale: 1.0),
    (name: 'desk by night', width: 1440.0, dark: true, rtl: false, scale: 1.0),
    (
      name: 'phone right to left',
      width: 390.0,
      dark: false,
      rtl: true,
      scale: 1.0,
    ),
    (
      name: 'phone at 200% text',
      width: 390.0,
      dark: false,
      rtl: false,
      scale: 2.0,
    ),
  ];
  for (final entry in BrutalInventory.registry.entries) {
    for (final c in cases) {
      testWidgets('${entry.row}, ${c.name}', (tester) async {
        tester.view.physicalSize = Size(c.width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          _host(
            entry.builder!,
            brightness: c.dark ? Brightness.dark : Brightness.light,
            direction: c.rtl ? TextDirection.rtl : TextDirection.ltr,
            textScale: c.scale,
          ),
        );
        // A skeleton breathes and a spinner turns for ever: a second lays
        // everything out without waiting for them to settle.
        await tester.pump(const Duration(seconds: 1));
        expect(tester.takeException(), isNull);
      });
    }
  }
}

// The inventory (looks/INVENTORY.md): Fluent 2 answers every one of the shared rows, once: with a live specimen that is
// the row's own class (`Fluent2<Stem>`), or, for a part Fluent never draws and its laws would not invent, absent with
// the reason and what stands in its place; and the gallery that lists them lays every specimen out, at a phone's width and
// a desktop's, in light and dark.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluent2_ui/fluent2_ui.dart';
import 'package:fluent2_ui/fluent2_host.dart';

Widget _app(Widget child, {Brightness brightness = Brightness.light}) =>
    MaterialApp(
      builder: (_, home) => Fluent2Host(brightness: brightness, child: home!),
      home: child,
    );

/// The rows Fluent 2 leaves out (DECISIONS K53): each says why and what stands in.
const _absent = {
  'ButtonGroup',
  'ToggleGroup',
  'InputOtp',
  'MenuBar',
  'Command',
  'HoverCard',
  'Meter',
};

void main() {
  setUp(
    () =>
        TestWidgetsFlutterBinding.ensureInitialized()
            .platformDispatcher
            .accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(
          disableAnimations: true,
        ),
  );
  tearDown(
    () => TestWidgetsFlutterBinding.ensureInitialized().platformDispatcher
        .clearAccessibilityFeaturesTestValue(),
  );

  test('every row is answered once, live or absent with a reason', () {
    expect(fluent2Inventory.problems, isEmpty);
    expect(fluent2Inventory.entries.length, DesignInventoryRow.all.length);
    expect({
      for (final e in fluent2Inventory.entries)
        if (e.builder == null) e.row,
    }, _absent);
    fluent2Inventory.verify();
  });

  testWidgets("every live specimen is its row's own class", (tester) async {
    late BuildContext host;
    await tester.pumpWidget(
      _app(
        Builder(
          builder: (context) {
            host = context;
            return const SizedBox();
          },
        ),
      ),
    );
    // Fluent's own component names stand where Fluent names the part (K49).
    const fluentNames = {
      'SearchField': 'SearchBox',
      'NumberField': 'SpinButton',
      'Chip': 'InteractionTag',
      'TabBar': 'TabList',
      'ListTile': 'ListItem',
      'Disclosure': 'Accordion',
      'DataTable': 'DataGrid',
      'TreeView': 'Tree',
      'Media': 'Image',
      'SnackBar': 'Toast',
      'Banner': 'MessageBar',
      'LinearProgressIndicator': 'ProgressBar',
      'CircularProgressIndicator': 'Spinner',
    };
    for (final entry in fluent2Inventory.entries) {
      if (entry.builder == null) continue;
      final specimen = entry.builder!(host);
      expect(
        specimen.runtimeType.toString().split('<').first,
        'Fluent2${fluentNames[entry.row] ?? entry.row}',
        reason: entry.row,
      );
    }
  });

  for (final width in const [390.0, 1440.0]) {
    for (final brightness in Brightness.values) {
      testWidgets(
        'the gallery lays out every row at $width ${brightness.name}',
        (tester) async {
          tester.view.physicalSize = Size(width, 1000);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          await tester.pumpWidget(
            _app(
              const Fluent2Scaffold(
                scroll: false,
                topBar: Fluent2AppBar(title: 'Components'),
                body: Fluent2InventoryGallery(),
              ),
              brightness: brightness,
            ),
          );
          await tester.pump();
          expect(tester.takeException(), isNull);
          final list = find
              .descendant(
                of: find.byType(Fluent2InventoryGallery),
                matching: find.byType(Scrollable),
              )
              .first;
          for (final row in DesignInventoryRow.all) {
            await tester.scrollUntilVisible(
              find.byKey(ValueKey<String>('inventory-${row.id}')),
              240,
              scrollable: list,
            );
            await tester.pump();
            expect(tester.takeException(), isNull, reason: row.id);
          }
        },
      );
    }
  }
}

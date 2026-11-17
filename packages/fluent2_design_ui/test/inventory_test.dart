// The inventory (looks/INVENTORY.md): Fluent 2 answers every one of the shared rows, once: with a live specimen that is
// the row's own class (`Fluent2<Stem>`), or, for a part Fluent never draws and its laws would not invent, absent with
// the reason and what stands in its place; and the gallery that lists them lays every specimen out, at a phone's width and
// a desktop's, in light and dark.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluent2_design_ui/fluent2_design_ui.dart';
import 'package:fluent2_design_ui/fluent2_design_host.dart';

import 'tiers.dart';

Widget _app(Widget child, {Brightness brightness = Brightness.light}) =>
    MaterialApp(
      builder: (_, home) => Fluent2Host(brightness: brightness, child: home!),
      home: child,
    );

/// The rows Fluent 2 leaves out (DECISIONS K53): each says why and what stands in.
const _absent = {'InputOtp', 'MenuBar', 'Command'};

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
      'ButtonGroup': 'ToolbarGroup',
      'ToggleGroup': 'ToolbarToggleGroup',
      // Fluent's hover card is its Popover opened on hover; its meter is
      // WinUI's ring with a value.
      'HoverCard': 'Popover',
      'Meter': 'Spinner',
    };
    // A specimen that owns its controller stands in a holder, as an app's
    // page would hold it; its class is the first of Fluent's it builds.
    final held = <String, Widget>{};
    for (final entry in fluent2Inventory.entries) {
      if (entry.builder == null) continue;
      final specimen = entry.builder!(host);
      final name = specimen.runtimeType.toString().split('<').first;
      if (name == '_Owning') {
        held[entry.row] = specimen;
        continue;
      }
      expect(
        name,
        'Fluent2${fluentNames[entry.row] ?? entry.row}',
        reason: entry.row,
      );
    }
    expect(held.keys, {
      'DateRangePicker',
      'ColorPicker',
      'DataTable',
      'ScrollArea',
    });
    for (final MapEntry(key: row, value: specimen) in held.entries) {
      await tester.pumpWidget(
        _app(KeyedSubtree(key: const Key('held'), child: specimen)),
      );
      String? first;
      void visit(Element e) {
        if (first != null) return;
        final name = e.widget.runtimeType.toString().split('<').first;
        if (name.startsWith('Fluent2')) {
          first = name;
        } else {
          e.visitChildElements(visit);
        }
      }

      tester.element(find.byKey(const Key('held'))).visitChildElements(visit);
      expect(first, 'Fluent2${fluentNames[row] ?? row}', reason: row);
    }
  });

  // Every run lays the gallery out on a phone by day and on a desk by night; the sweep, the other two.
  for (final (at, width) in const [390.0, 1440.0].indexed) {
    for (final brightness in Brightness.values) {
      testWidgets(
        'the gallery lays out every row at $width ${brightness.name}',
        tags: sweepUnless((at == 0) == (brightness == Brightness.light)),
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

// Every inventory entry has a live example or explains the available alternative.
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluent2_design_ui/fluent2_design_ui.dart';
import 'package:fluent2_design_ui/fluent2_design_host.dart';

import 'tiers.dart';

Widget _app(Widget child, {Brightness brightness = Brightness.light}) =>
    MaterialApp(
      builder: (_, home) => Fluent2Host(brightness: brightness, child: home!),
      home: child,
    );

/// Components without a Fluent equivalent and their alternatives.
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
    // Some inventory names have a more specific Fluent counterpart.
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
      'ToggleGroup',
      'RadioGroup',
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

  for (final (row, initial, next) in const [
    ('ToggleGroup', 'List', 'Tiles'),
    ('RadioGroup', 'Medium', 'Large'),
  ]) {
    testWidgets('the $row example keeps its keyboard selection', (
      tester,
    ) async {
      final entry = fluent2Inventory.entries.singleWhere(
        (entry) => entry.row == row,
      );
      await tester.pumpWidget(_app(Builder(builder: entry.builder!)));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(
        tester.getSemantics(find.bySemanticsLabel(initial)),
        isSemantics(isFocused: true, isChecked: true, isButton: false),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(
        tester.getSemantics(find.bySemanticsLabel(next)),
        isSemantics(isFocused: true, isChecked: true, isButton: false),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel(initial)),
        isSemantics(isChecked: false),
      );
    });
  }

  // Exercise every size and appearance, including the larger sweep.
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

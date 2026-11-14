// Every part keeps its own height: given a box with room to spare (a tile
// with a ceiling, a dialog's body), no inventory specimen fills it. The
// self-review's first round found the number field's well stretched to the
// inventory tile's 480 ceiling, an Align with no height factor.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_host.dart';

const _ceiling = 480.0;

// Parts that are a page's frame or a region of one: they take the room they
// are given, as a Scaffold does, and the inventory tile's ceiling is their
// size there.
const _fillsByNature = {
  'NavigationRail': 'runs the height of the page',
  'NavigationDrawer': 'runs the height of the page',
  'Scaffold': 'is the page',
  'ScrollArea': 'scrolls within the room it is given',
  'Resizable': 'splits the room it is given',
  'Sheet': 'is a page raised as a sheet',
  'StatusView': 'centres its words in the page it stands for',
};

void main() {
  test('each part named as filling its room is in the inventory', () {
    final rows = {for (final e in frostedInventory.entries) e.row};
    expect(_fillsByNature.keys.where((k) => !rows.contains(k)), isEmpty);
  });

  for (final entry in frostedInventory.entries) {
    final build = entry.builder;
    if (build == null || _fillsByNature.containsKey(entry.row)) continue;
    testWidgets('${entry.row} keeps its own height under a ceiling', (t) async {
      t.view.physicalSize = const Size(390, 1200);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      const key = ValueKey('specimen');
      await t.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          builder: (context, page) =>
              FrostedHost(brightness: Brightness.light, child: page!),
          home: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // As the inventory's tile holds a specimen.
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: _ceiling),
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    heightFactor: 1,
                    child: KeyedSubtree(
                      key: key,
                      child: Builder(builder: build),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await t.pump(const Duration(seconds: 1));
      t.takeException();
      expect(
        t.getSize(find.byKey(key)).height,
        lessThan(_ceiling - 1),
        reason: '${entry.row} filled the room it was given',
      );
    });
  }
}

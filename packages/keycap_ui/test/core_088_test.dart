// What ui_core 0.8.8 puts right for Keycap: a slid row is cut at the row's
// start, so its title doesn't show on the well's wall, and a phone's date
// sheet covers the page's foot (the dimmed Save key showed under it).
import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keycap_ui/keycap_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

Future<void> _phone(WidgetTester tester, Widget page) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (context, child) =>
          KeycapHost(brightness: Brightness.light, child: child!),
      home: page,
    ),
  );
  await tester.pumpAndSettle();
}

// What of [f] is in sight: its box cut by every clip above it up to [top]
// (the row's own clips, not the group's).
Rect _visible(WidgetTester tester, Finder f, Finder top) {
  final stop = tester.renderObject(top);
  final box = tester.renderObject<RenderBox>(f);
  var rect = MatrixUtils.transformRect(
    box.getTransformTo(null),
    Offset.zero & box.size,
  );
  for (
    RenderObject? o = box.parent;
    o != null && o != stop.parent;
    o = o.parent
  ) {
    if (o is RenderClipRect && o.clipBehavior != Clip.none) {
      final cut = o.clipper?.getClip(o.size) ?? Offset.zero & o.size;
      rect = rect.intersect(
        MatrixUtils.transformRect(o.getTransformTo(null), cut),
      );
    } else if (o is RenderClipRRect && o.clipBehavior != Clip.none) {
      rect = rect.intersect(
        MatrixUtils.transformRect(o.getTransformTo(null), Offset.zero & o.size),
      );
    }
  }
  return rect;
}

void main() {
  setUpAll(keycapLoadFonts);

  testWidgets("a slid row's title is cut at the row's start", (tester) async {
    const title = 'Jonathan Strange & Mr Norrell';
    await _phone(
      tester,
      KeycapScreen(
        body: KeycapListGroup(
          children: [
            KeycapSwipeActions(
              key: const ValueKey('row'),
              endActions: [
                RawSwipeAction(
                  label: 'Delete',
                  destructive: true,
                  onPressed: () {},
                ),
              ],
              child: KeycapListTile(title: title, onTap: () {}),
            ),
          ],
        ),
      ),
    );
    final row = tester.getRect(find.byKey(const ValueKey('row')));
    await tester.drag(find.text(title), const Offset(-120, 0));
    await tester.pumpAndSettle();
    // Open: the title has slid past the row's start.
    expect(tester.getRect(find.text(title)).left, lessThan(row.left));
    expect(
      _visible(
        tester,
        find.text(title),
        find.byKey(const ValueKey('row')),
      ).left,
      greaterThanOrEqualTo(row.left - 0.5),
    );
  });

  testWidgets("a phone's date sheet covers the page's foot", (tester) async {
    await _phone(
      tester,
      KeycapScaffold.branches(
        header: const Text('Shelf'),
        destinations: const [
          KeycapDestination(icon: LucideIcons.bookOpen, label: 'Books'),
          KeycapDestination(icon: LucideIcons.plus, label: 'Add a book'),
        ],
        selectedIndex: 1,
        onDestinationSelected: (_) {},
        branches: [(context) => const SizedBox(), (context) => _AddPage()],
      ),
    );
    final save = tester.getRect(find.byKey(const ValueKey('save')));
    await tester.tap(find.byType(KeycapDatePicker));
    await tester.pumpAndSettle();
    final sheet = tester.getRect(find.byType(KeycapSheet).last);
    // It covers the page's foot: past the Save key's bottom, down to the bar.
    expect(sheet.bottom, greaterThan(save.bottom));
  });
}

class _AddPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) => KeycapScreen(
    topBar: const KeycapAppBar(title: 'Add a book'),
    footer: KeycapButton.accent(
      key: const ValueKey('save'),
      onPressed: () {},
      child: const Text('Save'),
    ),
    body: KeycapDatePicker(
      labelText: 'Started',
      value: null,
      firstDate: DateTime(2000),
      lastDate: DateTime(2030),
      onChanged: (_) {},
    ),
  );
}

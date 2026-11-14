// Codes read left to right in any language (self-review round 3): under a right-to-left page an input group's parts
// keep the order of the value they make (https:// before .com), a profile's address and phone keep theirs, and the
// inventory stands at the scaffold's gutter alone.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:frosted_ui/frosted_host.dart';

Future<void> _pump(WidgetTester t, Widget page, {bool rtl = true}) async {
  t.view.physicalSize = const Size(390, 844);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (context, child) => Directionality(
        textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
        child: FrostedHost(child: child!),
      ),
      home: page,
    ),
  );
  await t.pumpAndSettle();
  expect(t.takeException(), isNull);
}

void main() {
  testWidgets('right to left an input group keeps https:// before .com', (
    t,
  ) async {
    await _pump(
      t,
      Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            FrostedInputGroup(
              label: 'Website',
              prefix: const Text('https://'),
              suffix: const Text('.com'),
              value: 'example',
              onChanged: (_) {},
            ),
          ],
        ),
      ),
    );
    final prefix = t.getRect(find.text('https://'));
    final suffix = t.getRect(find.text('.com'));
    expect(prefix.right, lessThan(suffix.left));
    final label = t.getRect(find.text('Website'));
    expect(label.right, closeTo(390 - 16, 1));
  });

  testWidgets('right to left a profile keeps its phone left to right', (
    t,
  ) async {
    await _pump(
      t,
      const Center(
        child: FrostedProfileHero(
          initials: 'MH',
          name: 'Maren Holt',
          contact: ['maren.holt@example.com', '+1 (415) 555-0142'],
        ),
      ),
    );
    final lines = t.widget<Text>(find.textContaining('555-0142'));
    expect(lines.textDirection, TextDirection.ltr);
  });

  testWidgets('right to left a fan runs from the start, with its rows', (
    t,
  ) async {
    Widget fan() => Builder(
      builder: (context) {
        final hues = context.frostedTheme.hues;
        return Padding(
          padding: const EdgeInsets.all(16),
          child: FrostedFan(
            source: hues.cyan,
            label: 'Scheduled, from Everyday',
            flows: [
              FrostedFanEnd(
                amount: 400,
                hue: hues.azure,
                title: 'Emergency fund',
              ),
            ],
          ),
        );
      },
    );
    double flipOf() => t
        .widget<Transform>(
          find
              .descendant(
                of: find.byType(FrostedFan),
                matching: find.byType(Transform),
              )
              .first,
        )
        .transform
        .storage[0];
    await _pump(t, fan());
    expect(flipOf(), -1);
    await _pump(t, fan(), rtl: false);
    expect(flipOf(), 1);
  });

  testWidgets('the inventory stands at the gutter, not twice it', (t) async {
    await _pump(
      t,
      const FrostedScaffold(
        scroll: false,
        topBar: FrostedAppBar(title: 'Inventory'),
        body: FrostedInventoryGallery(),
      ),
      rtl: false,
    );
    final list = t.getRect(find.byType(FrostedInventoryGallery));
    final first = t.getRect(find.byType(Scrollable).last);
    expect(list.left, closeTo(FrostedChromeMetrics.gutter, 0.5));
    expect(first.left, closeTo(list.left, 0.5));
  });
}

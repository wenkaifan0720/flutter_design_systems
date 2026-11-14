// ui_core's shared world checks (world_checks.dart, the same in every look) on a screen of the everyday parts, by day
// and by night: Flutter's four guidelines (48 and 44 px targets, labelled targets, text contrast), the screen mirrored
// right to left, and nothing overflowing at 200% text. The gallery's own tests run the guidelines on every page and
// preset (gallery_guidelines_test), the mirror per part (rtl_test) and 200% text per page (gallery_text_scale_test).
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:frosted_ui/frosted_host.dart';

import 'world_checks.dart';

void _drop(Object? _) {}

Widget _screen(
  Brightness brightness, {
  TextDirection direction = TextDirection.ltr,
}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  builder: (context, page) => Directionality(
    textDirection: direction,
    child: FrostedHost(brightness: brightness, child: page!),
  ),
  home: SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        FrostedTabBar(tabs: const ['Spending', 'Income'], onChanged: _drop),
        FrostedButton('Pay', icon: FrostedGlyphs.creditCard, onPressed: () {}),
        FrostedSegmentedButton<int>(
          label: 'Period',
          value: 0,
          onChanged: _drop,
          segments: const [
            FrostedButtonSegment(0, 'Week'),
            FrostedButtonSegment(1, 'Month'),
          ],
        ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: FrostedChip('Vegan', onPressed: () {}),
        ),
        FrostedTextField(label: 'Email', onChanged: _drop),
        FrostedSwitchRow(
          label: 'Weekly summary',
          value: true,
          onChanged: _drop,
        ),
        FrostedCheckRow(label: 'Agree', value: true, onChanged: _drop),
        FrostedListTile(
          title: 'Rent',
          leading: const Icon(FrostedGlyphs.house),
          onPressed: () {},
        ),
        FrostedSlider(label: 'Volume', value: .4, onChanged: _drop),
      ],
    ),
  ),
);

void main() {
  setUp(
    () =>
        TestWidgetsFlutterBinding
            .instance
            .platformDispatcher
            .accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(
          disableAnimations: true,
        ),
  );
  tearDown(
    () => TestWidgetsFlutterBinding.instance.platformDispatcher
        .clearAccessibilityFeaturesTestValue(),
  );

  for (final brightness in Brightness.values) {
    final when = brightness == Brightness.light ? 'by day' : 'by night';
    // The targets are laid out; the words' contrast is read from drawn
    // pixels, which depend on the rasterizer as a golden does.
    testWidgets('the everyday parts meet the target guidelines $when', (
      t,
    ) async {
      t.view.physicalSize = const Size(390, 1200);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      await t.pumpWidget(_screen(brightness));
      await t.pumpAndSettle();
      final semantics = t.ensureSemantics();
      await expectLater(t, meetsGuideline(androidTapTargetGuideline));
      await expectLater(t, meetsGuideline(iOSTapTargetGuideline));
      await expectLater(t, meetsGuideline(labeledTapTargetGuideline));
      semantics.dispose();
    });

    testWidgets('the everyday parts meet the guidelines $when', (t) async {
      t.view.physicalSize = const Size(390, 1200);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      await t.pumpWidget(_screen(brightness));
      await t.pumpAndSettle();
      await expectMeetsGuidelines(t);
    }, tags: const ['goldens']);

    testWidgets('the everyday parts mirror right to left $when', (t) async {
      t.view.physicalSize = const Size(390, 1200);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      await expectMirrorsInRtl(
        t,
        (direction) => _screen(brightness, direction: direction),
        parts: [
          find.text('Spending'),
          find.byIcon(FrostedGlyphs.creditCard),
          find.text('Week'),
          find.text('Vegan'),
          find.text('Weekly summary'),
          find.text('Agree'),
          find.byIcon(FrostedGlyphs.house),
        ],
      );
    });

    testWidgets('the everyday parts at 200% text $when', (t) async {
      t.view.physicalSize = const Size(390, 1200);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      await expectNoOverflowAtTextScale(t, _screen(brightness));
    });
  }
}

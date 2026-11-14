// Right to left: each everyday part laid out in a right-to-left reading mirrors its left-to-right self, by ui_core's
// shared check (world_checks.dart, the same in every look): a probe (the part's glyph, its first word) stands as far
// from the right as it stood from the left, at the same top and size. The slider runs from the start side, figures
// keep their sign in front, and the glyphs that point a way turn round.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:frosted_ui/frosted_host.dart';

import 'world_checks.dart';

Widget _app(TextDirection direction, Widget part) => MaterialApp(
  debugShowCheckedModeBanner: false,
  builder: (context, page) => Directionality(
    textDirection: direction,
    child: FrostedHost(child: page!),
  ),
  home: Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [part],
    ),
  ),
);

void _phone(WidgetTester t) {
  t.view.physicalSize = const Size(390, 844);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
}

Future<Rect> _probe(
  WidgetTester t,
  TextDirection direction,
  Widget part,
  Finder probe,
) async {
  _phone(t);
  await t.pumpWidget(_app(direction, part));
  await t.pumpAndSettle();
  expect(t.takeException(), isNull);
  return t.getRect(probe.first);
}

void _mirrors(String name, Widget part, Finder probe) {
  testWidgets('$name mirrors right to left', (t) async {
    _phone(t);
    await expectMirrorsInRtl(t, (d) => _app(d, part), parts: [probe.first]);
  });
}

void _drop(Object? _) {}

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
  const tabs = [
    FrostedNavItem(FrostedGlyphs.house, 'Home'),
    FrostedNavItem(FrostedGlyphs.receipt, 'Activity'),
    FrostedNavItem(FrostedGlyphs.person, 'Profile'),
  ];

  _mirrors(
    'a button with a glyph',
    Center(
      child: FrostedButton('Add', icon: FrostedGlyphs.add, onPressed: () {}),
    ),
    find.byIcon(FrostedGlyphs.add),
  );
  _mirrors(
    'a chip with a glyph',
    Align(
      alignment: AlignmentDirectional.centerStart,
      child: FrostedChip('Vegan', icon: FrostedGlyphs.check, onPressed: () {}),
    ),
    find.byIcon(FrostedGlyphs.check),
  );
  _mirrors(
    'a segmented button',
    FrostedSegmentedButton<int>(
      segments: const [
        FrostedButtonSegment(0, 'Light'),
        FrostedButtonSegment(1, 'Dark'),
      ],
      value: 0,
      onChanged: _drop,
      label: 'Theme',
    ),
    find.text('Light'),
  );
  _mirrors(
    'filter chips',
    FrostedFilterChipGroup<int>(
      options: const [
        FrostedFilterOption(0, 'All'),
        FrostedFilterOption(1, 'Income'),
      ],
      value: 0,
      onChanged: _drop,
    ),
    find.text('All'),
  );
  _mirrors(
    'a switch row',
    FrostedSwitchRow(label: 'Weekly summary', value: true, onChanged: _drop),
    find.text('Weekly summary'),
  );
  _mirrors(
    'a check row',
    FrostedCheckRow(label: 'Agree', value: true, onChanged: _drop),
    find.text('Agree'),
  );
  _mirrors(
    'a radio group',
    FrostedRadioGroup<String>(
      label: 'Plan',
      value: 'free',
      onChanged: _drop,
      options: const [
        FrostedRadio('free', 'Free'),
        FrostedRadio('plus', 'Plus'),
      ],
    ),
    find.text('Free'),
  );
  _mirrors(
    'a field with a leading glyph',
    FrostedTextField(
      label: 'Email',
      onChanged: _drop,
      leading: const Icon(FrostedGlyphs.email),
    ),
    find.byIcon(FrostedGlyphs.email),
  );
  _mirrors(
    'a list row',
    FrostedListTile(
      title: 'Rent',
      leading: const Icon(FrostedGlyphs.house),
      onPressed: () {},
    ),
    find.byIcon(FrostedGlyphs.house),
  );
  _mirrors(
    'a tab bar',
    FrostedTabBar(
      tabs: const ['Spending', 'Income', 'Transfers'],
      onChanged: _drop,
    ),
    find.text('Spending'),
  );
  _mirrors(
    'a navigation bar',
    FrostedNavigationBar(items: tabs, onDestinationSelected: _drop),
    find.text('Home'),
  );
  _mirrors(
    'a dialog',
    FrostedDialog(
      title: 'Delete the card?',
      confirmLabel: 'Delete',
      onConfirm: () {},
      onCancel: () {},
    ),
    find.text('Delete'),
  );

  for (final direction in TextDirection.values) {
    testWidgets('a slider runs from the start side (${direction.name})', (
      t,
    ) async {
      var value = .5;
      final rect = await _probe(
        t,
        direction,
        StatefulBuilder(
          builder: (context, set) => FrostedSlider(
            label: 'Volume',
            value: value,
            onChanged: (v) => set(() => value = v),
          ),
        ),
        find.byType(FrostedSlider),
      );
      // A press near the start side sets a low value, whichever side that is.
      final start = direction == TextDirection.ltr
          ? rect.left + rect.width * .1
          : rect.right - rect.width * .1;
      await t.tapAt(Offset(start, rect.center.dy));
      await t.pumpAndSettle();
      expect(value, lessThan(.3), reason: direction.name);
    });
  }

  testWidgets('figures read left to right, right to left too', (t) async {
    // The sign and the currency stay in front of the dollars.
    final sign = await _probe(
      t,
      TextDirection.rtl,
      const Center(child: FrostedMoney(-1326.44)),
      find.text('${FrostedFormat.minus}\$'),
    );
    final dollars = t.getRect(find.text('1,326'));
    expect(sign.right, lessThanOrEqualTo(dollars.left + 1));
  });

  // Figures, codes and the things printed on a card keep their order on a
  // right-to-left page (the self-review's shots read "K + ⌘", "500.00 $",
  // "+99", the card's groups backwards and "AM 30 : 9").
  testWidgets('keycaps keep their order right to left', (t) async {
    await _probe(
      t,
      TextDirection.rtl,
      Center(
        child: FrostedKbd.combo(const ['⌘', 'K'], semanticsLabel: 'Command K'),
      ),
      // ⌘ is drawn as a glyph; the + between the caps stands before K.
      find.text('+'),
    );
    expect(
      t.getRect(find.text('+')).left,
      lessThan(t.getRect(find.text('K')).left),
    );
  });

  testWidgets('an amount well keeps its sign before the figure right to left', (
    t,
  ) async {
    await _probe(
      t,
      TextDirection.rtl,
      FrostedAmountField(label: 'Amount', value: '500.00', onChanged: _drop),
      find.text('\$'),
    );
    expect(
      t.getRect(find.text('\$')).right,
      lessThanOrEqualTo(t.getRect(find.byType(EditableText)).left + 1),
    );
  });

  testWidgets('a card number keeps its groups in order right to left', (
    t,
  ) async {
    await _probe(
      t,
      TextDirection.rtl,
      const FrostedCardNumber(
        number: '4242424242427730',
        expires: '09/29',
        cvc: '317',
        name: 'Maren Holt',
      ),
      find.text('7730'),
    );
    expect(
      t.getRect(find.text('4242').first).left,
      lessThan(t.getRect(find.text('7730')).left),
    );
  });

  testWidgets('a badge count and a clock keep their order right to left', (
    t,
  ) async {
    await _probe(
      t,
      TextDirection.rtl,
      Column(
        children: [
          const Center(child: FrostedBadge(120)),
          FrostedTimePicker(
            value: const FrostedTime(hour: 9, minute: 30),
            onChanged: _drop,
          ),
        ],
      ),
      find.text('99+'),
    );
    expect(t.widget<Text>(find.text('99+')).textDirection, TextDirection.ltr);
    expect(
      t.getRect(find.text('9').first).left,
      lessThan(t.getRect(find.text('30').first).left),
    );
  });

  testWidgets('pagination ends in a pair of chevrons', (t) async {
    await _probe(
      t,
      TextDirection.rtl,
      FrostedPagination(pageCount: 3, selectedIndex: 1, onChanged: _drop),
      find.byIcon(FrostedGlyphs.chevronLeft),
    );
    expect(find.byIcon(FrostedGlyphs.chevronLeft), findsOneWidget);
    expect(find.byIcon(FrostedGlyphs.forward), findsOneWidget);
  });

  testWidgets("a move's arrow points from its source to its destination", (
    t,
  ) async {
    await _probe(
      t,
      TextDirection.rtl,
      Builder(
        builder: (context) => FrostedRoute(
          fromName: 'Everyday',
          fromIcon: FrostedGlyphs.wallet,
          fromHue: context.frostedTheme.hues.cyan,
          toName: 'Savings',
          toIcon: FrostedGlyphs.landmark,
          toHue: context.frostedTheme.hues.seafoam,
        ),
      ),
      find.byIcon(FrostedGlyphs.arrowRight),
    );
    // The arrow mirrors itself; a second flip turned it back.
    final flip = t.widget<Transform>(
      find
          .ancestor(
            of: find.byIcon(FrostedGlyphs.arrowRight),
            matching: find.byType(Transform),
          )
          .first,
    );
    expect(flip.transform.isIdentity(), isTrue);
  });

  test('the glyphs that point a way turn round right to left', () {
    for (final glyph in [
      FrostedGlyphs.back,
      FrostedGlyphs.forward,
      FrostedGlyphs.chevronLeft,
      FrostedGlyphs.arrowRight,
    ]) {
      expect(glyph.matchTextDirection, isTrue, reason: '$glyph');
    }
  });
}

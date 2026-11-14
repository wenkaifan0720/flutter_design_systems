// Frosted's inputs, one test each: the page owns every value through `value`
// and `onChanged`, and a null callback leaves the control inert.
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:frosted_ui/frosted_host.dart';
import 'package:frosted_ui/src/frosted/internal/well.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Pumps [child] across a phone's page, the gutter (16) in from each side,
/// in Frosted's light; nothing may throw.
Future<void> _pump(WidgetTester t, Widget child, {double gutter = 16}) async {
  t.view.physicalSize = const Size(390, 844);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (BuildContext context, Widget? page) =>
          FrostedHost(child: page!),
      home: Padding(
        padding: EdgeInsets.symmetric(horizontal: gutter),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [child],
        ),
      ),
    ),
  );
  expect(t.takeException(), isNull);
}

/// The node a screen reader lands on for [label].
SemanticsNode _node(WidgetTester t, String label) =>
    t.getSemantics(find.bySemanticsLabel(label));

/// A control that keeps the value its callback hands back, as a page does.
class _Owner<T> extends StatefulWidget {
  const _Owner(this.initial, this.builder, {this.seen});

  final T initial;
  final Widget Function(T value, ValueChanged<T> set) builder;
  final List<T>? seen;

  @override
  State<_Owner<T>> createState() => _OwnerState<T>();
}

class _OwnerState<T> extends State<_Owner<T>> {
  late T _value = widget.initial;

  @override
  Widget build(BuildContext context) => widget.builder(_value, (v) {
    widget.seen?.add(v);
    setState(() => _value = v);
  });
}

const _scopes = [
  FrostedFilterOption('all', 'All', key: ValueKey('search-again')),
  FrostedFilterOption('in', 'Money in'),
  FrostedFilterOption('out', 'Money out'),
];

const _ranges = [
  FrostedButtonSegment('1m', '1M'),
  FrostedButtonSegment('3m', '3M'),
  FrostedButtonSegment('1y', '1Y'),
  FrostedButtonSegment('all', 'All'),
];

const _icons = [
  FrostedIconChoice(LucideIcons.plane, 'Plane'),
  FrostedIconChoice(LucideIcons.shield, 'Shield'),
  FrostedIconChoice(LucideIcons.bike, 'Bike'),
  FrostedIconChoice(LucideIcons.house, 'House'),
  FrostedIconChoice(LucideIcons.car, 'Car'),
  FrostedIconChoice(LucideIcons.gift, 'Gift', key: ValueKey('gift')),
  FrostedIconChoice(LucideIcons.heart, 'Heart'),
];

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

  testWidgets('FrostedSearchLink opens the search; without a tap it is inert', (
    t,
  ) async {
    var opens = 0;
    await _pump(
      t,
      Column(
        children: [
          FrostedSearchLink(hint: 'Search activity', onPressed: () => opens++),
          const FrostedSearchLink(
            hint: 'Search',
            value: 'Blue Fern',
            label: 'Search, Blue Fern typed',
            onPressed: null,
          ),
        ],
      ),
    );
    expect(find.text('Search activity'), findsOneWidget);
    expect(find.text('Blue Fern'), findsOneWidget);
    expect(
      _node(t, 'Search activity'),
      isSemantics(isLink: true, isEnabled: true, hasTapAction: true),
    );
    expect(
      _node(t, 'Search, Blue Fern typed'),
      isSemantics(isEnabled: false, hasTapAction: false, value: 'Blue Fern'),
    );
    expect(t.getSize(find.byType(FrostedSearchLink).first).height, 44);
    await t.tap(find.text('Search activity'));
    await t.tap(find.text('Blue Fern'));
    expect(opens, 1);
  });

  testWidgets('FrostedSearchField hands each edit back and clears to nothing', (
    t,
  ) async {
    final seen = <String>[];
    await _pump(
      t,
      _Owner<String>(
        'Blue Fern',
        (value, set) => FrostedSearchField(
          value: value,
          hint: 'Search activity',
          onChanged: set,
        ),
        seen: seen,
      ),
    );
    expect(find.text('Blue Fern'), findsOneWidget);
    expect(_node(t, 'Search activity'), isSemantics(isTextField: true));
    expect(t.getSize(find.byType(FrostedSearchField)).height, 44);
    await t.enterText(find.byType(TextField), 'Blue');
    await t.pump();
    expect(seen, ['Blue']);
    await t.tap(find.bySemanticsLabel('Clear'));
    await t.pump();
    expect(seen, ['Blue', '']);
    expect(find.bySemanticsLabel('Clear'), findsNothing);
  });

  testWidgets('FrostedSearchField with onClear: the clear is a keyed link that '
      'leads there and leaves the words', (t) async {
    final seen = <String>[];
    var cleared = 0;
    const key = ValueKey('clear-search');
    await _pump(
      t,
      FrostedSearchField(
        value: 'Blue Fern',
        hint: 'Search activity',
        onChanged: seen.add,
        onClear: () => cleared++,
        clearKey: key,
      ),
    );
    expect(
      _node(t, 'Clear'),
      isSemantics(isLink: true, isEnabled: true, hasTapAction: true),
    );
    // The 28 round stands 6 into the pill's inset, 10 from its end.
    final pill = t.getRect(find.byType(FrostedSearchField));
    // The link itself spans the touch target; the round is drawn inside it.
    final clear = t.getRect(
      find
          .descendant(
            of: find.byKey(key),
            matching: find.byWidgetPredicate(
              (w) => w is SizedBox && w.width == 28,
            ),
          )
          .first,
    );
    expect(clear.width, 28);
    expect(pill.right - clear.right, closeTo(10, 1));
    await t.tap(find.byKey(key));
    await t.pump();
    expect(cleared, 1);
    expect(seen, isEmpty);
    expect(find.text('Blue Fern'), findsOneWidget);
  });

  testWidgets(
    'FrostedFilterChipGroup choose one; with no callback none moves',
    (t) async {
      final seen = <String>[];
      await _pump(
        t,
        Column(
          children: [
            _Owner<String>(
              'all',
              (value, set) => FrostedFilterChipGroup(
                options: _scopes,
                value: value,
                onChanged: set,
              ),
              seen: seen,
            ),
            const FrostedFilterChipGroup(
              options: [
                FrostedFilterOption('card', 'Keel Card'),
                FrostedFilterOption('every', 'Everyday'),
              ],
              value: 'every',
              label: 'Accounts',
              onChanged: null,
            ),
          ],
        ),
      );
      expect(_node(t, 'All'), isSemantics(isSelected: true, isEnabled: true));
      expect(_node(t, 'Money in'), isSemantics(isSelected: false));
      expect(t.getSize(find.text('All')).height, lessThanOrEqualTo(32));
      expect(
        t.getSize(find.widgetWithText(FrostedPressable, 'All')).height,
        32,
      );
      await t.tap(find.text('Money in'));
      await t.pump();
      expect(seen, ['in']);
      expect(_node(t, 'Money in'), isSemantics(isSelected: true));
      expect(
        _node(t, 'Everyday'),
        isSemantics(isSelected: true, isEnabled: false),
      );
      await t.tap(find.text('Keel Card'));
      await t.pump();
      expect(seen, ['in']);
      expect(find.bySemanticsLabel('Filters'), findsOneWidget);
      expect(find.bySemanticsLabel('Accounts'), findsOneWidget);
    },
  );

  testWidgets(
    'FrostedFilterChipGroup key a chip by its word; on a phone the row '
    'runs under the gutters, from 1024 wide it stands at its own width',
    (t) async {
      final seen = <String>[];
      Widget chips() => FrostedFilterChipGroup(
        options: _scopes,
        value: 'in',
        onChanged: seen.add,
      );
      await _pump(t, chips());
      await t.tap(find.byKey(const ValueKey('search-again')));
      expect(seen, ['all']);
      final phoneRow = t.getRect(find.byType(SingleChildScrollView));
      expect(phoneRow.left, 0);
      expect(phoneRow.right, 390);
      const wide = Size(FrostedBreakpoints.wide, 900);
      t.view.physicalSize = wide;
      await t.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          builder: (BuildContext context, Widget? page) =>
              FrostedHost(child: page!),
          home: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [chips()],
            ),
          ),
        ),
      );
      expect(t.takeException(), isNull);
      final all = t.getRect(find.byKey(const ValueKey('search-again')));
      final last = t.getRect(
        find.widgetWithText(FrostedPressable, 'Money out'),
      );
      final row = t.getRect(find.byType(FrostedFilterChipGroup<String>));
      expect(all.left, 32);
      expect(row.left, 32);
      expect(row.right, last.right);
      expect(row.width, lessThan(wide.width - 64));
    },
  );

  testWidgets(
    'FrostedSegmentedButton picks one of its words, named as a group; fill '
    "takes the field's width, 36 tall",
    (t) async {
      final seen = <String>[];
      await _pump(
        t,
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Owner<String>(
              '1y',
              (value, set) => FrostedSegmentedButton(
                segments: _ranges,
                value: value,
                label: 'Range',
                onChanged: set,
              ),
              seen: seen,
            ),
            FrostedSegmentedButton(
              segments: const [
                FrostedButtonSegment('today', 'Today'),
                FrostedButtonSegment('tomorrow', 'Tomorrow'),
                FrostedButtonSegment('date', 'Choose a date'),
              ],
              value: 'today',
              label: 'When',
              fill: true,
              onChanged: (_) {},
            ),
          ],
        ),
      );
      expect(find.bySemanticsLabel('Range'), findsOneWidget);
      expect(_node(t, '1Y'), isSemantics(isSelected: true));
      await t.tap(find.text('3M'));
      await t.pump();
      expect(seen, ['3m']);
      expect(_node(t, '3M'), isSemantics(isSelected: true));
      expect(_node(t, '1Y'), isSemantics(isSelected: false));
      final range = t.getSize(
        find
            .descendant(
              of: find.byType(FrostedSegmentedButton<String>).first,
              matching: find.byType(Row),
            )
            .first,
      );
      expect(range.height, 26);
      expect(range.width, lessThan(358 - 6));
      expect(t.getSize(find.widgetWithText(FrostedPressable, '1Y')).height, 26);
      final when = t.getSize(find.byType(FrostedSegmentedButton<String>).last);
      expect(when.width, 358);
      expect(when.height, 42);
      expect(
        t.getSize(find.widgetWithText(FrostedPressable, 'Today')).height,
        36,
      );
    },
  );

  testWidgets(
    'FrostedSegmentedButton fill shares the pill by its words: three unequal '
    'labels in a 358 field each keep their whole word, 36 tall, the slack '
    'shared equally; words too wide for it all narrow in proportion',
    (t) async {
      Widget pill(List<String> labels) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FrostedSegmentedButton(
            segments: [for (final l in labels) FrostedButtonSegment(l, l)],
            value: labels.first,
            label: 'When',
            fill: true,
            labelled: true,
            onChanged: (_) {},
          ),
        ],
      );
      // The test font draws every glyph 14 wide at 14: Now 42, Later 70,
      // Pick a day 140; with the 10 inset either side, 62, 90 and 160 of
      // their own. The pill's 358 less its 3 inset either side and the two 2
      // gaps leaves 348: 36 of slack, 12 to each.
      const fitting = ['Now', 'Later', 'Pick a day'];
      await _pump(t, pill(fitting));
      final widths = <double>[];
      for (final label in fitting) {
        final segment = t.getSize(find.widgetWithText(FrostedPressable, label));
        final word = t.renderObject<RenderParagraph>(find.text(label));
        expect(
          word.size.width,
          moreOrLessEquals(word.textSize.width, epsilon: 0.1),
          reason: '$label is drawn whole',
        );
        expect(segment.height, 36, reason: label);
        widths.add(segment.width);
      }
      expect(widths[0], moreOrLessEquals(74, epsilon: 0.1));
      expect(widths[1], moreOrLessEquals(102, epsilon: 0.1));
      expect(widths[2], moreOrLessEquals(172, epsilon: 0.1));
      expect(t.getSize(find.byType(FrostedSegmentedButton<String>)).width, 358);
      // Today, Tomorrow and Choose a date are 90, 132 and 202 of their own in
      // this font, 424 for the 348: all narrow in proportion, none to nothing.
      const wide = ['Today', 'Tomorrow', 'Choose a date'];
      await _pump(t, pill(wide));
      final narrowed = [
        for (final l in wide)
          t.getSize(find.widgetWithText(FrostedPressable, l)).width,
      ];
      expect(
        narrowed.fold(0.0, (a, b) => a + b),
        moreOrLessEquals(348, epsilon: 0.1),
      );
      expect(
        narrowed[1] / narrowed[0],
        moreOrLessEquals(132 / 90, epsilon: 0.01),
      );
      expect(
        narrowed[2] / narrowed[0],
        moreOrLessEquals(202 / 90, epsilon: 0.01),
      );
      expect(
        t.getSize(find.widgetWithText(FrostedPressable, 'Today')).height,
        36,
      );
    },
  );

  testWidgets('FrostedSwitch flips and says so; without a callback it is '
      'dimmed and paused', (t) async {
    final seen = <bool>[];
    await _pump(
      t,
      Row(
        children: [
          _Owner<bool>(
            false,
            (value, set) => FrostedSwitch(
              value: value,
              label: 'Weekly summary',
              onChanged: set,
            ),
            seen: seen,
          ),
          const FrostedSwitch(
            value: true,
            label: 'Contactless',
            onChanged: null,
          ),
        ],
      ),
    );
    expect(
      _node(t, 'Weekly summary'),
      isSemantics(isToggled: false, isEnabled: true, hasTapAction: true),
    );
    expect(t.getSize(find.byType(FrostedSwitch).first), const Size(44, 26));
    await t.tap(find.bySemanticsLabel('Weekly summary'));
    await t.pump();
    expect(seen, [true]);
    expect(_node(t, 'Weekly summary'), isSemantics(isToggled: true));
    expect(
      _node(t, 'Contactless'),
      isSemantics(isToggled: true, isEnabled: false, hasTapAction: false),
    );
    await t.tap(find.bySemanticsLabel('Contactless'));
    await t.pump();
    expect(seen, [true]);
  });

  testWidgets('FrostedSwitch read only shows its value at full strength and '
      'takes no input', (t) async {
    await _pump(
      t,
      const Row(
        children: [
          FrostedSwitch(
            value: true,
            label: 'Auto-save',
            onChanged: null,
            readOnly: true,
          ),
          FrostedSwitch(value: true, label: 'Contactless', onChanged: null),
        ],
      ),
    );
    expect(
      _node(t, 'Auto-save'),
      isSemantics(
        isToggled: true,
        isEnabled: true,
        isReadOnly: true,
        isFocusable: false,
        hasTapAction: false,
      ),
    );
    Finder faded(String label) => find.descendant(
      of: find.byWidgetPredicate((w) => w is FrostedSwitch && w.label == label),
      matching: find.byWidgetPredicate(
        // A dim, not the unlit focus light (0).
        (w) => w is AnimatedOpacity && w.opacity > 0 && w.opacity < 1,
      ),
    );
    expect(faded('Auto-save'), findsNothing);
    expect(faded('Contactless'), findsOneWidget);
    await t.tap(find.bySemanticsLabel('Auto-save'));
    await t.pump();
    expect(t.takeException(), isNull);
    expect(_node(t, 'Auto-save'), isSemantics(isToggled: true));
  });

  testWidgets('FrostedSwitchRow is one switch named by its title; its words '
      'flip it too', (t) async {
    final seen = <bool>[];
    await _pump(
      t,
      _Owner<bool>(
        true,
        (value, set) => FrostedSwitchRow(
          label: 'Face ID',
          note: 'To open Keel and approve payments',
          value: value,
          onChanged: set,
        ),
        seen: seen,
      ),
    );
    expect(find.text('Face ID'), findsOneWidget);
    expect(
      _node(t, 'Face ID'),
      isSemantics(
        isToggled: true,
        hint: 'To open Keel and approve payments',
        hasTapAction: true,
      ),
    );
    expect(find.bySemanticsLabel('Face ID'), findsOneWidget);
    // The title's line and its sub pass the 52 floor, as the source's do.
    expect(t.getSize(find.byType(FrostedSwitchRow)).height, greaterThan(52));
    await t.tap(find.text('Face ID'));
    await t.pump();
    expect(seen, [false]);
    await t.tap(find.byType(FrostedSwitch));
    await t.pump();
    expect(seen, [false, true]);
  });

  testWidgets('FrostedValueRow is a link with its value; disabled it dims and '
      'takes no tap', (t) async {
    var opens = 0;
    await _pump(
      t,
      Column(
        children: [
          FrostedValueRow(title: 'Change passcode', onPressed: () => opens++),
          FrostedValueRow(
            title: 'Monthly spending limit',
            subtitle: r'$1,259.82 spent in October',
            value: r'$2,000',
            enabled: false,
            onPressed: () => opens++,
          ),
        ],
      ),
    );
    expect(
      _node(t, 'Change passcode'),
      isSemantics(isLink: true, isEnabled: true, hasTapAction: true),
    );
    expect(
      _node(t, 'Monthly spending limit'),
      isSemantics(isEnabled: false, hasTapAction: false, value: r'$2,000'),
    );
    expect(find.byIcon(FrostedGlyphs.forward), findsNWidgets(2));
    final off = t.widget<AnimatedOpacity>(
      find.descendant(
        of: find.byType(FrostedValueRow).last,
        matching: find.byWidgetPredicate(
          (w) => w is AnimatedOpacity && w.opacity > 0 && w.opacity < 1,
        ),
      ),
    );
    expect(off.opacity, 0.45);
    await t.tap(find.text('Change passcode'));
    await t.tap(find.text('Monthly spending limit'));
    expect(opens, 1);
  });

  testWidgets('FrostedSettingsGroup parts its rows with hairlines under its '
      'head', (t) async {
    await _pump(
      t,
      FrostedSettingsGroup(
        title: 'Security',
        children: [
          FrostedSwitchRow(
            label: 'Face ID',
            note: 'To open Keel and approve payments',
            value: true,
            onChanged: (_) {},
          ),
          FrostedValueRow(title: 'Change passcode', onPressed: () {}),
          FrostedValueRow(title: 'Devices', value: '2', onPressed: () {}),
        ],
      ),
    );
    expect(find.text('Security'), findsOneWidget);
    expect(_node(t, 'Security'), isSemantics(isHeader: true));
    // `.set-row + .set-row { border-top: 1px }` in the page's border-box:
    // each row under another has the hairline at its own top, inside its
    // 52, flush with the row above.
    final lines = find.descendant(
      of: find.byType(FrostedSettingsGroup),
      matching: find.byWidgetPredicate(
        (w) =>
            w is DecoratedBox &&
            w.decoration is BoxDecoration &&
            ((w.decoration as BoxDecoration).border as Border?)?.top.width == 1,
      ),
    );
    expect(lines, findsNWidgets(2));
    final rows = find.byType(FrostedValueRow);
    final second = t.getRect(rows.first);
    final third = t.getRect(rows.last);
    expect(second.top, t.getRect(find.byType(FrostedSwitchRow)).bottom);
    expect(third.top, second.bottom);
    expect(third.height, FrostedChromeMetrics.settingRow);
    final head = t.getRect(find.text('Security'));
    final first = t.getRect(find.byType(FrostedSwitchRow));
    // The 20 line centred in the 24 head, then the 4: 6 under the words.
    expect(first.top - head.bottom, 6);
  });

  // A grid that measures its tiles and then stands each at what it measured
  // (Facet's board) gave the rows back the height without the room under
  // the last one, and the column overflowed by that room.
  testWidgets('a settings group and a titled list section stood at the '
      'height they measured hold their rows', (t) async {
    final parts = <Widget>[
      FrostedSettingsGroup(
        title: 'Security',
        children: [
          FrostedSwitchRow(label: 'Face ID', value: true, onChanged: (_) {}),
          FrostedValueRow(title: 'Devices', value: '2', onPressed: () {}),
        ],
      ),
      const FrostedListSection(
        title: 'October',
        tile: true,
        rows: [
          FrostedListTile(title: 'Rent'),
          FrostedListTile(title: 'Groceries'),
        ],
      ),
    ];
    for (final part in parts) {
      await _pump(t, part);
      final measured = t.getSize(find.byWidget(part)).height;
      await _pump(t, SizedBox(height: measured, child: part));
      expect(t.getSize(find.byWidget(part)).height, measured);
    }
  });

  testWidgets('FrostedMonthSwitch opens the months from itself; a step with '
      'nowhere to go stands off and unspoken', (t) async {
    BuildContext? anchor;
    var earlier = 0;
    var later = 0;
    Widget at({VoidCallback? onLater}) => FrostedMonthSwitch(
      month: 'October 2026',
      previous: 'September',
      onOpen: (c) => anchor = c,
      onEarlier: () => earlier++,
      onLater: onLater,
      openKey: const ValueKey<String>('keep-month'),
    );
    await _pump(t, at());
    expect(find.text('October 2026'), findsOneWidget);
    expect(find.text('September'), findsOneWidget);
    expect(find.bySemanticsLabel('Month'), findsOneWidget);
    expect(
      _node(t, 'Choose month'),
      isSemantics(
        isButton: true,
        isEnabled: true,
        hasTapAction: true,
        value: 'October 2026',
      ),
    );
    expect(
      _node(t, 'Previous month'),
      isSemantics(isButton: true, hasTapAction: true),
    );
    // Off, the later step is unspoken, as the source hides it.
    expect(find.bySemanticsLabel('Next month'), findsNothing);
    expect(t.getSize(find.byType(FrostedMonthSwitch)), const Size(358, 38));
    await t.tap(find.byKey(const ValueKey<String>('keep-month')));
    expect(anchor, isNotNull);
    // The months drop from the whole switch.
    final box = anchor!.findRenderObject()! as RenderBox;
    expect(
      box.localToGlobal(Offset.zero) & box.size,
      t.getRect(find.byType(FrostedMonthSwitch)),
    );
    await t.tap(find.bySemanticsLabel('Previous month'));
    expect(earlier, 1);
    await _pump(t, at(onLater: () => later++));
    await t.tap(find.bySemanticsLabel('Next month'));
    expect(later, 1);
  });

  testWidgets('FrostedQuickActions: four links across a tile, each named by '
      'its word', (t) async {
    final gone = <String>[];
    await _pump(
      t,
      FrostedQuickActions([
        FrostedQuickAction(
          LucideIcons.arrowLeftRight,
          'Transfer',
          onPressed: () => gone.add('transfer'),
        ),
        FrostedQuickAction(
          LucideIcons.receipt,
          'Pay a bill',
          onPressed: () => gone.add('bills'),
        ),
        FrostedQuickAction(
          LucideIcons.piggyBank,
          'Add to goal',
          onPressed: () => gone.add('goal'),
        ),
        const FrostedQuickAction(LucideIcons.split, 'Split', onPressed: null),
      ]),
    );
    expect(find.bySemanticsLabel('Quick actions'), findsOneWidget);
    expect(
      _node(t, 'Transfer'),
      isSemantics(isLink: true, isEnabled: true, hasTapAction: true),
    );
    expect(_node(t, 'Split'), isSemantics(isEnabled: false));
    final tile = t.getRect(find.byType(FrostedQuickActions));
    final first = t.getRect(find.widgetWithText(FrostedPressable, 'Transfer'));
    final last = t.getRect(find.widgetWithText(FrostedPressable, 'Split'));
    expect(first.left - tile.left, closeTo(8, 1));
    expect(tile.right - last.right, closeTo(8, 1));
    expect(first.top - tile.top, closeTo(14, 1));
    expect(
      first.width,
      moreOrLessEquals((tile.width - 16 - 3 * 4) / 4, epsilon: 1),
    );
    expect(t.getSize(find.byIcon(LucideIcons.receipt)).width, 18);
    await t.tap(find.text('Pay a bill'));
    expect(gone, ['bills']);
  });

  testWidgets('FrostedActionTiles: two across, the tiles of a row equal in '
      'height, each one link read as its word and line', (t) async {
    var opens = 0;
    await _pump(
      t,
      FrostedActionTiles([
        FrostedActionTile(
          LucideIcons.arrowLeftRight,
          'Transfer',
          note: 'Your accounts',
          onPressed: () => opens++,
        ),
        FrostedActionTile(
          LucideIcons.receipt,
          'Pay a bill',
          note: '6 in November',
          tail: r'$2,541.40',
          onPressed: () => opens++,
        ),
        FrostedActionTile(
          LucideIcons.piggyBank,
          'Add to goal',
          note: 'Lisbon in May',
          onPressed: () => opens++,
        ),
      ], label: 'Ways to move money'),
    );
    expect(find.bySemanticsLabel('Ways to move money'), findsOneWidget);
    expect(
      _node(t, 'Transfer\nYour accounts'),
      isSemantics(isLink: true, hasTapAction: true),
    );
    // The desktop's tail stays off a phone.
    expect(find.text('6 in November'), findsOneWidget);
    final a = t.getRect(find.widgetWithText(FrostedPressable, 'Transfer'));
    final b = t.getRect(find.widgetWithText(FrostedPressable, 'Pay a bill'));
    final c = t.getRect(find.widgetWithText(FrostedPressable, 'Add to goal'));
    expect(a.height, b.height);
    expect(b.left - a.right, 8);
    expect(c.top - a.bottom, 8);
    expect(a.width, moreOrLessEquals((358 - 8) / 2));
    expect(t.getSize(find.byIcon(LucideIcons.receipt)).width, 16);
    await t.tap(find.text('Add to goal'));
    expect(opens, 1);
  });

  testWidgets('FrostedQuickAmounts: three wells across; a tap picks by its '
      'amount, and the chosen one is selected', (t) async {
    final seen = <num?>[];
    await _pump(
      t,
      _Owner<num?>(
        100,
        (value, set) => FrostedQuickAmounts(
          options: const [
            FrostedQuickAmount(100, 'A month'),
            FrostedQuickAmount(200, 'Two months'),
            FrostedQuickAmount(1160, 'The rest'),
            FrostedQuickAmount(50, 'A little', key: ValueKey('little')),
          ],
          value: value,
          onChanged: set,
        ),
        seen: seen,
      ),
    );
    expect(find.text(r'$1,160'), findsOneWidget);
    expect(find.bySemanticsLabel('Quick amounts'), findsOneWidget);
    expect(
      _node(t, r'$100, A month'),
      isSemantics(isButton: true, isSelected: true, hasTapAction: true),
    );
    expect(_node(t, r'$200, Two months'), isSemantics(isSelected: false));
    final a = t.getRect(find.widgetWithText(FrostedPressable, 'A month'));
    final b = t.getRect(find.widgetWithText(FrostedPressable, 'Two months'));
    final d = t.getRect(find.byKey(const ValueKey('little')));
    expect(a.width, moreOrLessEquals((358 - 16) / 3));
    expect(b.left - a.right, 8);
    expect(d.top - a.bottom, 8);
    expect(d.left, a.left);
    await t.tap(find.text('Two months'));
    await t.pump();
    expect(seen, [200]);
    expect(_node(t, r'$200, Two months'), isSemantics(isSelected: true));
    expect(_node(t, r'$100, A month'), isSemantics(isSelected: false));
  });

  testWidgets('FrostedIconPicker sets its glyphs six to a row in 44 wells; the '
      'picked one is selected, and a tap picks', (t) async {
    final seen = <String?>[];
    await _pump(
      t,
      _Owner<String?>(
        'Bike',
        (value, set) =>
            FrostedIconPicker(icons: _icons, value: value, onChanged: set),
        seen: seen,
      ),
    );
    Finder well(String label) => find.byWidgetPredicate(
      (w) => w is FrostedPressable && w.label == label,
    );
    final wells = [for (final c in _icons) t.getRect(well(c.label))];
    const across = (358 - 5 * 8) / 6;
    for (var i = 0; i < _icons.length; i++) {
      expect(wells[i].width, moreOrLessEquals(across), reason: '$i');
      expect(wells[i].height, 44, reason: '$i');
      expect(
        wells[i].left,
        moreOrLessEquals(16 + (i % 6) * (across + 8)),
        reason: '$i',
      );
    }
    expect(wells[6].top - wells[0].bottom, 8);
    Icon glyph(String label) => t.widget<Icon>(
      find.descendant(of: well(label), matching: find.byType(Icon)),
    );
    final th = t.element(find.byType(FrostedIconPicker)).frostedTheme;
    expect(glyph('Plane').size, 18);
    expect(t.getRect(find.byIcon(LucideIcons.plane)).center, wells[0].center);
    expect(glyph('Bike').color, isSameColorAs(th.colorScheme.onButton));
    expect(glyph('Plane').color, isSameColorAs(th.colorScheme.textSecondary));
    expect(find.bySemanticsLabel('Icon'), findsOneWidget);
    expect(
      _node(t, 'Bike'),
      isSemantics(isButton: true, isSelected: true, hasTapAction: true),
    );
    expect(_node(t, 'Gift'), isSemantics(isSelected: false));
    await t.tap(find.byKey(const ValueKey('gift')));
    await t.pump();
    expect(seen, ['Gift']);
    expect(_node(t, 'Gift'), isSemantics(isSelected: true));
    expect(_node(t, 'Bike'), isSemantics(isSelected: false));
    await _pump(
      t,
      const FrostedIconPicker(icons: _icons, value: null, onChanged: null),
    );
    expect(_node(t, 'Plane'), isSemantics(hasTapAction: false));
  });

  testWidgets('FrostedTextField hands each edit back; with no callback it is '
      'read only; the label stays as written', (t) async {
    final seen = <String>[];
    await _pump(
      t,
      Column(
        children: [
          FrostedTextField(
            label: 'Note',
            hint: 'What it is for',
            helper: 'Shows on the statement',
            onChanged: seen.add,
          ),
          const FrostedTextField(label: 'Account', value: 'Checking ·· 4821'),
        ],
      ),
    );
    expect(find.text('Note'), findsOneWidget);
    expect(find.text('NOTE'), findsNothing);
    expect(find.text('What it is for'), findsOneWidget);
    expect(find.text('Shows on the statement'), findsOneWidget);
    expect(find.text('Checking ·· 4821'), findsOneWidget);
    // The field is named by its label, then the hint while it is empty.
    expect(
      t.getSemantics(find.byType(TextField).first),
      isSemantics(label: 'Note\nWhat it is for', isTextField: true),
    );
    final label = t.getRect(find.text('Note'));
    final wells = find.descendant(
      of: find.byType(FrostedTextField).first,
      matching: find.byType(FrostedWell),
    );
    expect(t.getRect(wells).top - label.bottom, 8);
    expect(t.getSize(wells).height, 48);
    await t.enterText(find.byType(TextField).first, 'November top-up');
    expect(seen, ['November top-up']);
    final account = t.widget<TextField>(find.byType(TextField).last);
    expect(account.readOnly, isTrue);
  });

  testWidgets('FrostedAmountField takes digits and a point into a 64 well; '
      'small it is 48 on the centre line', (t) async {
    final seen = <String>[];
    await _pump(
      t,
      Column(
        children: [
          FrostedAmountField(label: 'Amount', onChanged: seen.add),
          const FrostedAmountField(
            label: 'Target',
            value: '1200',
            size: FrostedAmountFieldSize.small,
          ),
        ],
      ),
    );
    expect(find.text(r'$'), findsNWidgets(2));
    // The decorator keeps a second, offstage copy of the hint for its size.
    expect(find.text('0'), findsAtLeastNWidgets(1));
    expect(find.text('1200'), findsOneWidget);
    expect(
      t.getSemantics(find.byType(TextField).first),
      isSemantics(label: 'Amount\n0', isTextField: true),
    );
    final wells = find.byType(FrostedWell);
    expect(t.getSize(wells.first).height, 64);
    expect(t.getSize(wells.last).height, 48);
    final sign = t.getRect(find.text(r'$').first);
    final well = t.getRect(wells.first);
    expect(sign.top - well.top, 18);
    expect(sign.left - well.left, 16);
    await t.enterText(find.byType(TextField).first, r'5a00.0$0');
    expect(seen, ['500.00']);
    final target = t.widget<TextField>(find.byType(TextField).last);
    expect(target.readOnly, isTrue);
  });

  testWidgets('FrostedPickerRow says its choice and opens the picker', (
    t,
  ) async {
    var opens = 0;
    await _pump(
      t,
      FrostedPickerRow(
        label: 'From',
        leading: const FrostedIconMark(LucideIcons.wallet),
        title: 'Everyday',
        subtitle: 'Checking ·· 4821',
        trailing: const FrostedAmount(6248.30, signed: false),
        onPressed: () => opens++,
      ),
    );
    expect(find.text('From'), findsOneWidget);
    expect(find.byIcon(LucideIcons.chevronDown), findsOneWidget);
    expect(
      _node(t, 'From: Everyday, Checking ·· 4821'),
      isSemantics(isButton: true, hasTapAction: true),
    );
    final well = t.getRect(find.byType(FrostedPressable));
    expect(well.height, 60);
    expect(t.getRect(find.byType(FrostedIconMark)).left - well.left, 10);
    expect(
      well.right - t.getRect(find.byIcon(LucideIcons.chevronDown)).right,
      14,
    );
    await t.tap(find.text('Everyday'));
    expect(opens, 1);
  });

  testWidgets(
    'FrostedSwapButton is the 16 between two pickers, its 32 disc centred '
    'on it; with a tap it is a button',
    (t) async {
      var swaps = 0;
      await _pump(
        t,
        Column(
          children: [
            const FrostedSwapButton(),
            const SizedBox(height: 40),
            FrostedSwapButton(onPressed: () => swaps++),
          ],
        ),
      );
      expect(FrostedSwapButton.height, 16);
      final mark = t.getRect(find.byType(FrostedSwapButton).first);
      expect(mark.height, 16);
      final disc = t.getRect(find.byIcon(LucideIcons.arrowDown).first);
      expect(disc.center, mark.center);
      expect(disc.width, 16);
      expect(find.bySemanticsLabel('Swap'), findsOneWidget);
      expect(_node(t, 'Swap'), isSemantics(isButton: true, hasTapAction: true));
      await t.tap(find.bySemanticsLabel('Swap'));
      expect(swaps, 1);
    },
  );

  testWidgets('FrostedNumberField steps by its step, stops at its floor and '
      'ceiling, and takes a typed figure', (t) async {
    final seen = <int>[];
    await _pump(
      t,
      _Owner<int>(
        250,
        (value, set) => FrostedNumberField(
          value: value,
          label: 'the budget',
          note: 'a month',
          max: 260,
          onChanged: set,
        ),
        seen: seen,
      ),
    );
    expect(find.text('a month'), findsOneWidget);
    expect(find.text('250'), findsOneWidget);
    expect(_node(t, 'the budget'), isSemantics(isTextField: true));
    expect(t.getSize(find.byType(FrostedIconButton).first), const Size(48, 48));
    // `.stepper .inp--amt { width: 3ch }`: three zeros' own advance, the
    // figure's tracking and tabular figures left out, as a ch is.
    final figure = t.widget<TextField>(find.byType(TextField)).style!;
    final room = TextPainter(
      text: TextSpan(
        text: '000',
        style: figure.copyWith(letterSpacing: 0, fontFeatures: const []),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    expect(
      t.getSize(find.byType(TextField)).width,
      moreOrLessEquals(room.width, epsilon: 0.01),
    );
    room.dispose();
    await t.tap(find.bySemanticsLabel('Raise the budget'));
    await t.pump();
    expect(
      _node(t, 'Raise the budget'),
      isSemantics(isEnabled: false, hasTapAction: false),
    );
    await t.tap(find.bySemanticsLabel('Lower the budget'));
    await t.pump();
    await t.tap(find.bySemanticsLabel('Lower the budget'));
    await t.pump();
    expect(seen, [260, 250, 240]);
    await t.enterText(find.byType(TextField), '9000');
    await t.pump();
    expect(seen.last, 260);
    await _pump(
      t,
      FrostedNumberField(value: 0, label: 'the budget', onChanged: seen.add),
    );
    expect(
      _node(t, 'Lower the budget'),
      isSemantics(isEnabled: false, hasTapAction: false),
    );
    expect(_node(t, 'Raise the budget'), isSemantics(isEnabled: true));
  });

  testWidgets('FrostedFormRow: a value and chevron make one link; a control '
      'keeps its own node; a bare row reads as one line', (t) async {
    var opens = 0;
    await _pump(
      t,
      Column(
        children: [
          FrostedFormRow(
            label: 'Currency',
            leading: LucideIcons.coins,
            value: 'USD',
            onPressed: () => opens++,
          ),
          FrostedFormRow(
            label: 'Weekly summary',
            detail: 'Every Sunday evening',
            trailing: FrostedSwitch(
              value: true,
              label: 'Summary alerts',
              onChanged: (_) {},
            ),
          ),
          const FrostedFormRow(label: 'Member since', value: '2021'),
        ],
      ),
    );
    expect(
      _node(t, 'Currency'),
      isSemantics(isLink: true, value: 'USD', hasTapAction: true),
    );
    expect(find.byIcon(FrostedGlyphs.forward), findsOneWidget);
    expect(find.byType(FrostedIconMark), findsOneWidget);
    expect(_node(t, 'Summary alerts'), isSemantics(isToggled: true));
    expect(find.text('Every Sunday evening'), findsOneWidget);
    expect(_node(t, 'Member since\n2021'), isSemantics(isLink: false));
    expect(t.getSize(find.byType(FrostedFormRow).first).height, 52);
    await t.tap(find.text('Currency'));
    expect(opens, 1);
  });

  testWidgets(
    'FrostedFormSection sets its fields 16 apart under its head, none '
    'round a swap; FrostedFieldPair halves the line',
    (t) async {
      await _pump(
        t,
        FrostedFormSection(
          title: 'New goal',
          children: [
            const FrostedTextField(label: 'Name', value: 'Lisbon'),
            const FrostedFieldPair(
              FrostedAmountField(
                label: 'Target',
                value: '1200',
                size: FrostedAmountFieldSize.small,
              ),
              FrostedTextField(label: 'Date', value: 'May 2027'),
            ),
            FrostedPickerRow(
              label: 'From',
              title: 'Everyday',
              onPressed: () {},
            ),
            const FrostedSwapButton(),
            FrostedPickerRow(label: 'To', title: 'Savings', onPressed: () {}),
          ],
        ),
      );
      expect(_node(t, 'New goal'), isSemantics(isHeader: true));
      final head = t.getRect(find.text('New goal'));
      final name = t.getRect(find.byType(FrostedTextField).first);
      final pair = t.getRect(find.byType(FrostedFieldPair));
      final target = t.getRect(find.byType(FrostedAmountField));
      final date = t.getRect(find.byType(FrostedTextField).last);
      final from = t.getRect(find.byType(FrostedPickerRow).first);
      final to = t.getRect(find.byType(FrostedPickerRow).last);
      // The 20 line centred in the 24 head, then the 16: 18 under the words.
      expect(name.top - head.bottom, 18);
      expect(pair.top - name.bottom, 16);
      expect(date.left - target.right, 12);
      expect(target.width, date.width);
      expect(to.top - from.bottom, 16);
      expect(t.getRect(find.byType(FrostedSwapButton)).top, from.bottom);
      expect(find.byType(FrostedCard), findsOneWidget);
      await _pump(
        t,
        const FrostedFormSection(
          bare: true,
          children: [FrostedTextField(label: 'Note', value: 'November top-up')],
        ),
      );
      expect(find.byType(FrostedCard), findsNothing);
    },
  );
}

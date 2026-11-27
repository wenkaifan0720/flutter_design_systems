// F17: an app's own corners on a part of Civic. Civic takes a step per
// corner: two diagonal cuts or one corner alone draw as given, mirrored in a
// right-to-left app; a full corner is held to extra large; a style's shape
// wins over its corners; a split button and a sheet take them on their
// outer corners alone.
import 'package:civic_ui/civic_parts.dart' show CivicFacePainter;
import 'package:civic_ui/civic_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

const _part = Key('part');

CivicStyle _corners(RawCorners corners) =>
    CivicStyle(corners: WidgetStatePropertyAll(corners));

// Civic's own steps.
const _radius = {
  RawCorner.none: 0.0,
  RawCorner.extraSmall: 2.0,
  RawCorner.small: 4.0,
  RawCorner.medium: 8.0,
  RawCorner.large: 12.0,
  RawCorner.extraLarge: 16.0,
};

// Each shaped part: its own step, how to build it with a style, and (for one
// on an overlay) the words inside its panel and the words to tap to open it.
typedef _Shaped = ({
  String name,
  RawCorner own,
  Widget Function(CivicStyle? style) build,
  String? inside,
  String? open,
});

_Shaped _on(String name, RawCorner own, Widget Function(CivicStyle?) build) =>
    (name: name, own: own, build: build, inside: null, open: null);

final List<_Shaped> _parts = [
  _on(
    'button',
    RawCorner.small,
    (s) => CivicButton(onPressed: () {}, style: s, child: const Text('Go')),
  ),
  _on(
    'secondary button',
    RawCorner.small,
    (s) => CivicButton.secondary(
      onPressed: () {},
      style: s,
      child: const Text('Back'),
    ),
  ),
  _on(
    'icon button',
    RawCorner.small,
    (s) => CivicIconButton(
      icon: Icons.close,
      semanticLabel: 'Close',
      onPressed: () {},
      style: s,
    ),
  ),
  _on('tag', RawCorner.small, (s) => CivicTag(label: 'Due', style: s)),
  _on(
    'badge',
    RawCorner.extraSmall,
    (s) => CivicBadge(count: 3, noun: 'message', style: s),
  ),
  _on('key', RawCorner.small, (s) => CivicKbd('Esc', style: s)),
  _on(
    'card',
    RawCorner.medium,
    (s) => CivicCard(title: 'Permit', style: s, child: const Text('Zone B')),
  ),
  _on(
    'chip',
    RawCorner.small,
    (s) => CivicChip(
      label: 'Parking',
      selected: false,
      onSelected: (_) {},
      style: s,
    ),
  ),
  _on(
    'toggle group',
    RawCorner.small,
    (s) => CivicToggleGroup<String>(
      segments: const [
        CivicSegment(value: 'bins', label: 'Bins'),
        CivicSegment(value: 'roads', label: 'Roads'),
      ],
      selected: const {'bins'},
      onSelectionChanged: (_) {},
      style: s,
    ),
  ),
  _on(
    'segmented control',
    RawCorner.small,
    (s) => CivicSegmentedControl<String>(
      segments: const [
        CivicSegment(value: 'week', label: 'Week'),
        CivicSegment(value: 'month', label: 'Month'),
      ],
      value: 'week',
      onChanged: (_) {},
      style: s,
    ),
  ),
  _on(
    'slider',
    RawCorner.small,
    (s) => CivicSlider(value: 0.5, onChanged: (_) {}, style: s),
  ),
  _on(
    'rating',
    RawCorner.small,
    (s) => CivicRating(value: 3, onChanged: (_) {}, style: s),
  ),
  _on(
    'summary card',
    RawCorner.medium,
    (s) => CivicSummaryCard(
      title: 'Your details',
      style: s,
      child: const Text('Ana Ruiz'),
    ),
  ),
  _on(
    'carousel',
    RawCorner.medium,
    (s) => CivicCarousel(
      semanticLabel: 'Zones',
      height: 120,
      itemCount: 2,
      itemBuilder: (_, i) => Text('Zone $i'),
      style: s,
    ),
  ),
  _on(
    'image',
    RawCorner.medium,
    (s) => CivicImage.decorative(image: null, style: s),
  ),
  _on(
    'reorderable list',
    RawCorner.medium,
    (s) => CivicReorderableList<String>(
      items: const ['Wake', 'Walk'],
      onReorder: (from, to) {},
      labelOf: (x) => x,
      style: s,
    ),
  ),
  _on(
    'progress bar',
    RawCorner.extraSmall,
    (s) => CivicProgressBar(label: 'Uploaded', value: 0.4, style: s),
  ),
  _on(
    'meter',
    RawCorner.extraSmall,
    (s) => CivicMeter(label: 'Storage', value: 3, max: 10, style: s),
  ),
  _on(
    'side navigation',
    RawCorner.small,
    (s) => SizedBox(
      height: 300,
      child: CivicSideNavigation(
        destinations: const [
          CivicNavigationDestination(icon: Icons.home, label: 'Home'),
          CivicNavigationDestination(icon: Icons.article, label: 'Permits'),
        ],
        selectedIndex: 0,
        onDestinationSelected: (_) {},
        style: s,
      ),
    ),
  ),
  (
    name: 'tooltip',
    own: RawCorner.small,
    build: (s) => CivicTooltip(
      message: 'Closes the page',
      triggerMode: TooltipTriggerMode.tap,
      style: s,
      child: const Text('Hint'),
    ),
    inside: 'Closes the page',
    open: 'Hint',
  ),
  (
    name: 'popover',
    own: RawCorner.small,
    build: (s) => CivicPopover(
      style: s,
      builder: (context, anchor) =>
          CivicButton(onPressed: anchor.toggle, child: const Text('More')),
      content: const Text('Opens at nine'),
    ),
    inside: 'Opens at nine',
    open: 'More',
  ),
  (
    name: 'menu',
    own: RawCorner.small,
    build: (s) => CivicMenu<String>(
      items: const [CivicMenuItem(value: 'print', label: 'Print')],
      onSelected: (_) {},
      style: s,
      builder: (context, anchor) => CivicButton.secondary(
        onPressed: anchor.toggle,
        child: const Text('Actions'),
      ),
    ),
    inside: 'Print',
    open: 'Actions',
  ),
  (
    name: 'dialog',
    own: RawCorner.medium,
    build: (s) => Builder(
      builder: (context) => CivicButton(
        onPressed: () => showCivicDialog<void>(
          context: context,
          builder: (context) => CivicDialog(
            title: 'Leave?',
            style: s,
            content: const Text('Your answers go.'),
          ),
        ),
        child: const Text('Open'),
      ),
    ),
    inside: 'Your answers go.',
    open: 'Open',
  ),
  (
    name: 'command palette',
    own: RawCorner.medium,
    build: (s) => Builder(
      builder: (context) => CivicButton(
        onPressed: () => showCivicCommandPalette(
          context: context,
          commands: [RawCommand(label: 'Your permits', onPressed: () {})],
          style: s,
        ),
        child: const Text('Find'),
      ),
    ),
    inside: 'Your permits',
    open: 'Find',
  ),
];

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  TextDirection direction = TextDirection.ltr,
  CivicThemeData? theme,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      key: UniqueKey(),
      builder: (context, app) => Directionality(
        textDirection: direction,
        child: CivicHost(
          theme: theme,
          brightness: Brightness.light,
          child: app!,
        ),
      ),
      home: Directionality(
        textDirection: direction,
        child: Center(
          child: SizedBox(
            width: 360,
            child: KeyedSubtree(key: _part, child: child),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

// The outline a widget draws: a face's, a shaped decoration's or a shaped
// clip's; null for any other.
OutlinedBorder? _shapeOf(Widget w) => switch (w) {
  CustomPaint(:final CivicFacePainter painter) => painter.shape,
  CustomPaint(:final Object painter) when _bar(painter) != null => _bar(
    painter,
  ),
  DecoratedBox(:final ShapeDecoration decoration) =>
    decoration.shape as OutlinedBorder,
  ClipPath(:final ShapeBorderClipper clipper) =>
    clipper.shape as OutlinedBorder,
  _ => null,
};

// A bar's track (a progress bar's, a meter's) keeps its outline on its
// painter.
OutlinedBorder? _bar(Object painter) {
  try {
    return (painter as dynamic).outline as OutlinedBorder?;
  } on NoSuchMethodError {
    return null;
  }
}

final _shaped = find.byWidgetPredicate((w) => _shapeOf(w) != null);

String _a(String name) => '${'aeiou'.contains(name[0]) ? 'an' : 'a'} $name';

// The part's outline: the outermost shape round the words inside an
// overlay's panel, else the part's largest shape.
OutlinedBorder _outline(WidgetTester tester, _Shaped part) {
  if (part.inside != null) {
    return _shapeOf(
      tester.widget(
        find.ancestor(of: find.text(part.inside!), matching: _shaped).last,
      ),
    )!;
  }
  final found = find.descendant(of: find.byKey(_part), matching: _shaped);
  var best = found.evaluate().first;
  for (final e in found.evaluate()) {
    final a = e.size!, b = best.size!;
    if (a.width * a.height > b.width * b.height) best = e;
  }
  return _shapeOf(best.widget)!;
}

Future<OutlinedBorder> _shown(
  WidgetTester tester,
  _Shaped part,
  CivicStyle? style, {
  TextDirection direction = TextDirection.ltr,
  CivicThemeData? theme,
}) async {
  await _pump(tester, part.build(style), direction: direction, theme: theme);
  if (part.open != null) {
    await tester.tap(find.text(part.open!));
    await tester.pumpAndSettle();
  }
  return _outline(tester, part);
}

// The radii drawn at each corner, start and end mirrored by [direction].
BorderRadius _drawn(OutlinedBorder shape, TextDirection direction) =>
    (shape as RawCornerBorder).borderRadius.resolve(direction);

// What a part whose corners are topStart, topEnd, bottomStart and bottomEnd
// draws in [direction].
BorderRadius _expect(
  RawCorner ts,
  RawCorner te,
  RawCorner bs,
  RawCorner be,
  TextDirection direction,
) {
  Radius r(RawCorner c) => Radius.circular(_radius[c]!);
  final rtl = direction == TextDirection.rtl;
  return BorderRadius.only(
    topLeft: r(rtl ? te : ts),
    topRight: r(rtl ? ts : te),
    bottomLeft: r(rtl ? be : bs),
    bottomRight: r(rtl ? bs : be),
  );
}

void main() {
  test('Civic opens a step per corner, from square to extra large', () {
    const limits = CivicThemeData.shapeLimits;
    expect(limits.cornerFreedom, RawCornerFreedom.perCorner);
    expect(limits.cornerSteps, contains(RawCorner.none));
    expect(limits.cornerSteps, isNot(contains(RawCorner.full)));
    expect(limits.nearestStep(RawCorner.full), RawCorner.extraLarge);
  });

  const none = RawCorner.none;
  for (final part in _parts) {
    for (final direction in TextDirection.values) {
      testWidgets('${_a(part.name)} takes its own corners, cut by corner '
          '(${direction.name})', (tester) async {
        final own = part.own;
        Future<void> check(CivicStyle? style, BorderRadius want) async {
          final shape = await _shown(tester, part, style, direction: direction);
          expect(_drawn(shape, direction), want);
          // A face paints its outline in the reading direction.
          for (final w in tester.widgetList<CustomPaint>(
            find.descendant(
              of: find.byKey(_part),
              matching: find.byType(CustomPaint),
            ),
          )) {
            if (w.painter case CivicFacePainter(:final shape?)) {
              expect(
                (w.painter! as CivicFacePainter).textDirection,
                direction,
                reason: '$shape',
              );
            }
          }
        }

        await check(null, _expect(own, own, own, own, direction));
        // Two diagonal cuts, each way.
        await check(
          _corners(const RawCorners(topEnd: none, bottomStart: none)),
          _expect(own, none, none, own, direction),
        );
        await check(
          _corners(const RawCorners(topStart: none, bottomEnd: none)),
          _expect(none, own, own, none, direction),
        );
        // One corner alone: the rest square.
        await check(
          _corners(const RawCorners.only(topStart: RawCorner.large)),
          _expect(RawCorner.large, none, none, none, direction),
        );
        // A full corner is held to the extra large.
        await check(
          _corners(const RawCorners.all(RawCorner.full)),
          _expect(
            RawCorner.extraLarge,
            RawCorner.extraLarge,
            RawCorner.extraLarge,
            RawCorner.extraLarge,
            direction,
          ),
        );
      });
    }
  }

  for (final name in ['card', 'button', 'dialog']) {
    testWidgets("${_a(name)}'s own shape wins over its corners", (
      tester,
    ) async {
      final part = _parts.firstWhere((p) => p.name == name);
      const bevel = BeveledRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(10)),
      );
      final shape = await _shown(
        tester,
        part,
        const CivicStyle(
          shape: WidgetStatePropertyAll(bevel),
          corners: WidgetStatePropertyAll(RawCorners.all(RawCorner.large)),
        ),
      );
      // A floating panel strokes it with its hairline.
      expect(shape, isA<BeveledRectangleBorder>());
      expect(
        (shape as BeveledRectangleBorder).borderRadius,
        bevel.borderRadius,
      );
    });
  }

  testWidgets("a step is the theme's: an app's scheme moves it", (
    tester,
  ) async {
    final part = _parts.firstWhere((p) => p.name == 'card');
    final theme = CivicThemeData.light().copyWith(
      shapeScheme: CivicThemeData.defaultShapeScheme.copyWith(
        corners: CivicThemeData.defaultShapeScheme.corners.copyWith(
          medium: 12,
          extraLarge: 20,
        ),
      ),
    );
    var shape = await _shown(tester, part, null, theme: theme);
    expect(_drawn(shape, TextDirection.ltr), BorderRadius.circular(12));
    shape = await _shown(
      tester,
      part,
      _corners(const RawCorners.only(bottomEnd: RawCorner.extraLarge)),
      theme: theme,
    );
    expect(
      _drawn(shape, TextDirection.ltr),
      const BorderRadius.only(bottomRight: Radius.circular(20)),
    );
  });

  for (final direction in TextDirection.values) {
    testWidgets(
      "a split button's halves take an app's corners at their outer ends "
      '(${direction.name})',
      (tester) async {
        await _pump(
          tester,
          CivicSplitButton(
            label: 'Send',
            onPressed: () {},
            expand: false,
            actions: [CivicSplitAction('Save for later', onPressed: () {})],
            style: _corners(const RawCorners.all(RawCorner.extraLarge)),
          ),
          direction: direction,
        );
        final faces = find
            .descendant(
              of: find.byKey(_part),
              matching: find.byWidgetPredicate(
                (w) => w is CustomPaint && w.painter is CivicFacePainter,
              ),
            )
            .evaluate()
            .toList();
        BorderRadius drawnAt(Element e) => _drawn(
          ((e.widget as CustomPaint).painter! as CivicFacePainter).shape!,
          direction,
        );
        final action = faces.firstWhere(
          (e) => find
              .descendant(
                of: find.byWidget(e.widget),
                matching: find.text('Send'),
              )
              .evaluate()
              .isNotEmpty,
        );
        final chevron = faces.firstWhere((e) => e != action);
        const xl = RawCorner.extraLarge, small = RawCorner.small;
        expect(drawnAt(action), _expect(xl, small, xl, small, direction));
        expect(drawnAt(chevron), _expect(small, xl, small, xl, direction));
      },
    );
  }

  for (final direction in TextDirection.values) {
    testWidgets(
      "a sheet takes an app's corners on its top two, its foot square "
      '(${direction.name})',
      (tester) async {
        Future<BorderRadius> sheet(CivicStyle? style) async {
          await _pump(
            tester,
            Builder(
              builder: (context) => CivicButton(
                onPressed: () => showCivicBottomSheet<void>(
                  context: context,
                  title: 'Filter',
                  style: style,
                  builder: (context) => const Text('By zone'),
                ),
                child: const Text('Open'),
              ),
            ),
            direction: direction,
          );
          await tester.tap(find.text('Open'));
          await tester.pumpAndSettle();
          final shape = _shapeOf(
            tester.widget(
              find.ancestor(of: find.text('By zone'), matching: _shaped).last,
            ),
          )!;
          return _drawn(shape, direction);
        }

        const m = RawCorner.medium, xl = RawCorner.extraLarge;
        const l = RawCorner.large, none = RawCorner.none;
        expect(await sheet(null), _expect(m, m, none, none, direction));
        expect(
          await sheet(_corners(const RawCorners.all(xl))),
          _expect(xl, xl, none, none, direction),
        );
        expect(
          await sheet(_corners(const RawCorners.only(topStart: l))),
          _expect(l, none, none, none, direction),
        );
      },
    );
  }
}

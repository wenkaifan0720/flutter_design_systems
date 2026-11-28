// An app's own corners on a part of Ledger. Ledger takes a step per corner:
// two diagonal cuts or one corner alone draw as given, mirrored in a
// right-to-left app; a control's round corner beside square ones reaches
// half a finger's 40; a style's shape wins over its corners; a slip's band
// keeps to the slip's top corners.
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_ui/ledger_parts.dart' show LedgerImpression;
import 'package:ledger_ui/ledger_ui.dart';

const _part = Key('part');

LedgerStyle _corners(RawCorners corners) =>
    LedgerStyle(corners: WidgetStatePropertyAll(corners));

// Ledger's own steps; a full corner is round at any height alone, half a
// finger's 40 beside a corner that isn't.
const _radius = {
  RawCorner.none: 0.0,
  RawCorner.extraSmall: 3.0,
  RawCorner.small: 6.0,
  RawCorner.medium: 6.0,
  RawCorner.large: 6.0,
  RawCorner.extraLarge: 12.0,
};

typedef _Shaped = ({
  String name,
  RawCorner own,
  Widget Function(LedgerStyle? style) build,
  String? inside,
  String? hover,
});

_Shaped _on(String name, RawCorner own, Widget Function(LedgerStyle?) build) =>
    (name: name, own: own, build: build, inside: null, hover: null);

final List<_Shaped> _parts = [
  _on(
    'button',
    RawCorner.full,
    (s) => LedgerButton('Move money', style: s, onPressed: () {}),
  ),
  _on(
    'filled button',
    RawCorner.full,
    (s) => LedgerButton.filled('Pay', style: s, onPressed: () {}),
  ),
  _on(
    'chip',
    RawCorner.full,
    (s) => LedgerChip('Groceries', style: s, onTap: () {}),
  ),
  _on(
    'toggle group',
    RawCorner.full,
    (s) => LedgerToggleGroup<String>(
      options: const ['Week'],
      selected: const {'Week'},
      semanticLabel: 'Range',
      labelOf: (o) => o,
      onSelectionChanged: (_) {},
      style: s,
    ),
  ),
  _on(
    'segmented control',
    RawCorner.full,
    (s) => LedgerSegmentedControl<String>(
      options: const ['In', 'Out'],
      value: 'In',
      onChanged: (_) {},
      style: s,
    ),
  ),
  _on(
    'slip',
    RawCorner.medium,
    (s) => LedgerSlip(style: s, child: const SizedBox(height: 80)),
  ),
  _on(
    'banner',
    RawCorner.medium,
    (s) => LedgerBanner(title: 'Card frozen', style: s),
  ),
  _on('toast', RawCorner.medium, (s) => LedgerToastCard('Saved', style: s)),
  _on(
    'dialog',
    RawCorner.large,
    (s) => LedgerDialog(title: 'Leave?', body: 'Your entry goes.', style: s),
  ),
  (
    name: 'tooltip',
    own: RawCorner.small,
    build: (s) => LedgerTooltip(
      message: 'Closes the page',
      style: s,
      child: const Text('Hint'),
    ),
    inside: 'Closes the page',
    hover: 'Hint',
  ),
];

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  TextDirection direction = TextDirection.ltr,
  LedgerThemeData? theme,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    WidgetsApp(
      key: UniqueKey(),
      color: const Color(0xFF000000),
      localizationsDelegates: const [RawWidgetsLocalizations.delegate],
      builder: (context, _) => Directionality(
        textDirection: direction,
        child: LedgerHost(
          brightness: Brightness.light,
          theme: theme,
          child: Navigator(
            onGenerateRoute: (_) => PageRouteBuilder<void>(
              pageBuilder: (_, _, _) => Center(
                child: SizedBox(
                  width: 342,
                  child: KeyedSubtree(key: _part, child: child),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

// The corners a widget draws: a box's or a clip's; null for any other.
BorderRadiusGeometry? _cornersOf(Widget w) => switch (w) {
  DecoratedBox(:final BoxDecoration decoration)
      when decoration.borderRadius != null =>
    decoration.borderRadius,
  ClipRRect(:final borderRadius) => borderRadius,
  _ => null,
};

final _boxed = find.byWidgetPredicate((w) => _cornersOf(w) != null);

String _a(String name) => '${'aeiou'.contains(name[0]) ? 'an' : 'a'} $name';

// The part's corners: the outermost box round the words inside an overlay,
// else the part's largest box.
BorderRadiusGeometry _outline(WidgetTester tester, _Shaped part) {
  if (part.inside != null) {
    return _cornersOf(
      tester.widget(
        find.ancestor(of: find.text(part.inside!), matching: _boxed).last,
      ),
    )!;
  }
  final found = find.descendant(of: find.byKey(_part), matching: _boxed);
  var best = found.evaluate().first;
  for (final e in found.evaluate()) {
    final a = e.size!, b = best.size!;
    if (a.width * a.height > b.width * b.height) best = e;
  }
  return _cornersOf(best.widget)!;
}

Future<BorderRadius> _shown(
  WidgetTester tester,
  _Shaped part,
  LedgerStyle? style, {
  TextDirection direction = TextDirection.ltr,
  LedgerThemeData? theme,
}) async {
  await _pump(tester, part.build(style), direction: direction, theme: theme);
  final words = part.hover;
  if (words == null) return _outline(tester, part).resolve(direction);
  final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
  await mouse.addPointer(location: tester.getCenter(find.text(words)));
  await tester.pump(const Duration(milliseconds: 600));
  await tester.pump(const Duration(milliseconds: 300));
  final drawn = _outline(tester, part).resolve(direction);
  await mouse.removePointer();
  await tester.pumpAndSettle();
  return drawn;
}

// What a part whose corners are topStart, topEnd, bottomStart and bottomEnd
// draws in [direction].
BorderRadius _expect(
  RawCorner ts,
  RawCorner te,
  RawCorner bs,
  RawCorner be,
  TextDirection direction,
) {
  final mixed = {ts, te, bs, be}.length > 1;
  Radius r(RawCorner c) =>
      Radius.circular(c == RawCorner.full ? (mixed ? 20 : 999) : _radius[c]!);
  final rtl = direction == TextDirection.rtl;
  return BorderRadius.only(
    topLeft: r(rtl ? te : ts),
    topRight: r(rtl ? ts : te),
    bottomLeft: r(rtl ? be : bs),
    bottomRight: r(rtl ? bs : be),
  );
}

void main() {
  test('Ledger opens a step per corner, every step', () {
    const limits = LedgerThemeData.shapeLimits;
    expect(limits.cornerFreedom, RawCornerFreedom.perCorner);
    expect(limits.cornerSteps, isNull);
  });

  const none = RawCorner.none;
  for (final part in _parts) {
    for (final direction in TextDirection.values) {
      testWidgets('${_a(part.name)} takes its own corners, cut by corner '
          '(${direction.name})', (tester) async {
        final own = part.own;
        Future<void> check(LedgerStyle? style, BorderRadius want) async {
          expect(
            await _shown(tester, part, style, direction: direction),
            want,
            reason: '$style',
          );
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
          _corners(const RawCorners.only(topStart: RawCorner.extraLarge)),
          _expect(RawCorner.extraLarge, none, none, none, direction),
        );
      });
    }
  }

  for (final name in ['slip', 'button', 'dialog']) {
    testWidgets("${_a(name)}'s own shape wins over its corners", (
      tester,
    ) async {
      final part = _parts.firstWhere((p) => p.name == name);
      const square = RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(10)),
      );
      final drawn = await _shown(
        tester,
        part,
        const LedgerStyle(
          shape: WidgetStatePropertyAll(square),
          corners: WidgetStatePropertyAll(RawCorners.all(RawCorner.none)),
        ),
      );
      expect(drawn, BorderRadius.circular(10));
    });
  }

  testWidgets("a step is the theme's: an app's scheme moves it", (
    tester,
  ) async {
    final part = _parts.firstWhere((p) => p.name == 'slip');
    final theme = LedgerThemeData.light().copyWith(
      shapeScheme: LedgerThemeData.defaultShapeScheme.copyWith(
        corners: LedgerThemeData.defaultShapeScheme.corners.copyWith(
          medium: 10,
          extraLarge: 16,
        ),
      ),
    );
    expect(
      await _shown(tester, part, null, theme: theme),
      BorderRadius.circular(10),
    );
    expect(
      await _shown(
        tester,
        part,
        _corners(const RawCorners.only(bottomEnd: RawCorner.extraLarge)),
        theme: theme,
      ),
      const BorderRadius.only(bottomRight: Radius.circular(16)),
    );
  });

  for (final direction in TextDirection.values) {
    testWidgets("a slip's band keeps to the slip's top corners "
        '(${direction.name})', (tester) async {
      await _pump(
        tester,
        LedgerSlip(
          style: _corners(
            const RawCorners(
              topStart: RawCorner.extraLarge,
              topEnd: none,
              bottomStart: none,
              bottomEnd: RawCorner.extraLarge,
            ),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [LedgerSlipBand(), SizedBox(height: 40)],
          ),
        ),
        direction: direction,
      );
      final clip = tester.widget<ClipRRect>(
        find.descendant(
          of: find.byType(LedgerSlipBand),
          matching: find.byType(ClipRRect),
        ),
      );
      final r = clip.borderRadius.resolve(direction);
      final rtl = direction == TextDirection.rtl;
      expect(r.topLeft, Radius.circular(rtl ? 0 : 12));
      expect(r.topRight, Radius.circular(rtl ? 12 : 0));
      expect(r.bottomLeft, Radius.zero);
      expect(r.bottomRight, Radius.zero);
    });
  }

  testWidgets("a press's wash keeps to the face's corners", (tester) async {
    await _pump(
      tester,
      LedgerButton(
        'Move money',
        style: _corners(const RawCorners.only(topStart: RawCorner.extraLarge)),
        onPressed: () {},
      ),
    );
    final press = tester.widget<LedgerPressable>(find.byType(LedgerPressable));
    expect(
      press.borderRadius.resolve(TextDirection.ltr),
      const BorderRadius.only(topLeft: Radius.circular(12)),
    );
    final impression = tester.widget<LedgerImpression>(
      find.descendant(
        of: find.byType(LedgerPressable),
        matching: find.byType(LedgerImpression),
      ),
    );
    expect(
      impression.wash,
      const BorderRadius.only(topLeft: Radius.circular(12)),
    );
  });

  testWidgets("a button's press keeps to its own shape over its corners", (
    tester,
  ) async {
    await _pump(
      tester,
      LedgerButton(
        'Move money',
        style: const LedgerStyle(
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
          ),
          corners: WidgetStatePropertyAll(RawCorners.all(RawCorner.none)),
        ),
        onPressed: () {},
      ),
    );
    final press = tester.widget<LedgerPressable>(find.byType(LedgerPressable));
    expect(
      press.borderRadius.resolve(TextDirection.ltr),
      BorderRadius.circular(10),
    );
  });
}

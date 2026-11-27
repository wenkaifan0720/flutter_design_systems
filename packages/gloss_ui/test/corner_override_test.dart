// An app's corners for a part (F17): a style's `corners` gives each corner
// its own step, held to Gloss's limits (every step, each corner its own:
// cornerFreedom perCorner) over the part's own corners, drawn in the theme's
// scale and laid from the reading start, so right to left they mirror. A
// style's `shape` wins, as given. A part of several pieces (a trough of
// keys, a split key, a segmented control) takes them on its outer corners;
// the joins stay. Read on screen: a corner is square where the part's paint
// reaches into it, round where it is cut away.
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gloss_ui/gloss_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;

const _shotKey = ValueKey('shot');

// Only the top start corner round (large); the others square.
const _start = RawCorners.only(topStart: RawCorner.large);

// The top start and the bottom end square; the other two the part's own.
const _diagonal = RawCorners(
  topStart: RawCorner.none,
  bottomEnd: RawCorner.none,
);

GlossStyle _cut(RawCorners corners) =>
    GlossStyle(corners: WidgetStatePropertyAll(corners));

void _none() {}

void _ignore(Object? _) {}

const _places = [
  GlossDestination(icon: LucideIcons.chefHat, label: 'Recipes'),
  GlossDestination(icon: LucideIcons.calendarDays, label: 'Plan'),
];

Future<void> _show(
  WidgetTester tester,
  Widget part,
  TextDirection direction, {
  Brightness brightness = Brightness.light,
}) async {
  tester.view.physicalSize = const Size(720, 560);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  // A fresh tree: nothing left open from the last part.
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, app) => GlossHost(
        theme: GlossThemeData.light(),
        darkTheme: GlossThemeData.dark(),
        brightness: brightness,
        child: Directionality(textDirection: direction, child: app!),
      ),
      home: Center(
        child: RepaintBoundary(
          key: _shotKey,
          child: Padding(padding: const EdgeInsets.all(32), child: part),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

// Whether each screen corner of [rect] (top left, top right, bottom left,
// bottom right) is round: its paint 1.5 px in, against the paint at that
// depth a little along the same edge (a quarter in, half the height at
// least, inside a pill's straight run).
Future<List<bool>> _roundCorners(
  WidgetTester tester,
  Rect rect, {
  double least = 100,
}) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_shotKey),
  );
  final origin = boundary.localToGlobal(Offset.zero);
  final shot = await tester.runAsync(() async {
    final image = await boundary.toImage();
    final bytes = (await image.toByteData())!;
    final width = image.width;
    image.dispose();
    return (bytes, width);
  });
  final (ByteData bytes, int width) = shot!;
  double alpha(double x, double y) {
    final px = (x - origin.dx).floor(), py = (y - origin.dy).floor();
    return bytes.getUint8(4 * (py * width + px) + 3).toDouble();
  }

  const d = 1.5;
  final along = math.min(
    math.max(rect.width / 4, rect.height / 2),
    rect.width / 2,
  );
  bool round(double x, double y, double refX) {
    final ref = alpha(refX, y);
    expect(ref, greaterThan(least), reason: 'paint along the edge at $refX');
    final ratio = alpha(x, y) / ref;
    expect(
      ratio < 0.5 || ratio > 0.7,
      isTrue,
      reason:
          'a corner reads clearly round or square (${ratio.toStringAsFixed(2)})',
    );
    return ratio < 0.5;
  }

  return [
    round(rect.left + d, rect.top + d, rect.left + along),
    round(rect.right - d, rect.top + d, rect.right - along),
    round(rect.left + d, rect.bottom - d, rect.left + along),
    round(rect.right - d, rect.bottom - d, rect.right - along),
  ];
}

// The round screen corners [cut] leaves in [direction]: top left, top right,
// bottom left, bottom right.
List<bool> _expected(RawCorners? cut, TextDirection direction) {
  final ltr = direction == TextDirection.ltr;
  if (cut == null) return [true, true, true, true];
  if (cut == _start) return [ltr, !ltr, false, false];
  return [!ltr, ltr, ltr, !ltr];
}

bool _isSurface(Widget w) => w is GlossSurface || w is AnimatedGlossSurface;

Finder _surfaces() => find.descendant(
  of: find.byKey(_shotKey),
  matching: find.byWidgetPredicate(_isSurface),
);

Rect _firstSurface(WidgetTester tester) => tester.getRect(_surfaces().first);

Rect _allSurfaces(WidgetTester tester) => _surfaces()
    .evaluate()
    .map((e) => tester.getRect(find.byElementPredicate((x) => x == e)))
    .reduce((a, b) => a.expandToInclude(b));

Rect _painted(WidgetTester tester, String painter, {double inset = 0}) => tester
    .getRect(
      find
          .descendant(
            of: find.byKey(_shotKey),
            matching: find.byWidgetPredicate(
              (w) =>
                  w is CustomPaint &&
                  w.painter.runtimeType.toString() == painter,
            ),
          )
          .first,
    )
    .deflate(inset);

typedef _Part = (
  Widget Function(GlossStyle style) build,
  Rect Function(WidgetTester tester) outline,
);

// The parts drawn as a glazed face, each with the outline that carries its
// corners (a trough for a group, both halves for a split key).
final Map<String, _Part> _faces = {
  'gel key': (
    (s) => GlossButton.filled('Cook this', onPressed: _none, style: s),
    _firstSurface,
  ),
  'pearl key': (
    (s) => GlossButton('Share', onPressed: _none, style: s),
    _firstSurface,
  ),
  'icon bead': (
    (s) => GlossIconButton(
      onPressed: _none,
      icon: const Icon(LucideIcons.heart),
      tooltip: 'Save',
      style: s,
    ),
    _firstSurface,
  ),
  'text field': (
    (s) => SizedBox(
      width: 260,
      child: GlossTextField(labelText: 'Name', style: s),
    ),
    _firstSurface,
  ),
  'search field': (
    (s) => SizedBox(
      width: 260,
      child: GlossSearchField(hintText: 'Search', style: s),
    ),
    _firstSurface,
  ),
  'password field': (
    (s) => SizedBox(
      width: 260,
      child: GlossPasswordField(labelText: 'Password', style: s),
    ),
    _firstSurface,
  ),
  'input group': (
    (s) => SizedBox(
      width: 260,
      child: GlossInputGroup(labelText: 'Weight', suffixText: 'g', style: s),
    ),
    _firstSurface,
  ),
  'code cell': (
    (s) => GlossOtpField(semanticLabel: 'Code', length: 4, style: s),
    _firstSurface,
  ),
  'select': (
    (s) => SizedBox(
      width: 260,
      child: GlossSelect<String>(
        labelText: 'Course',
        value: 'main',
        onChanged: _ignore,
        items: const [GlossSelectItem(value: 'main', label: 'Main')],
        style: s,
      ),
    ),
    _firstSurface,
  ),
  'combobox': (
    (s) => SizedBox(
      width: 260,
      child: GlossCombobox<String>(
        labelText: 'Ingredient',
        options: const ['Basil'],
        style: s,
      ),
    ),
    _firstSurface,
  ),
  'tag input': (
    (s) => SizedBox(
      width: 260,
      child: GlossTagInput<String>(
        labelText: 'Tags',
        values: const ['Quick'],
        onChanged: _ignore,
        options: const ['Quick'],
        style: s,
      ),
    ),
    _firstSurface,
  ),
  'checkbox': (
    (s) => GlossCheckbox(
      value: true,
      onChanged: _ignore,
      semanticLabel: 'Bought',
      style: s,
    ),
    (t) => _painted(t, '_SocketPainter'),
  ),
  'chip': (
    (s) => GlossChip(
      label: 'Quick',
      selected: false,
      onSelected: _ignore,
      style: s,
    ),
    _firstSurface,
  ),
  'segmented control': (
    (s) => SizedBox(
      width: 300,
      child: GlossSegmentedButton<int>(
        selected: 0,
        onChanged: _ignore,
        segments: const [
          GlossSegment(value: 0, label: 'Week'),
          GlossSegment(value: 1, label: 'Month'),
        ],
        style: s,
      ),
    ),
    _firstSurface,
  ),
  'button group': (
    (s) => GlossButtonGroup(
      items: const [
        GlossButtonGroupItem(label: 'Halve', onPressed: _none),
        GlossButtonGroupItem(label: 'Double', onPressed: _none),
      ],
      style: s,
    ),
    _firstSurface,
  ),
  'toggle group': (
    (s) => GlossToggleGroup<String>(
      semanticLabel: 'Diet',
      toggles: const [
        GlossToggle(value: 'veg', label: 'Veg'),
        GlossToggle(value: 'gf', label: 'GF'),
      ],
      selected: const {'veg'},
      onSelectionChanged: _ignore,
      style: s,
    ),
    _firstSurface,
  ),
  'split key': (
    (s) => GlossSplitButton.filled(
      label: 'Plan',
      onPressed: _none,
      actions: const [GlossSplitAction(label: 'Friday', onPressed: _none)],
      style: s,
    ),
    _allSurfaces,
  ),
  'pagination': (
    (s) => GlossPagination(
      page: 1,
      pageCount: 5,
      onPageChanged: _ignore,
      style: s,
    ),
    _firstSurface,
  ),
  'keycap': ((s) => GlossKbd('Ctrl K', style: s), _firstSurface),
  'card': (
    (s) => SizedBox(
      width: 260,
      height: 120,
      child: GlossCard(style: s, child: const Text('Lemon risotto')),
    ),
    _firstSurface,
  ),
  'banner': (
    (s) => SizedBox(
      width: 320,
      child: GlossBanner(title: 'Sync is paused', style: s),
    ),
    _firstSurface,
  ),
  'table': (
    (s) => SizedBox(
      width: 320,
      child: GlossTable(
        columns: const [GlossTableColumn('Ingredient')],
        rows: const [
          ['Rice'],
        ],
        style: s,
      ),
    ),
    _firstSurface,
  ),
  'avatar': (
    (s) => GlossAvatar(name: 'Noa Ferreira', size: 48, style: s),
    _firstSurface,
  ),
  'badge': (
    (s) => GlossBadge(
      count: 12,
      style: s,
      child: const SizedBox.square(dimension: 32),
    ),
    _firstSurface,
  ),
  'tag': ((s) => GlossTag('Quick', style: s), _firstSurface),
  'meter': (
    (s) => SizedBox(
      width: 260,
      child: GlossMeter(value: 0.6, label: 'Pantry', style: s),
    ),
    _firstSurface,
  ),
  'progress bar': (
    (s) => SizedBox(
      width: 260,
      child: GlossProgressBar(
        value: 0.4,
        semanticLabel: 'Upload',
        height: 14,
        style: s,
      ),
    ),
    _firstSurface,
  ),
  'chart tray': (
    (s) => SizedBox(
      width: 320,
      child: GlossBarChart(
        semanticLabel: 'Cooked',
        labels: const ['Mon', 'Tue'],
        series: const [
          GlossSeries('Cooked', [2, 3]),
        ],
        style: s,
      ),
    ),
    _firstSurface,
  ),
  'command palette': (
    (s) => SizedBox(
      width: 360,
      height: 260,
      child: GlossCommandPalette(
        commands: [const GlossCommand(label: 'Find', onPressed: _none)],
        style: s,
      ),
    ),
    _firstSurface,
  ),
  'menu row': (
    (s) => SizedBox(
      width: 220,
      child: GlossMenuRow(
        label: 'Share',
        states: const {WidgetState.hovered},
        style: s,
      ),
    ),
    _firstSurface,
  ),
  'list row': (
    (s) => SizedBox(
      width: 300,
      child: GlossListTile(
        title: 'Reminders',
        selected: true,
        onTap: _none,
        style: s,
      ),
    ),
    (t) => _painted(t, '_RowPainter', inset: 4),
  ),
};

// The corners every face and glaze under the shot was given (start on the
// left, as a face is laid): the parts whose shape shows only lit (a word
// key's glaze, a link's, a tab's) or only open (a popover, a tooltip).
List<BorderRadius> _given(WidgetTester tester) => [
  for (final e
      in find
          .byWidgetPredicate((w) => _isSurface(w) || w is GlossGlazeHighlight)
          .evaluate())
    ?switch (e.widget) {
      final GlossSurface w => w.face.corners,
      final AnimatedGlossSurface w => w.face.corners,
      final GlossGlazeHighlight w => w.corners,
      _ => null,
    },
];

void _expectGiven(List<BorderRadius> given, RawCorners cut) {
  expect(given, isNotEmpty, reason: 'the corners reach the part');
  for (final r in given) {
    if (cut == _start) {
      expect(r.topLeft.x, greaterThan(0));
      expect([
        r.topRight,
        r.bottomLeft,
        r.bottomRight,
      ], everyElement(Radius.zero));
    } else {
      expect([r.topLeft, r.bottomRight], everyElement(Radius.zero));
      expect(r.topRight.x, greaterThan(0));
      expect(r.bottomLeft.x, greaterThan(0));
    }
  }
}

typedef _Lit = (
  Widget Function(GlossStyle style) build,
  Future<void> Function(WidgetTester tester)? open,
);

final Map<String, _Lit> _lit = {
  'word key': (
    (s) => GlossButton.text('Skip', onPressed: _none, style: s),
    null,
  ),
  'plain icon key': (
    (s) => GlossIconButton.plain(
      onPressed: _none,
      icon: const Icon(LucideIcons.x),
      tooltip: 'Clear',
      style: s,
    ),
    null,
  ),
  'link': ((s) => GlossLink('Method', onPressed: _none, style: s), null),
  'breadcrumb': (
    (s) => GlossBreadcrumb(
      crumbs: const [
        GlossCrumb('Recipes', onPressed: _none),
        GlossCrumb('Risotto'),
      ],
      style: s,
    ),
    null,
  ),
  'disclosure': (
    (s) => SizedBox(
      width: 300,
      child: GlossDisclosure(
        title: 'Storage',
        style: s,
        child: const Text('Cool'),
      ),
    ),
    null,
  ),
  'tab': (
    (s) => SizedBox(
      width: 300,
      child: GlossTabBar(
        tabs: const ['Method', 'Ingredients'],
        selectedIndex: 0,
        onTap: _ignore,
        style: s,
      ),
    ),
    null,
  ),
  'navigation bar pocket': (
    (s) => SizedBox(
      width: 400,
      child: GlossNavigationBar(
        destinations: _places,
        selectedIndex: 0,
        onDestinationSelected: _ignore,
        style: s,
      ),
    ),
    null,
  ),
  'popover': (
    (s) => GlossPopover(
      style: s,
      builder: (context, toggle, open) =>
          GlossButton('Share', onPressed: toggle),
      content: (context, close) => const Text('Share Lemon risotto'),
    ),
    (tester) async {
      await tester.tap(find.text('Share'));
      await tester.pumpAndSettle();
    },
  ),
  'tooltip': (
    (s) => GlossTooltip(
      message: 'Save',
      style: s,
      child: const SizedBox.square(dimension: 40),
    ),
    (tester) async {
      await tester.longPress(find.byType(SizedBox).last);
      await tester.pumpAndSettle();
    },
  ),
};

void main() {
  setUpAll(glossLoadFonts);

  test('every corner of a Gloss part may take its own step', () {
    expect(
      GlossThemeData.shapeLimits.cornerFreedom,
      RawCornerFreedom.perCorner,
    );
    // Each corner as given, held to nothing: every step is open.
    const given = RawCorners(
      topStart: RawCorner.full,
      topEnd: RawCorner.none,
      bottomEnd: RawCorner.extraLarge,
    );
    expect(
      GlossThemeData.shapeLimits.clampCorners(
        given,
        base: const RawCorners.all(RawCorner.small),
        look: 'Gloss',
      ),
      const RawCorners(
        topStart: RawCorner.full,
        topEnd: RawCorner.none,
        bottomStart: RawCorner.small,
        bottomEnd: RawCorner.extraLarge,
      ),
    );
  });

  for (final MapEntry(key: name, value: (build, outline)) in _faces.entries) {
    testWidgets('a $name takes its style\'s corners, mirrored right to left', (
      tester,
    ) async {
      for (final direction in TextDirection.values) {
        for (final cut in [null, _start, _diagonal]) {
          await _show(
            tester,
            build(cut == null ? const GlossStyle() : _cut(cut)),
            direction,
          );
          expect(
            await _roundCorners(tester, outline(tester)),
            // A code reads left to right in any app; its cells are the
            // app's porcelain, mirrored as every part is.
            _expected(cut, direction),
            reason: '${cut ?? 'its own corners'}, ${direction.name}',
          );
        }
      }
    });
  }

  for (final MapEntry(key: name, value: (build, open)) in _lit.entries) {
    testWidgets('a $name takes its style\'s corners', (tester) async {
      for (final direction in TextDirection.values) {
        for (final cut in [_start, _diagonal]) {
          await _show(tester, build(_cut(cut)), direction);
          await open?.call(tester);
          _expectGiven(_given(tester), cut);
        }
      }
    });
  }

  testWidgets(
    "a word key's glaze follows its corners, mirrored right to left",
    (tester) async {
      for (final direction in TextDirection.values) {
        final focus = FocusNode();
        addTearDown(focus.dispose);
        FocusManager.instance.highlightStrategy =
            FocusHighlightStrategy.alwaysTraditional;
        addTearDown(
          () => FocusManager.instance.highlightStrategy =
              FocusHighlightStrategy.automatic,
        );
        await _show(
          tester,
          GlossButton.text(
            'Skip this step',
            onPressed: _none,
            focusNode: focus,
            style: _cut(_start),
          ),
          direction,
          brightness: Brightness.dark,
        );
        focus.requestFocus();
        await tester.pumpAndSettle();
        final glaze = tester.getRect(
          find.descendant(
            of: find.byKey(_shotKey),
            matching: find.byType(GlossGlazeHighlight),
          ),
        );
        expect(
          await _roundCorners(tester, glaze, least: 20),
          _expected(_start, direction),
          reason: direction.name,
        );
      }
    },
  );

  testWidgets("a style's shape wins, as given, outside Gloss's bands", (
    tester,
  ) async {
    // Corners 3 (under the small band's 8) win over the style's corners.
    await _show(
      tester,
      const GlossButton(
        'Share',
        onPressed: _none,
        style: GlossStyle(
          corners: WidgetStatePropertyAll(RawCorners.all(RawCorner.none)),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(3)),
            ),
          ),
        ),
      ),
      TextDirection.ltr,
    );
    expect(_given(tester), isNotEmpty);
    expect(_given(tester), everyElement(BorderRadius.circular(3)));
    // A shape's physical corner keeps its side right to left: the top left.
    for (final direction in TextDirection.values) {
      await _show(
        tester,
        const GlossButton(
          'Share',
          onPressed: _none,
          style: GlossStyle(
            corners: WidgetStatePropertyAll(RawCorners.all(RawCorner.full)),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.only(topLeft: Radius.circular(20)),
              ),
            ),
          ),
        ),
        direction,
      );
      expect(await _roundCorners(tester, _firstSurface(tester)), [
        true,
        false,
        false,
        false,
      ], reason: direction.name);
    }
  });

  testWidgets("an app's corners are drawn in the theme's scale", (
    tester,
  ) async {
    // A theme whose large step is 22 (Gloss's own is 18).
    final theme = GlossThemeData.light().copyWith(
      shapeScheme: GlossThemeData.defaultShapeScheme.copyWith(
        corners: GlossThemeData.defaultShapeScheme.corners.copyWith(large: 22),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, app) => GlossHost(theme: theme, child: app!),
        home: Center(
          child: SizedBox(
            width: 260,
            height: 120,
            child: GlossCard(
              style: _cut(_start),
              child: const Text('Lemon risotto'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(_given(tester), isNotEmpty);
    expect(
      _given(tester),
      everyElement(const BorderRadius.only(topLeft: Radius.circular(22))),
    );
  });

  testWidgets("a fill's tip keeps its own round end short of the groove's end", (
    tester,
  ) async {
    for (final direction in TextDirection.values) {
      for (final (value, square) in [(0.5, false), (1.0, true)]) {
        await _show(
          tester,
          SizedBox(
            width: 260,
            child: GlossMeter(
              value: value,
              label: 'Pantry',
              style: _cut(_diagonal),
            ),
          ),
          direction,
        );
        // The gel is the last face; laid from the start, its end on the right.
        final gel = _given(tester).last;
        expect(gel.topLeft, Radius.zero, reason: 'its start meets the groove');
        expect(gel.topRight.x, 5, reason: 'its tip is round by its height');
        expect(
          gel.bottomRight.x,
          square ? 0 : 5,
          reason: square
              ? "at the end it takes the groove's square corner"
              : 'short of the end its tip keeps its own',
        );
      }
    }
  });

  testWidgets("a trough's keys take its outer corners; the joins stay", (
    tester,
  ) async {
    for (final direction in TextDirection.values) {
      await _show(
        tester,
        GlossButtonGroup(
          items: const [
            GlossButtonGroupItem(label: 'Halve', onPressed: _none),
            GlossButtonGroupItem(label: 'Third', onPressed: _none),
            GlossButtonGroupItem(label: 'Double', onPressed: _none),
          ],
          style: _cut(_start),
        ),
        direction,
      );
      final trough =
          (tester.widget(_surfaces().first) as GlossSurface).face.corners!;
      // Each key a face that moves (it draws itself as a surface inside).
      final keys = [
        for (final e
            in find
                .descendant(
                  of: find.byKey(_shotKey),
                  matching: find.byType(AnimatedGlossSurface),
                )
                .evaluate())
          (e.widget as AnimatedGlossSurface).face,
      ];
      expect(keys, hasLength(3));
      final first = keys[0].corners!, middle = keys[1], last = keys[2].corners!;
      final large = GlossThemeData.light().shapeScheme.corners.large;
      final inset =
          tester.getRect(_surfaces().at(1)).top -
          tester.getRect(_surfaces().first).top;
      // The first key's top start is the large step; the trough runs
      // concentric outside it, as far out as the key stands in.
      expect(first.topLeft, Radius.circular(large));
      expect(trough.topLeft, Radius.circular(large + inset));
      expect(trough.topRight, Radius.zero);
      // The joins keep the keys' own corners, the middle key all four.
      final own = GlossThemeData.light().shapeScheme.corners.small;
      expect(first.topRight, Radius.circular(own));
      expect(last.topLeft, Radius.circular(own));
      expect(last.topRight, Radius.zero);
      expect(middle.corners, BorderRadius.circular(own));
    }
  });

  testWidgets("a split key's ends are round right to left too", (tester) async {
    // Its main half's outer side was the seam's: square at the ends.
    await _show(
      tester,
      const GlossSplitButton.filled(
        label: 'Plan',
        onPressed: _none,
        actions: [GlossSplitAction(label: 'Friday', onPressed: _none)],
      ),
      TextDirection.rtl,
    );
    expect(await _roundCorners(tester, _allSurfaces(tester)), [
      true,
      true,
      true,
      true,
    ]);
  });

  testWidgets("the segmented control's thumb eases to an end's corners", (
    tester,
  ) async {
    Widget control(int selected) => SizedBox(
      width: 300,
      child: GlossSegmentedButton<int>(
        selected: selected,
        onChanged: _ignore,
        segments: const [
          GlossSegment(value: 0, label: 'Week'),
          GlossSegment(value: 1, label: 'Month'),
          GlossSegment(value: 2, label: 'Year'),
        ],
        style: _cut(const RawCorners.all(RawCorner.none)),
      ),
    );
    BorderRadius thumb() =>
        (tester.widget(_surfaces().at(1)) as GlossSurface).face.corners!;
    await _show(tester, control(0), TextDirection.ltr);
    expect(thumb().topLeft, Radius.zero);
    final own = thumb().topRight.x;
    expect(own, greaterThan(10));
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, app) =>
            GlossHost(theme: GlossThemeData.light(), child: app!),
        home: Center(
          child: RepaintBoundary(
            key: _shotKey,
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: control(1),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 40));
    // On its way from the start to the middle: its start corner between
    // the square end's and its own.
    final moving = thumb().topLeft.x;
    expect(moving, greaterThan(0));
    expect(moving, lessThan(own));
    await tester.pumpAndSettle();
    expect(thumb().topLeft.x, own);
    expect(thumb().topRight.x, own);
  });

  test("a face moves between its own corners and an app's with no snap", () {
    final c = const GlossColors.light();
    final round = GlossFace.pearl(c, radius: 12);
    final square = round.copyWith(corners: BorderRadius.zero);
    final mid = GlossFace.lerp(round, square, 0.5).corners!;
    expect(mid.topLeft.x, greaterThan(0));
    expect(mid.topLeft.x, lessThan(12));
    expect(GlossFace.lerp(round, square, 0).corners!.topLeft.x, 12);
    // From a capsule: past a control's half height, still a pill, then in.
    final pill = GlossFace.pearl(c);
    final nine = pill.copyWith(corners: BorderRadius.circular(9));
    final early = GlossFace.lerp(pill, nine, 0.2).corners!.topLeft.x;
    final late = GlossFace.lerp(pill, nine, 0.8).corners!.topLeft.x;
    expect(early, greaterThan(24));
    expect(early, lessThan(glossFullCorner));
    expect(late, greaterThan(9));
    expect(late, lessThan(24));
  });
}

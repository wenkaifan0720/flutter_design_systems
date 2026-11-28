// A part's own corners (F17): a style's `corners` take a step per corner,
// held to Minimal's steps over the part's own and drawn in the theme's
// scale; start and end turn with the reading direction; composites take them
// on their outer corners only, their keys concentric; a sheet's foot and a
// side sheet's outer edge stay square; a style's `shape` wins.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

final MinimalThemeData _look = MinimalThemeData.preset(
  'standard',
  Brightness.light,
);

const Key _part = Key('part');

void _tap() {}

Widget _host(
  Widget child, {
  MinimalThemeData? theme,
  TextDirection direction = TextDirection.ltr,
}) => MaterialApp(
  builder: (context, navigator) => Directionality(
    textDirection: direction,
    child: MinimalHost(
      light: theme ?? _look,
      dark: theme ?? _look,
      brightness: Brightness.light,
      child: navigator!,
    ),
  ),
  home: Scaffold(
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: KeyedSubtree(key: _part, child: child),
      ),
    ),
  ),
);

/// Every outline the part paints, behind its content and over it, and the
/// slot a slider's painter draws its track in.
List<ShapeBorder> _outlines(WidgetTester tester) => [
  for (final box in tester.widgetList<DecoratedBox>(
    find.descendant(of: find.byKey(_part), matching: find.byType(DecoratedBox)),
  ))
    if (box.decoration case ShapeDecoration(:final shape)) shape,
  for (final paint in tester.widgetList<CustomPaint>(
    find.descendant(of: find.byKey(_part), matching: find.byType(CustomPaint)),
  ))
    ?_slot(paint.painter),
];

ShapeBorder? _slot(CustomPainter? painter) {
  try {
    // A slider's track painter names the slot it draws in.
    return (painter as dynamic).slot as ShapeBorder?;
    // ignore: avoid_catching_errors
  } on NoSuchMethodError {
    return null;
  }
}

/// [b] with no stroke, to compare outlines alone.
ShapeBorder _bare(ShapeBorder b) =>
    b is OutlinedBorder ? b.copyWith(side: BorderSide.none) : b;

bool _draws(WidgetTester tester, ShapeBorder want) =>
    _outlines(tester).any((o) => _bare(o) == _bare(want));

MinimalStyle _with(RawCorners c) =>
    MinimalStyle(corners: WidgetStatePropertyAll<RawCorners?>(c));

RawCornerBorder _expect(MinimalThemeData t, RawCorners cut, RawCorner own) =>
    t.shapeScheme.corners.borderOf(
      MinimalThemeData.shapeLimits.clampCorners(cut, base: RawCorners.all(own)),
    );

const _cutA = RawCorners(topStart: RawCorner.none, bottomEnd: RawCorner.none);
const _cutB = RawCorners(topEnd: RawCorner.none, bottomStart: RawCorner.full);
const _topStart = RawCorners.only(topStart: RawCorner.large);

typedef _Part = ({Widget Function(MinimalStyle s) build, RawCorner own});

_Part _p(Widget Function(MinimalStyle s) build, RawCorner own) =>
    (build: build, own: own);

/// The parts whose face a style shapes, with their own step.
final Map<String, _Part> _parts = {
  'MinimalButton': _p(
    (s) => MinimalButton('Save', onPressed: _tap, style: s),
    RawCorner.small,
  ),
  'MinimalIconButton': _p(
    (s) => MinimalIconButton(
      LucideIcons.x,
      semanticLabel: 'Close',
      onPressed: _tap,
      variant: MinimalIconButtonVariant.outline,
      style: s,
    ),
    RawCorner.small,
  ),
  'MinimalChip': _p(
    (s) => MinimalChip('Open', onPressed: _tap, style: s),
    RawCorner.full,
  ),
  'MinimalCheckbox': _p(
    (s) => MinimalCheckbox(value: true, onChanged: (_) {}, style: s),
    RawCorner.extraSmall,
  ),
  'MinimalSwitch': _p(
    (s) => MinimalSwitch(value: true, onChanged: (_) {}, style: s),
    RawCorner.full,
  ),
  'MinimalCard': _p(
    (s) => MinimalCard(onPressed: _tap, style: s, child: const Text('Plan')),
    RawCorner.medium,
  ),
  'MinimalTextField': _p(
    (s) => SizedBox(
      width: 240,
      child: MinimalTextField(labelText: 'Name', fieldStyle: s),
    ),
    RawCorner.small,
  ),
  'MinimalTextArea': _p(
    (s) => SizedBox(
      width: 240,
      child: MinimalTextArea(labelText: 'Notes', fieldStyle: s),
    ),
    RawCorner.small,
  ),
  'MinimalPasswordField': _p(
    (s) => SizedBox(
      width: 240,
      child: MinimalPasswordField(labelText: 'Password', fieldStyle: s),
    ),
    RawCorner.small,
  ),
  'MinimalInputGroup': _p(
    (s) => SizedBox(
      width: 320,
      child: MinimalInputGroup(
        labelText: 'Website',
        prefixText: 'https://',
        style: s,
      ),
    ),
    RawCorner.small,
  ),
  'MinimalCombobox': _p(
    (s) => SizedBox(
      width: 320,
      child: MinimalCombobox<String>(
        labelText: 'City',
        options: const ['Lisbon', 'London'],
        displayStringForOption: (c) => c,
        onSelected: (_) {},
        fieldStyle: s,
      ),
    ),
    RawCorner.small,
  ),
  'MinimalSegmentedButton': _p(
    (s) => MinimalSegmentedButton<int>(
      segments: const [
        MinimalButtonSegment(0, 'Day'),
        MinimalButtonSegment(1, 'Week'),
        MinimalButtonSegment(2, 'Month'),
      ],
      value: 0,
      semanticLabel: 'Range',
      onChanged: (_) {},
      style: s,
    ),
    RawCorner.small,
  ),
  'MinimalToggleGroup': _p(
    (s) => MinimalToggleGroup<String>(
      semanticLabel: 'View',
      selected: const {'list'},
      onSelectionChanged: (_) {},
      items: const [
        MinimalToggleItem('list', label: 'List'),
        MinimalToggleItem('board', label: 'Board'),
      ],
      style: s,
    ),
    RawCorner.small,
  ),
  'MinimalButtonGroup': _p(
    (s) => MinimalButtonGroup(
      items: const [
        MinimalButtonGroupItem(label: 'Day', onPressed: _tap),
        MinimalButtonGroupItem(label: 'Week', onPressed: _tap),
      ],
      style: s,
    ),
    RawCorner.small,
  ),
  'MinimalSplitButton': _p(
    (s) => MinimalSplitButton(
      'Save',
      onPressed: _tap,
      actions: const [MinimalMenuItem('Save as…', onPressed: _tap)],
      style: s,
    ),
    RawCorner.small,
  ),
  'MinimalMenuBar': _p(
    (s) => MinimalMenuBar(
      menus: const [
        MinimalMenuEntry(
          'File',
          children: [MinimalMenuEntry('New', onPressed: _tap)],
        ),
        MinimalMenuEntry(
          'Edit',
          children: [MinimalMenuEntry('Undo', onPressed: _tap)],
        ),
      ],
      style: s,
    ),
    RawCorner.small,
  ),
  'MinimalBadge': _p((s) => MinimalBadge(count: 3, style: s), RawCorner.full),
  'MinimalBanner': _p(
    (s) => MinimalBanner(title: 'Heads up', style: s),
    RawCorner.medium,
  ),
  'MinimalSnackBar': _p(
    (s) => MinimalSnackBar('Saved', style: s),
    RawCorner.medium,
  ),
  'MinimalDialog': _p(
    (s) => MinimalDialog(title: 'Delete?', style: s),
    RawCorner.large,
  ),
  'MinimalSlider': _p(
    (s) => SizedBox(
      width: 240,
      child: MinimalSlider(
        label: 'Volume',
        value: 0.5,
        onChanged: (_) {},
        style: s,
      ),
    ),
    RawCorner.full,
  ),
  'MinimalRangeSlider': _p(
    (s) => SizedBox(
      width: 240,
      child: MinimalRangeSlider(
        label: 'Price',
        values: const RawRangeValues(0.2, 0.8),
        onChanged: (_) {},
        style: s,
      ),
    ),
    RawCorner.full,
  ),
};

void main() {
  for (final MapEntry(key: name, value: part) in _parts.entries) {
    for (final direction in TextDirection.values) {
      for (final (label, cut) in [
        ('two diagonal corners square', _cutA),
        ('the other diagonal: square and capsule', _cutB),
        ('the top start large alone', _topStart),
      ]) {
        testWidgets('$name, ${direction.name}: $label', (tester) async {
          await tester.pumpWidget(
            _host(part.build(_with(cut)), direction: direction),
          );
          await tester.pumpAndSettle();
          expect(
            _draws(tester, _expect(_look, cut, part.own)),
            isTrue,
            reason: _outlines(tester).map(_bare).join('\n'),
          );
        });
      }
    }
  }

  testWidgets('start and end turn with the reading direction', (tester) async {
    Future<Path> drawn(TextDirection direction) async {
      await tester.pumpWidget(
        _host(
          MinimalButton('Save', onPressed: _tap, style: _with(_cutA)),
          direction: direction,
        ),
      );
      await tester.pumpAndSettle();
      final box = tester
          .widgetList<DecoratedBox>(
            find.descendant(
              of: find.byKey(_part),
              matching: find.byType(DecoratedBox),
            ),
          )
          .firstWhere((b) => b.decoration is ShapeDecoration);
      final shape = (box.decoration as ShapeDecoration).shape;
      return shape.getOuterPath(
        const Rect.fromLTWH(0, 0, 80, 32),
        textDirection: direction,
      );
    }

    final ltr = await drawn(TextDirection.ltr);
    expect(ltr.contains(const Offset(0.5, 0.5)), isTrue);
    expect(ltr.contains(const Offset(79.5, 0.5)), isFalse);
    expect(ltr.contains(const Offset(79.5, 31.5)), isTrue);
    final rtl = await drawn(TextDirection.rtl);
    expect(rtl.contains(const Offset(79.5, 0.5)), isTrue);
    expect(rtl.contains(const Offset(0.5, 0.5)), isFalse);
    expect(rtl.contains(const Offset(0.5, 31.5)), isTrue);
  });

  testWidgets("a corner a style leaves keeps the part's own", (tester) async {
    await tester.pumpWidget(
      _host(
        MinimalCard(
          style: _with(const RawCorners(topStart: RawCorner.large)),
          child: const Text('Plan'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final want = _look.shapeScheme.corners.borderOf(
      const RawCorners(
        topStart: RawCorner.large,
        topEnd: RawCorner.medium,
        bottomStart: RawCorner.medium,
        bottomEnd: RawCorner.medium,
      ),
    );
    expect(_draws(tester, want), isTrue);
  });

  testWidgets("the corners follow the theme's scale", (tester) async {
    final rounder = _look.copyWith(
      shapeScheme: const MinimalShapes(radius: 12).scheme,
    );
    await tester.pumpWidget(
      _host(
        MinimalButton(
          'Save',
          onPressed: _tap,
          style: _with(const RawCorners(topStart: RawCorner.large)),
        ),
        theme: rounder,
      ),
    );
    await tester.pumpAndSettle();
    final shape = _outlines(tester).whereType<RawCornerBorder>().first;
    final r = shape.borderRadius.resolve(TextDirection.ltr);
    expect(
      [r.topLeft.x, r.topRight.x, r.bottomRight.x, r.bottomLeft.x],
      [18, 12, 12, 12],
    );
  });

  testWidgets("a style's shape wins over its corners", (tester) async {
    const bevel = BeveledRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(6)),
    );
    await tester.pumpWidget(
      _host(
        const MinimalButton(
          'Save',
          onPressed: _tap,
          style: MinimalStyle(
            shape: WidgetStatePropertyAll<OutlinedBorder?>(bevel),
            corners: WidgetStatePropertyAll<RawCorners?>(_cutA),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(_outlines(tester).map(_bare), contains(bevel));
    expect(_outlines(tester).whereType<RawCornerBorder>(), isEmpty);
  });

  for (final direction in TextDirection.values) {
    testWidgets(
      'a joined strip takes them on its ends, its cells concentric (${direction.name})',
      (tester) async {
        await tester.pumpWidget(
          _host(
            _parts['MinimalButtonGroup']!.build(_with(_cutA)),
            direction: direction,
          ),
        );
        await tester.pumpAndSettle();
        final scale = _look.shapeScheme.corners;
        final held = MinimalThemeData.shapeLimits.clampCorners(
          _cutA,
          base: const RawCorners.all(RawCorner.small),
        );
        final rim = _look.rim;
        final first = scale
            .borderOf(
              RawCorners(
                topStart: held.topStart,
                bottomStart: held.bottomStart,
              ),
            )
            .inset(EdgeInsets.all(rim));
        final last = scale
            .borderOf(
              RawCorners(topEnd: held.topEnd, bottomEnd: held.bottomEnd),
            )
            .inset(EdgeInsets.all(rim));
        expect(_draws(tester, first), isTrue);
        expect(_draws(tester, last), isTrue);
      },
    );
  }

  testWidgets(
    "a segmented control's thumb takes the strip's corners at its end",
    (tester) async {
      await tester.pumpWidget(
        _host(_parts['MinimalSegmentedButton']!.build(_with(_cutA))),
      );
      await tester.pumpAndSettle();
      final thumb = _look.shapeScheme.corners
          .borderOf(
            const RawCorners(
              topStart: RawCorner.none,
              bottomStart: RawCorner.small,
              topEnd: RawCorner.small,
              bottomEnd: RawCorner.small,
            ),
          )
          // The thumb stands 2 px inside the strip.
          .inset(const EdgeInsets.all(2));
      expect(_draws(tester, thumb), isTrue);
    },
  );

  testWidgets("a drawer sheet's foot stays square", (tester) async {
    await tester.pumpWidget(
      _host(
        SizedBox(
          width: 360,
          height: 240,
          child: MinimalBottomSheet(
            style: _with(const RawCorners.all(RawCorner.extraLarge)),
            child: const Text('Filters'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final want = _look.shapeScheme.corners.borderOf(
      const RawCorners(
        topStart: RawCorner.extraLarge,
        topEnd: RawCorner.extraLarge,
      ),
    );
    expect(_draws(tester, want), isTrue);
  });

  for (final side in [MinimalSide.start, MinimalSide.end]) {
    testWidgets("a side sheet rounds its inner edge alone (${side.name})", (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          SizedBox(
            width: 320,
            height: 400,
            child: MinimalSheet(
              side: side,
              style: _with(const RawCorners.all(RawCorner.large)),
              child: const Text('Filters'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final want = _look.shapeScheme.corners.borderOf(
        side == MinimalSide.start
            ? const RawCorners(
                topEnd: RawCorner.large,
                bottomEnd: RawCorner.large,
              )
            : const RawCorners(
                topStart: RawCorner.large,
                bottomStart: RawCorner.large,
              ),
      );
      expect(_draws(tester, want), isTrue);
    });
  }

  testWidgets('corners that change with a press ease, never snap', (
    tester,
  ) async {
    final style = MinimalStyle(
      corners: WidgetStateProperty.resolveWith<RawCorners?>(
        (s) => s.contains(WidgetState.pressed)
            ? const RawCorners.all(RawCorner.none)
            : const RawCorners.all(RawCorner.large),
      ),
    );
    await tester.pumpWidget(
      _host(MinimalButton('Save', onPressed: _tap, style: style)),
    );
    await tester.pumpAndSettle();
    double radius() {
      final box = tester.renderObject<RenderBox>(find.text('Save'));
      expect(box.hasSize, isTrue);
      final shapes = _outlines(tester).whereType<OutlinedBorder>();
      final r = shapes.map(
        (s) => switch (s) {
          RawCornerBorder(:final borderRadius) =>
            borderRadius.resolve(TextDirection.ltr).topLeft.x,
          RoundedRectangleBorder(:final borderRadius) =>
            borderRadius.resolve(TextDirection.ltr).topLeft.x,
          _ => -1.0,
        },
      );
      return r.first;
    }

    expect(radius(), 14);
    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Save')),
    );
    final seen = <double>[];
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      seen.add(radius());
    }
    await gesture.up();
    await tester.pumpAndSettle();
    expect(seen.last, 0);
    expect(
      seen.where((r) => r > 0 && r < 14),
      isNotEmpty,
      reason: 'it passes through the radii between: $seen',
    );
  });
}

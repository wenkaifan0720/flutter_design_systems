// An app's corners on one part: a style's `corners` name a step per
// corner, held to Fluent 2's steps over the part's own and drawn in the
// theme's scale, start and end as the part reads; a style's `shape` wins as
// given. A joined part takes them on its outer corners alone (a split
// button's act its start ones and its chevron its end ones, an interaction
// tag's words and its dismiss the same, a segmented button's track and the
// segment at either end); where the parts meet stays as Fluent draws it. A
// sheet takes them on its free corners: a bottom sheet's top, a side
// drawer's inner edge.
import 'package:flutter/foundation.dart' show debugPrint, listEquals;
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluent2_design_ui/fluent2_design_ui.dart';

typedef _Part = Widget Function(Fluent2Style? style);

final Map<String, _Part> _parts = {
  'Fluent2Button': (s) => Fluent2Button('Save', style: s, onPressed: () {}),
  'Fluent2Button.circular': (s) => Fluent2Button(
    'Save',
    shape: Fluent2ButtonShape.circular,
    style: s,
    onPressed: () {},
  ),
  'Fluent2IconButton': (s) => Fluent2IconButton(
    Fluent2Icons.share,
    semanticLabel: 'Share',
    appearance: Fluent2ButtonAppearance.secondary,
    style: s,
    onPressed: () {},
  ),
  'Fluent2ToggleButton': (s) =>
      Fluent2ToggleButton('Bold', value: true, style: s, onChanged: (_) {}),
  'Fluent2CompoundButton': (s) => Fluent2CompoundButton(
    'Open',
    secondary: 'The last file',
    style: s,
    onPressed: () {},
  ),
  'Fluent2MenuButton': (s) =>
      Fluent2MenuButton('Sort', style: s, onPressed: () {}),
  'Fluent2Card': (s) =>
      Fluent2Card(style: s, children: const [SizedBox(width: 160, height: 60)]),
  'Fluent2Card.large': (s) => Fluent2Card(
    size: Fluent2CardSize.large,
    style: s,
    onPressed: () {},
    children: const [SizedBox(width: 160, height: 60)],
  ),
  'Fluent2SegmentedButton': (s) => Fluent2SegmentedButton<String>(
    semanticLabel: 'View',
    style: s,
    segments: const [
      Fluent2ButtonSegment('grid', 'Grid'),
      Fluent2ButtonSegment('list', 'List'),
      Fluent2ButtonSegment('map', 'Map'),
    ],
    value: 'list',
    onChanged: (_) {},
  ),
  'Fluent2Tag': (s) => Fluent2Tag('Draft', style: s),
  'Fluent2Tag.dismiss': (s) => Fluent2Tag('Draft', style: s, onDeleted: () {}),
  'Fluent2InteractionTag': (s) =>
      Fluent2InteractionTag('Draft', style: s, onPressed: () {}),
  'Fluent2LabelBadge': (s) => Fluent2LabelBadge(label: 'Draft', style: s),
  'Fluent2Avatar': (s) => Fluent2Avatar(name: 'Kai Tanaka', style: s),
  'Fluent2Switch': (s) => Fluent2Switch(
    value: true,
    semanticLabel: 'Updates',
    style: s,
    onChanged: (_) {},
  ),
  'Fluent2Radio': (s) => Fluent2RadioGroup<int>(
    value: 1,
    onChanged: (_) {},
    options: [Fluent2Radio(1, 'One', style: s)],
  ),
  'Fluent2Checkbox': (s) => Fluent2Checkbox(
    value: true,
    semanticLabel: 'Gift',
    size: Fluent2CheckboxSize.large,
    style: s,
    onChanged: (_) {},
  ),
  'Fluent2Dialog': (s) => Fluent2Dialog(
    title: 'Delete the file?',
    message: 'It goes to the bin.',
    style: s,
  ),
  'Fluent2Menu': (s) => Fluent2Menu<String>(
    style: s,
    items: const [Fluent2MenuItem('a', 'Copy'), Fluent2MenuItem('b', 'Paste')],
    onSelected: (_) {},
  ),
  'Fluent2Toast': (s) => Fluent2Toast('Saved', style: s),
  'Fluent2SheetCard.dialog': (s) => Fluent2SheetCard.dialog(
    style: s,
    child: const SizedBox(width: 200, height: 120),
  ),
  'Fluent2TextField': (s) =>
      Fluent2TextField(semanticLabel: 'Name', hintText: 'Name', style: s),
};

const _cutA = RawCorners(topStart: RawCorner.none, bottomEnd: RawCorner.none);
const _cutB = RawCorners(topEnd: RawCorner.none, bottomStart: RawCorner.none);
const _topStart = RawCorners.only(topStart: RawCorner.large);

Fluent2Style _with(RawCorners c) =>
    Fluent2Style(corners: WidgetStatePropertyAll(c));

const _part = ValueKey('part');

Widget _app(
  Widget part, {
  TextDirection direction = TextDirection.ltr,
  Fluent2ThemeData? theme,
}) => MaterialApp(
  builder: (context, app) => Fluent2Host(
    light: theme ?? Fluent2ThemeData.lapis(),
    brightness: Brightness.light,
    child: app!,
  ),
  home: Directionality(
    textDirection: direction,
    child: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: KeyedSubtree(key: _part, child: part),
      ),
    ),
  ),
);

/// A face drawn under the part: its box on screen and the outline it is
/// drawn with, in its own box.
typedef _Face = ({Rect rect, Path path});

Path? _pathOf(Widget widget, Rect local, TextDirection direction) {
  switch (widget) {
    case DecoratedBox(:final decoration):
      if (decoration is BoxDecoration &&
          decoration.borderRadius == null &&
          decoration.shape == BoxShape.rectangle) {
        return null;
      }
      if (decoration is! BoxDecoration && decoration is! ShapeDecoration) {
        return null;
      }
      return decoration.getClipPath(local, direction);
    case ClipPath(:final ShapeBorderClipper clipper):
      return clipper.shape.getOuterPath(local, textDirection: direction);
    case CustomPaint(:final painter?):
      // A field draws its frame: the corners it is painted with.
      final BorderRadius corners;
      try {
        corners = (painter as dynamic).corners as BorderRadius;
      } on NoSuchMethodError {
        return null;
      }
      final most = local.shortestSide / 2;
      Radius at(Radius r) => Radius.circular(r.x.clamp(0, most).toDouble());
      return Path()..addRRect(
        RRect.fromRectAndCorners(
          local,
          topLeft: at(corners.topLeft),
          topRight: at(corners.topRight),
          bottomLeft: at(corners.bottomLeft),
          bottomRight: at(corners.bottomRight),
        ),
      );
  }
  return null;
}

List<_Face> _faces(WidgetTester tester, [Finder? under]) => [
  for (final e
      in find
          .descendant(
            of: under ?? find.byKey(_part),
            matching: find.byWidgetPredicate(
              (w) => w is DecoratedBox || w is ClipPath || w is CustomPaint,
            ),
          )
          .evaluate())
    if (e.renderObject case final RenderBox box
        when box.hasSize && box.size.shortestSide >= 12)
      if (_pathOf(e.widget, Offset.zero & box.size, Directionality.of(e))
          case final path?)
        (
          rect: MatrixUtils.transformRect(
            box.getTransformTo(null),
            Offset.zero & box.size,
          ),
          path: path,
        ),
];

/// Which corners of [face] are square: top left, top right, bottom left,
/// bottom right (on screen).
List<bool> _square(_Face face) {
  final s = face.rect.size;
  const e = 0.25;
  return [
    face.path.contains(const Offset(e, e)),
    face.path.contains(Offset(s.width - e, e)),
    face.path.contains(Offset(e, s.height - e)),
    face.path.contains(Offset(s.width - e, s.height - e)),
  ];
}

/// The square corners [c] leaves on a part rounded all round, on screen.
List<bool> _expected(RawCorners c, TextDirection d) {
  bool sq(RawCorner? step) => step == RawCorner.none;
  final rtl = d == TextDirection.rtl;
  final (tl, tr, bl, br) = rtl
      ? (c.topEnd, c.topStart, c.bottomEnd, c.bottomStart)
      : (c.topStart, c.topEnd, c.bottomStart, c.bottomEnd);
  return [sq(tl), sq(tr), sq(bl), sq(br)];
}

int _matching(WidgetTester tester, List<bool> want, [Finder? under]) =>
    _faces(tester, under).where((f) => listEquals(_square(f), want)).length;

const _diagonal = <(String, RawCorners)>[
  ('two diagonal cuts', _cutA),
  ('the other diagonal', _cutB),
];

void main() {
  test('Fluent 2 lets a style set a step per corner', () {
    expect(
      Fluent2ThemeData.shapeLimits.cornerFreedom,
      RawCornerFreedom.perCorner,
    );
  });

  group('every shaped part takes a style\'s corners', () {
    for (final MapEntry(key: name, value: build) in _parts.entries) {
      for (final d in TextDirection.values) {
        for (final (what, corners) in _diagonal) {
          testWidgets('$name, ${d.name}: $what', (tester) async {
            final want = _expected(corners, d);
            await tester.pumpWidget(_app(build(null), direction: d));
            await tester.pumpAndSettle();
            expect(
              _matching(tester, want),
              0,
              reason: 'its own corners are rounded all round',
            );
            await tester.pumpWidget(_app(build(_with(corners)), direction: d));
            await tester.pumpAndSettle();
            expect(
              _matching(tester, want),
              greaterThan(0),
              reason:
                  'a face takes the cut corners: ${[for (final f in _faces(tester)) _square(f)]}',
            );
          });
        }
      }
      testWidgets('$name: only the top start corner rounded', (tester) async {
        for (final d in TextDirection.values) {
          await tester.pumpWidget(_app(build(_with(_topStart)), direction: d));
          await tester.pumpAndSettle();
          expect(
            _matching(tester, _expected(_topStart, d)),
            greaterThan(0),
            reason: d.name,
          );
        }
      });
    }
  });

  testWidgets('a style\'s shape wins over its corners', (tester) async {
    await tester.pumpWidget(
      _app(
        Fluent2Button(
          'Save',
          style: const Fluent2Style(
            shape: WidgetStatePropertyAll(StadiumBorder()),
            corners: WidgetStatePropertyAll(_cutA),
          ),
          onPressed: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(_matching(tester, _expected(_cutA, TextDirection.ltr)), 0);
    final faces = _faces(tester);
    expect(
      faces.where((f) => listEquals(_square(f), [false, false, false, false])),
      isNotEmpty,
    );
  });

  group("a style's shape keeps its corners off every part", () {
    for (final MapEntry(key: name, value: build) in _parts.entries) {
      testWidgets(name, (tester) async {
        for (final d in TextDirection.values) {
          await tester.pumpWidget(
            _app(
              build(
                const Fluent2Style(
                  shape: WidgetStatePropertyAll(StadiumBorder()),
                  corners: WidgetStatePropertyAll(_cutA),
                ),
              ),
              direction: d,
            ),
          );
          await tester.pumpAndSettle();
          expect(_matching(tester, _expected(_cutA, d)), 0, reason: d.name);
        }
      });
    }
  });

  testWidgets("a corner's step is drawn in the theme's scale", (tester) async {
    final t = Fluent2ThemeData.lapis().copyWith(
      shapeScheme: const RawShapeScheme(
        corners: RawCornerScale(
          extraSmall: 4,
          small: 8,
          medium: 10,
          large: 12,
          extraLarge: 16,
        ),
      ),
    );
    await tester.pumpWidget(
      _app(
        Fluent2Dialog(
          title: 'Delete the file?',
          style: _with(
            const RawCorners(
              topStart: RawCorner.small,
              bottomEnd: RawCorner.none,
            ),
          ),
        ),
        theme: t,
      ),
    );
    await tester.pumpAndSettle();
    final shape = tester
        .widgetList<DecoratedBox>(
          find.descendant(
            of: find.byType(Fluent2Dialog),
            matching: find.byType(DecoratedBox),
          ),
        )
        .map((b) => b.decoration)
        .whereType<ShapeDecoration>()
        .first
        .shape;
    expect(
      shape,
      t.shapeScheme.corners.borderOf(
        const RawCorners(
          topStart: RawCorner.small,
          topEnd: RawCorner.large,
          bottomStart: RawCorner.large,
          bottomEnd: RawCorner.none,
        ),
        side: (shape as OutlinedBorder).side,
      ),
    );
  });

  group('a joined part takes the corners on its outer ones', () {
    for (final d in TextDirection.values) {
      testWidgets('split button, ${d.name}', (tester) async {
        await tester.pumpWidget(
          _app(
            Fluent2SplitButton(
              'Save',
              style: _with(_cutA),
              onPressed: () {},
              actions: [Fluent2SplitAction('Save a copy', onPressed: () {})],
            ),
            direction: d,
          ),
        );
        await tester.pumpAndSettle();
        final halves = _faces(tester)
          ..sort((a, b) => a.rect.left.compareTo(b.rect.left));
        final rtl = d == TextDirection.rtl;
        final act = rtl ? halves.last : halves.first;
        final chevron = rtl ? halves.first : halves.last;
        // The act: its top start cut, its bottom start its own; the join
        // square. The chevron: its top end its own, its bottom end cut.
        expect(
          _square(act),
          rtl ? [true, true, true, false] : [true, true, false, true],
        );
        expect(
          _square(chevron),
          rtl ? [false, true, true, true] : [true, false, true, true],
        );
      });

      testWidgets('interaction tag with its dismiss, ${d.name}', (
        tester,
      ) async {
        await tester.pumpWidget(
          _app(
            Fluent2InteractionTag(
              'Draft',
              style: _with(_cutB),
              onPressed: () {},
              onDeleted: () {},
            ),
            direction: d,
          ),
        );
        await tester.pumpAndSettle();
        final parts = _faces(tester)
          ..sort((a, b) => a.rect.left.compareTo(b.rect.left));
        final rtl = d == TextDirection.rtl;
        final words = rtl ? parts.last : parts.first;
        final dismiss = rtl ? parts.first : parts.last;
        // _cutB: top end and bottom start square.
        expect(
          _square(words),
          rtl ? [true, false, true, true] : [false, true, true, true],
        );
        expect(
          _square(dismiss),
          rtl ? [true, true, false, true] : [true, true, true, false],
        );
      });

      testWidgets('segmented button: the thumb at an end takes that end\'s, '
          '${d.name}', (tester) async {
        Widget strip(String value) => Fluent2SegmentedButton<String>(
          semanticLabel: 'View',
          style: _with(_cutA),
          segments: const [
            Fluent2ButtonSegment('grid', 'Grid'),
            Fluent2ButtonSegment('list', 'List'),
            Fluent2ButtonSegment('map', 'Map'),
          ],
          value: value,
          onChanged: (_) {},
        );
        await tester.pumpWidget(_app(strip('grid'), direction: d));
        await tester.pumpAndSettle();
        final rtl = d == TextDirection.rtl;
        // The track: the whole cut. The thumb on the first segment: its
        // top start cut, its other corners its own.
        expect(_matching(tester, _expected(_cutA, d)), greaterThan(0));
        expect(
          _matching(
            tester,
            rtl ? [false, true, false, false] : [true, false, false, false],
          ),
          greaterThan(0),
        );
        // In the middle the thumb is its own all round; at the end it takes
        // the bottom end cut, easing there.
        await tester.pumpWidget(_app(strip('map'), direction: d));
        await tester.pump(const Duration(milliseconds: 50));
        await tester.pumpAndSettle();
        expect(
          _matching(
            tester,
            rtl ? [false, false, true, false] : [false, false, false, true],
          ),
          greaterThan(0),
        );
      });
    }
  });

  group('a sheet takes them on its free corners', () {
    for (final d in TextDirection.values) {
      testWidgets('a bottom sheet its top ones, ${d.name}', (tester) async {
        await tester.pumpWidget(
          _app(
            Fluent2SheetCard.bottom(
              style: _with(_cutA),
              child: const SizedBox(width: 240, height: 120),
            ),
            direction: d,
          ),
        );
        await tester.pumpAndSettle();
        final rtl = d == TextDirection.rtl;
        expect(
          _matching(
            tester,
            rtl ? [false, true, true, true] : [true, false, true, true],
          ),
          greaterThan(0),
        );
      });

      testWidgets('a side drawer its inner edge, ${d.name}', (tester) async {
        await tester.pumpWidget(
          _app(
            Fluent2SheetCard.side(
              style: _with(
                const RawCorners(
                  topStart: RawCorner.large,
                  bottomStart: RawCorner.large,
                  topEnd: RawCorner.large,
                ),
              ),
              child: const SizedBox(width: 240, height: 120),
            ),
            direction: d,
          ),
        );
        await tester.pumpAndSettle();
        final rtl = d == TextDirection.rtl;
        // Its start edge rounds; its end edge stays against the window.
        expect(
          _matching(
            tester,
            rtl ? [true, false, true, false] : [false, true, false, true],
          ),
          greaterThan(0),
        );
      });
    }
  });

  testWidgets('a list drawn as a card takes the card theme\'s corners', (
    tester,
  ) async {
    final t = Fluent2ThemeData.lapis().copyWith(cardTheme: _with(_cutA));
    await tester.pumpWidget(
      _app(
        SizedBox(
          width: 320,
          child: Fluent2ListGroup(
            title: 'Mail',
            children: [
              Fluent2ListItem(title: 'Inbox', onTap: () {}),
              Fluent2ListItem(title: 'Sent', onTap: () {}),
            ],
          ),
        ),
        theme: t,
      ),
    );
    await tester.pumpAndSettle();
    expect(
      _matching(tester, _expected(_cutA, TextDirection.ltr)),
      greaterThan(0),
    );
  });

  testWidgets('a tooltip\'s bubble takes them', (tester) async {
    await tester.pumpWidget(
      _app(
        Fluent2Tooltip(
          message: 'Share the file',
          style: _with(_cutA),
          child: Fluent2IconButton(
            Fluent2Icons.share,
            semanticLabel: 'Share',
            onPressed: () {},
          ),
        ),
      ),
    );
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
    await mouse.moveTo(tester.getCenter(find.byType(Fluent2IconButton)));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(find.text('Share the file'), findsOneWidget);
    expect(
      _matching(
        tester,
        _expected(_cutA, TextDirection.ltr),
        find.byType(Fluent2Plate),
      ),
      greaterThan(0),
    );
  });

  testWidgets('corners that change with a press ease there', (tester) async {
    final style = Fluent2Style(
      corners: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.pressed) ? _cutA : null,
      ),
    );
    await tester.pumpWidget(
      _app(Fluent2Button('Save', style: style, onPressed: () {})),
    );
    await tester.pumpAndSettle();
    ShapeBorder face() => tester
        .widgetList<DecoratedBox>(
          find.descendant(
            of: find.byType(Fluent2Button),
            matching: find.byType(DecoratedBox),
          ),
        )
        .map((b) => b.decoration)
        .whereType<ShapeDecoration>()
        .first
        .shape;
    final rest = face();
    final press = await tester.startGesture(
      tester.getCenter(find.byType(Fluent2Button)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    final mid = face();
    await tester.pumpAndSettle();
    final held = face();
    expect(mid, isNot(rest));
    expect(mid, isNot(held));
    expect(
      _matching(tester, _expected(_cutA, TextDirection.ltr)),
      greaterThan(0),
    );
    await press.up();
    await tester.pumpAndSettle();
  });

  testWidgets('a corner override prints nothing: every step is Fluent\'s', (
    tester,
  ) async {
    final printed = <String>[];
    final was = debugPrint;
    debugPrint = (String? m, {int? wrapWidth}) => printed.add(m ?? '');
    try {
      await tester.pumpWidget(
        _app(Fluent2Button('Save', style: _with(_cutA), onPressed: () {})),
      );
      await tester.pumpAndSettle();
    } finally {
      debugPrint = was;
    }
    expect(printed.where((m) => m.contains('Fluent 2')), isEmpty);
  });
}

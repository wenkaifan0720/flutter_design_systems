// An app's corners on one part: a style's `corners` name a step per
// corner, held to Appliance's steps (a moulded corner is never sharp: a cut
// holds at extra small; a capsule end is allowed) and drawn in the theme's
// scale, start and end as the part reads; a style's `shape` wins as given.
// A part made of keys takes them on its outer corners only: the keys at its
// ends follow, concentric, and the joins stay as Appliance draws them. A
// sheet takes its top corners, a side sheet its inner edge's; the edges on
// the screen's side stay square. What a part holds is clipped to the
// corners it is drawn with.
import 'package:appliance_ui/appliance_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;

typedef _Part = Widget Function(ApplianceStyle? style);

final Map<String, _Part> _parts = {
  'ApplianceButton': (s) => ApplianceButton('Save', style: s, onPressed: () {}),
  'ApplianceButton.filled': (s) =>
      ApplianceButton.filled('Add', style: s, onPressed: () {}),
  'ApplianceButton.text': (s) =>
      ApplianceButton.text('Update', style: s, onPressed: () {}),
  'ApplianceIconButton': (s) => ApplianceIconButton(
    icon: const Icon(LucideIcons.search),
    semanticLabel: 'Search',
    style: s,
    onPressed: () {},
  ),
  'ApplianceToolbar': (s) => ApplianceToolbar(
    semanticLabel: 'Text',
    style: s,
    children: [
      ApplianceIconButton(
        icon: const Icon(LucideIcons.bold),
        semanticLabel: 'Bold',
        onPressed: () {},
      ),
      ApplianceIconButton(
        icon: const Icon(LucideIcons.italic),
        semanticLabel: 'Italic',
        onPressed: () {},
      ),
    ],
  ),
  'ApplianceToggleGroup': (s) => ApplianceToggleGroup<String>(
    semanticLabel: 'Programme',
    style: s,
    options: const [
      ApplianceToggleOption(value: 'eco', label: 'Eco'),
      ApplianceToggleOption(value: 'quick', label: 'Quick'),
      ApplianceToggleOption(value: 'deep', label: 'Deep'),
    ],
    selected: const {'eco'},
    onSelectionChanged: (_) {},
  ),
  'ApplianceSplitButton': (s) => ApplianceSplitButton(
    label: 'Save',
    style: s,
    onPressed: () {},
    actions: [RawSplitAction(label: 'Save a copy', onPressed: () {})],
  ),
  'ApplianceCheckbox': (s) => ApplianceCheckbox(
    value: true,
    semanticLabel: 'Gift',
    style: s,
    onChanged: (_) {},
  ),
  'ApplianceSwitch': (s) => ApplianceSwitch(
    value: true,
    semanticLabel: 'Updates',
    style: s,
    onChanged: (_) {},
  ),
  'ApplianceSegmentedButton': (s) => ApplianceSegmentedButton<String>(
    semanticLabel: 'View',
    style: s,
    segments: const [
      ApplianceSegment(value: 'grid', label: 'Grid'),
      ApplianceSegment(value: 'list', label: 'List'),
      ApplianceSegment(value: 'map', label: 'Map'),
    ],
    value: 'grid',
    onChanged: (_) {},
  ),
  'ApplianceStepper': (s) => ApplianceStepper(
    value: 2,
    min: 1,
    max: 9,
    semanticLabel: 'How many',
    style: s,
    onChanged: (_) {},
  ),
  'ApplianceTag': (s) => ApplianceTag('In stock', style: s),
  'ApplianceChip': (s) =>
      ApplianceChip('Vegan', selected: true, style: s, onSelected: (_) {}),
  'ApplianceKbd': (s) => ApplianceKbd('Esc', style: s),
  'ApplianceTextField': (s) =>
      ApplianceTextField(labelText: 'Full name', style: s),
  'ApplianceSearchField': (s) =>
      ApplianceSearchField(hintText: 'Search', style: s),
  'AppliancePasswordField': (s) =>
      AppliancePasswordField(labelText: 'Password', style: s),
  'ApplianceInputGroup': (s) =>
      ApplianceInputGroup(labelText: 'Budget', prefix: '£', style: s),
  'ApplianceCombobox': (s) => ApplianceCombobox<String>(
    labelText: 'Town',
    value: 'Leith',
    style: s,
    onSelected: (_) {},
    options: const ['Leith', 'Portobello'],
  ),
  'ApplianceTagInput': (s) => ApplianceTagInput<String>(
    labelText: 'Rooms',
    values: const ['Hall'],
    style: s,
    onChanged: (_) {},
    options: const ['Kitchen', 'Hall'],
  ),
  'ApplianceSelect': (s) => ApplianceSelect<String>(
    labelText: 'Shelf',
    value: 'a',
    style: s,
    items: const [ApplianceSelectItem(value: 'a', label: 'Cookware')],
    onChanged: (_) {},
  ),
  'ApplianceOtpField': (s) => ApplianceOtpField(style: s),
  'ApplianceDropZone': (s) => ApplianceDropZone(
    label: 'Drop a photo',
    hint: 'PNG',
    style: s,
    onPressed: () {},
  ),
  'AppliancePanel': (s) =>
      AppliancePanel(style: s, child: const SizedBox(width: 200, height: 80)),
  'ApplianceListTile': (s) => ApplianceListTile(
    title: 'Order 2041',
    subtitle: 'On its way',
    style: s,
    onTap: () {},
  ),
  'ApplianceTable': (s) => ApplianceTable(
    style: s,
    columns: const [ApplianceTableColumn('Item'), ApplianceTableColumn('Qty')],
    rows: const [
      ['Kettle', '1'],
    ],
  ),
  'ApplianceDisclosure': (s) => ApplianceDisclosure(
    title: 'Care',
    style: s,
    child: const Text('Descale monthly.'),
  ),
  'ApplianceCalendar': (s) => ApplianceCalendar(style: s),
  'ApplianceMeter': (s) =>
      ApplianceMeter(value: 0.6, label: 'Storage', style: s),
  'ApplianceStatusView': (s) => ApplianceStatusView(
    status: ApplianceStatus.error,
    title: 'Payment failed',
    style: s,
  ),
  'ApplianceProgressBar': (s) =>
      ApplianceProgressBar(value: 0.4, semanticLabel: 'Up', style: s),
  'ApplianceSkeleton': (s) =>
      ApplianceSkeleton(width: 120, height: 40, style: s),
  'ApplianceBanner': (s) =>
      ApplianceBanner(title: 'Card expiring', style: s, onClose: () {}),
  'ApplianceTooltip': (s) => ApplianceTooltip(
    message: 'Keeps warm',
    style: s,
    child: const Text('Keep warm'),
  ),
  'ApplianceMedia': (s) => ApplianceMedia(
    slotId: 'kettle',
    semanticLabel: 'A kettle',
    aspectRatio: 4 / 3,
    style: s,
    placeholder: const Icon(LucideIcons.cookingPot),
  ),
  'ApplianceAvatar': (s) => ApplianceAvatar(name: 'Ada Lovelace', style: s),
  'ApplianceDialog': (s) => ApplianceDialog(
    title: 'Remove?',
    style: s,
    content: const Text('It goes back.'),
    actions: [ApplianceButton('Keep it', onPressed: () {})],
  ),
  'ApplianceSheet': (s) =>
      ApplianceSheet(title: 'Basket', style: s, child: const Text('Kettle')),
  'ApplianceSideSheet': (s) => ApplianceSideSheet(
    title: 'Filters',
    style: s,
    child: const Text('Kettle'),
  ),
  'ApplianceBreadcrumb': (s) => ApplianceBreadcrumb(
    style: s,
    crumbs: [
      ApplianceCrumb('Shop', onPressed: () {}),
      const ApplianceCrumb('Kettles'),
    ],
  ),
  'ApplianceLink': (s) => ApplianceLink('Delivery', style: s, onPressed: () {}),
  'ApplianceSlider': (s) =>
      ApplianceSlider(value: 0.5, style: s, onChanged: (_) {}),
  'ApplianceRadio': (s) => ApplianceRadio<int>(value: 1, style: s),
  'ApplianceTabBar': (s) => ApplianceTabBar<int>(
    tabs: const [
      ApplianceSegment(value: 0, label: 'A'),
      ApplianceSegment(value: 1, label: 'B'),
    ],
    value: 0,
    style: s,
    onChanged: (_) {},
  ),
  'ApplianceCarousel': (s) => ApplianceCarousel(
    itemCount: 3,
    semanticLabel: 'Kettles',
    style: s,
    itemBuilder: (context, i) => Text('Kettle $i'),
  ),
  'ApplianceColorPicker': (s) => ApplianceColorPicker(style: s),
};

// The parts that keep a form of their own whatever a style's corners say
// (a lamp, a knob, a radio key, a switch's slot, a slider's cap, a printed
// link), those with no face of their own (a tag and a tooltip draw through
// a decoration, tested below; a table, a bar and a skeleton draw lines),
// and those with a test of their own below.
const _ownForm = {
  'ApplianceSwitch',
  'ApplianceAvatar',
  'ApplianceSlider',
  'ApplianceStatusView',
  'ApplianceBreadcrumb',
  'ApplianceLink',
  'ApplianceRadio',
  'ApplianceTag',
  'ApplianceTooltip',
  'ApplianceTable',
  'ApplianceProgressBar',
  'ApplianceSkeleton',
  'ApplianceStepper',
  'ApplianceSideSheet',
};

const _cutA = RawCorners(topStart: RawCorner.none, bottomEnd: RawCorner.none);
const _cutB = RawCorners(topEnd: RawCorner.none, bottomStart: RawCorner.none);
const _topStart = RawCorners.only(topStart: RawCorner.large);

ApplianceStyle _with(RawCorners c) =>
    ApplianceStyle(corners: WidgetStatePropertyAll(c));

const _part = ValueKey('part');

typedef _Face = (Rect, BorderRadius);

// Every face under the part (round ones aside), where it stands on screen,
// with the corners it is drawn with.
List<_Face> _faces(WidgetTester tester) => [
  for (final e
      in find
          .descendant(
            of: find.byKey(_part),
            matching: find.byType(ApplianceSurface),
          )
          .evaluate())
    if (e.renderObject case final RenderBox box
        when box.hasSize && !(e.widget as ApplianceSurface).face.circle)
      (
        MatrixUtils.transformRect(
          box.getTransformTo(null),
          Offset.zero & box.size,
        ),
        () {
          final d = Directionality.of(e);
          final f = (e.widget as ApplianceSurface).face.resolveCorners(
            ApplianceTheme.of(e),
            d,
          );
          return f.borderRadius?.resolve(d) ?? f.radius;
        }(),
      ),
];

_Face _outer(List<_Face> faces) => faces.reduce(
  (a, b) => a.$1.width * a.$1.height >= b.$1.width * b.$1.height ? a : b,
);

Future<List<_Face>> _show(
  WidgetTester tester,
  Widget part,
  TextDirection direction, {
  ApplianceThemeData? theme,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, app) => ApplianceHost(
        light: theme,
        brightness: Brightness.light,
        child: app!,
      ),
      home: Directionality(
        textDirection: direction,
        child: Center(
          child: SizedBox(
            width: 360,
            child: KeyedSubtree(key: _part, child: part),
          ),
        ),
      ),
    ),
  );
  await tester.pump(const Duration(seconds: 1));
  return _faces(tester);
}

// Each corner as it reads: start and end turned to left and right.
List<double> _reading(BorderRadius r, TextDirection d) => d == TextDirection.ltr
    ? [r.topLeft.x, r.topRight.x, r.bottomLeft.x, r.bottomRight.x]
    : [r.topRight.x, r.topLeft.x, r.bottomRight.x, r.bottomLeft.x];

List<RawCorner?> _steps(RawCorners c) => [
  c.topStart,
  c.topEnd,
  c.bottomStart,
  c.bottomEnd,
];

// The faces of a row of keys, start to end as the part reads.
List<_Face> _inReading(Iterable<_Face> faces, TextDirection d) =>
    faces.toList()..sort(
      (a, b) => d == TextDirection.ltr
          ? a.$1.left.compareTo(b.$1.left)
          : b.$1.left.compareTo(a.$1.left),
    );

void main() {
  setUpAll(applianceLoadFonts);
  final theme = ApplianceThemeData.light();
  final scale = theme.shapeScheme.corners;
  // A step as Appliance holds it: a cut stays a moulded corner, extra small;
  // a capsule end is a round one.
  double px(RawCorner s) => switch (s) {
    RawCorner.none || RawCorner.extraSmall => scale.extraSmall,
    RawCorner.small => scale.small,
    RawCorner.medium => scale.medium,
    RawCorner.large => scale.large,
    RawCorner.extraLarge => scale.extraLarge,
    RawCorner.full => double.infinity,
  };

  testWidgets('a corner held to a step says so once, in debug', (tester) async {
    final lines = <String>[];
    final print = debugPrint;
    debugPrint = (m, {wrapWidth}) => lines.add(m ?? '');
    try {
      await _show(
        tester,
        ApplianceButton('Save', style: _with(_cutA), onPressed: () {}),
        TextDirection.ltr,
      );
      final first = lines.where((l) => l.startsWith('Appliance holds')).length;
      expect(first, greaterThan(0));
      await _show(
        tester,
        AppliancePanel(style: _with(_cutA), child: const SizedBox(height: 40)),
        TextDirection.ltr,
      );
      expect(lines.where((l) => l.startsWith('Appliance holds')).length, first);
    } finally {
      debugPrint = print;
    }
  });

  for (final MapEntry(key: name, value: build) in _parts.entries) {
    if (_ownForm.contains(name)) continue;
    for (final d in TextDirection.values) {
      for (final (label, asked) in [
        ('cut top-start and bottom-end', _cutA),
        ('cut top-end and bottom-start', _cutB),
        ('only top-start, large', _topStart),
      ]) {
        testWidgets('$name, ${d.name}: $label', (tester) async {
          // A code's boxes read left to right in any language.
          final r = name == 'ApplianceOtpField' ? TextDirection.ltr : d;
          final plain = _reading(
            _outer(await _show(tester, build(null), d)).$2,
            r,
          );
          final got = _reading(
            _outer(await _show(tester, build(_with(asked)), d)).$2,
            r,
          );
          final steps = _steps(asked);
          for (var i = 0; i < 4; i++) {
            final step = steps[i];
            final double want;
            if (name == 'ApplianceSheet' && i >= 2) {
              want = 0; // the foot on the screen's edge
            } else if (name == 'ApplianceSplitButton' && (i == 1 || i == 3)) {
              want = plain[i]; // the join with the menu key
            } else {
              want = step == null ? plain[i] : px(step);
            }
            expect(got[i], want, reason: '$name corner $i in $label');
          }
        });
      }
    }
  }

  for (final d in TextDirection.values) {
    testWidgets("a toggle group's end keys follow its outer corners, "
        'concentric, ${d.name}', (tester) async {
      final build = _parts['ApplianceToggleGroup']!;
      final plain = await _show(tester, build(null), d);
      final plainFrame = _outer(plain);
      final plainKeys = _inReading(plain.where((f) => f != plainFrame), d);
      final own = _reading(plainKeys[1].$2, d)[0];
      final faces = await _show(tester, build(_with(_topStart)), d);
      final frame = _outer(faces);
      final keys = _inReading(faces.where((f) => f != frame), d);
      final inset = keys.first.$1.top - frame.$1.top;
      final outer = _reading(frame.$2, d);
      // `.only` cuts the corners it leaves unnamed.
      expect(outer, [
        px(RawCorner.large),
        px(RawCorner.none),
        px(RawCorner.none),
        px(RawCorner.none),
      ]);
      double less(double r) => (r - inset).clamp(0, double.infinity);
      expect(_reading(keys.first.$2, d), [
        less(outer[0]),
        own,
        less(outer[2]),
        own,
      ]);
      expect(_reading(keys.last.$2, d), [
        own,
        less(outer[1]),
        own,
        less(outer[3]),
      ]);
      expect(_reading(keys[1].$2, d), [own, own, own, own]);
    });

    testWidgets("a selector's block stands concentric at either end, "
        'its own corners between, ${d.name}', (tester) async {
      Widget at(String value, ApplianceStyle? s) =>
          ApplianceSegmentedButton<String>(
            semanticLabel: 'View',
            style: s,
            segments: const [
              ApplianceSegment(value: 'grid', label: 'Grid'),
              ApplianceSegment(value: 'list', label: 'List'),
              ApplianceSegment(value: 'map', label: 'Map'),
            ],
            value: value,
            onChanged: (_) {},
          );
      // The block: the one face besides the trough that the style moves.
      Future<(List<double>, List<double>, double)> block(String value) async {
        final plain = await _show(tester, at(value, null), d);
        final styled = await _show(tester, at(value, _with(_cutA)), d);
        final trough = _outer(styled);
        final moved = [
          for (var i = 0; i < styled.length; i++)
            if (styled[i] != trough && styled[i].$2 != plain[i].$2) styled[i],
        ];
        final face = moved.isEmpty
            ? plain.firstWhere((f) => f.$1.height < trough.$1.height - 1)
            : moved.single;
        return (
          _reading(trough.$2, d),
          _reading(face.$2, d),
          face.$1.top - trough.$1.top,
        );
      }

      final (outer, first, inset) = await block('grid');
      double less(double r) => (r - inset).clamp(0, double.infinity);
      expect(outer[0], px(RawCorner.none));
      expect(first[0], closeTo(less(outer[0]), 0.01));
      expect(first[3], greaterThan(less(outer[3])));
      final (_, last, _) = await block('map');
      expect(last[3], closeTo(less(outer[3]), 0.01));
      expect(last[0], greaterThan(less(outer[0])));
      final (_, middle, _) = await block('list');
      expect(middle[0], middle[1]);
      expect(middle[2], middle[3]);
    });

    testWidgets("a stepper's keys take its start and end corners, "
        '${d.name}', (tester) async {
      final build = _parts['ApplianceStepper']!;
      final plain = await _show(tester, build(null), d);
      final faces = await _show(tester, build(_with(_cutA)), d);
      final keys = _inReading(faces, d);
      final plainKeys = _inReading(plain, d);
      final minus = _reading(keys.first.$2, d);
      final plus = _reading(keys.last.$2, d);
      final ownMinus = _reading(plainKeys.first.$2, d);
      final ownPlus = _reading(plainKeys.last.$2, d);
      // The decrease key starts the part, the increase key ends it.
      expect(minus, [
        px(RawCorner.none),
        ownMinus[1],
        ownMinus[2],
        ownMinus[3],
      ]);
      expect(plus, [ownPlus[0], ownPlus[1], ownPlus[2], px(RawCorner.none)]);
      // The window between keeps its own.
      expect(keys[1].$2, plainKeys[1].$2);
    });

    testWidgets("a split button's keys share its corners, the join "
        'square, ${d.name}', (tester) async {
      final build = _parts['ApplianceSplitButton']!;
      final plain = _inReading(await _show(tester, build(null), d), d);
      final keys = _inReading(await _show(tester, build(_with(_cutB)), d), d);
      final main = _reading(keys.first.$2, d);
      final menu = _reading(keys.last.$2, d);
      final ownMain = _reading(plain.first.$2, d);
      final ownMenu = _reading(plain.last.$2, d);
      expect(main, [ownMain[0], ownMain[1], px(RawCorner.none), ownMain[3]]);
      expect(menu, [ownMenu[0], px(RawCorner.none), ownMenu[2], ownMenu[3]]);
    });

    testWidgets("a side sheet takes its inner edge's corners, its screen "
        'edge square, ${d.name}', (tester) async {
      final build = _parts['ApplianceSideSheet']!;
      final r = _outer(await _show(tester, build(_with(_cutA)), d)).$2;
      // It stands at the right; its inner edge is its left.
      expect(r.topRight.x, 0);
      expect(r.bottomRight.x, 0);
      final ltr = d == TextDirection.ltr;
      // Top-left reads as top-start in LTR (cut), top-end in RTL (its own).
      expect(r.topLeft.x, ltr ? px(RawCorner.none) : theme.radiusLid);
      expect(r.bottomLeft.x, ltr ? theme.radiusLid : px(RawCorner.none));
    });
  }

  test("a corner a style leaves keeps the face's own, where it stands", () {
    // A face rounder on its left: in either direction the steps named land
    // where the part reads them, the rest stay on the side they were on.
    const face = ApplianceFace(
      top: Color(0xFFEEEEEE),
      bottom: Color(0xFFDDDDDD),
      radius: BorderRadius.horizontal(
        left: Radius.circular(12),
        right: Radius.circular(4),
      ),
      corners: RawCorners(topStart: RawCorner.large),
    );
    final ltr = face
        .resolveCorners(theme, TextDirection.ltr)
        .borderRadius!
        .resolve(TextDirection.ltr);
    expect(
      [ltr.topLeft.x, ltr.topRight.x, ltr.bottomLeft.x, ltr.bottomRight.x],
      [px(RawCorner.large), 4, 12, 4],
    );
    final rtl = face
        .resolveCorners(theme, TextDirection.rtl)
        .borderRadius!
        .resolve(TextDirection.rtl);
    expect(
      [rtl.topLeft.x, rtl.topRight.x, rtl.bottomLeft.x, rtl.bottomRight.x],
      [12, px(RawCorner.large), 12, 4],
    );
  });

  testWidgets("a style's shape wins, unclamped, over its corners", (
    tester,
  ) async {
    const style = ApplianceStyle(
      corners: WidgetStatePropertyAll(RawCorners.all(RawCorner.large)),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(1)),
        ),
      ),
    );
    final faces = await _show(
      tester,
      ApplianceButton('Save', style: style, onPressed: () {}),
      TextDirection.ltr,
    );
    expect(_reading(_outer(faces).$2, TextDirection.ltr), [1, 1, 1, 1]);
    final strip = await _show(
      tester,
      _parts['ApplianceToolbar']!(
        const ApplianceStyle(shape: WidgetStatePropertyAll(StadiumBorder())),
      ),
      TextDirection.ltr,
    );
    expect(_outer(strip).$2.topLeft.x, double.infinity);
  });

  testWidgets("a step is drawn in the theme's scale", (tester) async {
    final rounder = theme.copyWith(
      shapeScheme: const RawShapeScheme(
        corners: RawCornerScale(
          extraSmall: 5,
          small: 8,
          medium: 10,
          large: 14,
          extraLarge: 18,
        ),
      ),
    );
    final faces = await _show(
      tester,
      ApplianceButton('Save', style: _with(_topStart), onPressed: () {}),
      TextDirection.ltr,
      theme: rounder,
    );
    expect(_reading(_outer(faces).$2, TextDirection.ltr), [14, 5, 5, 5]);
  });

  RRect clipUnder(WidgetTester tester, Finder of) {
    final box = tester
        .renderObjectList<RenderClipRRect>(
          find.descendant(of: of, matching: find.byType(ClipRRect)),
        )
        .firstWhere((c) => c.clipper != null);
    return box.clipper!.getClip(box.size);
  }

  for (final d in TextDirection.values) {
    testWidgets(
      "an input group's words are clipped to its corners, ${d.name}",
      (tester) async {
        await _show(tester, _parts['ApplianceInputGroup']!(_with(_cutA)), d);
        final r = clipUnder(tester, find.byType(ApplianceInputGroup));
        final ltr = d == TextDirection.ltr;
        expect(ltr ? r.tlRadiusX : r.trRadiusX, px(RawCorner.none));
        expect(ltr ? r.trRadiusX : r.tlRadiusX, theme.radiusWell);
      },
    );

    for (final name in [
      'ApplianceMedia',
      'ApplianceCarousel',
      'ApplianceColorPicker',
    ]) {
      testWidgets('$name: what its well holds follows its corners, '
          'concentric, ${d.name}', (tester) async {
        final faces = await _show(tester, _parts[name]!(_with(_topStart)), d);
        final well = _outer(faces);
        final r = clipUnder(tester, find.byKey(_part));
        final ltr = d == TextDirection.ltr;
        final start = ltr ? r.tlRadiusX : r.trRadiusX;
        final end = ltr ? r.trRadiusX : r.tlRadiusX;
        final outerStart = _reading(well.$2, d)[0];
        final outerEnd = _reading(well.$2, d)[1];
        expect(outerStart, px(RawCorner.large));
        // The same inset at both corners: the window stands concentric.
        expect(outerStart - start, closeTo(outerEnd - end, 0.01));
        expect(start, greaterThan(end));
      });
    }

    testWidgets("a tag's plate takes its corners, ${d.name}", (tester) async {
      await _show(tester, ApplianceTag('In stock', style: _with(_cutA)), d);
      final box = tester
          .widgetList<DecoratedBox>(
            find.descendant(
              of: find.byType(ApplianceTag),
              matching: find.byType(DecoratedBox),
            ),
          )
          .firstWhere((b) => b.decoration is ShapeDecoration);
      final shape = (box.decoration as ShapeDecoration).shape;
      final path = shape.getOuterPath(
        const Rect.fromLTWH(0, 0, 100, 24),
        textDirection: d,
      );
      // A point 1.2 in from a corner lies inside a corner of 3 (the tag's
      // own) and outside one of 6 (a cut, held at extra small).
      const near = Offset(1.2, 1.2);
      const far = Offset(98.8, 1.2);
      final ltr = d == TextDirection.ltr;
      expect(path.contains(ltr ? near : far), isFalse, reason: 'top-start');
      expect(path.contains(ltr ? far : near), isTrue, reason: 'top-end');
    });
  }

  testWidgets('corners that change with a press ease, never snap', (
    tester,
  ) async {
    final style = ApplianceStyle(
      corners: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.pressed)
            ? const RawCorners.all(RawCorner.large)
            : null,
      ),
    );
    await _show(
      tester,
      ApplianceButton('Save', style: style, onPressed: () {}),
      TextDirection.ltr,
    );
    double tl() => _outer(_faces(tester)).$2.topLeft.x;
    expect(tl(), theme.radiusKey);
    final press = await tester.startGesture(
      tester.getCenter(find.byType(ApplianceButton)),
    );
    final seen = <double>[];
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      seen.add(tl());
    }
    expect(
      seen.where((r) => r > theme.radiusKey && r < px(RawCorner.large)),
      isNotEmpty,
    );
    await tester.pumpAndSettle();
    expect(tl(), px(RawCorner.large));
    await press.up();
    await tester.pumpAndSettle();
  });
}

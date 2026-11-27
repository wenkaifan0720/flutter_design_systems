// An app's corners on one part: a style's `corners` name a step per
// corner, held to Studio's steps (a milled corner is never sharp, a key never
// a pill: a cut holds at extra small) and drawn in the theme's scale, start
// and end as the part reads; a style's `shape` wins as given. A part made of
// keys takes them on its outer corners only: the keys at its ends follow,
// concentric, and the joins stay as Studio draws them. A sheet takes its top
// corners; its foot stays square on the screen's edge.
import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studio_ui/studio_ui.dart';

typedef _Part = Widget Function(StudioStyle style);

final Map<String, _Part> _parts = {
  'StudioButton': (s) => StudioButton('Save', style: s, onPressed: () {}),
  'StudioButton.lit': (s) =>
      StudioButton.lit('Publish', style: s, onPressed: () {}),
  'StudioIconButton': (s) => StudioIconButton(
    icon: const Icon(LucideIcons.chevronLeft),
    tooltip: 'Back',
    style: s,
    onPressed: () {},
  ),
  'StudioFloatingKey': (s) => StudioFloatingKey(
    icon: const Icon(LucideIcons.mic),
    tooltip: 'Record',
    style: s,
    onPressed: () {},
  ),
  'StudioKeyRow': (s) => StudioKeyRow(
    semanticLabel: 'Clip',
    style: s,
    items: [
      StudioKeyRowItem(label: 'Cut', onPressed: () {}),
      StudioKeyRowItem(label: 'Copy', onPressed: () {}),
      StudioKeyRowItem(label: 'Split', onPressed: () {}),
    ],
  ),
  'StudioToggleBank': (s) => StudioToggleBank<String>(
    options: const ['Mute', 'Solo', 'Arm'],
    selected: const {'Mute'},
    labelOf: (v) => v,
    style: s,
    onSelectionChanged: (_) {},
  ),
  'StudioSplitKey': (s) => StudioSplitKey(
    label: 'Export',
    style: s,
    onPressed: () {},
    actions: [StudioMenuItem(label: 'Export WAV', onPressed: () {})],
  ),
  'StudioSegmentedButton': (s) => StudioSegmentedButton<double>(
    segments: const [
      StudioSegment(value: 1, label: '1x'),
      StudioSegment(value: 1.5, label: '1.5x'),
      StudioSegment(value: 2, label: '2x'),
    ],
    value: 1,
    style: s,
    onChanged: (_) {},
  ),
  'StudioCheckbox': (s) => StudioCheckbox(
    value: true,
    style: s,
    onChanged: (_) {},
    semanticLabel: 'Explicit',
  ),
  'StudioCheckRow': (s) =>
      StudioCheckRow(label: 'Done', value: true, style: s, onChanged: (_) {}),
  'StudioMeter': (s) => SizedBox(
    width: 200,
    child: StudioMeter(level: 0.5, style: s, semanticLabel: 'Left'),
  ),
  'StudioTextField': (s) =>
      StudioTextField(labelText: 'Title', style: s, onChanged: (_) {}),
  'StudioSearchField': (s) =>
      StudioSearchField(hintText: 'Search', style: s, onChanged: (_) {}),
  'StudioPasswordField': (s) =>
      StudioPasswordField(labelText: 'Password', style: s, onChanged: (_) {}),
  'StudioInputGroup': (s) => StudioInputGroup(
    labelText: 'Feed',
    leading: const Text('https://'),
    style: s,
    onChanged: (_) {},
  ),
  'StudioCombobox': (s) => StudioCombobox<String>(
    labelText: 'Show',
    options: const ['A', 'B'],
    labelOf: (v) => v,
    value: 'A',
    style: s,
    onSelected: (_) {},
  ),
  'StudioTagInput': (s) => StudioTagInput<String>(
    labelText: 'Topics',
    values: const ['A'],
    options: const ['A', 'B'],
    labelOf: (v) => v,
    style: s,
    onChanged: (_) {},
  ),
  'StudioSelect': (s) => StudioSelect<String>(
    labelText: 'Quality',
    value: 'hi',
    items: const [StudioSelectItem(value: 'hi', label: 'High')],
    style: s,
    onChanged: (_) {},
  ),
  'StudioCalendar': (s) => StudioCalendar(
    firstDate: DateTime(2026),
    lastDate: DateTime(2027),
    selectedDate: DateTime(2026, 5, 4),
    style: s,
    onDateChanged: (_) {},
  ),
  'StudioChip': (s) => StudioChip(
    label: 'Interviews',
    selected: true,
    style: s,
    onSelected: (_) {},
  ),
  'StudioFileDrop': (s) => StudioFileDrop(
    labelText: 'Audio',
    hintText: 'WAV',
    files: const [],
    style: s,
    onChoose: () {},
    onRemove: (_) {},
  ),
  'StudioListTile': (s) => StudioListTile(
    title: 'Audio quality',
    trailingText: 'High',
    style: s,
    onTap: () {},
  ),
  'StudioPanel': (s) =>
      StudioPanel(style: s, child: const SizedBox(width: 200, height: 80)),
  'StudioDisplay': (s) =>
      StudioDisplay(style: s, child: const SizedBox(width: 200, height: 80)),
  'StudioDialog': (s) => StudioDialog(
    title: 'Discard?',
    style: s,
    content: const Text('Gone.'),
    actions: [StudioButton('Keep', onPressed: () {})],
  ),
  'StudioSheet': (s) =>
      StudioSheet(title: 'Export', style: s, child: const Text('MP3')),
  'StudioCommandPalette': (s) => StudioCommandPalette(
    commands: [StudioCommand(label: 'New', onPressed: () {})],
    style: s,
    onSelected: (_) {},
  ),
  'StudioMenuBar': (s) => StudioMenuBar(
    style: s,
    menus: [
      StudioMenuBarMenu('Episode', [
        StudioMenuItem(label: 'New', onPressed: () {}),
      ]),
    ],
  ),
};

const _cutA = RawCorners(topStart: RawCorner.none, bottomEnd: RawCorner.none);
const _cutB = RawCorners(topEnd: RawCorner.none, bottomStart: RawCorner.none);
const _topStart = RawCorners.only(topStart: RawCorner.large);

StudioStyle _with(RawCorners c) =>
    StudioStyle(corners: WidgetStatePropertyAll(c));

const _part = ValueKey('part');

// Every face under the part, where it stands on screen.
List<(Rect, StudioFacePainter)> _faces(WidgetTester tester) => [
  for (final e
      in find
          .descendant(of: find.byKey(_part), matching: find.byType(CustomPaint))
          .evaluate())
    if (e.renderObject case final RenderCustomPaint ro
        when ro.hasSize &&
            (ro.painter ?? ro.foregroundPainter) is StudioFacePainter)
      (
        MatrixUtils.transformRect(
          ro.getTransformTo(null),
          Offset.zero & ro.size,
        ),
        (ro.painter ?? ro.foregroundPainter)! as StudioFacePainter,
      ),
];

(Rect, StudioFacePainter) _outer(List<(Rect, StudioFacePainter)> faces) =>
    faces.reduce(
      (a, b) => a.$1.width * a.$1.height >= b.$1.width * b.$1.height ? a : b,
    );

BorderRadius _radii(StudioFacePainter p) =>
    p.face.borderRadius?.resolve(p.textDirection ?? TextDirection.ltr) ??
    BorderRadius.circular(p.face.radius);

Future<List<(Rect, StudioFacePainter)>> _show(
  WidgetTester tester,
  Widget part,
  TextDirection direction, {
  StudioThemeData? theme,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, app) => StudioHost(theme: theme, child: app!),
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

void main() {
  final theme = StudioThemeData.light();
  final scale = theme.shapeScheme.corners;
  // A step as Studio holds it: a cut stays a milled corner, extra small.
  double px(RawCorner s) =>
      scale.radius(s == RawCorner.none ? RawCorner.extraSmall : s);

  testWidgets('a corner held to a step says so once, in debug', (tester) async {
    final lines = <String>[];
    final print = debugPrint;
    debugPrint = (m, {wrapWidth}) => lines.add(m ?? '');
    try {
      await _show(
        tester,
        StudioButton('Save', style: _with(_cutA), onPressed: () {}),
        TextDirection.ltr,
      );
      final first = lines.where((l) => l.startsWith('Studio holds')).length;
      expect(first, greaterThan(0));
      await _show(
        tester,
        StudioPanel(style: _with(_cutA), child: const SizedBox(height: 40)),
        TextDirection.ltr,
      );
      expect(lines.where((l) => l.startsWith('Studio holds')).length, first);
    } finally {
      debugPrint = print;
    }
  });

  for (final MapEntry(key: name, value: build) in _parts.entries) {
    for (final d in TextDirection.values) {
      for (final (label, asked) in [
        ('cut top-start and bottom-end', _cutA),
        ('cut top-end and bottom-start', _cutB),
        ('only top-start, large', _topStart),
      ]) {
        testWidgets('$name, ${d.name}: $label', (tester) async {
          final plain = _reading(
            _radii(
              _outer(await _show(tester, build(const StudioStyle()), d)).$2,
            ),
            d,
          );
          final got = _reading(
            _radii(_outer(await _show(tester, build(_with(asked)), d)).$2),
            d,
          );
          final steps = [
            asked.topStart,
            asked.topEnd,
            asked.bottomStart,
            asked.bottomEnd,
          ];
          for (var i = 0; i < 4; i++) {
            final step = steps[i];
            final double want;
            if (name == 'StudioSheet' && i >= 2) {
              want = 0; // the foot on the screen's edge
            } else if (name == 'StudioSheet' && step == null) {
              want = theme.radiusPanel; // its clip's top corner
            } else if (name == 'StudioSplitKey' && (i == 1 || i == 3)) {
              want = plain[i]; // the join with the narrow key
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
    testWidgets(
      "a bank's end keys follow its outer corners, concentric, ${d.name}",
      (tester) async {
        for (final name in [
          'StudioKeyRow',
          'StudioToggleBank',
          'StudioSegmentedButton',
        ]) {
          final faces = await _show(tester, _parts[name]!(_with(_topStart)), d);
          final frame = _outer(faces);
          final keys = faces.where((f) => f != frame).toList()
            ..sort((a, b) => a.$1.left.compareTo(b.$1.left));
          if (d == TextDirection.rtl) {
            final turned = keys.reversed.toList();
            keys
              ..clear()
              ..addAll(turned);
          }
          const inset = StudioMetrics.recessInset;
          final own = theme.radiusBank - inset;
          final outer = _reading(_radii(frame.$2), d);
          expect(outer, [
            px(RawCorner.large),
            px(RawCorner.none),
            px(RawCorner.none),
            px(RawCorner.none),
          ]);
          double less(double r) => (r - inset).clamp(0, double.infinity);
          final first = _reading(_radii(keys.first.$2), d);
          final last = _reading(_radii(keys.last.$2), d);
          expect(first, [
            less(outer[0]),
            own,
            less(outer[2]),
            own,
          ], reason: name);
          expect(last, [
            own,
            less(outer[1]),
            own,
            less(outer[3]),
          ], reason: name);
          for (final k in keys.sublist(1, keys.length - 1)) {
            expect(_reading(_radii(k.$2), d), [
              own,
              own,
              own,
              own,
            ], reason: name);
          }
        }
      },
    );
  }

  testWidgets("a style's shape wins, unclamped, over its corners", (
    tester,
  ) async {
    const style = StudioStyle(
      corners: WidgetStatePropertyAll(RawCorners.all(RawCorner.large)),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(1)),
        ),
      ),
    );
    final faces = await _show(
      tester,
      StudioButton('Save', style: style, onPressed: () {}),
      TextDirection.ltr,
    );
    expect(_reading(_radii(_outer(faces).$2), TextDirection.ltr), [1, 1, 1, 1]);
    final bank = await _show(
      tester,
      _parts['StudioKeyRow']!(
        const StudioStyle(shape: WidgetStatePropertyAll(StadiumBorder())),
      ),
      TextDirection.ltr,
    );
    final r = _radii(_outer(bank).$2);
    expect(r.topLeft.x, double.infinity);
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
      StudioButton('Save', style: _with(_topStart), onPressed: () {}),
      TextDirection.ltr,
      theme: rounder,
    );
    expect(_reading(_radii(_outer(faces).$2), TextDirection.ltr), [
      14,
      5,
      5,
      5,
    ]);
  });

  testWidgets("a sheet's clip follows the corners an app gave it", (
    tester,
  ) async {
    await _show(
      tester,
      StudioSheet(
        title: 'Export',
        style: _with(_cutA),
        child: const Text('MP3'),
      ),
      TextDirection.ltr,
    );
    final clip = tester
        .widgetList<ClipRRect>(
          find.descendant(
            of: find.byKey(_part),
            matching: find.byType(ClipRRect),
          ),
        )
        .firstWhere((c) => c.clipper != null);
    final r = clip.clipper!.getClip(const Size(360, 120));
    expect(
      [r.tlRadiusX, r.trRadiusX, r.blRadiusX, r.brRadiusX],
      [px(RawCorner.none), theme.radiusPanel, 0, 0],
    );
  });

  testWidgets('corners that change with a press ease, never snap', (
    tester,
  ) async {
    final style = StudioStyle(
      corners: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.pressed)
            ? const RawCorners.all(RawCorner.large)
            : null,
      ),
    );
    await _show(
      tester,
      StudioButton('Save', style: style, onPressed: () {}),
      TextDirection.ltr,
    );
    double tl() => _radii(_outer(_faces(tester)).$2).topLeft.x;
    expect(tl(), theme.radiusKey);
    final press = await tester.startGesture(
      tester.getCenter(find.byType(StudioButton)),
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

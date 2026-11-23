// What says a control is there, and what says it is off (glass with no
// dark edge):
// - An unchosen part at rest (an empty check, round or square, an unchosen
//   radio, an empty star, an off switch, an unchosen menu option, a
//   segmented strip) is glass in a field's language: no pixel of it is
//   darker on the ground it stands on than a field's darkest (its inner
//   shade) but by the step a field's own tint makes on a flat ground,
//   measured from the pixels drawn, in every preset by day and by night, on
//   the page, the surface and the wash. Glass has no dark edge; it still
//   shows.
// - Off is one share, once: a settings row that is off dims its words and
//   its switch together, and nothing inside it is dimmed a second time.
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:frosted_ui/frosted_host.dart';
import 'package:frosted_ui/src/frosted/internal/well.dart';

void _drop(Object? _) {}

void _none() {}

const _capture = ValueKey('ground');

/// The parts unchosen at rest, and the field they answer to.
final _parts = <String, Widget>{
  'round check': const FrostedCheckbox(
    value: false,
    label: 'Agree',
    onChanged: _drop,
  ),
  'square check': const FrostedCheckbox(
    value: false,
    label: 'Done',
    onChanged: _drop,
    style: FrostedStyle(
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(6)),
        ),
      ),
    ),
  ),
  'radio': const FrostedRadioGroup<String>(
    labelText: 'Plan',
    value: null,
    onChanged: _drop,
    options: [FrostedRadio('free', 'Free'), FrostedRadio('pro', 'Pro')],
  ),
  'star': const FrostedRating(value: 0, label: 'Your rating', onChanged: _drop),
  'off switch': const FrostedSwitch(
    value: false,
    label: 'Share',
    onChanged: _drop,
  ),
  'menu option': const SizedBox(
    width: 240,
    child: FrostedOption(label: 'Weekly', selected: false, onPressed: _none),
  ),
  'segmented strip': const FrostedSegmentedButton<String>(
    segments: [
      FrostedButtonSegment('d', 'Day'),
      FrostedButtonSegment('w', 'Week'),
    ],
    value: 'd',
    onChanged: _drop,
    label: 'Range',
  ),
};

const _field = FrostedWell(child: SizedBox(width: 200, height: 40));

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return la > lb ? (la + .05) / (lb + .05) : (lb + .05) / (la + .05);
}

/// How far [part] draws on [ground] at 3x, its words and glyphs left out:
/// the darkest pixel's contrast with the ground (1 when none is darker), and
/// the strongest either way (that it shows).
Future<({double dark, double shows, Offset at})> _measure(
  WidgetTester tester,
  FrostedThemeData theme,
  Color ground,
  Widget part,
) async {
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (context, page) => FrostedHost(
        theme: theme,
        darkTheme: theme,
        brightness: theme.brightness,
        child: page!,
      ),
      home: Center(
        child: RepaintBoundary(
          key: _capture,
          child: ColoredBox(
            color: ground,
            child: Padding(padding: const EdgeInsets.all(12), child: part),
          ),
        ),
      ),
    ),
  );
  // The face eases from the last preset's, and after a day/night flip the
  // host's theme eases too: measure once all is still.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
  await tester.pumpAndSettle();
  final stage = tester.getRect(find.byKey(_capture));
  final words = [
    for (final e
        in find
            .descendant(
              of: find.byKey(_capture),
              matching: find.byType(RichText),
            )
            .evaluate())
      switch (e.renderObject! as RenderBox) {
        final box =>
          (box.localToGlobal(Offset.zero) & box.size)
              .inflate(1)
              .shift(-stage.topLeft),
      },
  ];
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_capture),
  );
  const ratio = 3.0;
  final (px, width) = (await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: ratio);
    try {
      return ((await image.toByteData())!.buffer.asUint8List(), image.width);
    } finally {
      image.dispose();
    }
  }))!;
  // The ground, read 4 px in; the capture's outer 4 px (its edge pixels may
  // be partly the page outside) and any pixel not wholly drawn are left out.
  final first = (4 * ratio).round() * (width + 1) * 4;
  final base = Color.fromARGB(255, px[first], px[first + 1], px[first + 2]);
  final lb = base.computeLuminance();
  final height = px.length ~/ 4 ~/ width;
  var dark = 1.0, shows = 1.0;
  var where = Offset.zero;
  for (var i = 0; i < px.length; i += 4) {
    final k = i ~/ 4;
    final at = Offset((k % width + .5) / ratio, (k ~/ width + .5) / ratio);
    if (px[i + 3] < 255 ||
        at.dx < 4 ||
        at.dy < 4 ||
        at.dx > width / ratio - 4 ||
        at.dy > height / ratio - 4 ||
        words.any((r) => r.contains(at))) {
      continue;
    }
    final c = Color.fromARGB(255, px[i], px[i + 1], px[i + 2]);
    final ratioOf = _contrast(c, base);
    if (ratioOf > shows) shows = ratioOf;
    if (c.computeLuminance() < lb && ratioOf > dark) {
      dark = ratioOf;
      where = at;
    }
  }
  return (dark: dark, shows: shows, at: where);
}

void main() {
  testWidgets('an unchosen part at rest is glass: no pixel darker on its '
      'ground than a field\'s, and it shows, every preset, by day and by '
      'night', (tester) async {
    final faults = <String>[];
    for (final preset in FrostedThemeData.presets) {
      for (final brightness in Brightness.values) {
        final t = FrostedThemeData.preset(preset, brightness);
        final page = t.colorScheme.background.withValues(alpha: 1);
        final grounds = {
          'page': page,
          'surface': Color.alphaBlend(t.colorScheme.surface, page),
          'wash': Color.alphaBlend(t.colorScheme.surfaceAlt, page),
        };
        for (final MapEntry(key: on, value: ground) in grounds.entries) {
          final field = await _measure(tester, t, ground, _field);
          for (final MapEntry(key: name, value: part) in _parts.entries) {
            final m = await _measure(tester, t, ground, part);
            final where = '$preset ${brightness.name} $name on the $on';
            // On a flat ground a field's own tint lifts it a little, where a
            // bead's or a star's body is the well's raised tone alone: a step
            // of up to 0.1 is the same glass (on Frosted's backdrop the two
            // measure alike); a dark ring stands 1.5:1 and more.
            if (m.dark > field.dark + .1) {
              faults.add(
                '$where: darkest ${m.dark.toStringAsFixed(2)}:1, the '
                'field\'s ${field.dark.toStringAsFixed(2)}:1, at ${m.at}',
              );
            }
            if (m.shows < 1.05) {
              faults.add('$where: shows at ${m.shows.toStringAsFixed(2)}:1');
            }
          }
        }
      }
    }
    expect(faults, isEmpty, reason: faults.join('\n'));
  }, tags: const ['goldens']);

  testWidgets('a settings row that is off dims as one thing, once', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        builder: (context, page) =>
            FrostedHost(brightness: Brightness.light, child: page!),
        home: const FrostedSettingsGroup(
          children: [
            FrostedSwitchRow(
              label: 'Weekly summary',
              note: 'Every Sunday evening',
              value: false,
              onChanged: null,
            ),
            FrostedValueRow(
              title: 'Monthly spending limit',
              value: r'$2,000',
              onPressed: null,
              enabled: false,
            ),
          ],
        ),
      ),
    );
    double share(Finder of) => tester
        .widgetList<AnimatedOpacity>(
          find.ancestor(of: of, matching: find.byType(AnimatedOpacity)),
        )
        .fold(1.0, (a, o) => a * o.opacity);
    const off = FrostedChromeMetrics.disabledOpacity;
    expect(share(find.text('Weekly summary')), off);
    expect(share(find.text('Every Sunday evening')), off);
    expect(
      share(
        find
            .descendant(
              of: find.byType(FrostedSwitch),
              // The track's face.
              matching: find.byType(CustomPaint),
            )
            .first,
      ),
      off,
      reason: 'the switch is dimmed with its row, not twice',
    );
    expect(share(find.text('Monthly spending limit')), off);
    expect(share(find.text(r'$2,000')), off);
  });
}

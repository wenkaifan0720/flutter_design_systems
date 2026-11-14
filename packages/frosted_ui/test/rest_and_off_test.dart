// What says a control is there, and what says it is off (design round,
// faults 2 and 3):
// - An empty check, an unchosen radio and an empty star are only their ring,
//   so the ring reads 3:1 on the ground it stands on (WCAG 1.4.11), measured
//   from the pixels drawn, in every preset by day and by night, on the page,
//   the surface and the wash.
// - Off is one share, once: a settings row that is off dims its words and
//   its switch together, and nothing inside it is dimmed a second time.
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:frosted_ui/frosted_host.dart';

void _drop(Object? _) {}

const _capture = ValueKey('ring');

/// The parts whose ring is all that shows at rest.
final _parts = <String, Widget>{
  'checkbox': const FrostedCheckbox(
    value: false,
    label: 'Agree',
    onChanged: _drop,
  ),
  'radio': const FrostedRadioGroup<String>(
    label: 'Plan',
    value: 'none',
    onChanged: _drop,
    options: [FrostedRadio('free', 'Free')],
  ),
  'star': const FrostedRating(value: 0, label: 'Your rating', onChanged: _drop),
};

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return la > lb ? (la + .05) / (lb + .05) : (lb + .05) / (la + .05);
}

/// The strongest contrast any pixel of [part] makes with its [ground], as
/// drawn at 3x (a 1.5 ring covers whole pixels there).
Future<double> _ringContrast(
  WidgetTester tester,
  FrostedThemeData theme,
  Color ground,
  Widget part,
) async {
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (context, page) => FrostedHost(
        light: theme,
        dark: theme,
        brightness: theme.brightness,
        child: page!,
      ),
      home: Center(
        child: RepaintBoundary(
          key: _capture,
          child: ColoredBox(
            color: ground,
            child: Padding(padding: const EdgeInsets.all(8), child: part),
          ),
        ),
      ),
    ),
  );
  // The face eases from the last preset's, and after a day/night flip the
  // host's theme eases too (the first capture of each preset was taken
  // mid-ease: even the label read under 3:1): measure once all is still.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
  await tester.pumpAndSettle();
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_capture),
  );
  final px = (await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 3);
    try {
      return (await image.toByteData())!.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  }))!;
  final base = Color.fromARGB(255, px[0], px[1], px[2]);
  var best = 1.0;
  for (var i = 0; i < px.length; i += 4) {
    final c = _contrast(Color.fromARGB(255, px[i], px[i + 1], px[i + 2]), base);
    if (c > best) best = c;
  }
  return best;
}

void main() {
  testWidgets('a ring at rest reads 3:1 on its ground, every preset, by day '
      'and by night', (tester) async {
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
        for (final MapEntry(key: name, value: part) in _parts.entries) {
          for (final MapEntry(key: on, value: ground) in grounds.entries) {
            final c = await _ringContrast(tester, t, ground, part);
            if (c < 3) {
              faults.add(
                '$preset ${brightness.name} $name on the $on: '
                '${c.toStringAsFixed(2)}:1',
              );
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

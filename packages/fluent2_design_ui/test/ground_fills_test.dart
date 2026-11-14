// A neutral track or rest fill shows on every ground it stands on, in every
// preset by day and by night: the segmented control's track, a filled
// circular tab and a filled tag at rest, a neutral tile, a progress bar's
// track and a rating's unfilled stars stand at least 1.15:1 from the page
// (the brand-tinted ground), a card and the desktop layer; a well out of use
// at least 1.1:1. Fluent's own `neutralBackground3` (#F5F5F5) stood 1.01:1
// on the tinted page, so the segmented control's track vanished and its
// unchosen words read loose. Fluent's other greys (disabled fills and
// strokes, rules, a chosen row) are laid as steps and the brand tint steps
// a shade deeper where the page would swallow it.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluent2_design_ui/fluent2_design_ui.dart';
import 'package:fluent2_design_ui/fluent2_design_host.dart';
import 'package:fluent2_design_ui/src/fluent2_design/components/input/field_core.dart'
    show fluent2PlaceholderInk;
import 'package:fluent2_design_ui/src/fluent2_design/internal/well.dart';

Widget _host(Fluent2ThemeData theme, Widget child) => MaterialApp(
  debugShowCheckedModeBanner: false,
  builder: (context, route) => Fluent2Host(
    light: theme.brightness == Brightness.light ? theme : null,
    darkData: theme.brightness == Brightness.dark ? theme : null,
    brightness: theme.brightness,
    child: route!,
  ),
  home: Center(child: child),
);

/// The fill a part's first [Container] under [of] paints.
Color _fillOf(WidgetTester t, Finder of, {int at = 0}) {
  final boxes = find
      .descendant(of: of, matching: find.byType(Container))
      .evaluate()
      .map((e) => e.widget as Container)
      .where((c) => c.decoration is BoxDecoration)
      .toList();
  return (boxes[at].decoration! as BoxDecoration).color!;
}

void main() {
  final themes = [
    for (final id in Fluent2ThemeData.presets)
      for (final b in Brightness.values) Fluent2ThemeData.preset(id, b),
  ];

  Map<String, Color> grounds(Fluent2ThemeData t) => {
    'page': t.background,
    'card': t.surface,
    'layer': Color.alphaBlend(
      t.colors.neutralBackground1.withValues(alpha: 0.5),
      t.background,
    ),
    'raised ground': t.colors.neutralBackground2,
  };

  void holds(Fluent2ThemeData t, String part, Color fill, double floor) {
    for (final g in grounds(t).entries) {
      final seen = Color.alphaBlend(fill, g.value);
      expect(
        Fluent2ThemeData.contrast(seen, g.value),
        greaterThanOrEqualTo(floor),
        reason: '${t.id} ${t.brightness.name}: $part on the ${g.key}',
      );
    }
  }

  for (final t in themes) {
    final name = '${t.id} ${t.brightness.name}';
    test('rest fills and rails show on every ground ($name)', () {
      holds(t, 'well', fluent2Well(t), 1.15);
      holds(
        t,
        'well under the pointer',
        fluent2Well(t, Fluent2Press.hover),
        1.1,
      );
      holds(t, 'pressed well', fluent2Well(t, Fluent2Press.pressed), 1.15);
      holds(t, 'well out of use', fluent2WellDisabled(t), 1.1);
      holds(t, 'rail', fluent2Rail(t), 1.15);
      holds(t, 'progress track', fluent2ProgressTrack(t), 1.15);
      for (final p in [
        Fluent2Press.rest,
        Fluent2Press.hover,
        Fluent2Press.pressed,
      ]) {
        holds(
          t,
          'filled tag ${p.name}',
          Fluent2TagFace.of(t, Fluent2TagAppearance.filled, p).fill,
          1.1,
        );
      }
      holds(t, 'neutral tile', Fluent2Hue.neutral.of(t).$1, 1.15);
      holds(t, 'filled-darker field', fluent2FieldWell(t), 1.1);
      // Fluent's greys laid as steps: a disabled stroke or rail and the
      // default rule clear every ground, the subtle rule shows, the strong
      // one stands darker than the default, and a chosen row's fill shows.
      final c = t.colors;
      holds(t, 'disabled stroke', fluent2Step(t, c.neutralStrokeDisabled), 1.2);
      holds(t, 'rule', fluent2Step(t, c.neutralStroke2), 1.2);
      holds(t, 'subtle rule', fluent2Step(t, c.neutralStroke3), 1.1);
      // A disabled face is the well out of use (held above): by day Fluent's
      // disabled grey laid as its step.
      if (t.brightness == Brightness.light) {
        expect(
          fluent2WellDisabled(t),
          fluent2Step(t, c.neutralBackgroundDisabled),
          reason: '$name: the disabled well is Fluent\'s disabled step',
        );
      }
      holds(t, 'chosen row', fluent2Step(t, c.subtleBackgroundSelected), 1.1);
      for (final g in grounds(t).values) {
        double over(Color f) =>
            Fluent2ThemeData.contrast(Color.alphaBlend(f, g), g);
        expect(
          over(fluent2Step(t, c.neutralStroke1)),
          greaterThan(over(fluent2Step(t, c.neutralStroke2))),
          reason: '$name: the strong rule no darker than the default',
        );
      }
      // The brand tint: 1.15:1 from the page it would vanish on, a step
      // from every other ground, its words in the brand's second ink.
      final tint = fluent2BrandWell(t);
      expect(
        Fluent2ThemeData.contrast(tint, t.background),
        greaterThanOrEqualTo(1.15),
        reason: '$name: brand tint on the page',
      );
      holds(t, 'brand tint', tint, 1.1);
      expect(
        Fluent2ThemeData.contrast(c.brandForeground2, tint),
        greaterThanOrEqualTo(4.5),
        reason: '$name: brand words on the brand tint',
      );
      // The words a well carries hold 4.5:1 on it over every ground: the
      // second ink (segments, tags, the informative badge), and the third
      // (a placeholder) on the field's lighter well.
      for (final g in grounds(t).entries) {
        for (final (what, ink, fill) in [
          (
            'second ink on the well',
            t.colors.neutralForeground2,
            fluent2Well(t),
          ),
          (
            'placeholder on the filled-darker field',
            fluent2PlaceholderInk(t, Fluent2InputAppearance.filledDarker),
            fluent2FieldWell(t),
          ),
        ]) {
          expect(
            Fluent2ThemeData.contrast(ink, Color.alphaBlend(fill, g.value)),
            greaterThanOrEqualTo(4.5),
            reason: '$name: $what on the ${g.key}',
          );
        }
      }
      holds(
        t,
        'informative badge',
        Fluent2BadgeFace.of(
          t,
          Fluent2BadgeAppearance.filled,
          Fluent2BadgeColor.informative,
        ).fill,
        1.15,
      );
    });

    testWidgets('the segmented track and a filled tab show ($name)', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          t,
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Fluent2SegmentedButton<String>(
                label: 'View',
                segments: const [
                  Fluent2ButtonSegment('day', 'Day'),
                  Fluent2ButtonSegment('week', 'Week'),
                  Fluent2ButtonSegment('month', 'Month'),
                ],
                value: 'week',
                onChanged: (_) {},
              ),
              Fluent2TabList(
                tabs: const ['Posts', 'Files'],
                selectedIndex: 0,
                appearance: Fluent2TabAppearance.filledCircular,
                onChanged: (_) {},
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      holds(
        t,
        'segmented track',
        _fillOf(tester, find.byType(Fluent2SegmentedButton<String>)),
        1.15,
      );
      // The second tab's face: unchosen, at rest.
      final faces = find
          .descendant(
            of: find.byType(Fluent2TabList),
            matching: find.byType(Container),
          )
          .evaluate()
          .map((e) => e.widget as Container)
          .where(
            (c) =>
                c.decoration is BoxDecoration &&
                (c.decoration! as BoxDecoration).color != null,
          )
          .toList();
      holds(
        t,
        'unchosen filled tab',
        (faces.last.decoration! as BoxDecoration).color!,
        1.15,
      );
    });
  }
}

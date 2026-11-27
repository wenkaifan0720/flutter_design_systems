// Words on a pearl part read at 4.5:1 where they stand, by day and by night,
// on each of the six gels: a selected GlossListTile's supporting words on the
// pearl plate under its row (by night they stood at about 3.7:1 on the
// moonlit pearl; on a row not selected they keep the secondary ink), and a
// chosen segment's jade words on its pearl, measured at its crown.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gloss_ui/gloss_ui.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;

Future<void> _show(
  WidgetTester tester,
  GlossThemeData theme, [
  Widget? part,
]) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, app) => GlossTheme(data: theme, child: app!),
      home: Align(
        alignment: Alignment.topCenter,
        child:
            part ??
            const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GlossListTile(
                  title: 'Proof the studio map',
                  subtitle: 'Open studio · Nov 20',
                  selected: true,
                ),
                GlossListTile(
                  title: 'Print the guide',
                  subtitle: 'Field guide',
                ),
              ],
            ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Color _colorOf(WidgetTester tester, String words) =>
    tester.widget<Text>(find.text(words)).style!.color!;

void main() {
  setUpAll(glossLoadFonts);

  for (final b in Brightness.values) {
    for (final name in [for (final p in GlossThemeData.palettes) p.id]) {
      testWidgets("${b.name}, $name: a selected row's supporting words read "
          'on its pearl plate', (tester) async {
        final theme = GlossThemeData.preset(name, b);
        await _show(tester, theme);
        final c = theme.colors;
        final plate = GlossFace.pearl(c);
        final words = _colorOf(tester, 'Open studio · Nov 20');
        for (final ground in [
          Color.lerp(plate.top, plate.middle, 0.4)!,
          plate.middle,
          plate.bottom,
        ]) {
          expect(
            RawPalette.contrastRatio(words, ground),
            greaterThanOrEqualTo(4.5),
          );
        }
        expect(_colorOf(tester, 'Field guide'), c.inkSecondary);
      });

      testWidgets("${b.name}, $name: a chosen segment's words read on its "
          'pearl', (tester) async {
        final theme = GlossThemeData.preset(name, b);
        await _show(
          tester,
          theme,
          GlossSegmentedButton<String>(
            segments: const [
              GlossSegment(value: 'day', label: 'Daily'),
              GlossSegment(value: 'week', label: 'Weekly'),
            ],
            selected: 'week',
            onChanged: (_) {},
          ),
        );
        final words = _colorOf(tester, 'Weekly');
        expect(
          RawPalette.contrastRatio(words, GlossFace.pearl(theme.colors).top),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          RawHct.fromColor(words).hue,
          closeTo(RawHct.fromColor(theme.colors.jadeInk).hue, 12),
        );
      });
    }
  }
}

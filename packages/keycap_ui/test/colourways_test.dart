// Keycap's colourways: the six are ui_core's named palettes and the host takes one; a tone's ink stays apart from the
// others, and a note's from the accent's words, in every colourway, day and night.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keycap_ui/keycap_ui.dart';
import 'package:ui_core_test/ui_core_test.dart';

void main() {
  test("the six colourways are ui_core's named palettes, each with its keys' colours", () {
    expect([
      for (final p in KeycapThemeData.palettes) p.id,
    ], KeycapThemeData.presets);
    for (final p in KeycapThemeData.palettes) {
      for (final b in Brightness.values) {
        final c = KeycapThemeData.preset(p.id, b).colors;
        expect(p.swatchesFor(b), [
          c.accent.top,
          c.modifier.top,
          c.alpha.top,
        ], reason: '${p.id} $b');
      }
    }
  });

  testWidgets('the host takes a palette', (tester) async {
    final sage = KeycapThemeData.palettes.firstWhere((p) => p.id == 'sage');
    late KeycapThemeData shown;
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: KeycapHost(
          palette: sage,
          brightness: Brightness.dark,
          child: Builder(
            builder: (context) {
              shown = KeycapTheme.of(context);
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 2));
    expect(
      shown.colors,
      KeycapThemeData.preset('sage', Brightness.dark).colors,
    );
  });

  test("a tone's ink stays apart from the others in every colourway, day and night", () {
    const DesignToneCheck(look: 'Keycap').check([
      for (final palette in KeycapThemeData.palettes)
        for (final brightness in Brightness.values)
          DesignToneSet(
            palette: palette.label,
            brightness: brightness,
            tones: {
              for (final tone in KeycapTone.values)
                tone.name: tone.inkIn(
                  KeycapThemeData.preset(palette.id, brightness).colors,
                ),
            },
          ),
    ]).verify();
  });

  // A note never reads as a link or a choice: its ink stays apart from the
  // accent's words, in the six colourways and for a brand's key.
  test("a note's ink stays apart from the accent's words in every colourway and for a brand's key", () {
    const brands = [
      Color(0xFF2F59CF),
      Color(0xFF3B82F6),
      Color(0xFF0E7C86),
      Color(0xFF16807A),
      Color(0xFF6A4FC8),
      Color(0xFFC2477A),
    ];
    final sets = <DesignToneSet>[];
    void add(String name, Brightness brightness, KeycapColors c) {
      sets
        ..add(
          DesignToneSet(
            palette: name,
            brightness: brightness,
            tones: {'info': c.info, 'accent': c.accentInk},
          ),
        )
        ..add(
          DesignToneSet(
            palette: name,
            brightness: brightness,
            tones: {
              for (final tone in KeycapTone.values) tone.name: tone.inkIn(c),
            },
          ),
        );
    }

    for (final brightness in Brightness.values) {
      for (final palette in KeycapThemeData.palettes) {
        add(
          palette.label,
          brightness,
          KeycapThemeData.preset(palette.id, brightness).colors,
        );
      }
      for (final accent in brands) {
        add(
          'from(${accent.toARGB32().toRadixString(16)})',
          brightness,
          KeycapColors.from(brightness: brightness, accent: accent),
        );
      }
    }
    const DesignToneCheck(look: 'Keycap').check(sets).verify();
  });

  for (final b in Brightness.values) {
    testWidgets(
      "a destructive key's words and a date key's hint read 4.5:1 on the key in every colourway (${b.name})",
      (tester) async {
        for (final id in KeycapThemeData.presets) {
          final theme = KeycapThemeData.preset(id, b);
          await tester.pumpWidget(
            Directionality(
              textDirection: TextDirection.ltr,
              child: MediaQuery(
                data: const MediaQueryData(),
                child: KeycapTheme(
                  data: theme,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        KeycapButton(
                          isDestructiveAction: true,
                          onPressed: () {},
                          child: const Text('Remove'),
                        ),
                        SizedBox(
                          width: 300,
                          child: KeycapDatePicker(
                            hintText: 'Not yet',
                            value: null,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2030),
                            onChanged: (_) {},
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pump(const Duration(seconds: 1));
          Color ink(String words) => tester
              .widget<RichText>(
                find.byWidgetPredicate(
                  (w) => w is RichText && w.text.toPlainText() == words,
                ),
              )
              .text
              .style!
              .color!;
          final face = theme.colors.alpha.top;
          for (final words in ['Remove', 'Not yet']) {
            expect(
              keycapContrast(ink(words), face),
              greaterThanOrEqualTo(4.5),
              reason: '$id ${b.name}: "$words" ${ink(words)} on $face',
            );
          }
        }
      },
    );
  }
}

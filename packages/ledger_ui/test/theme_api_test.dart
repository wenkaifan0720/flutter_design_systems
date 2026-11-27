// The theme as a value: copyWith, lerp and equality round trip on every
// preset by day and by lamplight, the per-part styles with them, and
// LedgerTheme.of answers the default where no theme stands.
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_ui/ledger_ui.dart';

void main() {
  group('LedgerThemeData', () {
    for (final id in [for (final p in LedgerThemeData.palettes) p.id]) {
      for (final brightness in Brightness.values) {
        final at = '$id ${brightness.name}';
        final theme = LedgerThemeData.preset(id, brightness);

        test('$at: the same preset is the same value', () {
          final again = LedgerThemeData.preset(id, brightness);
          expect(again, theme);
          expect(again.hashCode, theme.hashCode);
        });

        test('$at: copyWith() with nothing is the same value', () {
          final copy = theme.copyWith();
          expect(copy, theme);
          expect(copy.hashCode, theme.hashCode);
        });

        test('$at: lerp lands on its ends and passes between them', () {
          final other = LedgerThemeData.preset(
            id == 'quire' ? 'carbon' : 'quire',
            brightness == Brightness.light ? Brightness.dark : Brightness.light,
          );
          expect(LedgerThemeData.lerp(theme, other, 0), theme);
          expect(LedgerThemeData.lerp(theme, other, 1), other);
          expect(LedgerThemeData.lerp(theme, theme, 0.5), theme);
          final mid = LedgerThemeData.lerp(theme, other, 0.5);
          expect(mid, isNot(theme));
          expect(mid, isNot(other));
          expect(mid.accent, Color.lerp(theme.accent, other.accent, 0.5));
        });
      }
    }

    test('copyWith changes what it is given and nothing else', () {
      final theme = LedgerThemeData.light();
      const red = Color(0xFFB3261E);
      final changed = theme.copyWith(accent: red);
      expect(changed.accent, red);
      expect(changed, isNot(theme));
      expect(changed.copyWith(accent: theme.accent), theme);
    });

    test('day and lamplight are different values', () {
      expect(LedgerThemeData.light(), isNot(LedgerThemeData.dark()));
    });

    test('names its values in the inspector', () {
      final names = LedgerThemeData.light()
          .toDiagnosticsNode()
          .getProperties()
          .map((p) => p.name)
          .toSet();
      expect(
        names,
        containsAll(<String>['brightness', 'accent', 'components']),
      );
    });
  });

  group('LedgerComponentThemes', () {
    const pill = LedgerStyle(
      shape: WidgetStatePropertyAll<OutlinedBorder?>(StadiumBorder()),
    );
    const roomy = LedgerStyle(
      padding: WidgetStatePropertyAll<EdgeInsetsGeometry?>(
        EdgeInsets.symmetric(horizontal: 24),
      ),
    );

    test('empty by default, and equal by value', () {
      expect(const LedgerComponentThemes().isEmpty, isTrue);
      expect(
        const LedgerComponentThemes(button: pill),
        const LedgerComponentThemes(button: pill),
      );
      expect(
        const LedgerComponentThemes(button: pill),
        isNot(const LedgerComponentThemes(chip: pill)),
      );
    });

    test('copyWith keeps what it is not given', () {
      const themes = LedgerComponentThemes(button: pill);
      final copy = themes.copyWith(chip: roomy);
      expect(copy.button, pill);
      expect(copy.chip, roomy);
      expect(themes.copyWith(), themes);
    });

    test('lerp lands on its ends', () {
      const a = LedgerComponentThemes(button: pill);
      const b = LedgerComponentThemes(button: roomy, chip: pill);
      final start = LedgerComponentThemes.lerp(a, b, 0);
      final end = LedgerComponentThemes.lerp(a, b, 1);
      const states = <WidgetState>{};
      expect(start.button?.shape?.resolve(states), const StadiumBorder());
      expect(
        end.button?.padding?.resolve(states),
        const EdgeInsets.symmetric(horizontal: 24),
      );
      expect(end.chip?.shape?.resolve(states), const StadiumBorder());
    });

    test('travel with the theme: copyWith, lerp and equality', () {
      final plain = LedgerThemeData.light();
      final styled = plain.copyWith(
        components: const LedgerComponentThemes(button: pill),
      );
      expect(styled, isNot(plain));
      expect(styled.components.button, pill);
      expect(styled.copyWith(), styled);
      expect(
        LedgerThemeData.lerp(
          plain,
          styled,
          1,
        ).components.button?.shape?.resolve(const <WidgetState>{}),
        const StadiumBorder(),
      );
    });
  });

  group('LedgerTheme.of', () {
    LedgerThemeData? found;
    Widget probe() => Builder(
      builder: (context) {
        found = LedgerTheme.of(context);
        return const SizedBox();
      },
    );

    testWidgets('answers the theme in scope', (t) async {
      final theme = LedgerThemeData.preset('indigo', Brightness.dark);
      await t.pumpWidget(LedgerTheme(data: theme, child: probe()));
      expect(found, theme);
    });

    testWidgets('with no theme, answers the default by day', (t) async {
      await t.pumpWidget(probe());
      expect(t.takeException(), isNull);
      expect(found, LedgerThemeData.light());
    });

    testWidgets('with no theme on a dark platform, the default by lamplight', (
      t,
    ) async {
      await t.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(platformBrightness: Brightness.dark),
          child: probe(),
        ),
      );
      expect(found, LedgerThemeData.dark());
    });
  });

  test('the public widgets name their settings in the inspector', () {
    String described(Diagnosticable d) => d.toDiagnosticsNode().toStringDeep();
    expect(
      described(const LedgerTextField(labelText: 'Name', maxLines: 2)),
      contains('maxLines: 2'),
    );
    expect(
      described(LedgerButton.filled('Save', onPressed: () {})),
      contains('Save'),
    );
  });

  test('values out of range fail an assert', () {
    // Not constants, so the asserts run when the test does.
    final none = 0;
    expect(
      () => LedgerCarousel(
        itemCount: 3,
        itemBuilder: (_, _) => const SizedBox(),
        semanticLabel: 'Cards',
        viewportFraction: 1.5,
      ),
      throwsAssertionError,
    );
    expect(
      () => LedgerCodeField(length: none, semanticLabel: 'Code'),
      throwsAssertionError,
    );
  });
}

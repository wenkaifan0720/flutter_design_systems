// What an app can change and what it cannot: a brand colour is held to 7:1
// on the ground and on a card by day and by night, keeping its hue; a focus plate that
// cannot carry ink words and a tap floor under 48 are refused; a part's
// own style wins over its theme slot, which wins over the look; the face
// reaches Flutter's own widgets under Civic.
import 'package:civic_ui/civic_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

double _hue(Color c) => HSLColor.fromColor(c).hue;

void main() {
  group('the brand factory', () {
    const green = Color(0xFF0A7D4F);

    test('holds an action colour to 7:1 by day, darker, its hue kept', () {
      final t = CivicThemeData.from(
        brightness: Brightness.light,
        action: green,
      );
      // By day the ground is the darker of the two the words stand on.
      final ratio = CivicThemeData.contrastRatio(t.action, t.ground);
      expect(ratio, greaterThanOrEqualTo(7));
      expect(ratio, lessThan(7.4), reason: 'darkened no further than needed');
      expect(
        CivicThemeData.contrastRatio(t.action, t.background),
        greaterThanOrEqualTo(7),
      );
      expect(_hue(t.action), closeTo(_hue(green), 2));
      expect(
        HSLColor.fromColor(t.action).lightness,
        lessThan(HSLColor.fromColor(green).lightness),
      );
    });

    test('lightens it by night', () {
      final t = CivicThemeData.from(brightness: Brightness.dark, action: green);
      expect(
        CivicThemeData.contrastRatio(t.action, t.background),
        greaterThanOrEqualTo(7),
      );
      expect(_hue(t.action), closeTo(_hue(green), 2));
      expect(
        HSLColor.fromColor(t.action).lightness,
        greaterThan(HSLColor.fromColor(green).lightness),
      );
    });

    test('holds danger and success the same way', () {
      for (final b in Brightness.values) {
        final t = CivicThemeData.from(
          brightness: b,
          danger: const Color(0xFFFF4D4D),
          success: const Color(0xFF33CC66),
        );
        for (final c in [t.danger, t.success]) {
          expect(
            CivicThemeData.contrastRatio(c, t.background),
            greaterThanOrEqualTo(7),
          );
        }
      }
    });

    test("keeps a button's words at 4.5:1 on any action colour", () {
      for (final seed in const [
        Color(0xFF0A7D4F),
        Color(0xFF6A1B9A),
        Color(0xFFE65100),
        Color(0xFF00838F),
      ]) {
        for (final b in Brightness.values) {
          final t = CivicThemeData.from(brightness: b, action: seed);
          expect(
            CivicThemeData.contrastRatio(t.onAction, t.action),
            greaterThanOrEqualTo(4.5),
          );
        }
      }
    });

    test('refuses a focus plate that cannot carry ink words', () {
      expect(
        () => CivicThemeData.from(
          brightness: Brightness.light,
          focus: const Color(0xFF1F5FBF),
        ),
        throwsAssertionError,
      );
      // A lighter, warmer plate is fine.
      CivicThemeData.from(
        brightness: Brightness.light,
        focus: const Color(0xFFFFB84D),
      );
    });

    test('refuses a tap floor under 48 for a finger or 24 for a pointer', () {
      final t = CivicThemeData.light();
      expect(
        () => t.copyWith(
          tapTargets: const DesignTapTargets(touch: Size.square(40)),
        ),
        throwsAssertionError,
      );
      expect(
        () => t.copyWith(
          tapTargets: const DesignTapTargets(
            touch: Size.square(48),
            pointer: Size.square(20),
          ),
        ),
        throwsAssertionError,
      );
      // A floor can rise.
      t.copyWith(
        tapTargets: const DesignTapTargets(
          touch: Size.square(56),
          pointer: Size.square(32),
        ),
      );
    });

    test('sets the face for the ramp, keeping figures in code', () {
      final t = CivicThemeData.from(
        brightness: Brightness.light,
        fontFamily: 'Serif',
      );
      expect(t.text.body.fontFamily, 'Serif');
      expect(t.compactText.headingXL.fontFamily, 'Serif');
      expect(t.text.code.fontFamily, isNot('Serif'));
    });
  });

  group('the two layers', () {
    Future<Color?> tagInk(
      WidgetTester tester, {
      CivicStyle? style,
      CivicStyle? slot,
    }) async {
      final base = CivicThemeData.light();
      await tester.pumpWidget(
        MaterialApp(
          home: CivicTheme(
            data: base.copyWith(tagStyle: slot),
            child: Center(
              child: CivicTag(label: 'Sent', style: style),
            ),
          ),
        ),
      );
      final text = tester.widget<RichText>(
        find.descendant(
          of: find.byType(CivicTag),
          matching: find.byType(RichText),
        ),
      );
      return text.text.style?.color;
    }

    testWidgets("a part's style wins over its slot, the slot over the look", (
      tester,
    ) async {
      const mine = Color(0xFF123456);
      const theirs = Color(0xFF654321);
      final look = await tagInk(tester);
      expect(look, isNot(anyOf(mine, theirs)));
      expect(
        await tagInk(
          tester,
          slot: const CivicStyle(foreground: WidgetStatePropertyAll(theirs)),
        ),
        theirs,
      );
      expect(
        await tagInk(
          tester,
          slot: const CivicStyle(foreground: WidgetStatePropertyAll(theirs)),
          style: const CivicStyle(foreground: WidgetStatePropertyAll(mine)),
        ),
        mine,
      );
    });

    testWidgets('a button kind reads its own slot', (tester) async {
      final base = CivicThemeData.light();
      const pad = EdgeInsets.symmetric(horizontal: 80);
      Future<double> width(Widget button, CivicThemeData data) async {
        await tester.pumpWidget(
          MaterialApp(
            home: CivicTheme(
              data: data,
              child: Center(child: button),
            ),
          ),
        );
        return tester.getSize(find.byType(CivicButton)).width;
      }

      Widget primary() => CivicButton(
        onPressed: () {},
        expand: false,
        child: const Text('Continue'),
      );
      Widget secondary() => CivicButton.secondary(
        onPressed: () {},
        expand: false,
        child: const Text('Continue'),
      );
      final wider = base.copyWith(
        primaryButtonStyle: const CivicStyle(
          padding: WidgetStatePropertyAll(pad),
        ),
      );
      expect(
        await width(primary(), wider),
        greaterThan(await width(primary(), base)),
      );
      expect(await width(secondary(), wider), await width(secondary(), base));
    });

    testWidgets('an icon button never stands under 48', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CivicTheme(
            data: CivicThemeData.light(),
            child: Center(
              child: CivicIconButton(
                onPressed: () {},
                semanticLabel: 'Close',
                style: const CivicStyle(
                  minimumSize: WidgetStatePropertyAll(Size.square(24)),
                ),
                icon: Icons.close,
              ),
            ),
          ),
        ),
      );
      final size = tester.getSize(find.byType(CivicIconButton));
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
    });

    testWidgets("the face reaches Flutter's own widgets under Civic", (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CivicTheme(
            data: CivicThemeData.from(
              brightness: Brightness.light,
              fontFamily: 'Serif',
            ),
            child: Builder(
              builder: (context) => Text(
                Theme.of(context).textTheme.bodyMedium?.fontFamily ?? '',
              ),
            ),
          ),
        ),
      );
      expect(find.text('Serif'), findsOneWidget);
    });
  });
}

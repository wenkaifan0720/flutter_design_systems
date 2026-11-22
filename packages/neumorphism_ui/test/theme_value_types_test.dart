// The theme's parts are values, as Flutter's own theme data are: NeumorphicTextTheme compares by what it holds, and
// copies and blends; NeumorphicColors copies with any colour replaced.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

void main() {
  final day = NeumorphicThemeData.porcelain();
  final night = NeumorphicThemeData.porcelain(Brightness.dark);

  group('NeumorphicTextTheme', () {
    test('two text themes that hold the same things are equal', () {
      final again = day.copyWith(id: 'again').textTheme;
      expect(identical(again, day.textTheme), isFalse);
      expect(again, day.textTheme);
      expect(again.hashCode, day.textTheme.hashCode);
      expect(night.textTheme, isNot(day.textTheme));
    });

    test('copyWith replaces what it is given and keeps the rest', () {
      final text = day.textTheme;
      expect(text.copyWith(), text);
      final desk = text.copyWith(desk: true);
      expect(desk.desk, isTrue);
      expect(desk.page.fontSize, 48);
      expect(desk.colors, text.colors);
      expect(desk.typeface, text.typeface);
      final inNight = text.copyWith(colors: night.colors);
      expect(inNight.body.color, night.colors.ink);
      expect(inNight.desk, text.desk);
    });

    test('lerp blends the inks and snaps the desktop sizes at the middle', () {
      final a = day.textTheme;
      final b = night.textTheme.copyWith(desk: true);
      expect(NeumorphicTextTheme.lerp(a, b, 0), a);
      expect(NeumorphicTextTheme.lerp(a, b, 1), b);
      final half = NeumorphicTextTheme.lerp(a, b, .5);
      expect(half.body.color, Color.lerp(a.colors.ink, b.colors.ink, .5));
      expect(NeumorphicTextTheme.lerp(a, b, .4).desk, isFalse);
      expect(half.desk, isTrue);
    });
  });

  group('NeumorphicColors', () {
    test('copyWith replaces the colours it is given and keeps the rest', () {
      final c = day.colors;
      expect(c.copyWith(), c);
      const red = Color(0xFFD03030);
      final inked = c.copyWith(ink: red, dark: true);
      expect(inked.ink, red);
      expect(inked.dark, isTrue);
      expect(inked.ground, c.ground);
      expect(inked.accent, c.accent);
      expect(inked, isNot(c));
    });

    test('the pigment goes by its own names', () {
      final c = day.colors;
      const green = Color(0xFF2E7D32), white = Color(0xFFFFFFFF);
      final painted = c.copyWith(pigment: green, onPigment: white);
      expect(painted.accent, green);
      expect(painted.onAccent, white);
      expect(painted.accentInk, c.accentInk);
      final inked = c.copyWith(pigmentInk: white);
      expect(inked.accentInk, white);
      expect(inked.accent, c.accent);
    });

    test('a theme takes the copy', () {
      final colors = day.colors.copyWith(ground: const Color(0xFFE8E3ED));
      final theme = day.copyWith(colors: colors);
      expect(theme.colors.ground, const Color(0xFFE8E3ED));
      expect(theme.textTheme.colors, colors);
    });
  });
}

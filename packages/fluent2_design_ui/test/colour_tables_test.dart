// Fluent 2's colour tables compare by value and blend colour by colour, as
// Material's ColorScheme does, and a theme compares and blends its tables so.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluent2_design_ui/fluent2_design_ui.dart';

void main() {
  final light = Fluent2ThemeData.lapis();
  final dark = Fluent2ThemeData.lapis(Brightness.dark);

  test('a colour table equals a copy of it built apart', () {
    final copy = Fluent2Colors.fromMap(light.colors.toMap());
    expect(identical(copy, light.colors), isFalse);
    expect(copy, light.colors);
    expect(copy.hashCode, light.colors.hashCode);
    expect(light.colors, isNot(dark.colors));
  });

  test('a theme with an equal shared palette built apart equals the theme', () {
    final palette = Fluent2SharedColors.lerp(
      light.sharedColors,
      dark.sharedColors,
      0,
    );
    expect(identical(palette, light.sharedColors), isFalse);
    expect(palette, light.sharedColors);
    final copy = light.copyWith(sharedColors: palette);
    expect(copy, light);
    expect(copy.hashCode, light.hashCode);
  });

  test('a theme halfway to another blends its shared palette', () {
    final mid = light.lerp(dark, .5);
    final a = light.sharedColors.paletteRedBackground1;
    final b = dark.sharedColors.paletteRedBackground1;
    expect(a, isNot(b));
    expect(mid.sharedColors.paletteRedBackground1, Color.lerp(a, b, .5));
    expect(
      mid.colors.neutralBackground1,
      isNot(dark.colors.neutralBackground1),
    );
  });
}

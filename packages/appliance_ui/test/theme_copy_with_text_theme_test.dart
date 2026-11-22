// A theme copied with new colours recolours its text and keeps its face: a
// brand's family (and the package it comes from) set through
// ApplianceThemeData.from stays, as do its sizes; the words take the new
// colours' print.
import 'package:appliance_ui/appliance_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('copyWith(colors:) keeps the family set through from(fontFamily:)', () {
    final branded = ApplianceThemeData.from(
      brightness: Brightness.light,
      fontFamily: 'Inter',
    );
    final night = branded.copyWith(colors: ApplianceColors.dark);
    expect(night.textTheme.body.fontFamily, 'Inter');
    expect(night.textTheme.title.fontFamily, 'Inter');
    expect(night.textTheme.body.fontSize, branded.textTheme.body.fontSize);
    expect(night.textTheme.body.color, ApplianceColors.dark.print);
    expect(night.textTheme.secondary.color, ApplianceColors.dark.printMuted);
  });

  test('copyWith(colors:) keeps the package a family comes from', () {
    final branded = ApplianceThemeData.from(
      brightness: Brightness.light,
      fontFamily: 'Inter',
      fontPackage: 'brand_fonts',
    );
    final night = branded.copyWith(colors: ApplianceColors.dark);
    expect(night.textTheme.body.fontFamily, 'packages/brand_fonts/Inter');
    expect(
      night.textTheme.legend,
      branded.textTheme.legend.copyWith(color: ApplianceColors.dark.printMuted),
    );
  });

  test(
    'copyWith(colors:) on the preset matches the preset in those colours',
    () {
      expect(
        ApplianceThemeData.light()
            .copyWith(colors: ApplianceColors.dark)
            .textTheme,
        ApplianceThemeData.dark().textTheme,
      );
    },
  );
}

// Tags, monograms and the glyphs set beside words grow with the reader's
// text size, as the words do: at 200% a tag's words, its lamp and its plate,
// an avatar in a row's register and its initials, a row's glyph and a key's
// glyph beside its legend are larger than at 100%; a portrait keeps its
// size.
import 'package:appliance_ui/appliance_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;

Widget _at(double scale, Widget child) => MaterialApp(
  builder: (context, app) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
    child: ApplianceHost(brightness: Brightness.light, child: app!),
  ),
  home: Center(child: child),
);

void main() {
  setUpAll(applianceLoadFonts);

  testWidgets('a tag, its lamp and its words grow with the text', (
    tester,
  ) async {
    final sizes = <double, ({double plate, double lamp, double words})>{};
    for (final scale in const [1.0, 2.0]) {
      await tester.pumpWidget(
        _at(
          scale,
          const ApplianceTag('In stock', tone: ApplianceTagTone.ready),
        ),
      );
      await tester.pumpAndSettle();
      final lamp = find.descendant(
        of: find.byType(ApplianceTag),
        matching: find.byType(ApplianceLamp),
      );
      sizes[scale] = (
        plate: tester.getSize(find.byType(ApplianceTag)).height,
        lamp: tester.getSize(lamp.first).height,
        words: tester.getSize(find.text('IN STOCK')).height,
      );
    }
    expect(sizes[2]!.words, greaterThan(sizes[1]!.words * 1.5));
    expect(sizes[2]!.lamp, greaterThan(sizes[1]!.lamp * 1.5));
    expect(sizes[2]!.plate, greaterThan(sizes[1]!.plate * 1.4));
  });

  testWidgets("a row's avatar and its initials grow with the text; a "
      'portrait keeps its size', (tester) async {
    final discs = <double>[], letters = <double>[], portraits = <double>[];
    for (final scale in const [1.0, 2.0]) {
      await tester.pumpWidget(
        _at(
          scale,
          const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ApplianceAvatar(name: 'Ana Lima'),
              ApplianceAvatar(name: 'Bo Ek', size: 96),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      discs.add(tester.getSize(find.byType(ApplianceAvatar).first).height);
      letters.add(tester.getSize(find.text('AL')).height);
      portraits.add(tester.getSize(find.byType(ApplianceAvatar).last).height);
    }
    expect(discs[1], greaterThan(discs[0] * 1.5));
    expect(letters[1], greaterThan(letters[0] * 1.3));
    expect(portraits[1], portraits[0]);
  });

  testWidgets("a row's, a key's and a chip's glyph grow with the text", (
    tester,
  ) async {
    final rows = <double>[], keys = <double>[], chips = <double>[];
    for (final scale in const [1.0, 2.0]) {
      await tester.pumpWidget(
        _at(
          scale,
          SizedBox(
            width: 600,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const ApplianceListGroup(
                  children: [
                    ApplianceListTile(
                      leading: Icon(LucideIcons.bell, key: ValueKey('row')),
                      title: 'Order updates',
                    ),
                  ],
                ),
                ApplianceButton(
                  'Add',
                  icon: const Icon(LucideIcons.plus, key: ValueKey('key')),
                  onPressed: () {},
                ),
                ApplianceChip(
                  'On offer',
                  icon: const Icon(LucideIcons.tag, key: ValueKey('chip')),
                  onSelected: (_) {},
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      rows.add(tester.getSize(find.byKey(const ValueKey('row'))).height);
      keys.add(tester.getSize(find.byKey(const ValueKey('key'))).height);
      chips.add(tester.getSize(find.byKey(const ValueKey('chip'))).height);
    }
    expect(rows[1], greaterThan(rows[0] * 1.5));
    expect(keys[1], greaterThan(keys[0] * 1.5));
    expect(chips[1], greaterThan(chips[0] * 1.5));
  });
}

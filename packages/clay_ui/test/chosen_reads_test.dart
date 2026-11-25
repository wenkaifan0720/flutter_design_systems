// What Clay draws on a chosen part reads on it in Clay's palette and a
// brand's, by day and by night: a chosen row's second words, value and
// chevron (secondary ink on the warm plate, 4.5:1; they read 3.6:1 by
// night), and the chosen place's glyph in a sidebar (the accent's ink on
// its risen clay, 3:1; a navy brand's sank to 2.5:1 by night).
import 'package:clay_ui/clay_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;

const _briefs = {
  'navy': Color(0xFF1F3A68),
  'green': Color(0xFF2E7D32),
  'gold': Color(0xFFC9A227),
  'purple': Color(0xFF6D28D9),
  'blush': Color(0xFFF4A7B9),
};

Map<String, ClayThemeData> _themes(Brightness b) => {
  'clay': ClayThemeData.clay(b),
  for (final MapEntry(key: name, value: accent) in _briefs.entries)
    name: ClayThemeData.from(accent: accent, brightness: b),
};

Future<void> _show(
  WidgetTester tester,
  ClayThemeData theme,
  Widget part,
) async {
  tester.view.physicalSize = const Size(1440, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, app) => ClayTheme(data: theme, child: app!),
      home: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(width: 400, height: 600, child: part),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Color _textColour(WidgetTester tester, String text) =>
    tester.widget<Text>(find.text(text)).style!.color!;

void main() {
  setUpAll(clayLoadFonts);

  for (final b in Brightness.values) {
    for (final MapEntry(key: name, value: theme) in _themes(b).entries) {
      testWidgets('${b.name}, $name: a chosen row\'s second words and value '
          'read on its plate', (tester) async {
        await _show(
          tester,
          theme,
          ClayListTile(
            title: 'Proof the studio map',
            subtitle: 'Open studio · Nov 20',
            trailingText: '3 days',
            selected: true,
            onTap: () {},
          ),
        );
        final plate = clayChosenFill(theme.colors);
        for (final words in ['Open studio · Nov 20', '3 days']) {
          expect(
            clayContrast(_textColour(tester, words), plate),
            greaterThanOrEqualTo(4.5),
            reason: words,
          );
        }
      });

      testWidgets("${b.name}, $name: the chosen place's glyph stands 3:1 on "
          'its risen clay', (tester) async {
        await _show(
          tester,
          theme,
          ClaySidebar(
            destinations: const [
              ClayDestination(icon: LucideIcons.sun, label: 'Today'),
              ClayDestination(icon: LucideIcons.listChecks, label: 'Habits'),
            ],
            selectedIndex: 0,
            onDestinationSelected: (_) {},
          ),
        );
        final glyph = tester.widget<Icon>(find.byIcon(LucideIcons.sun));
        expect(
          clayContrast(glyph.color!, theme.colors.risen),
          greaterThanOrEqualTo(3),
        );
      });
    }
  }

  testWidgets("a row that is not chosen keeps Clay's secondary ink", (
    tester,
  ) async {
    final theme = ClayThemeData.clay(Brightness.dark);
    await _show(
      tester,
      theme,
      const ClayListTile(
        title: 'Proof the studio map',
        subtitle: 'Open studio',
      ),
    );
    expect(_textColour(tester, 'Open studio'), theme.colors.inkSecondary);
  });
}

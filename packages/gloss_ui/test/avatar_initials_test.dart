// An avatar's initials are sized to the disc as it is laid out: in a list
// row's 24 leading slot a 32 avatar is a 24 disc, its initials with 4 px and
// more clear each side (they were sized to 32, about 3 px from the rim). A
// free avatar keeps its initials at 0.38 of its size. The initials take the
// ink, 4.5:1 or more on the bead by day and by night (at night the second
// ink stood 3.8:1 on it).
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gloss_ui/gloss_ui.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;

double _contrast(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

Future<void> _show(
  WidgetTester tester,
  Widget part, {
  Brightness brightness = Brightness.light,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, app) => GlossHost(
        theme: GlossThemeData.light(),
        darkTheme: GlossThemeData.dark(),
        brightness: brightness,
        child: app!,
      ),
      home: Align(
        alignment: Alignment.topCenter,
        child: Padding(padding: const EdgeInsets.all(24), child: part),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(glossLoadFonts);

  testWidgets("in a row's leading slot the initials stand clear of the rim", (
    tester,
  ) async {
    await _show(
      tester,
      const GlossListTile(
        leading: GlossAvatar(name: 'Maya Reed', size: 32),
        title: 'Maya Reed',
      ),
    );
    final disc = tester.getRect(find.byType(GlossAvatar));
    final initials = tester.getRect(find.text('MR'));
    expect(disc.width, 24);
    expect(initials.left - disc.left, greaterThanOrEqualTo(4));
    expect(disc.right - initials.right, greaterThanOrEqualTo(4));
  });

  testWidgets('a free avatar keeps its initials at 0.38 of its size', (
    tester,
  ) async {
    await _show(tester, const GlossAvatar(name: 'Maya Reed'));
    expect(tester.getSize(find.byType(GlossAvatar)), const Size(40, 40));
    expect(tester.widget<Text>(find.text('MR')).style?.fontSize, 40 * 0.38);
  });

  testWidgets('the initials read on the bead by day and by night', (
    tester,
  ) async {
    for (final brightness in Brightness.values) {
      await _show(
        tester,
        const GlossAvatar(name: 'Maya Reed'),
        brightness: brightness,
      );
      final ink = tester.widget<Text>(find.text('MR')).style!.color!;
      final bead = GlossFace.pearl(
        GlossTheme.of(tester.element(find.text('MR'))).colors,
      );
      for (final glaze in [bead.top, bead.middle, bead.bottom]) {
        expect(
          _contrast(ink, glaze),
          greaterThanOrEqualTo(4.5),
          reason: '$brightness: $ink on $glaze',
        );
      }
    }
  });
}

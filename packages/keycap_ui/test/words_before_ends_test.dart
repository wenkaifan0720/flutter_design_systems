// At twice the text size on a phone, words that say what a part is stay
// whole: an input group's add-ons ("https://", ".notes") print smaller
// rather than be cut to "…htt", and a command's name keeps its room beside
// its shortcut, which prints smaller instead. At the usual size nothing
// prints smaller.
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keycap_ui/keycap_ui.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;

Future<void> _show(
  WidgetTester tester,
  Widget child, {
  required double scale,
  required TextDirection direction,
}) async {
  tester.view.devicePixelRatio = 2;
  tester.view.physicalSize = const Size(390 * 2, 844 * 2);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, app) => MediaQuery.withClampedTextScaling(
        minScaleFactor: scale,
        maxScaleFactor: scale,
        child: KeycapHost(brightness: Brightness.light, child: app!),
      ),
      home: Directionality(
        textDirection: direction,
        child: Align(
          alignment: Alignment.topCenter,
          child: Padding(padding: const EdgeInsets.all(16), child: child),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

const _group = KeycapInputGroup(
  label: 'Address',
  prefix: 'https://',
  suffix: '.notes',
);

final _palette = SizedBox(
  width: 340,
  child: KeycapCommandPalette(
    commands: [
      RawCommand(
        label: 'New note',
        group: 'Notes',
        shortcut: 'Command+N',
        onPressed: () {},
      ),
    ],
  ),
);

RenderParagraph _paragraph(WidgetTester tester, String text) =>
    tester.renderObject<RenderParagraph>(find.text(text));

void main() {
  setUpAll(keycapLoadFonts);

  for (final direction in TextDirection.values) {
    testWidgets('an input group keeps its add-ons whole at 2x, '
        '${direction.name}', (tester) async {
      await _show(tester, _group, scale: 2, direction: direction);
      for (final words in ['https://', '.notes']) {
        expect(
          _paragraph(tester, words).didExceedMaxLines,
          isFalse,
          reason: '"$words" cut',
        );
      }
      // The entry keeps a third of the well.
      final well = tester.getRect(find.byType(KeycapInputGroup));
      final entry = tester.getRect(find.byType(EditableText));
      expect(entry.width, greaterThanOrEqualTo(well.width / 3 - 32));
    });

    testWidgets('a command keeps its name whole beside its shortcut at 2x, '
        '${direction.name}', (tester) async {
      await _show(tester, _palette, scale: 2, direction: direction);
      expect(
        _paragraph(tester, 'New note').didExceedMaxLines,
        isFalse,
        reason: '"New note" cut',
      );
      expect(find.text('Command+N'), findsOneWidget);
      final name = tester.getRect(find.text('New note'));
      final shortcut = tester.getRect(find.text('Command+N'));
      expect(
        name.overlaps(shortcut),
        isFalse,
        reason: 'name $name, shortcut $shortcut',
      );
    });
  }

  testWidgets('at the usual size add-ons and shortcuts print full size', (
    tester,
  ) async {
    await _show(
      tester,
      Column(children: [_group, const SizedBox(height: 16), _palette]),
      scale: 1,
      direction: TextDirection.ltr,
    );
    for (final words in ['https://', '.notes']) {
      final paragraph = _paragraph(tester, words);
      expect(paragraph.textScaler.scale(16), 16, reason: '"$words" smaller');
      expect(paragraph.didExceedMaxLines, isFalse);
    }
    final shortcut = _paragraph(tester, 'Command+N');
    expect(
      tester.getRect(find.text('Command+N')).width,
      moreOrLessEquals(shortcut.size.width, epsilon: 0.5),
      reason: 'the shortcut printed smaller',
    );
    expect(_paragraph(tester, 'New note').didExceedMaxLines, isFalse);
  });
}

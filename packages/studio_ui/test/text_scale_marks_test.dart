// A row's leading glyph and a small avatar grow with the reader's text, as
// the words beside them do, up to the 40 px a row's avatar takes; a 40 px
// avatar keeps its size. A tag's words grow; its lamp stays 6 px.
import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studio_ui/studio_ui.dart';

Future<void> _pump(WidgetTester tester, double scale) async {
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, app) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: StudioHost(brightness: Brightness.light, child: app!),
      ),
      home: StudioScreen(
        body: Column(
          children: [
            StudioListGroup(
              children: [
                StudioListTile(
                  leading: const Icon(LucideIcons.mic),
                  title: 'Record',
                  onTap: () {},
                ),
              ],
            ),
            const StudioAvatar(
              key: ValueKey('small'),
              name: 'Ada Lovelace',
              size: 24,
            ),
            const StudioAvatar(key: ValueKey('row'), name: 'Ada Lovelace'),
            const StudioTag('Live', tone: StudioTagTone.lit),
          ],
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(studioLoadFonts);

  testWidgets('glyphs, monograms and tags grow with the text', (tester) async {
    await _pump(tester, 1);
    expect(tester.getSize(find.byIcon(LucideIcons.mic)).width, 24);
    expect(tester.getSize(find.byKey(const ValueKey('small'))).width, 24);
    final tag = tester.getSize(find.byType(StudioTag)).height;
    final lamp = tester
        .getSize(
          find.descendant(
            of: find.byType(StudioTag),
            matching: find.byType(StudioLamp),
          ),
        )
        .width;
    await _pump(tester, 2);
    expect(tester.getSize(find.byIcon(LucideIcons.mic)).width, 40);
    expect(tester.getSize(find.byKey(const ValueKey('small'))).width, 40);
    expect(tester.getSize(find.byKey(const ValueKey('row'))).width, 40);
    expect(tester.getSize(find.byType(StudioTag)).height, greaterThan(tag));
    expect(
      tester
          .getSize(
            find.descendant(
              of: find.byType(StudioTag),
              matching: find.byType(StudioLamp),
            ),
          )
          .width,
      lamp,
    );
  });
}

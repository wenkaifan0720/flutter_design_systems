// The side navigation (from 1024 wide) is as wide as its words need at the
// reader's text size, from 240 to a third of the window, in Civic's own
// face (the test font sets every letter a square, wider than any face):
// every word of the service's name and the places stands whole, wrapping
// by words, and at the reader's own size the app's act stands on one line;
// the choice moving along the places leaves the width alone.
import 'dart:convert';

import 'package:civic_ui/civic_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

const _places = [
  CivicNavItem(LucideIcons.house, 'Home', ValueKey('home')),
  CivicNavItem(LucideIcons.fileText, 'Applications', ValueKey('applications')),
  CivicNavItem(LucideIcons.circleUser, 'Account', ValueKey('account')),
];

const _service = 'Brindlemere parking permits';
const _act = 'Apply for a permit';

Future<void> _loadFonts() async {
  final manifest = json.decode(
    await rootBundle.loadString('FontManifest.json'),
  ) as List<dynamic>;
  for (final entry in manifest.cast<Map<String, dynamic>>()) {
    final family = entry['family'] as String;
    final loader = FontLoader(
      family.startsWith('packages/') ? family : civicFontFamily(family),
    );
    for (final font
        in (entry['fonts'] as List<dynamic>).cast<Map<String, dynamic>>()) {
      loader.addFont(rootBundle.load(font['asset'] as String));
    }
    await loader.load();
  }
}

Widget _frame(int place) => CivicPreview(
  tabs: _places,
  activeIndex: place,
  brand: _service,
  action: CivicShellAction(
    icon: LucideIcons.plus,
    label: _act,
    accent: true,
    onPressed: (_) {},
  ),
  child: const CivicScreen(
    topBar: CivicTopBar(title: _service),
    body: Text('A permit lets you park in your zone at any time.'),
  ),
);

Future<void> _show(
  WidgetTester tester, {
  required double width,
  required double text,
  int place = 1,
}) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = text;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await tester.pumpWidget(_frame(place));
  await tester.pumpAndSettle();
}

// The side navigation's width: where its places end.
double _side(WidgetTester tester) =>
    tester.getRect(find.byKey(const ValueKey('applications'))).width;

void main() {
  setUpAll(_loadFonts);

  for (final (width, text) in [
    (1024.0, 1.0),
    (1440.0, 1.0),
    (1024.0, 2.0),
    (1440.0, 2.0),
  ]) {
    testWidgets('the side navigation keeps its words whole '
        '($width, text x$text)', (tester) async {
      await _show(tester, width: width, text: text);
      expect(tester.takeException(), isNull);
      // The service's name is the side's header and the top bar's title.
      final words = [_service, 'Home', 'Applications', 'Account', _act];
      for (final say in words) {
        for (final paragraph in tester.renderObjectList<RenderParagraph>(
          find.text(say),
        )) {
          // No word broken: the longest word fits the line.
          expect(
            paragraph.getMinIntrinsicWidth(double.infinity),
            lessThanOrEqualTo(paragraph.size.width + 0.01),
            reason: say,
          );
          expect(paragraph.didExceedMaxLines, isFalse, reason: say);
        }
      }
      if (text == 1) {
        final act = tester.renderObject<RenderParagraph>(find.text(_act));
        expect(
          act.getMaxIntrinsicWidth(double.infinity),
          lessThanOrEqualTo(act.size.width + 0.01),
          reason: "the act's words on one line",
        );
      }
      final side = _side(tester);
      expect(side, greaterThanOrEqualTo(CivicLayout.sideNavigationWidth));
      expect(side, lessThanOrEqualTo(width / 3 + 0.01));
    });
  }

  testWidgets('the side navigation keeps its width as the choice moves', (
    tester,
  ) async {
    await _show(tester, width: 1440, text: 2, place: 0);
    final first = _side(tester);
    final page = tester.getRect(find.textContaining('A permit lets you'));
    for (final place in [1, 2]) {
      await tester.pumpWidget(_frame(place));
      await tester.pumpAndSettle();
      expect(_side(tester), first, reason: '$place');
      expect(
        tester.getRect(find.textContaining('A permit lets you')).left,
        page.left,
        reason: '$place',
      );
    }
  });
}

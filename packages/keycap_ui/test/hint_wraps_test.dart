// A text area's hint wraps over the area's lines, as its words would: at a
// large text size on a phone, "What goes in this folder" is never cut to
// "What goes in this f…". A one-line field still ends its hint in an ellipsis.
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keycap_ui/keycap_ui.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;

Future<void> _show(WidgetTester tester, Widget field) async {
  tester.view.devicePixelRatio = 2;
  tester.view.physicalSize = const Size(390 * 2, 844 * 2);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, app) => MediaQuery.withClampedTextScaling(
        minScaleFactor: 2,
        maxScaleFactor: 2,
        child: KeycapHost(brightness: Brightness.light, child: app!),
      ),
      home: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [field],
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

RenderParagraph _hint(WidgetTester tester, String hint) =>
    tester.renderObject<RenderParagraph>(find.text(hint));

void main() {
  setUpAll(keycapLoadFonts);

  testWidgets("a text area's hint wraps at 2x text on a phone", (tester) async {
    const hint = 'What goes in this folder';
    await _show(
      tester,
      const KeycapTextField(
        label: 'Description',
        hint: hint,
        maxLines: 4,
        minLines: 3,
      ),
    );
    final words = _hint(tester, hint);
    expect(words.didExceedMaxLines, isFalse, reason: 'the hint is not cut');
    final lineHeight = words.getFullHeightForCaret(
      const TextPosition(offset: 0),
    );
    expect(words.size.height, greaterThan(lineHeight * 1.5));
  });

  testWidgets("a one-line field's hint still ends in an ellipsis", (
    tester,
  ) async {
    const hint = 'Where shared notes are sent from, and replies go';
    await _show(tester, const KeycapTextField(label: 'Email', hint: hint));
    expect(_hint(tester, hint).didExceedMaxLines, isTrue);
  });
}

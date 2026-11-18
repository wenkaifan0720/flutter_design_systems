// A CivicLink runs a callback, so a screen reader hears a button with a
// link's look: on the web an anchor with no address is read as plain
// words. One with nothing to do is words.
import 'package:civic_ui/civic_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

/// The node a screen reader reads for [link], found by its [words].
Future<SemanticsData> _read(
  WidgetTester tester,
  Widget link,
  String words,
) async {
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => CivicHost(child: child!),
      home: Center(child: link),
    ),
  );
  return tester.getSemantics(find.bySemanticsLabel(words)).getSemanticsData();
}

void main() {
  testWidgets('a link that runs a callback is a button', (tester) async {
    final handle = tester.ensureSemantics();
    var pressed = 0;
    final data = await _read(
      tester,
      CivicLink(onPressed: () => pressed++, child: const Text('Clear filters')),
      'Clear filters',
    );
    expect(data.flagsCollection.isButton, isTrue);
    expect(data.flagsCollection.isLink, isFalse);
    expect(data.hasAction(SemanticsAction.tap), isTrue);
    await tester.tap(find.text('Clear filters'));
    expect(pressed, 1);
    handle.dispose();
  });

  testWidgets('a quiet link and the back link are buttons too', (tester) async {
    final handle = tester.ensureSemantics();
    final quiet = await _read(
      tester,
      CivicLink.quiet(onPressed: () {}, child: const Text('Privacy')),
      'Privacy',
    );
    expect(quiet.flagsCollection.isButton, isTrue);
    expect(quiet.flagsCollection.isLink, isFalse);
    final back = await _read(tester, CivicBackLink(onPressed: () {}), 'Back');
    expect(back.flagsCollection.isButton, isTrue);
    expect(back.flagsCollection.isLink, isFalse);
    handle.dispose();
  });

  testWidgets('words with nothing to do are neither', (tester) async {
    final handle = tester.ensureSemantics();
    final data = await _read(
      tester,
      const CivicLink(onPressed: null, child: Text('Not yet open')),
      'Not yet open',
    );
    expect(data.flagsCollection.isButton, isFalse);
    expect(data.flagsCollection.isLink, isFalse);
    expect(data.hasAction(SemanticsAction.tap), isFalse);
    handle.dispose();
  });
}

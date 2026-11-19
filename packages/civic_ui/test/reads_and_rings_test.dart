// What a part tells a screen reader beyond its words, and what it shows a
// keyboard: an icon button that is on, a segment's spoken name, what a row
// holds, whether a banner is heard as it appears, the page's heading naming
// it, a field's hint and its whole height; a card with no title ringed by
// its focus, a group's hairlines only between rows that draw, and a
// slider's end told where it ended.
import 'dart:ui' show Tristate;

import 'package:civic_ui/civic_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(WidgetTester tester, Widget child) => tester.pumpWidget(
  MaterialApp(
    builder: (context, child) => CivicHost(child: child!),
    home: Scaffold(body: child),
  ),
);

SemanticsData _node(WidgetTester tester, Pattern words) =>
    tester.getSemantics(find.bySemanticsLabel(words)).getSemanticsData();

void main() {
  testWidgets('an icon button that is on reads as toggled, with its value', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await _pump(
      tester,
      Row(
        children: [
          CivicIconButton(
            icon: Icons.notifications_outlined,
            semanticLabel: 'Alerts',
            semanticValue: '3 new',
            selected: true,
            onPressed: () {},
          ),
          CivicIconButton(
            icon: Icons.bookmark_outline,
            semanticLabel: 'Save',
            selected: false,
            onPressed: () {},
          ),
          CivicIconButton(
            icon: Icons.share_outlined,
            semanticLabel: 'Share',
            onPressed: () {},
          ),
        ],
      ),
    );
    final on = _node(tester, 'Alerts');
    expect(on.flagsCollection.isToggled, Tristate.isTrue);
    expect(on.value, '3 new');
    expect(_node(tester, 'Save').flagsCollection.isToggled, Tristate.isFalse);
    // One that is never on is a plain button.
    expect(_node(tester, 'Share').flagsCollection.isToggled, Tristate.none);
    handle.dispose();
  });

  testWidgets('a segment is read by its spoken name where its words say less', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await _pump(
      tester,
      CivicSegmentedControl<String>(
        labelText: 'Text size',
        value: 's',
        onChanged: (_) {},
        segments: const [
          CivicSegment(value: 's', label: 'S', semanticLabel: 'Small'),
          CivicSegment(value: 'l', label: 'L', semanticLabel: 'Large'),
        ],
      ),
    );
    expect(find.bySemanticsLabel('Small'), findsOneWidget);
    expect(find.bySemanticsLabel('Large'), findsOneWidget);
    expect(find.text('S'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('a row that goes somewhere reads what it holds after its name', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await _pump(
      tester,
      CivicListGroup(
        children: [
          CivicListRow(
            title: const Text('Your details'),
            semanticLabel: 'Your details',
            semanticValue: 'Current step',
            onTap: () {},
          ),
        ],
      ),
    );
    expect(_node(tester, 'Your details').value, 'Current step');
    handle.dispose();
  });

  testWidgets('a banner is heard as it appears where its tone or it says so', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    bool live(String title) => find.semantics
        .byPredicate((node) {
          final data = node.getSemanticsData();
          return data.flagsCollection.isLiveRegion &&
              (data.label.contains(title) ||
                  _holds(node, (d) => d.label.contains(title)));
        })
        .evaluate()
        .isNotEmpty;

    await _pump(
      tester,
      const Column(
        children: [
          CivicNotificationBanner(
            title: 'Saved',
            tone: CivicTone.success,
            child: Text('Your details are saved.'),
          ),
          CivicNotificationBanner(
            title: 'Opening hours',
            child: Text('We close at 5pm on Fridays.'),
          ),
          CivicNotificationBanner(
            title: 'Checking',
            announce: true,
            child: Text('We are checking your documents.'),
          ),
          CivicNotificationBanner(
            title: 'Renewed',
            tone: CivicTone.success,
            announce: false,
            child: Text('Your permit runs to May.'),
          ),
        ],
      ),
    );
    expect(live('Saved'), isTrue, reason: 'a success is heard');
    expect(live('Opening hours'), isFalse, reason: 'news is not');
    expect(live('Checking'), isTrue, reason: 'unless it says it is');
    expect(live('Renewed'), isFalse, reason: 'or says it is not');
    handle.dispose();
  });

  testWidgets('a page body\'s heading is a header that names the page', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await _pump(
      tester,
      const CivicPageBody(
        title: 'Apply for a permit',
        children: [Text('Who is it for?')],
      ),
    );
    final heading = _node(tester, 'Apply for a permit');
    expect(heading.flagsCollection.isHeader, isTrue);
    expect(heading.flagsCollection.namesRoute, isTrue);
    handle.dispose();
  });

  testWidgets('a field\'s input is the box\'s whole height; its placeholder '
      'is read only where there is no help or error', (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(
      tester,
      const Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            CivicTextField(labelText: 'Email', hintText: 'name@example.com'),
            CivicTextField(
              labelText: 'Work email',
              helperText: 'We send your sign-in link here.',
              hintText: 'name@example.com',
            ),
            CivicTextField(
              labelText: 'Home email',
              errorText: 'Enter an email address',
              hintText: 'name@example.com',
            ),
          ],
        ),
      ),
    );
    final email = tester.getSemantics(find.bySemanticsLabel('Email'));
    expect(email.rect.height, greaterThanOrEqualTo(48));
    expect(email.getSemanticsData().hint, 'name@example.com');
    expect(_node(tester, 'Work email').hint, 'We send your sign-in link here.');
    expect(_node(tester, 'Home email').hint, 'Enter an email address');
    // The placeholder is still drawn in each empty box.
    expect(find.text('name@example.com'), findsNWidgets(3));
    handle.dispose();
  });

  testWidgets('a card with no title shows its keyboard focus as a ring', (
    tester,
  ) async {
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
    addTearDown(
      () => FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.automatic,
    );
    await _pump(
      tester,
      Padding(
        padding: const EdgeInsets.all(24),
        child: CivicCard(
          semanticLabel: 'Zone B',
          onPressed: () {},
          child: const Text('Zone B'),
        ),
      ),
    );
    final focus = CivicTheme.of(tester.element(find.byType(CivicCard))).focus;
    bool ringed() => tester
        .widgetList<DecoratedBox>(
          find.descendant(
            of: find.byType(CivicCard),
            matching: find.byType(DecoratedBox),
          ),
        )
        .any((box) {
          final decoration = box.decoration;
          return decoration is BoxDecoration &&
              decoration.border is Border &&
              (decoration.border! as Border).top.color == focus;
        });
    expect(ringed(), isFalse);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect(ringed(), isTrue, reason: 'the yellow ring stands round it');
  });

  testWidgets('a group draws no hairline for a row that draws nothing', (
    tester,
  ) async {
    await _pump(
      tester,
      CivicListGroup(
        children: [
          CivicListRow(title: const Text('Resident permit'), onTap: () {}),
          const SizedBox.shrink(),
          CivicListRow(title: const Text('Visitor permit'), onTap: () {}),
        ],
      ),
    );
    final first = tester.getRect(find.byType(CivicListRow).first);
    final second = tester.getRect(find.byType(CivicListRow).last);
    expect(second.top - first.bottom, 1, reason: 'one hairline between them');
  });

  testWidgets('a slider\'s end is told where the drag ended, before the page '
      'rebuilds', (tester) async {
    double? moved;
    double? ended;
    await _pump(
      tester,
      Padding(
        padding: const EdgeInsets.all(24),
        child: CivicSlider(
          labelText: 'Volume',
          value: 0.2,
          onChanged: (v) => moved = v,
          onChangeEnd: (v) => ended = v,
        ),
      ),
    );
    final track = tester.getRect(find.byType(CivicSlider));
    await tester.dragFrom(
      Offset(track.left + track.width * 0.2, track.bottom - 24),
      Offset(track.width * 0.5, 0),
    );
    await tester.pump();
    expect(moved, isNotNull);
    expect(moved, greaterThan(0.5));
    expect(ended, moved, reason: 'the end is where the drag left it');
  });
}

bool _holds(SemanticsNode node, bool Function(SemanticsData) test) {
  var found = false;
  node.visitChildren((child) {
    if (test(child.getSemanticsData()) || _holds(child, test)) found = true;
    return !found;
  });
  return found;
}

// What goes somewhere is read as a link carrying its address: a CivicLink
// with a url, and the parts that navigate (breadcrumbs, pagination, the
// summary list's Change, the error summary's entries, a card). What only
// runs a callback in place is a button with a link's look, so a browser does
// not read it as plain words. What does neither is words.
import 'dart:ui' show Tristate;

import 'package:civic_ui/civic_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(WidgetTester tester, Widget child) => tester.pumpWidget(
  MaterialApp(
    builder: (context, child) => CivicHost(child: child!),
    home: Scaffold(body: Center(child: child)),
  ),
);

/// The node a screen reader reads for [words].
SemanticsData _node(WidgetTester tester, Pattern words) =>
    tester.getSemantics(find.bySemanticsLabel(words)).getSemanticsData();

void _isLink(SemanticsData data, Uri url) {
  expect(data.flagsCollection.isLink, isTrue);
  expect(data.flagsCollection.isButton, isFalse);
  expect(data.linkUrl, url);
  expect(data.hasAction(SemanticsAction.tap), isTrue);
}

void _isButton(SemanticsData data) {
  expect(data.flagsCollection.isButton, isTrue);
  expect(data.flagsCollection.isLink, isFalse);
  expect(data.linkUrl, isNull);
  expect(data.hasAction(SemanticsAction.tap), isTrue);
}

void main() {
  testWidgets('a link with a url is a link with its address', (tester) async {
    final handle = tester.ensureSemantics();
    var pressed = 0;
    await _pump(
      tester,
      CivicLink(
        url: Uri.parse('/guidance/permit-zones'),
        onPressed: () => pressed++,
        child: const Text('Read the guidance on permit zones'),
      ),
    );
    _isLink(
      _node(tester, 'Read the guidance on permit zones'),
      Uri.parse('/guidance/permit-zones'),
    );
    await tester.tap(find.text('Read the guidance on permit zones'));
    expect(pressed, 1);
    handle.dispose();
  });

  testWidgets('a link with a url and no onPressed follows it', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => CivicHost(child: child!),
        routes: {
          '/': (_) => Scaffold(
            body: Center(
              child: CivicLink(
                url: Uri.parse('/permits'),
                child: const Text('Your permits'),
              ),
            ),
          ),
          '/permits': (_) => const Scaffold(body: Text('Permits page')),
        },
      ),
    );
    _isLink(_node(tester, 'Your permits'), Uri.parse('/permits'));
    await tester.tap(find.text('Your permits'));
    // url_launcher pushes the route to the app over the navigation channel.
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
    expect(find.text('Permits page'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('a link that only runs a callback is a button', (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(
      tester,
      CivicLink(onPressed: () {}, child: const Text('Clear filters')),
    );
    _isButton(_node(tester, 'Clear filters'));
    handle.dispose();
  });

  testWidgets('a quiet link and the back link follow the same rule', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await _pump(
      tester,
      CivicLink.quiet(
        url: Uri.parse('https://example.org/privacy'),
        onPressed: () {},
        child: const Text('Privacy'),
      ),
    );
    _isLink(_node(tester, 'Privacy'), Uri.parse('https://example.org/privacy'));
    await _pump(tester, CivicBackLink(onPressed: () {}));
    _isButton(_node(tester, 'Back'));
    handle.dispose();
  });

  testWidgets('words with nothing to do are neither', (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(
      tester,
      const CivicLink(onPressed: null, child: Text('Not yet open')),
    );
    final data = _node(tester, 'Not yet open');
    expect(data.flagsCollection.isButton, isFalse);
    expect(data.flagsCollection.isLink, isFalse);
    expect(data.hasAction(SemanticsAction.tap), isFalse);
    handle.dispose();
  });

  testWidgets('breadcrumbs: a place with an address is a link to it, the '
      'page itself is words', (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(
      tester,
      CivicBreadcrumbs(
        items: [
          CivicBreadcrumb(label: 'Home', onPressed: () {}, url: Uri.parse('/')),
          CivicBreadcrumb(label: 'Parking', onPressed: () {}),
          const CivicBreadcrumb(label: 'Resident permit'),
        ],
      ),
    );
    _isLink(_node(tester, 'Home'), Uri.parse('/'));
    _isButton(_node(tester, 'Parking'));
    final here = _node(tester, 'Resident permit');
    expect(here.flagsCollection.isLink, isFalse);
    expect(here.flagsCollection.isButton, isFalse);
    handle.dispose();
  });

  testWidgets('pagination: with addresses its pages are links to them, '
      'without they change the page in place', (tester) async {
    final handle = tester.ensureSemantics();
    Uri page(int index) => Uri.parse('/streets?page=${index + 1}');
    var chosen = -1;
    await _pump(
      tester,
      CivicPagination(
        pageCount: 5,
        selectedIndex: 2,
        onPageChanged: (index) => chosen = index,
        urlOf: page,
      ),
    );
    _isLink(_node(tester, 'Previous page'), page(1));
    _isLink(_node(tester, 'Next page'), page(3));
    _isLink(_node(tester, RegExp(r'^\D*2\D+5\D*$')), page(1));
    final shown = _node(tester, RegExp(r'^\D*3\D+5\D*$'));
    expect(shown.flagsCollection.isSelected, Tristate.isTrue);
    expect(shown.flagsCollection.isLink, isFalse);
    await tester.tap(find.text('Next page'));
    expect(chosen, 3);
    await _pump(
      tester,
      CivicPagination(pageCount: 5, selectedIndex: 2, onPageChanged: (_) {}),
    );
    _isButton(_node(tester, 'Previous page'));
    _isButton(_node(tester, RegExp(r'^\D*2\D+5\D*$')));
    handle.dispose();
  });

  testWidgets("the summary list's Change is a link to its question with an "
      'address, else a button', (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(
      tester,
      CivicSummaryList(
        rows: [
          CivicSummaryRow(
            label: 'Name',
            value: const Text('Amara Okafor'),
            actionLabel: 'Change',
            actionSemanticLabel: 'Change name',
            onActionPressed: () {},
            actionUrl: Uri.parse('/apply/name'),
          ),
          CivicSummaryRow(
            label: 'Vehicle',
            value: const Text('Car or van'),
            actionLabel: 'Change',
            actionSemanticLabel: 'Change vehicle',
            onActionPressed: () {},
          ),
        ],
      ),
    );
    _isLink(_node(tester, 'Change name'), Uri.parse('/apply/name'));
    _isButton(_node(tester, 'Change vehicle'));
    handle.dispose();
  });

  testWidgets("the error summary's entries are links to their fields, and a "
      'press takes the focus there', (tester) async {
    final handle = tester.ensureSemantics();
    final name = FocusNode();
    addTearDown(name.dispose);
    await _pump(
      tester,
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CivicErrorSummary(
            title: 'There is a problem',
            errors: [
              CivicErrorSummaryItem(
                text: 'Enter your full name',
                onPressed: name.requestFocus,
                url: Uri(fragment: 'full-name'),
              ),
              CivicErrorSummaryItem(text: 'Enter a postcode', onPressed: () {}),
            ],
          ),
          Focus(focusNode: name, child: const SizedBox(width: 10, height: 10)),
        ],
      ),
    );
    await tester.pumpAndSettle();
    _isLink(_node(tester, 'Enter your full name'), Uri(fragment: 'full-name'));
    _isButton(_node(tester, 'Enter a postcode'));
    expect(name.hasFocus, isFalse);
    await tester.tap(find.text('Enter your full name'));
    await tester.pump();
    expect(name.hasFocus, isTrue);
    handle.dispose();
  });

  testWidgets('a card that is a link carries its address, else a button', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    var opened = 0;
    await _pump(
      tester,
      SizedBox(
        width: 320,
        child: CivicCard(
          title: 'Resident permit, Zone B',
          url: Uri.parse('/permits/BRM-4821-K'),
          onPressed: () => opened++,
          child: const Text('Valid until 31 March'),
        ),
      ),
    );
    _isLink(
      _node(tester, RegExp('^Resident permit, Zone B')),
      Uri.parse('/permits/BRM-4821-K'),
    );
    await tester.tap(find.text('Valid until 31 March'));
    expect(opened, 1);
    await _pump(
      tester,
      SizedBox(
        width: 320,
        child: CivicCard(
          title: 'Visitor permits',
          onPressed: () {},
          child: const Text('Buy a book of 10'),
        ),
      ),
    );
    _isButton(_node(tester, RegExp('^Visitor permits')));
    handle.dispose();
  });
}

// A section header and the words after it are read as two nodes, the
// header flagged as one, wherever Keycap's host stands: over the app (in
// MaterialApp.builder) or as a page of its own, round the app frame at a
// phone's width and at a desk's (ui_core's adaptive shell) or round the bare
// words. Nothing the host mounts (its toaster's keys) merges them into one.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keycap_ui/keycap_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;

const _heading = 'Pinned';
const _body = 'Two notes pinned to the top';

Widget _words() => const Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  mainAxisSize: MainAxisSize.min,
  children: [KeycapSectionHeader(_heading), Text(_body)],
);

Widget _frame() => KeycapScaffold(
  destinations: const [
    KeycapDestination(icon: LucideIcons.house, label: 'Home'),
    KeycapDestination(icon: LucideIcons.settings, label: 'Settings'),
  ],
  selectedIndex: 0,
  onDestinationSelected: (_) {},
  body: _words(),
);

Widget _host(Widget child) =>
    KeycapHost(brightness: Brightness.light, child: child);

final _mountings = <String, Widget Function()>{
  'over the app, round the frame': () =>
      MaterialApp(builder: (context, app) => _host(app!), home: _frame()),
  'as the page, round the frame': () => MaterialApp(home: _host(_frame())),
  'as the page, round the words': () => MaterialApp(home: _host(_words())),
};

void _expectApart(WidgetTester tester) {
  final heading = find.semantics.byLabel(_heading);
  final body = find.semantics.byLabel(_body);
  expect(heading, findsOne, reason: 'the header is a node of its own');
  expect(body, findsOne, reason: 'the words are a node of their own');
  expect(heading.evaluate().single.flagsCollection.isHeader, isTrue);
  expect(body.evaluate().single.flagsCollection.isHeader, isFalse);
}

void main() {
  for (final MapEntry(key: where, value: app) in _mountings.entries) {
    for (final width in [390.0, 1440.0]) {
      testWidgets('the host $where: a header and the words after it are '
          'two nodes at ${width.round()} wide', (tester) async {
        final semantics = tester.ensureSemantics();
        try {
          tester.view.physicalSize = Size(width, 900);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          await tester.pumpWidget(app());
          await tester.pumpAndSettle();
          _expectApart(tester);
        } finally {
          semantics.dispose();
        }
      });
    }
  }
}

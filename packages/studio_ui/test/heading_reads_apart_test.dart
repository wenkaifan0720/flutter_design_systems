// A heading and the text after it are read as two nodes, the heading
// flagged as a header, wherever the look's host puts its keyboard keys
// (the toaster's F6, the shell's): those keys add no node over the app that
// would merge the two.
import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studio_ui/studio_ui.dart';

// The gallery's theme; a test reads it from the example.
// ignore_for_file: avoid_relative_lib_imports
import '../example/lib/kit_gallery/kit.dart' show kitApp, kitTheme;

const _heading = 'Recent episodes';
const _body = 'Three new this week.';

// The look's section header, and the heading an app writes itself.
final _pages = <String, Widget>{
  'a section header': const Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [StudioSectionHeader(_heading), Text(_body)],
  ),
  'a heading of its own': Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Semantics(header: true, child: const Text(_heading)),
      const Text(_body),
    ],
  ),
};

// Every node under [node], itself first.
Iterable<SemanticsNode> _all(SemanticsNode node) sync* {
  yield node;
  final children = <SemanticsNode>[];
  node.visitChildren((child) {
    children.add(child);
    return true;
  });
  for (final child in children) {
    yield* _all(child);
  }
}

void _readApart(WidgetTester tester, String heading, String body) {
  final root = tester
      .binding
      .renderViews
      .first
      .owner!
      .semanticsOwner!
      .rootSemanticsNode!;
  final nodes = [for (final n in _all(root)) n.getSemanticsData()];
  final headings = [
    for (final d in nodes)
      if (d.label.contains(heading)) d,
  ];
  expect(headings, hasLength(1), reason: 'the heading on one node');
  expect(headings.single.flagsCollection.isHeader, isTrue);
  expect(headings.single.label, isNot(contains(body)));
  final bodies = [
    for (final d in nodes)
      if (d.label.contains(body)) d,
  ];
  expect(bodies, hasLength(1), reason: 'the text on a node of its own');
  expect(bodies.single.flagsCollection.isHeader, isFalse);
}

Future<void> _read(
  WidgetTester tester,
  Widget app, {
  double width = 390,
}) async {
  tester.view.physicalSize = Size(width, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final semantics = tester.ensureSemantics();
  await tester.pumpWidget(app);
  await tester.pumpAndSettle();
  _readApart(tester, _heading, _body);
  semantics.dispose();
}

void main() {
  setUpAll(studioLoadFonts);

  for (final MapEntry(key: kind, value: page) in _pages.entries) {
    testWidgets('$kind: read apart on a page under the app\'s toaster', (
      tester,
    ) async {
      await _read(tester, kitApp(brightness: Brightness.light, home: page));
    });

    testWidgets('$kind: read apart under a toaster round the page', (
      tester,
    ) async {
      await _read(
        tester,
        MaterialApp(
          debugShowCheckedModeBanner: false,
          localizationsDelegates: const [
            StudioLocalizations.delegate,
            RawWidgetsLocalizations.delegate,
          ],
          builder: (context, app) =>
              StudioTheme(data: kitTheme(Brightness.light), child: app!),
          home: StudioToaster(child: page),
        ),
      );
    });

    for (final width in const [390.0, 1440.0]) {
      testWidgets('$kind: read apart in a frame\'s body at ${width.round()}', (
        tester,
      ) async {
        await _read(
          tester,
          kitApp(
            brightness: Brightness.light,
            home: StudioScaffold(
              destinations: const [
                StudioDestination(
                  icon: SizedBox.square(dimension: 20),
                  label: 'Home',
                ),
                StudioDestination(
                  icon: SizedBox.square(dimension: 20),
                  label: 'Library',
                ),
              ],
              onDestinationSelected: (_) {},
              body: page,
            ),
          ),
          width: width,
        );
      });
    }
  }
}

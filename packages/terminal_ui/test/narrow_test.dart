// At 200% text on a phone the cell doubles and a line holds about twenty
// characters. What overruns its line is cut with an ellipsis or moves to a
// line of its own; nothing stops mid-letter, and what a person must read
// whole (the words to type) shows whole.
import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terminal_ui/terminal_ui.dart';

import 'faces.dart';

void _phone(WidgetTester tester) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 844);
  addTearDown(tester.view.reset);
}

Widget _app(Widget home, {double scale = 2}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
    child: TermTheme(
      data: TermThemeData.dark(),
      child: TermToaster(child: child!),
    ),
  ),
  home: Builder(
    builder: (context) => ColoredBox(
      color: TermTheme.of(context).background,
      child: Align(alignment: AlignmentDirectional.topStart, child: home),
    ),
  ),
);

const _windows = [
  TermNavigationDestination(label: 'home'),
  TermNavigationDestination(label: 'runs'),
  TermNavigationDestination(label: 'deploy'),
  TermNavigationDestination(label: 'config'),
];

void main() {
  setUpAll(loadFaces);

  testWidgets('a title and its trailing words too long for the top line: '
      'the title keeps it, the trailing words go to the bottom line', (
    tester,
  ) async {
    _phone(tester);
    await tester.pumpWidget(
      _app(
        const SizedBox(
          width: 390,
          child: TermPane(
            title: '#1481 atlas-api',
            trailing: 'failed',
            child: Text('fix the cache key'),
          ),
        ),
      ),
    );
    final pane = tester.getRect(find.byType(TermPane));
    final title = tester.getRect(find.textContaining('#1481 atlas-api'));
    final trailing = tester.getRect(find.textContaining('failed'));
    expect(find.textContaining('…'), findsNothing);
    expect(title.top, pane.top);
    expect(trailing.bottom, pane.bottom);
    expect(trailing.right, lessThanOrEqualTo(pane.right));
    expect(tester.takeException(), isNull);
  });

  testWidgets('a title too long for its line alone ends in an ellipsis', (
    tester,
  ) async {
    _phone(tester);
    await tester.pumpWidget(
      _app(
        const SizedBox(
          width: 390,
          child: TermPane(
            title: '#1481 atlas-api · the token cache',
            child: Text('fix the cache key'),
          ),
        ),
      ),
    );
    expect(find.textContaining('#1481 atl'), findsOneWidget);
    expect(find.textContaining('…'), findsOneWidget);
    expect(
      find.bySemanticsLabel('#1481 atlas-api · the token cache'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('a field label too long for its frame ends in an ellipsis', (
    tester,
  ) async {
    _phone(tester);
    await tester.pumpWidget(
      _app(
        const TermTextField(
          labelText: 'the branch or the commit to deploy',
          hintText: 'main',
        ),
      ),
    );
    expect(find.textContaining('the branch'), findsOneWidget);
    expect(find.textContaining('…'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the window list goes by numbers where the names do not fit', (
    tester,
  ) async {
    _phone(tester);
    Widget bar() => SizedBox(
      width: 390,
      child: TermNavigationBar(
        destinations: _windows,
        selectedIndex: 1,
        onDestinationSelected: (_) {},
      ),
    );
    await tester.pumpWidget(_app(bar(), scale: 1));
    expect(find.textContaining('1:home'), findsOneWidget);
    expect(find.textContaining('2:runs*'), findsOneWidget);

    await tester.pumpWidget(_app(bar()));
    expect(find.text('1'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
    expect(find.textContaining('2:runs*'), findsOneWidget);
    // Each window keeps its name for a screen reader.
    expect(find.bySemanticsLabel('home'), findsOneWidget);
    expect(find.bySemanticsLabel('deploy'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a phone at its own text size names every window whole', (
    tester,
  ) async {
    _phone(tester);
    await tester.pumpWidget(
      _app(
        SizedBox(
          width: 390,
          child: TermNavigationBar(
            destinations: _windows,
            selectedIndex: 2,
            onDestinationSelected: (_) {},
          ),
        ),
        scale: 1,
      ),
    );
    for (final name in ['1:home', '2:runs', '3:deploy*', '4:config']) {
      final text = find.textContaining(name);
      expect(text, findsOneWidget, reason: name);
      final box = tester.renderObject<RenderBox>(text);
      expect(
        box.getMaxIntrinsicWidth(double.infinity),
        lessThanOrEqualTo(box.size.width + 0.5),
        reason: '$name is cut',
      );
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('a tab row longer than its line says there is more', (
    tester,
  ) async {
    _phone(tester);
    await tester.pumpWidget(
      _app(
        SizedBox(
          width: 390,
          child: TermTabBar(
            tabs: const ['all', 'failed', 'running', 'passed'],
            selectedIndex: 0,
            onTap: (_) {},
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('›'), findsOneWidget);
    expect(find.text('‹'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets("a banner's action stands under its words on a narrow line", (
    tester,
  ) async {
    _phone(tester);
    await tester.pumpWidget(
      _app(
        SizedBox(
          width: 390,
          child: TermBanner(
            title: 'offline',
            message: 'connection lost · these runs are from 2 min ago',
            tone: TermTone.error,
            action: TermButton(label: 'retry', onPressed: () {}),
          ),
        ),
      ),
    );
    final words = tester.getRect(find.textContaining('connection lost'));
    final retry = tester.getRect(find.byType(TermButton));
    expect(retry.top, greaterThanOrEqualTo(words.bottom - 0.5));
    expect(tester.takeException(), isNull);
  });

  testWidgets("a banner's action ends its line when the words fit beside it", (
    tester,
  ) async {
    // At the phone's own text size, where a short line has room; the view
    // wide enough for the widest banner below.
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1000, 844);
    addTearDown(tester.view.reset);
    Future<void> banner(double width, String message) => tester.pumpWidget(
      _app(
        Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: width,
            child: TermBanner(
              title: 'offline',
              message: message,
              tone: TermTone.error,
              action: TermButton(label: 'retry', onPressed: () {}),
            ),
          ),
        ),
        scale: 1,
      ),
    );
    // Short words on a phone: one line, the action beside them, centred
    // on them.
    await banner(390, 'connection lost');
    var words = tester.getRect(find.textContaining('connection lost'));
    var retry = tester.getRect(find.text('retry'));
    expect(retry.left, greaterThan(words.right));
    expect(retry.center.dy, moreOrLessEquals(words.center.dy, epsilon: 1));
    // Long words on a column that would wrap them beside it: under.
    const long = 'connection lost · these runs are from 2 min ago';
    await banner(420, long);
    words = tester.getRect(find.textContaining('connection lost'));
    retry = tester.getRect(find.byType(TermButton));
    expect(retry.top, greaterThanOrEqualTo(words.bottom - 0.5));
    // The same words on a wide line: beside again.
    await banner(900, long);
    words = tester.getRect(find.textContaining('connection lost'));
    retry = tester.getRect(find.text('retry'));
    expect(retry.left, greaterThan(words.right));
    expect(tester.takeException(), isNull);
  });

  testWidgets('a typed confirmation shows the words to type whole', (
    tester,
  ) async {
    // A short phone: the sheet's words scroll, its actions stay in reach.
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 700);
    addTearDown(tester.view.reset);
    late BuildContext page;
    await tester.pumpWidget(
      _app(
        Builder(
          builder: (context) {
            page = context;
            return const SizedBox.expand();
          },
        ),
      ),
    );
    unawaited(
      showTermConfirmDialog(
        context: page,
        title: 'delete project',
        message: 'atlas-api, its 1482 runs and their logs go for good.',
        confirmLabel: 'delete',
        isDestructiveAction: true,
        typedConfirmation: 'atlas-api',
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.textContaining('type atlas-api to confirm'), findsOneWidget);
    expect(tester.takeException(), isNull);
    final no = tester.getRect(find.widgetWithText(TermButton, 'no'));
    expect(no.bottom, lessThanOrEqualTo(700));
    expect(find.widgetWithText(TermButton, 'no').hitTestable(), findsOneWidget);
    Navigator.of(page).pop();
    await tester.pumpAndSettle();
  });
}

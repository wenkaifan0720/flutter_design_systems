// The command palette: what it lights is what ranked the command, it
// counts what matches, Return runs the highlighted command after it
// closes, and Escape closes it. The typed guard stands as a sheet on a
// phone and a dialog on a desk; the desk's panes switch on [ and ].
import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terminal_ui/terminal_ui.dart';

// The example's screens are the ones under test.
// ignore_for_file: avoid_relative_lib_imports
import '../example/lib/kit_gallery/slipway.dart';
import 'faces.dart';

void _size(WidgetTester tester, Size size) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
}

// Spinners turn for ever on slipway's screens: wait out the motion, not
// for stillness.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Widget _host(Widget home) => MaterialApp(
  builder: (context, child) =>
      TermTheme(data: TermThemeData.dark(), child: child!),
  home: home,
);

void main() {
  // The screens' lines are laid on the bundled faces' cells.
  setUpAll(loadFaces);

  test('the lit letters are the ones that matched', () {
    expect(termMatchRanges('deploy to staging', 'dep'), [(0, 3)]);
    expect(termMatchRanges('deploy to staging', 'stag'), [(10, 14)]);
    expect(termMatchRanges('deploy to staging', 'dts'), [
      (0, 1),
      (7, 8),
      (10, 11),
    ]);
    expect(termMatchRanges('deploy to staging', 'xyz'), isEmpty);
    expect(termMatchRanges('Deploy', 'dEp'), [(0, 3)]);
  });

  testWidgets('the palette counts, runs and closes', (tester) async {
    _size(tester, const Size(1024, 768));
    var ran = '';
    late BuildContext page;
    await tester.pumpWidget(
      _host(
        Builder(
          builder: (context) {
            page = context;
            return const SizedBox.expand();
          },
        ),
      ),
    );
    final commands = [
      RawCommand(label: 'go home', onPressed: () => ran = 'home'),
      RawCommand(label: 'deploy to staging', onPressed: () => ran = 'stg'),
      RawCommand(label: 'deploy to production', onPressed: () => ran = 'p'),
    ];

    unawaited(showTermCommandPalette(context: page, commands: commands));
    await tester.pumpAndSettle();
    expect(find.textContaining('3/3'), findsOneWidget);

    await tester.enterText(find.byType(EditableText), 'dep');
    await tester.pump();
    expect(find.textContaining('2/3'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.byType(TermCommandPalette), findsNothing);
    expect(ran, 'p');

    unawaited(showTermCommandPalette(context: page, commands: commands));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText), 'zzz');
    await tester.pump();
    expect(find.textContaining('0/3'), findsOneWidget);
    expect(find.textContaining('no command matches'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(TermCommandPalette), findsNothing);
    expect(ran, 'p');
  });

  testWidgets('slipway opens its palette on ^K', (tester) async {
    _size(tester, const Size(1024, 768));
    await tester.pumpWidget(slipwayApp(Brightness.dark));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await _settle(tester);
    expect(find.byType(TermCommandPalette), findsOneWidget);
  });

  for (final (width, sheet) in const [(390.0, true), (1024.0, false)]) {
    testWidgets('the typed guard at ${width.toInt()} is a '
        '${sheet ? 'sheet' : 'dialog'}', (tester) async {
      _size(tester, Size(width, 800));
      await tester.pumpWidget(
        slipwayApp(Brightness.dark, place: SlipwayPlace.confirm),
      );
      await _settle(tester);
      expect(find.byType(TermSheet), sheet ? findsOneWidget : findsNothing);
      expect(find.byType(TermDialog), sheet ? findsNothing : findsOneWidget);
      if (sheet) {
        // On the screen's foot, where a thumb reaches.
        final rect = tester.getRect(find.byType(TermSheet));
        expect(rect.bottom, greaterThan(800 - 40));
      }
      // The yes waits for the project's name.
      final yes = find.widgetWithText(TermButton, 'delete');
      expect(tester.widget<TermButton>(yes).onPressed, isNull);
      await tester.enterText(find.byType(EditableText).last, 'atlas-api');
      await tester.pump();
      expect(tester.widget<TermButton>(yes).onPressed, isNotNull);
    });
  }

  testWidgets("the desk's panes switch on [ and ]", (tester) async {
    _size(tester, const Size(1440, 900));
    await tester.pumpWidget(
      slipwayApp(Brightness.dark, place: SlipwayPlace.runs),
    );
    await _settle(tester);
    expect(find.text('1:runs*'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.bracketRight);
    await _settle(tester);
    expect(find.text('2:run*'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.bracketLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.bracketLeft);
    await _settle(tester);
    expect(find.text('3:log*'), findsOneWidget);
  });
}

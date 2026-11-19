// What opens over or beside the page (ui_core's behaviour, Civic's
// painting): a menu and a split button open on a press and the keys, walk
// on Up and Down, run a choice once closed and give the focus back; a
// popover takes the focus and gives it back; a tooltip shows on the
// keyboard's focus and is heard on its control; the sheets open with their
// title, close on Close and Escape, and an action sheet answers with the
// action chosen; the command palette finds a command by its words and runs
// it. Leak tracking is on for every test here.
import 'package:civic_ui/civic_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// The page holding [body], pumped at [size]; its context.
Future<BuildContext> _app(
  WidgetTester tester,
  Widget body, {
  Size size = const Size(390, 844),
}) async {
  late BuildContext page;
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => CivicHost(child: child!),
      home: Builder(
        builder: (context) {
          page = context;
          return CivicScreen(
            body: Padding(
              padding: const EdgeInsets.all(CivicSpacing.s16),
              child: Align(alignment: Alignment.topLeft, child: body),
            ),
          );
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
  return page;
}

Future<void> _keys(WidgetTester tester, List<LogicalKeyboardKey> keys) async {
  for (final key in keys) {
    await tester.sendKeyEvent(key);
    await tester.pumpAndSettle();
  }
}

/// The text of the widget holding the primary focus, if it says one.
bool _focusOn(WidgetTester tester, String words) {
  final focused = FocusManager.instance.primaryFocus?.context;
  if (focused == null) return false;
  return find
      .descendant(of: find.byWidget(focused.widget), matching: find.text(words))
      .evaluate()
      .isNotEmpty;
}

void main() {
  group('a menu', () {
    Widget menu(ValueChanged<String> chosen) => CivicMenu<String>(
      semanticLabel: 'Application actions',
      items: const [
        CivicMenuItem(value: 'print', label: 'Print your answers'),
        CivicMenuItem(value: 'copy', label: 'Download a copy'),
        CivicMenuItem(value: 'change', label: 'Change vehicle', enabled: false),
        CivicMenuItem(
          value: 'withdraw',
          label: 'Withdraw application',
          isDestructiveAction: true,
          startsGroup: true,
        ),
      ],
      onSelected: chosen,
      builder: (context, anchor) => CivicButton.secondary(
        onPressed: anchor.toggle,
        child: const Text('Actions'),
      ),
    );

    testWidgets('a press opens it; a choice closes it, then runs', (
      tester,
    ) async {
      String? chosen;
      await _app(tester, menu((v) => chosen = v));
      await tester.tap(find.text('Actions'));
      await tester.pumpAndSettle();
      expect(find.text('Download a copy'), findsOneWidget);
      await tester.tap(find.text('Download a copy'));
      await tester.pumpAndSettle();
      expect(chosen, 'copy');
      expect(find.text('Download a copy'), findsNothing);
    });

    testWidgets('the keys walk it past what cannot be chosen; Escape closes '
        'it and the focus goes back', (tester) async {
      String? chosen;
      await _app(tester, menu((v) => chosen = v));
      await _keys(tester, [LogicalKeyboardKey.tab, LogicalKeyboardKey.enter]);
      expect(find.text('Print your answers'), findsOneWidget);
      expect(_focusOn(tester, 'Print your answers'), isTrue);
      await _keys(tester, [
        LogicalKeyboardKey.arrowDown,
        LogicalKeyboardKey.arrowDown,
      ]);
      expect(_focusOn(tester, 'Withdraw application'), isTrue);
      await _keys(tester, [LogicalKeyboardKey.escape]);
      expect(find.text('Print your answers'), findsNothing);
      expect(_focusOn(tester, 'Actions'), isTrue);
      expect(chosen, isNull);
    });

    testWidgets("a row without a glyph starts its words on the glyphs' line", (
      tester,
    ) async {
      await _app(
        tester,
        CivicMenu<String>(
          items: const [
            CivicMenuItem(
              value: 'print',
              label: 'Print your answers',
              icon: Icons.print,
            ),
            CivicMenuItem(value: 'withdraw', label: 'Withdraw application'),
          ],
          onSelected: (_) {},
          builder: (context, anchor) => CivicButton.secondary(
            onPressed: anchor.toggle,
            child: const Text('Actions'),
          ),
        ),
      );
      await tester.tap(find.text('Actions'));
      await tester.pumpAndSettle();
      expect(
        tester.getTopLeft(find.text('Withdraw application')).dx,
        tester.getTopLeft(find.text('Print your answers')).dx,
      );
    });

    testWidgets('a screen reader hears each row as a button', (tester) async {
      final semantics = tester.ensureSemantics();
      await _app(tester, menu((_) {}));
      await tester.tap(find.text('Actions'));
      await tester.pumpAndSettle();
      expect(
        tester.getSemantics(find.text('Print your answers')),
        matchesSemantics(
          label: 'Print your answers',
          isButton: true,
          hasTapAction: true,
          hasFocusAction: true,
          hasEnabledState: true,
          isEnabled: true,
          isFocusable: true,
        ),
      );
      semantics.dispose();
    });
  });

  group('a split button', () {
    testWidgets('its action and its menu are two buttons', (tester) async {
      final said = <String>[];
      await _app(
        tester,
        CivicSplitButton(
          label: 'Send application',
          onPressed: () => said.add('send'),
          actions: [
            CivicSplitAction(
              'Save and come back later',
              onPressed: () => said.add('save'),
            ),
          ],
        ),
      );
      await tester.tap(find.text('Send application'));
      await tester.pumpAndSettle();
      expect(said, ['send']);
      await tester.tap(find.bySemanticsLabel('More options'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save and come back later'));
      await tester.pumpAndSettle();
      expect(said, ['send', 'save']);
      expect(find.text('Save and come back later'), findsNothing);
    });

    for (final (width, spans) in [(390.0, true), (1440.0, false)]) {
      testWidgets(
        'at $width wide its action ${spans ? 'spans' : 'keeps its '
                  'words\' width in'} its column',
        (tester) async {
          await _app(
            tester,
            CivicSplitButton(
              label: 'Send',
              onPressed: () {},
              actions: [CivicSplitAction('Send later', onPressed: () {})],
            ),
            size: Size(width, 844),
          );
          final face = tester.getRect(
            find
                .ancestor(
                  of: find.text('Send'),
                  matching: find.byType(CustomPaint),
                )
                .first,
          );
          final chevron = tester.getRect(
            find
                .ancestor(
                  of: find.byIcon(LucideIcons.chevronDown),
                  matching: find.byType(CustomPaint),
                )
                .first,
          );
          final column = tester.getRect(find.byType(CivicSplitButton));
          // The action at the column's start, a 2 pt seam, the chevron.
          expect(face.left, column.left);
          expect(chevron.left - face.right, 2);
          if (spans) {
            expect(chevron.right, column.right);
            expect(column.width, greaterThan(width / 2));
          } else {
            expect(face.width, lessThan(200));
          }
        },
      );
    }

    testWidgets('disabled, both halves are, and its menu stays shut', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await _app(
        tester,
        CivicSplitButton(
          label: 'Send application',
          onPressed: null,
          actions: [
            CivicSplitAction('Save and come back later', onPressed: () {}),
          ],
        ),
      );
      // A screen reader is offered nothing to do with it.
      expect(
        tester
            .getSemantics(find.bySemanticsLabel('More options'))
            .getSemanticsData()
            .hasAction(SemanticsAction.tap),
        isFalse,
      );
      await tester.tap(find.bySemanticsLabel('More options'));
      await tester.pumpAndSettle();
      expect(find.text('Save and come back later'), findsNothing);
      semantics.dispose();
    });

    testWidgets("its halves share one height when the action's words wrap", (
      tester,
    ) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await _app(
        tester,
        CivicSplitButton(
          label: 'Send your application to the council',
          onPressed: () {},
          actions: [CivicSplitAction('Send later', onPressed: () {})],
        ),
      );
      Rect face(Finder inside) => tester.getRect(
        find.ancestor(of: inside, matching: find.byType(CustomPaint)).first,
      );
      final action = face(find.text('Send your application to the council'));
      final chevron = face(find.byIcon(LucideIcons.chevronDown));
      expect(action.height, greaterThan(100));
      expect(chevron.top, action.top);
      expect(chevron.height, action.height);
    });

    testWidgets("from 600 its menu is as wide as its rows, and at least the "
        "pair's width", (tester) async {
      await _app(
        tester,
        SizedBox(
          width: 640,
          child: CivicSplitButton(
            label: 'Send application',
            onPressed: () {},
            actions: [
              CivicSplitAction('Save', onPressed: () {}),
              CivicSplitAction('Print', onPressed: () {}),
            ],
          ),
        ),
        size: const Size(1440, 900),
      );
      Rect face(Finder inside) => tester.getRect(
        find.ancestor(of: inside, matching: find.byType(CustomPaint)).first,
      );
      final start = face(find.text('Send application')).left;
      final end = face(find.byIcon(LucideIcons.chevronDown)).right;
      await tester.tap(find.bySemanticsLabel('More options'));
      await tester.pumpAndSettle();
      final panel = tester.getRect(
        find
            .ancestor(
              of: find.text('Save'),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      expect(panel.width, moreOrLessEquals(end - start, epsilon: 1));
      expect(panel.left, moreOrLessEquals(start, epsilon: 1));
    });

    testWidgets('a menu wider than the pair grows from its start', (
      tester,
    ) async {
      await _app(
        tester,
        SizedBox(
          width: 640,
          child: CivicSplitButton(
            label: 'Send',
            onPressed: () {},
            actions: [
              CivicSplitAction('Save and come back later', onPressed: () {}),
            ],
          ),
        ),
        size: const Size(1440, 900),
      );
      Rect face(Finder inside) => tester.getRect(
        find.ancestor(of: inside, matching: find.byType(CustomPaint)).first,
      );
      final start = face(find.text('Send')).left;
      final end = face(find.byIcon(LucideIcons.chevronDown)).right;
      await tester.tap(find.bySemanticsLabel('More options'));
      await tester.pumpAndSettle();
      final panel = tester.getRect(
        find
            .ancestor(
              of: find.text('Save and come back later'),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      expect(panel.left, moreOrLessEquals(start, epsilon: 1));
      expect(panel.width, greaterThan(end - start));
      expect(panel.width, lessThanOrEqualTo(320));
    });

    testWidgets('Down on the action opens the menu at its first', (
      tester,
    ) async {
      await _app(
        tester,
        CivicSplitButton.secondary(
          label: 'Download',
          onPressed: () {},
          actions: [
            CivicSplitAction('As a PDF', onPressed: () {}),
            CivicSplitAction('As a spreadsheet', onPressed: () {}),
          ],
        ),
      );
      await _keys(tester, [
        LogicalKeyboardKey.tab,
        LogicalKeyboardKey.arrowDown,
      ]);
      expect(_focusOn(tester, 'As a PDF'), isTrue);
    });
  });

  testWidgets("a link's face hugs its words in a wide column", (tester) async {
    await _app(
      tester,
      SizedBox(
        width: 358,
        child: CivicLink(onPressed: () {}, child: const Text('Read the rules')),
      ),
    );
    final words = tester.getRect(find.text('Read the rules'));
    final face = tester.getRect(
      find
          .ancestor(
            of: find.text('Read the rules'),
            matching: find.byType(CustomPaint),
          )
          .first,
    );
    expect(face.left, words.left);
    expect(face.width, moreOrLessEquals(words.width, epsilon: 1));
  });

  testWidgets('a popover takes the focus and gives it back', (tester) async {
    await _app(
      tester,
      CivicPopover(
        title: 'Who counts as a visitor',
        content: CivicLink(
          onPressed: () {},
          child: const Text('Read the rules'),
        ),
        builder: (context, anchor) => CivicLink(
          onPressed: anchor.toggle,
          child: const Text('Who counts as a visitor?'),
        ),
      ),
    );
    await _keys(tester, [LogicalKeyboardKey.tab, LogicalKeyboardKey.enter]);
    expect(find.text('Who counts as a visitor'), findsOneWidget);
    expect(_focusOn(tester, 'Read the rules'), isTrue);
    await _keys(tester, [LogicalKeyboardKey.escape]);
    expect(find.text('Who counts as a visitor'), findsNothing);
    expect(_focusOn(tester, 'Who counts as a visitor?'), isTrue);
  });

  testWidgets("a tooltip shows on the keyboard's focus and is heard once", (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _app(
      tester,
      CivicIconButton(
        icon: Icons.print,
        semanticLabel: 'Print this page',
        tooltip: 'Print this page',
        onPressed: () {},
      ),
    );
    expect(find.text('Print this page'), findsNothing);
    await _keys(tester, [LogicalKeyboardKey.tab]);
    expect(find.text('Print this page'), findsOneWidget);
    // The words are the button's own label: not read a second time.
    expect(find.bySemanticsLabel('Print this page'), findsOneWidget);
    await _keys(tester, [LogicalKeyboardKey.escape]);
    expect(find.text('Print this page'), findsNothing);
    semantics.dispose();
  });

  group('sheets', () {
    testWidgets('a bottom sheet opens with its title and closes on Close', (
      tester,
    ) async {
      final page = await _app(tester, const Text('Your applications'));
      final closed = showCivicBottomSheet<void>(
        context: page,
        title: 'Filter applications',
        builder: (context) => const Text('Status'),
      );
      await tester.pumpAndSettle();
      expect(find.text('Filter applications'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Close'));
      await tester.pumpAndSettle();
      await closed;
      expect(find.text('Filter applications'), findsNothing);
    });

    testWidgets("below 600 a side sheet takes the screen's width", (
      tester,
    ) async {
      final page = await _app(tester, const Text('Your applications'));
      showCivicSideSheet<void>(
        context: page,
        title: 'Filter applications',
        builder: (context) => const Text('Status'),
      ).ignore();
      await tester.pumpAndSettle();
      // The sheet's own margin from the screen's start: no gap before it.
      expect(
        tester.getTopLeft(find.text('Filter applications')).dx,
        lessThanOrEqualTo(CivicSpacing.s24),
      );
    });

    testWidgets('a side sheet closes on Escape', (tester) async {
      final page = await _app(
        tester,
        const Text('Your applications'),
        size: const Size(1440, 900),
      );
      showCivicSideSheet<void>(
        context: page,
        title: 'Filter applications',
        builder: (context) => const Text('Status'),
      ).ignore();
      await tester.pumpAndSettle();
      expect(find.text('Filter applications'), findsOneWidget);
      await _keys(tester, [LogicalKeyboardKey.escape]);
      expect(find.text('Filter applications'), findsNothing);
    });

    for (final (press, answer) in [
      ('Withdraw application', 'withdraw'),
      ('Cancel', null),
    ]) {
      testWidgets('an action sheet answers "$press" with $answer', (
        tester,
      ) async {
        final page = await _app(tester, const Text('Your application'));
        final answered = showCivicActionSheet<String>(
          context: page,
          title: 'Application BRM-4821-K',
          actions: const [
            CivicActionSheetAction(value: 'print', label: 'Print your answers'),
            CivicActionSheetAction(
              value: 'withdraw',
              label: 'Withdraw application',
              isDestructiveAction: true,
            ),
          ],
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text(press));
        await tester.pumpAndSettle();
        expect(await answered, answer);
      });
    }
  });

  testWidgets('the command palette finds a command by its words and runs it '
      'once closed', (tester) async {
    final ran = <String>[];
    final page = await _app(
      tester,
      const Text('Your applications'),
      size: const Size(1440, 900),
    );
    showCivicCommandPalette(
      context: page,
      commands: [
        DesignCommand(
          label: 'Your permits',
          group: 'Pages',
          onPressed: () => ran.add('permits'),
        ),
        DesignCommand(
          label: 'Apply for a permit',
          group: 'Actions',
          onPressed: () => ran.add('apply'),
        ),
      ],
    ).ignore();
    await tester.pumpAndSettle();
    final top = tester.getTopLeft(find.byType(EditableText)).dy;
    await tester.enterText(find.byType(EditableText), 'apply');
    await tester.pumpAndSettle();
    expect(find.text('Your permits'), findsNothing);
    // Fewer results, and the field stays where it was under the typing.
    expect(tester.getTopLeft(find.byType(EditableText)).dy, top);
    await tester.testTextInput.receiveAction(TextInputAction.go);
    await tester.pumpAndSettle();
    expect(ran, ['apply']);
    expect(find.text('Apply for a permit'), findsNothing);
  });

  group('the banner', () {
    testWidgets('its band frames the message all round', (tester) async {
      await _app(
        tester,
        const CivicNotificationBanner(
          title: 'Important',
          child: Text('Permits for Zone C are paused.'),
        ),
      );
      final banner = tester.getRect(find.byType(CivicNotificationBanner));
      final message = tester.getRect(
        find
            .ancestor(
              of: find.text('Permits for Zone C are paused.'),
              matching: find.byType(ColoredBox),
            )
            .first,
      );
      // Civic's 4 pt bar, as the band's colour.
      expect(message.left - banner.left, 4);
      expect(banner.right - message.right, 4);
      expect(banner.bottom - message.bottom, 4);
    });

    for (final tone in [CivicTone.warning, CivicTone.error]) {
      testWidgets('a ${tone.name} draws its own band', (tester) async {
        Future<Color?> band(CivicTone tone) async {
          await _app(
            tester,
            CivicNotificationBanner(
              title: 'Notice',
              tone: tone,
              child: const Text('Permits for Zone C are paused.'),
            ),
          );
          final box = tester.widget<DecoratedBox>(
            find
                .descendant(
                  of: find.byType(CivicNotificationBanner),
                  matching: find.byType(DecoratedBox),
                )
                .first,
          );
          return (box.decoration as BoxDecoration).color;
        }

        final info = await band(CivicTone.info);
        final own = await band(tone);
        expect(own, isNot(info));
      });
    }
  });
}

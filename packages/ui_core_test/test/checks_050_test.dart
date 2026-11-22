// ui_core_test 0.3.0's checks: an overlay shows whole and on the screen,
// nothing overflows at large text, a dialog's actions stand in one row or one
// column of one width with the confirming action on top, and a field's help
// and error are read with it. Each catches its fault and passes the fix.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/ui_core.dart';
import 'package:ui_core_test/ui_core_test.dart';

import 'behaviour_harness.dart';

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Widget _key(String label, {double width = 48, double height = 44}) => RawButton(
  semanticLabel: label,
  excludeSemantics: true,
  onPressed: () {},
  builder: (context, states, _) => SizedBox(
    width: width,
    height: height,
    child: Center(child: Text(label)),
  ),
);

const _days = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];

void main() {
  group('DesignOverlayCheck', () {
    // A date field 540 down a phone, its month 300 high, placed as [fit]
    // says: a month that keeps its height ([shrinks] false) or one that
    // shrinks to the room and scrolls; or a list of rows ([list]).
    Future<DesignAlignmentReport> calendar(
      WidgetTester tester, {
      required RawPopoverFit fit,
      bool shrinks = false,
      bool list = false,
    }) async {
      final Widget month = SizedBox(
        width: 336,
        height: 300,
        child: list
            ? Column(
                children: [
                  for (final d in _days) _key(d, width: 336, height: 300 / 7),
                ],
              )
            : Wrap(children: [for (final d in _days) _key(d)]),
      );
      _phone(tester);
      await tester.pumpWidget(
        harness(
          Padding(
            padding: const EdgeInsets.only(top: 540, left: 16),
            child: Align(
              alignment: Alignment.topLeft,
              child: RawPopover(
                placement: RawPopoverPlacement(
                  matchAnchorWidth: false,
                  fit: fit,
                ),
                semanticLabel: 'Due date',
                anchorBuilder: (context, anchor) => RawButton(
                  semanticLabel: 'Due',
                  excludeSemantics: true,
                  onPressed: anchor.toggle,
                  builder: (context, states, _) => const SizedBox(
                    key: ValueKey('due'),
                    width: 200,
                    height: 44,
                  ),
                ),
                overlayBuilder: (context, info) => shrinks || list
                    ? ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: info.maxSize.height,
                        ),
                        child: SingleChildScrollView(child: month),
                      )
                    : UnconstrainedBox(
                        alignment: Alignment.topLeft,
                        child: month,
                      ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(const ValueKey('due')));
      await tester.pumpAndSettle();
      tester.takeException();
      return const DesignOverlayCheck(look: 'Test')
          .check(tester.element(find.byType(RawPopover)));
    }

    testWidgets('catches a month that runs off the screen\'s foot (Brutal\'s '
        'and Gloss\'s phone date pickers)', (tester) async {
      final report = await calendar(tester, fit: RawPopoverFit.scroll);
      expect(report.problems, [
        contains(
          'an overlay from a button "Due" runs past the screen\'s foot by',
        ),
      ]);
    });

    testWidgets('catches a month that shrinks and scrolls where above holds '
        'it whole (Brutal\'s and Gloss\'s phone date pickers)', (tester) async {
      final report = await calendar(
        tester,
        fit: RawPopoverFit.scroll,
        shrinks: true,
      );
      expect(report.problems, [
        allOf(
          startsWith('an overlay from a button "Due" shrinks a grid to'),
          contains(
            'of its 300 px high and scrolls it, where above its '
            'anchor holds it whole',
          ),
        ),
      ]);
    });

    for (final shrinks in [false, true]) {
      testWidgets('passes the month that wants its whole height '
          '(${shrinks ? 'shrinks' : 'keeps its height'})', (tester) async {
        final report = await calendar(
          tester,
          fit: RawPopoverFit.whole,
          shrinks: shrinks,
        );
        expect(report.problems, isEmpty);
      });
    }

    testWidgets('passes a list that shrinks to the room below and scrolls', (
      tester,
    ) async {
      final report = await calendar(
        tester,
        fit: RawPopoverFit.scroll,
        list: true,
      );
      expect(report.problems, isEmpty);
    });

    // A dialog holding a week of 48 px days in [body] px, scrolled
    // sideways.
    Future<DesignAlignmentReport> strip(
      WidgetTester tester,
      double body,
    ) async {
      _phone(tester);
      await tester.pumpWidget(harness(const SizedBox.expand()));
      tester
          .state<NavigatorState>(find.byType(Navigator))
          .push(
            RawDialogRoute<void>(
              pageBuilder: (context, _, _) => Center(
                child: Semantics(
                  namesRoute: true,
                  label: 'Pick a date',
                  child: SizedBox(
                    width: body,
                    height: 60,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(children: [for (final d in _days) _key(d)]),
                    ),
                  ),
                ),
              ),
            ),
          );
      await tester.pumpAndSettle();
      return const DesignOverlayCheck(look: 'Test')
          .check(tester.element(find.byType(Navigator)));
    }

    testWidgets('catches a week that scrolls sideways by less than a day '
        '(Comic\'s phone date picker)', (tester) async {
      expect((await strip(tester, 310)).problems, [
        'in a dialog "Pick a date": a grid scrolls sideways by 26 px, less '
            'than its narrowest control (48 px): it fits whole, or scrolls '
            'by a control at least',
      ]);
    });

    testWidgets('passes a strip that scrolls by a day or more', (tester) async {
      expect((await strip(tester, 280)).problems, isEmpty);
    });

    // A dialog whose body is [body] wide, holding a week of 48 px days.
    Future<DesignAlignmentReport> week(WidgetTester tester, double body) async {
      _phone(tester);
      await tester.pumpWidget(harness(const SizedBox.expand()));
      tester
          .state<NavigatorState>(find.byType(Navigator))
          .push(
            RawDialogRoute<void>(
              pageBuilder: (context, _, _) => Center(
                child: Semantics(
                  namesRoute: true,
                  label: 'Pick a date',
                  child: ClipRect(
                    child: SizedBox(
                      width: body,
                      height: 60,
                      child: OverflowBox(
                        alignment: AlignmentDirectional.topStart,
                        maxWidth: 336,
                        child: Row(children: [for (final d in _days) _key(d)]),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
      await tester.pumpAndSettle();
      return const DesignOverlayCheck(look: 'Test')
          .check(tester.element(find.byType(Navigator)));
    }

    testWidgets('catches a Sunday cut by a dialog narrower than the week', (
      tester,
    ) async {
      final report = await week(tester, 310);
      expect(report.problems, [
        startsWith(
          'in a dialog "Pick a date": a button "Su" is cut at its '
          'right by',
        ),
      ]);
    });

    testWidgets('passes the dialog that holds the week', (tester) async {
      expect((await week(tester, 336)).problems, isEmpty);
    });

    testWidgets('a list that scrolls is read against itself, its rows past '
        'the frame scrolling into view', (tester) async {
      _phone(tester);
      await tester.pumpWidget(harness(const SizedBox.expand()));
      tester
          .state<NavigatorState>(find.byType(Navigator))
          .push(
            RawDialogRoute<void>(
              pageBuilder: (context, _, _) => Center(
                child: SizedBox(
                  width: 200,
                  height: 200,
                  child: ListView(
                    children: [
                      for (var i = 0; i < 30; i++) _key('Row $i', width: 200),
                    ],
                  ),
                ),
              ),
            ),
          );
      await tester.pumpAndSettle();
      expect(
        const DesignOverlayCheck(look: 'Test')
            .check(tester.element(find.byType(Navigator)))
            .problems,
        isEmpty,
      );
    });
  });

  group('DesignOverflowCheck', () {
    Widget window(double scale) => harness(
      const Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: 358,
          height: 134,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('- - -', style: TextStyle(fontSize: 40)),
              Text('No time logged this week'),
            ],
          ),
        ),
      ),
      textScale: scale,
    );

    testWidgets('catches a chart\'s window that outgrows its 134 px at 2x '
        '(Appliance\'s idle chart)', (tester) async {
      await tester.pumpWidget(window(2));
      tester.takeException();
      final report = const DesignOverflowCheck(look: 'Test')
          .check(tester.element(find.byType(Column)));
      expect(report.problems, [
        allOf(
          startsWith('a column holding "- - -" overflows its 134 px by'),
          endsWith('at its foot'),
        ),
      ]);
    });

    testWidgets('passes it at 1x', (tester) async {
      await tester.pumpWidget(window(1));
      expect(
        const DesignOverflowCheck(look: 'Test')
            .check(tester.element(find.byType(Column)))
            .problems,
        isEmpty,
      );
    });
  });

  group('DesignDialogActionsCheck', () {
    const actions = ['Cancel', 'Discard', 'Save changes'];
    const check = DesignDialogActionsCheck(look: 'Test', actions: actions);

    Future<DesignAlignmentReport> show(WidgetTester tester, Widget bar) async {
      _phone(tester);
      await tester.pumpWidget(
        harness(Align(alignment: Alignment.topLeft, child: bar)),
      );
      return check.check(tester.element(find.byWidget(bar)));
    }

    testWidgets('passes one row', (tester) async {
      final report = await show(
        tester,
        Row(children: [for (final a in actions) _key(a, width: 100)]),
      );
      expect(report.problems, isEmpty);
    });

    testWidgets('catches two side by side and one under them (Expressive\'s '
        'and Terminal\'s 2+1)', (tester) async {
      final report = await show(
        tester,
        SizedBox(
          width: 240,
          child: Wrap(children: [for (final a in actions) _key(a, width: 110)]),
        ),
      );
      expect(report.problems, [
        startsWith(
          'actions "Cancel", "Discard", "Save changes": "Cancel" '
          'and "Discard" stand side by side and "Save changes" on a line '
          'of their own',
        ),
      ]);
    });

    testWidgets('catches Cancel on top of a stack (Brutal\'s)', (tester) async {
      final report = await show(
        tester,
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [for (final a in actions) _key(a, width: 200)],
        ),
      );
      expect(report.problems, [
        contains(
          'stacked: "Cancel" stands on top and "Save changes" at the '
          'foot; the confirming "Save changes" goes on top',
        ),
      ]);
    });

    testWidgets('catches a ragged stack (Comic\'s)', (tester) async {
      final report = await show(
        tester,
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (final (i, a) in actions.reversed.indexed)
              _key(a, width: 100.0 + i * 30),
          ],
        ),
      );
      expect(report.problems, [
        contains(
          'stacked: 160 px, 130 px, 100 px wide; a stack is one column '
          'of one width',
        ),
      ]);
    });

    testWidgets('passes RawActionBar\'s stack', (tester) async {
      final report = await show(
        tester,
        SizedBox(
          width: 200,
          child: RawActionBar(
            children: [for (final a in actions) _key(a, width: 100)],
          ),
        ),
      );
      expect(report.problems, isEmpty);
    });
  });

  group('DesignFieldWordsCheck', () {
    const words = ['We never share it'];
    const errorWords = ['Enter a valid email'];

    Widget entry(TextEditingController c, FocusNode f) => EditableText(
      controller: c,
      focusNode: f,
      style: const TextStyle(),
      cursorColor: const Color(0xFF000000),
      backgroundCursorColor: const Color(0xFF808080),
    );

    testWidgets('catches help and error drawn beside the field (nine looks '
        'on 0.4.1)', (tester) async {
      final semantics = tester.ensureSemantics();
      final c = TextEditingController();
      final f = FocusNode();
      addTearDown(c.dispose);
      addTearDown(f.dispose);
      await tester.pumpWidget(
        harness(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Semantics(container: true, label: 'Email', child: entry(c, f)),
              const Text('We never share it'),
              Semantics(
                liveRegion: true,
                container: true,
                child: const Text('Enter a valid email'),
              ),
            ],
          ),
        ),
      );
      final report = const DesignFieldWordsCheck(
        look: 'Test',
        words: [...words, ...errorWords],
      ).check(tester.element(find.byType(Column)));
      expect(report.problems, [
        startsWith(
          'the words "We never share it" are read on a node of '
          'their own at',
        ),
        startsWith(
          'the words "Enter a valid email" are read on a node of '
          'their own at',
        ),
      ]);
      expect(report.problems.first, contains('the text field "Email"'));
      semantics.dispose();
    });

    testWidgets('catches an error read on the field and again beside it; '
        'passes it as a live region', (tester) async {
      final semantics = tester.ensureSemantics();
      final c = TextEditingController();
      final f = FocusNode();
      addTearDown(c.dispose);
      addTearDown(f.dispose);
      for (final live in [false, true]) {
        await tester.pumpWidget(
          harness(
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Semantics(
                  container: true,
                  label: 'Email',
                  hint: 'Enter a valid email',
                  child: entry(c, f),
                ),
                Semantics(
                  liveRegion: live,
                  container: true,
                  child: const Text('Enter a valid email'),
                ),
              ],
            ),
          ),
        );
        final report = const DesignFieldWordsCheck(
          look: 'Test',
          words: errorWords,
        ).check(tester.element(find.byType(Column)));
        expect(
          report.problems,
          live
              ? isEmpty
              : [
                  startsWith(
                    'the words "Enter a valid email" are read on the text '
                    'field and again on a node of their own',
                  ),
                ],
        );
      }
      semantics.dispose();
    });

    testWidgets('catches help left out of the tree', (tester) async {
      final semantics = tester.ensureSemantics();
      final c = TextEditingController();
      final f = FocusNode();
      addTearDown(c.dispose);
      addTearDown(f.dispose);
      await tester.pumpWidget(
        harness(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Semantics(container: true, label: 'Email', child: entry(c, f)),
              const ExcludeSemantics(child: Text('We never share it')),
            ],
          ),
        ),
      );
      expect(
        const DesignFieldWordsCheck(
          look: 'Test',
          words: words,
        ).check(tester.element(find.byType(Column))).problems,
        ['the words "We never share it" are read nowhere'],
      );
      semantics.dispose();
    });

    for (final error in [null, 'Enter a valid email']) {
      testWidgets('passes RawInputDecorator (error: $error)', (tester) async {
        final semantics = tester.ensureSemantics();
        final c = TextEditingController();
        final f = FocusNode();
        addTearDown(c.dispose);
        addTearDown(f.dispose);
        await tester.pumpWidget(
          harness(
            MediaQuery(
              data: const MediaQueryData(supportsAnnounce: false),
              child: RawInputDecorator(
                labelText: 'Email',
                helperText: 'We never share it',
                errorText: error,
                focusNode: f,
                builder: (context, parts) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ?parts.label,
                    parts.control,
                    ?parts.helper,
                    ?parts.error,
                  ],
                ),
                child: entry(c, f),
              ),
            ),
          ),
        );
        expect(
          const DesignFieldWordsCheck(
            look: 'Test',
            words: [...words, ...errorWords],
          ).check(tester.element(find.byType(RawInputDecorator))).problems,
          error == null
              ? ['the words "Enter a valid email" are read nowhere']
              : isEmpty,
        );
        semantics.dispose();
      });
    }
  });
}

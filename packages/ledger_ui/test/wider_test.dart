// The wider look's controls and overlays: what any paper and ink app reaches
// for beside the ledger's own (chips, checks, sliders, tabs, the dialog, the
// action bar, the composer, the search entry, the date picker, the avatar
// stack, the week strip and the counter). Each is pumped
// on a phone and at desktop width in both appearances (nothing overflows or
// throws), read back through its semantics, then driven.
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_ui/ledger_ui.dart';
import 'package:ledger_ui/ledger_host.dart';

const Size _phone = Size(390, 844);
const Size _desktop = Size(1440, 900);

/// A page's column: the gutter at its sides, the widget as wide as the
/// column, free to grow down.
Widget _host(Widget child, Brightness brightness) => MaterialApp(
  debugShowCheckedModeBanner: false,
  builder: (context, page) => LedgerHost(brightness: brightness, child: page!),
  home: Scaffold(
    body: Builder(
      builder: (context) => SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: LedgerLayout.gutter(context),
          vertical: 24,
        ),
        child: child,
      ),
    ),
  ),
);

Future<void> _pump(
  WidgetTester t,
  Widget child, {
  Size size = _phone,
  Brightness brightness = Brightness.light,
}) async {
  t.view.physicalSize = size;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(_host(child, brightness));
  await t.pump();
}

/// Pumps [child] on a phone and at desktop width, light and dark: each lays
/// out clean.
Future<void> _everywhere(WidgetTester t, Widget child) async {
  for (final size in const [_phone, _desktop]) {
    for (final brightness in Brightness.values) {
      await _pump(t, child, size: size, brightness: brightness);
      expect(
        t.takeException(),
        isNull,
        reason: '${size.width.round()} wide, ${brightness.name}',
      );
    }
  }
}

SemanticsNode _node(WidgetTester t, Pattern label) =>
    t.getSemantics(find.bySemanticsLabel(label));

void main() {
  setUpAll(_stillMotion);
  tearDownAll(_movingMotion);

  group('chips', () {
    Widget chips({String chosen = 'Open', ValueChanged<String>? pick}) =>
        LedgerChipRow(
          label: 'Show',
          children: [
            for (final f in const ['All', 'Open', 'Paid'])
              LedgerChip(
                f,
                selected: f == chosen,
                count: f == 'Open' ? 4 : null,
                onTap: pick == null ? null : () => pick(f),
              ),
          ],
        );

    testWidgets(
      'lay out everywhere',
      (t) => _everywhere(t, chips(pick: (_) {})),
    );

    testWidgets('say whether they are chosen and call back', (t) async {
      String? picked;
      await _pump(t, chips(pick: (f) => picked = f));
      expect(
        _node(t, RegExp('Open')),
        isSemantics(hasSelectedState: true, isSelected: true),
      );
      expect(
        _node(t, RegExp('Paid')),
        isSemantics(hasSelectedState: true, isSelected: false),
      );
      await t.tap(find.text('Paid'));
      expect(picked, 'Paid');
    });

    testWidgets('are held when nothing answers', (t) async {
      await _pump(t, chips());
      expect(find.text('All'), findsOneWidget);
      await t.tap(find.text('All'));
      expect(t.takeException(), isNull);
    });
  });

  group('check', () {
    testWidgets(
      'lays out everywhere',
      (t) => _everywhere(
        t,
        LedgerCheck(value: true, label: 'Done', onChanged: (_) {}),
      ),
    );

    testWidgets('flips through onChanged and says it is checked', (t) async {
      var done = false;
      late StateSetter set;
      await _pump(
        t,
        StatefulBuilder(
          builder: (context, setState) {
            set = setState;
            return LedgerCheck(
              value: done,
              label: 'Order paper',
              onChanged: (v) => set(() => done = v),
            );
          },
        ),
      );
      expect(
        _node(t, 'Order paper'),
        isSemantics(hasCheckedState: true, isChecked: false),
      );
      await t.tap(find.byType(LedgerCheck));
      await t.pump();
      expect(done, isTrue);
      expect(
        _node(t, 'Order paper'),
        isSemantics(hasCheckedState: true, isChecked: true),
      );
    });

    testWidgets('is a mark when nothing answers', (t) async {
      await _pump(t, const LedgerCheck(value: true, label: 'Reconciled'));
      expect(
        _node(t, 'Reconciled'),
        isSemantics(
          hasCheckedState: true,
          isChecked: true,
          hasTapAction: false,
        ),
      );
    });
  });

  group('slider', () {
    Widget slider(ValueChanged<double>? set, {int? divisions}) => LedgerSlider(
      label: 'Paper weight',
      value: 120,
      min: 80,
      max: 200,
      unit: 'gsm',
      divisions: divisions,
      onChanged: set,
    );

    testWidgets(
      'lays out everywhere',
      (t) => _everywhere(t, slider((_) {}, divisions: 10)),
    );

    testWidgets('prints its value and answers the arrow keys', (t) async {
      double? set;
      await _pump(t, slider((v) => set = v, divisions: 12));
      expect(find.textContaining('120'), findsWidgets);
      await t.tap(find.byType(LedgerSlider));
      await t.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await t.pump();
      expect(set, isNotNull);
    });

    testWidgets('is an adjustable value', (t) async {
      await _pump(t, slider((_) {}, divisions: 12));
      expect(
        _node(t, RegExp('Paper weight')),
        isSemantics(hasIncreaseAction: true, hasDecreaseAction: true),
      );
    });
  });

  group('tabs', () {
    testWidgets('lay out everywhere, fitting and scrolling', (t) async {
      await _everywhere(
        t,
        LedgerTabs(
          tabs: const ['Entries', 'Notes', 'Files'],
          selectedIndex: 0,
          counts: const [12, 3, null],
          onSelected: (_) {},
        ),
      );
      await _everywhere(
        t,
        LedgerTabs(
          tabs: const [
            'Overview',
            'Entries',
            'Invoices',
            'Notes',
            'Files',
            'People',
            'History',
          ],
          selectedIndex: 2,
          onSelected: (_) {},
        ),
      );
    });

    testWidgets('choose on a tap and say which is chosen', (t) async {
      int? chosen;
      await _pump(
        t,
        LedgerTabs(
          tabs: const ['Entries', 'Notes'],
          selectedIndex: 0,
          onSelected: (i) => chosen = i,
        ),
      );
      expect(
        _node(t, RegExp('Entries')),
        isSemantics(hasSelectedState: true, isSelected: true),
      );
      await t.tap(find.text('Notes'));
      expect(chosen, 1);
    });
  });

  group('dialog', () {
    Widget opener(void Function(bool?) done, LedgerDialogType kind) => Builder(
      builder: (context) => LedgerButton.filled(
        'Ask',
        onPressed: () async => done(
          await LedgerDialog.show(
            context,
            title: 'Delete this entry?',
            body: 'It leaves your records for good.',
            type: kind,
          ),
        ),
      ),
    );

    for (final kind in LedgerDialogType.values) {
      testWidgets(
        '${kind.name} lays out in place everywhere',
        (t) => _everywhere(
          t,
          Center(
            child: LedgerDialog(
              title: 'Delete this entry?',
              body: 'It leaves your records for good.',
              type: kind,
              onConfirmPressed: () {},
            ),
          ),
        ),
      );
    }

    testWidgets('confirm completes true, cancel false', (t) async {
      bool? answer;
      var asked = 0;
      await _pump(
        t,
        opener((v) {
          answer = v;
          asked++;
        }, LedgerDialogType.confirm),
      );
      await t.tap(find.text('Ask'));
      await t.pumpAndSettle();
      expect(find.text('Delete this entry?'), findsOneWidget);
      await t.tap(find.text('Confirm'));
      await t.pumpAndSettle();
      expect(answer, isTrue);
      await t.tap(find.text('Ask'));
      await t.pumpAndSettle();
      await t.tap(find.text('Cancel'));
      await t.pumpAndSettle();
      expect(answer, isFalse);
      expect(asked, 2);
    });

    testWidgets(
      'the scrim dismisses to null and an acknowledgement has one act',
      (t) async {
        var answered = false;
        bool? answer = true;
        await _pump(
          t,
          opener((v) {
            answer = v;
            answered = true;
          }, LedgerDialogType.acknowledge),
        );
        await t.tap(find.text('Ask'));
        await t.pumpAndSettle();
        expect(find.text('Cancel'), findsNothing);
        expect(find.text('Got it'), findsOneWidget);
        await t.tapAt(const Offset(4, 4));
        await t.pumpAndSettle();
        expect(answered, isTrue);
        expect(answer, isNull);
      },
    );

    testWidgets('a destructive confirm is struck in the vermilion', (t) async {
      await _pump(
        t,
        Center(
          child: LedgerDialog(
            title: 'Delete this entry?',
            type: LedgerDialogType.destructive,
            onConfirmPressed: () {},
          ),
        ),
      );
      final theme = t.element(find.byType(LedgerDialog)).ledgerTheme;
      final fills = t
          .widgetList<Container>(find.byType(Container))
          .where(
            (c) =>
                c.decoration is BoxDecoration &&
                (c.decoration! as BoxDecoration).color == theme.danger,
          );
      expect(fills, isNotEmpty);
    });
  });

  group('action bar', () {
    testWidgets('lays out everywhere, docked and floating', (t) async {
      await _everywhere(
        t,
        LedgerActionBar(
          summary: '\$1,240.00',
          detail: 'Due Nov 1',
          label: 'Pay now',
          onTap: () {},
        ),
      );
      await _everywhere(
        t,
        LedgerActionBar(floating: true, label: 'File them', onTap: () {}),
      );
    });

    testWidgets('prints the summary and acts', (t) async {
      var paid = 0;
      await _pump(
        t,
        LedgerActionBar(
          summary: '\$1,240.00',
          detail: 'Due Nov 1',
          label: 'Pay now',
          onTap: () => paid++,
        ),
      );
      expect(find.text('\$1,240.00'), findsOneWidget);
      expect(find.text('DUE NOV 1'), findsOneWidget);
      await t.tap(find.text('Pay now'));
      expect(paid, 1);
    });

    testWidgets('busy shows its words and takes no press', (t) async {
      var paid = 0;
      await _pump(
        t,
        LedgerActionBar(label: 'Pay now', busy: true, onTap: () => paid++),
      );
      expect(find.text('Working…'), findsOneWidget);
      await t.tap(find.text('Working…'));
      expect(paid, 0);
    });

    testWidgets('stacks at large text', (t) async {
      t.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
      await _pump(
        t,
        LedgerActionBar(
          summary: '\$1,240.00',
          detail: 'Due Nov 1',
          label: 'Pay now',
          onTap: () {},
        ),
      );
      expect(t.takeException(), isNull);
      final sum = t.getTopLeft(find.text('\$1,240.00'));
      final act = t.getTopLeft(find.text('Pay now'));
      expect(act.dy, greaterThan(sum.dy));
    });
  });

  group('composer', () {
    testWidgets('lays out everywhere, both styles', (t) async {
      await _everywhere(
        t,
        LedgerComposer(onAttachPressed: () {}, onVoicePressed: () {}),
      );
      await _everywhere(
        t,
        LedgerComposer(
          style: LedgerComposerStyle.assistant,
          onAttachPressed: () {},
          onSubmitted: () {},
          toolbar: [LedgerChip('This month', onTap: () {})],
        ),
      );
    });

    testWidgets('sends once there are words, voice before them', (t) async {
      final words = TextEditingController();
      addTearDown(words.dispose);
      var sent = 0;
      var spoke = 0;
      await _pump(
        t,
        LedgerComposer(
          controller: words,
          onSubmitted: () => sent++,
          onVoicePressed: () => spoke++,
        ),
      );
      await t.tap(find.bySemanticsLabel('Voice message'));
      expect(spoke, 1);
      await t.enterText(find.byType(EditableText), 'On its way');
      await t.pump();
      expect(find.bySemanticsLabel('Voice message'), findsNothing);
      await t.tap(find.bySemanticsLabel('Send'));
      expect(sent, 1);
    });

    testWidgets('shows the stop while a send runs', (t) async {
      var stopped = 0;
      await _pump(
        t,
        LedgerComposer(sending: true, onStopPressed: () => stopped++),
      );
      await t.tap(find.bySemanticsLabel('Stop'));
      expect(stopped, 1);
    });
  });

  group('search entry', () {
    testWidgets(
      'lays out everywhere',
      (t) => _everywhere(
        t,
        LedgerSearchEntry(onTap: () {}, onFilterPressed: () {}, filterCount: 2),
      ),
    );

    testWidgets('opens the search and the filters, and counts them', (t) async {
      var searched = 0;
      var filtered = 0;
      await _pump(
        t,
        LedgerSearchEntry(
          hint: 'Search entries',
          onTap: () => searched++,
          onFilterPressed: () => filtered++,
          filterCount: 3,
        ),
      );
      expect(find.text('3'), findsOneWidget);
      await t.tap(find.text('Search entries'));
      expect(searched, 1);
      await t.tap(find.bySemanticsLabel(RegExp('Filters')));
      expect(filtered, 1);
    });
  });

  group('date picker', () {
    final day = DateTime(2026, 11, 4, 9, 30);

    testWidgets('lays out everywhere in every presentation', (t) async {
      for (final presentation in LedgerDatePickerPresentation.values) {
        for (final mode in LedgerDatePickerMode.values) {
          await _everywhere(
            t,
            LedgerDatePicker(
              value: day,
              mode: mode,
              presentation: presentation,
              today: DateTime(2026, 11, 1),
              onChanged: (_) {},
            ),
          );
        }
      }
    });

    testWidgets('the compact line prints the pills', (t) async {
      await _pump(
        t,
        LedgerDatePicker(
          label: 'Due',
          value: day,
          mode: LedgerDatePickerMode.dateAndTime,
          onChanged: (_) {},
        ),
      );
      expect(find.text('Nov 4, 2026'), findsOneWidget);
      expect(find.text('9:30 AM'), findsOneWidget);
    });

    testWidgets('the month picks a day and keeps the time', (t) async {
      DateTime? picked;
      await _pump(
        t,
        LedgerDatePicker(
          value: day,
          presentation: LedgerDatePickerPresentation.inline,
          mode: LedgerDatePickerMode.dateAndTime,
          onChanged: (v) => picked = v,
        ),
      );
      expect(find.text('November 2026'), findsOneWidget);
      await t.tap(find.text('12'));
      expect(picked, DateTime(2026, 11, 12, 9, 30));
    });

    testWidgets('days outside the range are inert and the month steps', (
      t,
    ) async {
      DateTime? picked;
      await _pump(
        t,
        LedgerDatePicker(
          value: day,
          presentation: LedgerDatePickerPresentation.inline,
          firstDate: DateTime(2026, 11, 3),
          lastDate: DateTime(2026, 11, 20),
          onChanged: (v) => picked = v,
        ),
      );
      await t.tap(find.text('2'));
      expect(picked, isNull);
      await t.tap(find.text('21'));
      expect(picked, isNull);
      expect(_node(t, 'Previous month'), isSemantics(hasTapAction: false));
      expect(_node(t, 'Next month'), isSemantics(hasTapAction: false));
    });

    // Self-review round 1: at 1440 the month spread its days 150 apart
    // across the column. From 600 it stands at its sheet's width.
    testWidgets('the month and the wheels keep their measure from 600', (
      t,
    ) async {
      for (final presentation in const [
        LedgerDatePickerPresentation.inline,
        LedgerDatePickerPresentation.wheel,
      ]) {
        for (final size in const [_phone, _desktop]) {
          await _pump(
            t,
            LedgerDatePicker(
              value: day,
              presentation: presentation,
              mode: LedgerDatePickerMode.dateAndTime,
              onChanged: (_) {},
            ),
            size: size,
          );
          final slot = t.getSize(find.byType(LedgerDatePicker)).width;
          final face = t
              .getSize(
                find
                    .descendant(
                      of: find.byType(LedgerDatePicker),
                      matching: find.byType(ConstrainedBox),
                    )
                    .first,
              )
              .width;
          if (size == _phone) {
            expect(slot, size.width - 2 * LedgerChromeMetrics.gutter);
          } else {
            expect(face, lessThanOrEqualTo(416), reason: presentation.name);
            expect(slot, greaterThan(416), reason: presentation.name);
          }
        }
      }
    });

    testWidgets('next month shows the following month', (t) async {
      await _pump(
        t,
        LedgerDatePicker(
          value: day,
          presentation: LedgerDatePickerPresentation.inline,
          onChanged: (_) {},
        ),
      );
      await t.tap(find.bySemanticsLabel('Next month'));
      await t.pump();
      expect(find.text('December 2026'), findsOneWidget);
    });

    testWidgets('a wheel is an adjustable value', (t) async {
      DateTime? picked;
      await _pump(
        t,
        LedgerDatePicker(
          value: day,
          mode: LedgerDatePickerMode.time,
          presentation: LedgerDatePickerPresentation.wheel,
          onChanged: (v) => picked = v,
        ),
      );
      expect(
        _node(t, 'Hour'),
        isSemantics(
          value: '9',
          hasIncreaseAction: true,
          hasDecreaseAction: true,
        ),
      );
      t.semantics.increase(find.semantics.byLabel('Hour'));
      await t.pump();
      expect(picked?.hour, 10);
    });

    testWidgets('a held picker is dimmed and calls nothing', (t) async {
      await _pump(t, LedgerDatePicker(value: day, onChanged: null));
      await t.tap(find.text('Nov 4, 2026'));
      await t.pumpAndSettle();
      expect(find.text('Done'), findsNothing);
    });

    testWidgets('a pill raises the sheet and Done commits', (t) async {
      DateTime? picked;
      await _pump(
        t,
        LedgerDatePicker(
          label: 'Due',
          value: day,
          onChanged: (v) => picked = v,
        ),
      );
      await t.tap(find.text('Nov 4, 2026'));
      await t.pumpAndSettle();
      await t.tap(find.text('9'));
      await t.pump();
      await t.tap(find.text('Done'));
      await t.pumpAndSettle();
      expect(picked, DateTime(2026, 11, 9, 9, 30));
    });
  });

  group('avatar stack', () {
    testWidgets('lays out everywhere and says who and how many', (t) async {
      const names = ['Maren Holt', 'Jonas Ahn', 'Priya Rao', 'Lee Wong'];
      await _everywhere(t, const LedgerAvatarStack(names: names, total: 9));
      await _pump(t, const LedgerAvatarStack(names: names, total: 9));
      expect(find.text('+5'), findsOneWidget);
      expect(find.text('MH'), findsOneWidget);
      expect(_node(t, RegExp('Maren Holt')).label, contains('more'));
    });
  });

  group('week strip', () {
    const week = [
      LedgerDayMark.kept,
      LedgerDayMark.kept,
      LedgerDayMark.missed,
      LedgerDayMark.today,
      LedgerDayMark.upcoming,
      LedgerDayMark.upcoming,
      LedgerDayMark.upcoming,
    ];

    testWidgets('lays out everywhere and reads as one node', (t) async {
      await _everywhere(
        t,
        const LedgerWeekStrip(days: week, label: 'Morning pages'),
      );
      await _pump(t, const LedgerWeekStrip(days: week, label: 'Morning pages'));
      final node = _node(t, 'Morning pages');
      expect(node.value, contains('Wednesday missed'));
      expect(node.value, contains('Thursday today, still to do'));
    });
  });

  group('counter', () {
    testWidgets('lays out everywhere and lands on its value', (t) async {
      await _everywhere(t, LedgerCounter(12, format: (v) => '$v days'));
      await _pump(t, LedgerCounter(12, format: (v) => '$v days'));
      expect(_node(t, '12 days'), isSemantics(label: '12 days'));
    });

    testWidgets('is re-inked at a new value', (t) async {
      late StateSetter set;
      var streak = 9;
      await _pump(
        t,
        StatefulBuilder(
          builder: (context, setState) {
            set = setState;
            return LedgerCounter(streak);
          },
        ),
      );
      set(() => streak = 10);
      await t.pumpAndSettle();
      expect(find.bySemanticsLabel('10'), findsOneWidget);
      expect(t.takeException(), isNull);
    });
  });
}

/// Reduced motion on, as a reader who asked for it has it: every Ledger
/// change lands at once, so a test reads the settled frame.
void _stillMotion() =>
    TestWidgetsFlutterBinding.ensureInitialized()
        .platformDispatcher
        .accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(
      disableAnimations: true,
    );

/// The platform's own motion back.
void _movingMotion() => TestWidgetsFlutterBinding.instance.platformDispatcher
    .clearAccessibilityFeaturesTestValue();

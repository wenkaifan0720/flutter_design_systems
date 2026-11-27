// A section's head with a note longer than the room beside its rubric:
// the note turns onto more lines at the end, never runs past the page.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_ui/ledger_ui.dart';

void main() {
  testWidgets('a long note wraps beside the rubric at a phone width', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      WidgetsApp(
        color: const Color(0xFF000000),
        localizationsDelegates: const [RawWidgetsLocalizations.delegate],
        builder: (context, _) => const LedgerHost(
          brightness: Brightness.light,
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Align(
              alignment: Alignment.topCenter,
              child: LedgerHead(
                'Colour',
                note: 'The seal and the paper of every page',
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final note = tester.getRect(
      find.text('THE SEAL AND THE PAPER OF EVERY PAGE'),
    );
    expect(note.right, lessThanOrEqualTo(390 - 24 + .5));
    expect(
      tester.getRect(find.textContaining('COLOUR')).right,
      lessThan(note.left),
    );
  });

  testWidgets("a control at the head's end keeps its own width", (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    Widget head(Widget? before) => WidgetsApp(
      color: const Color(0xFF000000),
      localizationsDelegates: const [RawWidgetsLocalizations.delegate],
      builder: (context, _) => LedgerHost(
        brightness: Brightness.light,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Align(
            alignment: Alignment.topCenter,
            child:
                before ??
                LedgerHead(
                  'Spending by category this year',
                  trailing: LedgerSegmentedControl(
                    options: const ['1M', '3M', '1Y', 'All'],
                    value: '1Y',
                    onChanged: (_) {},
                  ),
                ),
          ),
        ),
      ),
    );
    // The control's own width, alone.
    await tester.pumpWidget(
      head(
        LedgerSegmentedControl(
          options: const ['1M', '3M', '1Y', 'All'],
          value: '1Y',
          onChanged: (_) {},
        ),
      ),
    );
    final own = tester
        .getSize(find.byType(LedgerSegmentedControl<String>))
        .width;
    await tester.pumpWidget(head(null));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(
      tester.getSize(find.byType(LedgerSegmentedControl<String>)).width,
      own,
    );
  });
}

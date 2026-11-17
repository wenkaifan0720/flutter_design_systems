// iOS's Reduce Motion alone. Flutter 3.47 sets only dart:ui's reduceMotion there, never MediaQuery's
// disableAnimations. Ledger reads ui_core's designReduceMotionOf (LedgerMotion.isReduced), so its steps, its loops and
// its eases calm with that flag alone, and a flip while a loop runs reaches the loop as a build.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_ui/ledger_ui.dart';
import 'package:ledger_ui/ledger_host.dart';

/// Sets iOS's Reduce Motion, and only it, for the rest of the test.
void _iosReduceMotion(WidgetTester t, bool on) {
  t.platformDispatcher.accessibilityFeaturesTestValue =
      FakeAccessibilityFeatures(reduceMotion: on);
}

Widget _app(Widget child) => MaterialApp(
  debugShowCheckedModeBanner: false,
  builder: (context, page) =>
      LedgerHost(brightness: Brightness.light, child: page!),
  home: Center(child: child),
);

void main() {
  for (final reduced in const [false, true]) {
    testWidgets(
      'with iOS\'s flag ${reduced ? 'on every step is a cut' : 'off every step moves'}',
      (t) async {
        addTearDown(t.platformDispatcher.clearAccessibilityFeaturesTestValue);
        _iosReduceMotion(t, reduced);
        late BuildContext context;
        await t.pumpWidget(
          _app(
            Builder(
              builder: (c) {
                context = c;
                return const SizedBox();
              },
            ),
          ),
        );
        expect(MediaQuery.disableAnimationsOf(context), isFalse);
        expect(LedgerMotion.isReduced(context), reduced);
        for (final step in const [
          LedgerMotion.fast,
          LedgerMotion.base,
          LedgerMotion.slow,
        ]) {
          expect(
            LedgerMotion.of(context, step),
            reduced ? Duration.zero : step,
          );
        }
        expect(
          LedgerSheet.motionOf(context).duration,
          reduced ? Duration.zero : LedgerMotion.slow,
        );
      },
    );
  }

  for (final (name, part) in const <(String, Widget)>[
    ('the progress bar', LedgerProgressBar(label: 'Saving')),
    ('the progress ring', LedgerProgressRing(label: 'Saving')),
    ('the skeleton', SizedBox(width: 240, child: LedgerSkeleton())),
    ('the loading state', LedgerLoadingState()),
  ]) {
    testWidgets(
      '$name stops as iOS\'s Reduce Motion turns on and runs as it turns off',
      (t) async {
        addTearDown(t.platformDispatcher.clearAccessibilityFeaturesTestValue);
        await t.pumpWidget(_app(SizedBox(width: 320, child: part)));
        expect(t.hasRunningAnimations, isTrue);
        _iosReduceMotion(t, true);
        await t.pump();
        expect(t.hasRunningAnimations, isFalse);
        _iosReduceMotion(t, false);
        await t.pump();
        expect(t.hasRunningAnimations, isTrue);
      },
    );
  }

  for (final reduced in const [false, true]) {
    testWidgets(
      'a disclosure ${reduced ? 'opens at once' : 'eases open'} with iOS\'s flag ${reduced ? 'on' : 'off'}',
      (t) async {
        addTearDown(t.platformDispatcher.clearAccessibilityFeaturesTestValue);
        _iosReduceMotion(t, reduced);
        await t.pumpWidget(
          _app(
            const SizedBox(
              width: 320,
              child: LedgerDisclosure(
                title: 'Notes',
                child: Text('Paid in cash at the counter.'),
              ),
            ),
          ),
        );
        await t.tap(find.text('Notes'));
        await t.pump();
        expect(t.hasRunningAnimations, !reduced);
        await t.pumpAndSettle();
        expect(find.text('Paid in cash at the counter.'), findsOneWidget);
      },
    );
  }
}

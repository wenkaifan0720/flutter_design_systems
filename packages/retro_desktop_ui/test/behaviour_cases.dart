// The same source-enumerated inventory as reach_test: every interactive part
// must be keyboard reachable, expose state, and stop when disabled. The parts
// run in three files (behaviour_a/b/c_test.dart), a third each, so no test
// process runs all 3,000 cases (one that did grew to 7.4 GB on Linux). Every
// day each case runs on a desk platform and a phone one, and each part's 2x type
// and RTL check at one width, the parts taking the four in turn; the rest of the
// matrix is tagged sweep.
import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';

import 'interactive_samples.dart';

import 'support.dart';

const _part = ValueKey('tested-part');

Widget _host(
  Widget child, {
  double scale = 1,
  TextDirection direction = TextDirection.ltr,
}) => retroDesktopApp(
  Builder(
    builder: (context) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: true),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: KeyedSubtree(key: _part, child: child),
        ),
      ),
    ),
  ),
  scale: scale,
  direction: direction,
);

bool _focusedInPart() {
  var inPart = false;
  FocusManager.instance.primaryFocus?.context?.visitAncestorElements((e) {
    if (e.widget.key == _part) inPart = true;
    return true;
  });
  return inPart;
}

void _size(WidgetTester tester, double width) {
  tester.view.physicalSize = Size(width, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// Round 4's parts whose keys are not a press's Enter and Space: ui_core's
/// behaviours and the wheel. Tab reaches them here and they lay out everywhere;
/// their keys and what they do are held by ui_core's tests and coverage_test.
const _onCore = {
  'RetroDesktopCombobox',
  'RetroDesktopRangeSlider',
  'RetroDesktopCalendar',
  'RetroDesktopDateRangePicker',
  'RetroDesktopDataTable',
  'RetroDesktopResizable',
  'RetroDesktopTreeView',
};

/// Parts that are one focus stop with the period's keys, not a press per row: Tab reaches the part, an arrow chooses
/// the next row. Their rows are places to press, not presses, so hover changes nothing.
const _oneStop = {'RetroDesktopListTable'};

/// The widths of the 2x type and RTL check, each with the platform it runs on every day (four platforms, once each).
final _everydayAt = <double, TargetPlatform>{
  390.0: TargetPlatform.android,
  768.0: TargetPlatform.iOS,
  1024.0: TargetPlatform.windows,
  1440.0: TargetPlatform.macOS,
};

/// The behaviour tests of every [parts]th interactive part, from the [part]th (0-based).
void behaviourTests({required int part, required int parts}) {
  setUpAll(loadRetroDesktopFonts);
  final entries = retroDesktopInteractiveSamples.entries.toList();
  for (final (index, entry) in entries.indexed) {
    if (index % parts != part) continue;
    final editor = [
      'RetroDesktopTextField',
      'RetroDesktopInput',
      'RetroDesktopSearchField',
      'RetroDesktopInputOtp',
      'RetroDesktopTextArea',
      'RetroDesktopPasswordField',
      'RetroDesktopInputGroup',
    ].contains(entry.key);
    final onCore = _onCore.contains(entry.key);
    final oneStop = _oneStop.contains(entry.key);
    final menuTrigger =
        entry.key == 'RetroDesktopSelect' ||
        entry.key == 'RetroDesktopMenuAnchor' ||
        entry.key == 'RetroDesktopTimePicker';
    final closingAction = entry.key == 'RetroDesktopDialogAction';
    group(entry.key, () {
      testWidgetsAcross('Tab focuses and keyboard activates', (tester) async {
        _size(tester, 390);
        var hits = 0;
        if (closingAction) {
          // A dialog action closes its route, so it cannot be activated twice in place.
          await tester.pumpWidget(
            _host(
              Builder(
                builder: (context) => RetroDesktopButton(
                  'Open dialog',
                  onPressed: () => showRetroDesktopDialog<void>(
                    context,
                    builder: (_) => RetroDesktopDialog(
                      title: 'Dialog body',
                      actions: [entry.value(() => hits++)],
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.tap(find.text('Open dialog'));
          await tester.pumpAndSettle();
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await tester.pump();
          await tester.sendKeyEvent(LogicalKeyboardKey.enter);
          await tester.pumpAndSettle();
          expect(hits, 1);
          expect(find.text('Dialog body'), findsNothing);
          expect(tester.takeException(), isNull);
          return;
        }
        await tester.pumpWidget(_host(entry.value(() => hits++)));
        FocusManager.instance.highlightStrategy =
            FocusHighlightStrategy.alwaysTraditional;
        addTearDown(
          () => FocusManager.instance.highlightStrategy =
              FocusHighlightStrategy.automatic,
        );
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        expect(_focusedInPart(), isTrue);
        if (onCore) {
          expect(tester.takeException(), isNull);
          return;
        }
        if (oneStop) {
          await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
          await tester.pump();
          expect(hits, greaterThan(0), reason: 'an arrow chooses a row');
          expect(tester.takeException(), isNull);
          return;
        }
        if (editor) {
          await tester.enterText(
            find.byType(EditableText),
            entry.key == 'RetroDesktopInputOtp' ? '123456' : 'Keyboard input',
          );
          expect(hits, greaterThan(0));
        } else {
          expect(
            tester
                .stateList<DesignPressableState>(find.byType(DesignPressable))
                .any((state) => state.states.contains(WidgetState.focused)),
            isTrue,
          );
          if (entry.key == 'RetroDesktopRadioGroup' ||
              entry.key == 'RetroDesktopSegmentedButton') {
            await tester.sendKeyEvent(LogicalKeyboardKey.enter);
            await tester.sendKeyEvent(LogicalKeyboardKey.space);
            await tester.pumpAndSettle();
            expect(
              hits,
              0,
              reason: 'reactivating the selected value is a no-op',
            );
            await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
            await tester.pumpAndSettle();
            expect(hits, 1, reason: 'an arrow selects the next enabled value');
            expect(tester.takeException(), isNull);
            return;
          }
          await tester.sendKeyEvent(LogicalKeyboardKey.enter);
          await tester.pumpAndSettle();
          if (menuTrigger) {
            await tester.sendKeyEvent(LogicalKeyboardKey.enter);
            await tester.pumpAndSettle();
          }
          expect(hits, greaterThan(0));
          final afterEnter = hits;
          await tester.sendKeyEvent(LogicalKeyboardKey.space);
          await tester.pumpAndSettle();
          if (menuTrigger) {
            await tester.sendKeyEvent(LogicalKeyboardKey.space);
            await tester.pumpAndSettle();
          }
          expect(hits, greaterThan(afterEnter));
        }
        expect(tester.takeException(), isNull);
      });

      if (!onCore) {
        testWidgetsAcross('disabled parts take no focus or activation', (
          tester,
        ) async {
          _size(tester, 390);
          await tester.pumpWidget(_host(entry.value(null)));
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await tester.pump();
          expect(_focusedInPart(), isFalse);
          for (final state in tester.stateList<DesignPressableState>(
            find.byType(DesignPressable),
          )) {
            expect(state.states, contains(WidgetState.disabled));
          }
          expect(tester.takeException(), isNull);
        }, everyday: const {TargetPlatform.macOS});
      }

      if (!editor && !onCore && !oneStop) {
        // A pointer's hover: a desk's every day.
        testWidgetsAcross(
          'hover reaches the face and reduced motion stays still',
          (tester) async {
            _size(tester, 390);
            await tester.pumpWidget(_host(entry.value(() {})));
            final first = find
                .byWidgetPredicate(
                  (widget) =>
                      widget is DesignPressable &&
                      (widget.enabled ??
                          (widget.onPressed != null ||
                              widget.onLongPress != null)),
                )
                .first;
            final mouse = await tester.createGesture(
              kind: PointerDeviceKind.mouse,
            );
            await mouse.addPointer(location: Offset.zero);
            addTearDown(mouse.removePointer);
            await mouse.moveTo(tester.getCenter(first));
            await tester.pump();
            expect(
              tester.state<DesignPressableState>(first).states,
              contains(WidgetState.hovered),
            );
            if (!closingAction) await tester.tap(first);
            await tester.pump();
            await tester.pump();
            expect(tester.hasRunningAnimations, isFalse);
            expect(tester.takeException(), isNull);
          },
          everyday: const {TargetPlatform.macOS},
        );
      }

      // Every day at one width a part, the parts taking the four widths in turn.
      final widths = _everydayAt.keys.toList();
      for (final width in widths) {
        testWidgetsAcross(
          '2x type and RTL at $width',
          (tester) async {
            _size(tester, width);
            await tester.pumpWidget(
              _host(entry.value(() {}), scale: 2, direction: TextDirection.rtl),
            );
            await tester.pump();
            expect(tester.takeException(), isNull);
          },
          everyday: width == widths[index % widths.length]
              ? {_everydayAt[width]!}
              : const {},
        );
      }
    });
  }
}

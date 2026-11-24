import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/ui_core.dart';

import 'behaviour_harness.dart';

// A kept part standing on a kept band extends it: the toasts stand above a
// page's foot over a status line over a tab bar, as Material's Scaffold keeps
// a snackbar above its footer buttons and those above its navigation bar.
// The toaster's padding (16) stays between the band and the toasts.

final _toaster = GlobalKey<RawToasterState>();

Rect _toast(WidgetTester tester) =>
    tester.getRect(find.byKey(const ValueKey('toast')));

Widget _kept(double height, {Key? key, double? width}) => RawToasterKeepClear(
  key: key,
  child: SizedBox(height: height, width: width ?? double.infinity),
);

// [page] under a toaster round the navigator, with [chrome] (parts of the
// app's own, beside every route) under the navigator.
Future<void> _pump(
  WidgetTester tester,
  Widget page, {
  required Size size,
  TextDirection textDirection = TextDirection.ltr,
  AlignmentGeometry alignment = AlignmentDirectional.bottomCenter,
  List<Widget> chrome = const [],
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    harness(
      page,
      textDirection: textDirection,
      wrap: (context, navigator) => RawToaster(
        key: _toaster,
        alignment: alignment,
        constraints: const BoxConstraints(maxWidth: 300),
        toastBuilder: (context, details) => SizedBox(
          key: const ValueKey('toast'),
          height: 40,
          child: Text(details.toast.message),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: navigator!),
            ...chrome,
          ],
        ),
      ),
    ),
  );
  _toaster.currentState!.show(
    const RawToast(message: 'Changes saved', duration: null),
  );
  await tester.pumpAndSettle();
}

// A phone: the page's foot (80) on a status line (24) on a tab bar (48).
Widget _phone({bool foot = true, bool status = true}) => Column(
  children: [
    const Expanded(child: SizedBox.expand()),
    if (foot) _kept(80, key: const ValueKey('foot')),
    if (status) _kept(24),
    _kept(48),
  ],
);

// A desk: a list (480) beside a detail pane whose foot (80) stands on the
// window-wide status line (24).
Widget _desk({bool status = true}) => Column(
  children: [
    Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(width: 480),
          Expanded(
            child: Column(
              children: [
                const Expanded(child: SizedBox.expand()),
                _kept(80, key: const ValueKey('foot')),
              ],
            ),
          ),
        ],
      ),
    ),
    if (status) _kept(24),
  ],
);

void main() {
  group('RawToasterKeepClear: a part standing on a kept band', () {
    for (final direction in TextDirection.values) {
      testWidgets(
        'a foot on a status line on a tab bar, 390, ${direction.name}',
        (tester) async {
          await _pump(
            tester,
            _phone(),
            size: const Size(390, 844),
            textDirection: direction,
          );
          expect(
            _toast(tester).bottom,
            844 - 48 - 24 - 80 - 16,
            reason: 'above the foot, the status line and the bar, stacked',
          );
          final foot = tester.getRect(find.byKey(const ValueKey('foot')));
          expect(_toast(tester).bottom, lessThanOrEqualTo(foot.top - 16));
        },
      );

      testWidgets('a detail pane\'s foot on a window-wide status line, 1440, '
          '${direction.name}', (tester) async {
        await _pump(
          tester,
          _desk(),
          size: const Size(1440, 900),
          textDirection: direction,
        );
        expect(
          _toast(tester).bottom,
          900 - 24 - 80 - 16,
          reason: 'above the foot and the status line',
        );
      });
    }

    testWidgets('a part kept clear by the app beside the routes is a footing '
        'too: a page\'s foot stands on it', (tester) async {
      await _pump(
        tester,
        Column(
          children: [
            const Expanded(child: SizedBox.expand()),
            _kept(80),
          ],
        ),
        size: const Size(390, 844),
        chrome: [_kept(24), _kept(48)],
      );
      expect(_toast(tester).bottom, 844 - 48 - 24 - 80 - 16);
    });

    testWidgets('a foot that floats over the band with a gap is not stacked', (
      tester,
    ) async {
      await _pump(
        tester,
        Column(
          children: [
            const Expanded(child: SizedBox.expand()),
            _kept(80),
            const SizedBox(height: 8),
            _kept(48),
          ],
        ),
        size: const Size(390, 844),
      );
      expect(
        _toast(tester).bottom,
        844 - 48 - 16,
        reason: 'the bar alone: the foot does not stand on it',
      );
    });

    testWidgets('a part that lines up with the band beside it, not on it, is '
        'not stacked', (tester) async {
      await _pump(
        tester,
        Stack(
          children: [
            // The band: a foot along the bottom of a pane on the end side.
            PositionedDirectional(
              end: 0,
              bottom: 0,
              width: 540,
              child: _kept(72),
            ),
            // On the start side, ending where the band starts, over nothing.
            PositionedDirectional(
              start: 0,
              bottom: 72,
              width: 200,
              child: _kept(120),
            ),
          ],
        ),
        size: const Size(1440, 900),
      );
      expect(_toast(tester).bottom, 900 - 72 - 16);
    });

    testWidgets('as a foot leaves, the toasts come down to the band left; '
        'as its footing leaves, it no longer stands on anything', (
      tester,
    ) async {
      var foot = true;
      var status = true;
      late StateSetter setPage;
      await _pump(
        tester,
        StatefulBuilder(
          builder: (context, setState) {
            setPage = setState;
            return Stack(
              children: [
                if (foot)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 48 + 24,
                    child: _kept(80),
                  ),
                if (status)
                  Positioned(left: 0, right: 0, bottom: 48, child: _kept(24)),
                Positioned(left: 0, right: 0, bottom: 0, child: _kept(48)),
              ],
            );
          },
        ),
        size: const Size(390, 844),
      );
      expect(_toast(tester).bottom, 844 - 152 - 16);
      setPage(() => foot = false);
      await tester.pumpAndSettle();
      expect(_toast(tester).bottom, 844 - 72 - 16, reason: 'the foot left');
      setPage(() => foot = true);
      await tester.pumpAndSettle();
      expect(_toast(tester).bottom, 844 - 152 - 16, reason: 'the foot is back');
      setPage(() => status = false);
      await tester.pumpAndSettle();
      expect(
        _toast(tester).bottom,
        844 - 48 - 16,
        reason: 'the foot floats 24 over the bar now: the bar alone',
      );
    });

    testWidgets('a foot on a covered route lets go, and stands on the band '
        'again as the route pops', (tester) async {
      await _pump(
        tester,
        Column(
          children: [
            const Expanded(child: SizedBox.expand()),
            _kept(80),
          ],
        ),
        size: const Size(390, 844),
        chrome: [_kept(24), _kept(48)],
      );
      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      unawaited(
        navigator.push(
          PageRouteBuilder<void>(
            pageBuilder: (context, _, _) => const SizedBox.expand(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        _toast(tester).bottom,
        844 - 72 - 16,
        reason: 'the foot is under the pushed page; the chrome stays',
      );
      navigator.pop();
      await tester.pumpAndSettle();
      expect(_toast(tester).bottom, 844 - 152 - 16);
    });

    testWidgets('along the top, a strip hanging under a kept top bar keeps '
        'top toasts below both', (tester) async {
      await _pump(
        tester,
        Column(
          children: [
            _kept(56),
            _kept(48),
            const Expanded(child: SizedBox.expand()),
          ],
        ),
        size: const Size(390, 844),
        alignment: AlignmentDirectional.topCenter,
      );
      expect(_toast(tester).top, 56 + 48 + 16);
    });

    for (final alignment in [
      AlignmentDirectional.bottomCenter,
      AlignmentDirectional.topCenter,
    ]) {
      testWidgets('a part between the two bands (a rail under a kept top bar, '
          'on a kept status line) joins neither, $alignment', (tester) async {
        await _pump(
          tester,
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _kept(56),
              const Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    RawToasterKeepClear(child: SizedBox(width: 80)),
                    Expanded(child: SizedBox.expand()),
                  ],
                ),
              ),
              _kept(24),
            ],
          ),
          size: const Size(900, 900),
          alignment: alignment,
        );
        if (alignment == AlignmentDirectional.bottomCenter) {
          expect(_toast(tester).bottom, 900 - 24 - 16);
        } else {
          expect(_toast(tester).top, 56 + 16);
        }
      });
    }
  });
}

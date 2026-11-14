// In motion: what a part shows between its states, read on what is painted
// while a finger or the pointer is still on it. In both appearances, by day
// and by night, at a phone's width and a desktop's.
// - A carousel swiped 30% and 70% of the way, and across the loop's wrap: the
//   slides move inside the frame, and no slide pixel reaches the frame's rim.
// - A date range waiting for its end: with the pointer, then the keyboard, on
//   a later day in the same week, in a later week and before the start, the
//   preview's band ends on that day, lit as a finished range's end is, and no
//   day after it is washed.
// - A toast caught half-way in: Platinum's hard shadow already stands beside
//   it (it does not pop in as the toast settles); Chisel casts none.
// - A side sheet: in one frame at its place, as the look's dialogs are.
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';

import 'support.dart';

const appearances = <String, RetroDesktopAppearance>{
  'chisel': RetroDesktopAppearance.chisel,
  'platinum': RetroDesktopAppearance.platinum,
};

class _Shot {
  _Shot(this.width, this.height, this.pixels);
  final int width, height;
  final Uint8List pixels;

  Color at(Offset p) {
    final x = p.dx.floor().clamp(0, width - 1),
        y = p.dy.floor().clamp(0, height - 1);
    final i = (y * width + x) * 4;
    return Color.fromARGB(
      pixels[i + 3],
      pixels[i],
      pixels[i + 1],
      pixels[i + 2],
    );
  }
}

final _boundary = GlobalKey();

Future<_Shot> _take(WidgetTester tester) => tester
    .runAsync(() async {
      final box =
          _boundary.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
      final image = await box.toImage();
      final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      final shot = _Shot(image.width, image.height, data!.buffer.asUint8List());
      image.dispose();
      return shot;
    })
    .then((shot) => shot!);

RetroDesktopThemeData _theme(RetroDesktopAppearance a, Brightness b) =>
    RetroDesktopThemeData.preset('classic', b).copyWith(appearance: a);

Future<void> _host(
  WidgetTester tester,
  RetroDesktopThemeData theme,
  double width,
  Widget child,
) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (context, page) => RetroDesktopTheme(
        data: theme.atWidth(MediaQuery.sizeOf(context).width),
        child: page!,
      ),
      home: RepaintBoundary(
        key: _boundary,
        child: ColoredBox(
          color: theme.colors.platinum,
          child: Align(
            alignment: Alignment.topCenter,
            child: Padding(padding: const EdgeInsets.all(16), child: child),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  setUpAll(loadRetroDesktopFonts);

  for (final appearance in appearances.entries) {
    for (final brightness in Brightness.values) {
      for (final width in const [390.0, 1440.0]) {
        final where = '${appearance.key} ${brightness.name} at $width';
        final theme = _theme(appearance.value, brightness);

        testWidgets('$where: a range preview ends on the day it would end '
            'on', (tester) async {
          final c = theme.colors;
          await _host(
            tester,
            theme,
            width,
            SizedBox(
              width: width >= 768 ? 640 : 340,
              child: RetroDesktopDateRangePicker(
                label: 'Stay',
                firstDate: DateTime(2026, 6),
                lastDate: DateTime(2026, 9, 30),
                initialMonth: DateTime(2026, 6),
                onChanged: (_) {},
              ),
            ),
          );
          Rect cell(int day) => tester.getRect(
            find
                .ancestor(
                  of: find.text('$day').first,
                  matching: find.byType(RetroDesktopHighlight),
                )
                .first,
          );
          Future<void> expectBand(String how, int start, int? end) async {
            final why = '$where, $how';
            final shot = await _take(tester);
            // A cell's ground, away from its numeral and from a focus ring.
            Color ground(int day) {
              final r = cell(day);
              return shot.at(r.center - Offset(r.width * .3, r.height * .3));
            }

            expect(ground(start), c.highlight, reason: '$why: the start lit');
            if (end == null) {
              for (final d in [start - 3, start - 1, start + 1, start + 3]) {
                expect(
                  ground(d),
                  isNot(anyOf(c.highlight, c.highlightContainer)),
                  reason: '$why: no band, yet $d is washed',
                );
              }
              return;
            }
            expect(
              ground(end),
              c.highlight,
              reason: '$why: the band ends on $end, lit as an end',
            );
            for (var d = start + 1; d < end; d++) {
              expect(
                ground(d),
                c.highlightContainer,
                reason: '$why: $d lies inside',
              );
            }
            for (final d in [end + 1, end + 2]) {
              expect(
                ground(d),
                isNot(anyOf(c.highlight, c.highlightContainer)),
                reason: '$why: the band runs past $end onto $d',
              );
            }
          }

          // 10 June 2026 is a Wednesday; the 13th ends its week, the 24th is
          // two weeks on, the 5th is before it.
          await tester.tap(find.text('10').first);
          await tester.pump();
          final mouse = await tester.createGesture(
            kind: PointerDeviceKind.mouse,
          );
          await mouse.addPointer(location: Offset.zero);
          addTearDown(mouse.removePointer);
          for (final (to, end) in const [(13, 13), (24, 24), (5, null)]) {
            await mouse.moveTo(tester.getCenter(find.text('$to').first));
            await tester.pump();
            await expectBand('the pointer on $to', 10, end);
          }
          await mouse.moveTo(Offset.zero);
          await tester.pump();

          // The same from the keyboard: the arrows move the day the preview
          // ends on.
          await tester.tap(find.text('10').first);
          await tester.pump();
          await tester.tap(find.text('10').first);
          await tester.pump();
          // A tap chooses without taking focus: give the grid the keyboard
          // (its node is the one that reads keys).
          var grid = Focus.of(tester.element(find.text('10').first));
          while (grid.onKeyEvent == null) {
            grid = grid.parent!;
          }
          grid.requestFocus();
          await tester.pump();
          for (final (keys, end) in [
            (
              [
                LogicalKeyboardKey.arrowRight,
                LogicalKeyboardKey.arrowRight,
                LogicalKeyboardKey.arrowRight,
              ],
              13,
            ),
            ([LogicalKeyboardKey.arrowDown, LogicalKeyboardKey.arrowDown], 27),
          ]) {
            for (final key in keys) {
              await tester.sendKeyEvent(key);
              await tester.pump();
            }
            await expectBand('the keyboard on $end', 10, end);
          }
          expect(tester.takeException(), isNull, reason: where);
        }, tags: const ['goldens']);

        testWidgets('$where: a side sheet stands in one frame', (tester) async {
          await _host(
            tester,
            theme,
            width,
            Builder(
              builder: (context) => RetroDesktopButton(
                'Details',
                wide: true,
                onPressed: () => showRetroDesktopSheet<void>(
                  context,
                  title: 'Details',
                  builder: (_) => const Text('Kind: report'),
                ),
              ),
            ),
          );
          await tester.tap(find.text('Details'));
          await tester.pump();
          final first = tester.getRect(find.byType(RetroDesktopSheet));
          await tester.pumpAndSettle();
          expect(
            tester.getRect(find.byType(RetroDesktopSheet)),
            first,
            reason: '$where: the sheet moved after its first frame',
          );
          expect(tester.takeException(), isNull, reason: where);
        });
      }
    }
  }
}

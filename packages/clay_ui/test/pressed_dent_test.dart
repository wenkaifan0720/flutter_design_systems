// A press is a dent (Clay's law 3): a pressed key sinks, its shadow goes, and
// a shade comes up inside its top-leading edge, where the light was, while
// its lower trailing lip catches the light, as a well's does. The gallery's
// pressed key read raised: its shadow stayed, and the shade it gained sat
// at its bottom-trailing edge, a raised part's. Checked on the pixels for the
// coral key and the white clay key, by day and by night, left to right and
// right to left, at a desk's and a phone's pixel ratio, half-way down, and
// frame by frame through a press.
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:clay_ui/clay_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

final _stage = GlobalKey();
final _part = GlobalKey();

class _Shot {
  _Shot(this.data, this.width, this.ratio, this.origin);

  final Uint8List data;
  final int width;
  final double ratio;
  final Offset origin;

  /// The light of the pixel at [at] (logical, in the window), 0 to 255.
  double lum(Offset at) {
    final x = ((at.dx - origin.dx) * ratio).floor();
    final y = ((at.dy - origin.dy) * ratio).floor();
    final i = (y * width + x) * 4;
    return 0.2126 * data[i] + 0.7152 * data[i + 1] + 0.0722 * data[i + 2];
  }

  /// The largest step of any channel between the pixel at [at] and [colour].
  int off(Offset at, Color colour) {
    final x = ((at.dx - origin.dx) * ratio).floor();
    final y = ((at.dy - origin.dy) * ratio).floor();
    final i = (y * width + x) * 4;
    final c = colour.toARGB32();
    return [
      (data[i] - ((c >> 16) & 0xFF)).abs(),
      (data[i + 1] - ((c >> 8) & 0xFF)).abs(),
      (data[i + 2] - (c & 0xFF)).abs(),
    ].reduce((a, b) => a > b ? a : b);
  }
}

Future<_Shot> _shoot(WidgetTester tester, double ratio) async {
  final boundary =
      _stage.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final data = (await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: ratio);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    image.dispose();
    return bytes!.buffer.asUint8List();
  }))!;
  final rect = tester.getRect(find.byKey(_stage));
  return _Shot(data, (rect.width * ratio).round(), ratio, rect.topLeft);
}

Future<(Rect, ClayColors)> _key(
  WidgetTester tester, {
  required ClayButtonKind kind,
  required Brightness brightness,
  required TextDirection direction,
  required double ratio,
  required Set<WidgetState> states,
}) async {
  tester.view.physicalSize = Size(320 * ratio, 160 * ratio);
  tester.view.devicePixelRatio = ratio;
  addTearDown(tester.view.reset);
  final theme = ClayThemeData.clay(brightness);
  await tester.pumpWidget(
    Directionality(
      textDirection: direction,
      child: ClayTheme(
        data: theme,
        child: RepaintBoundary(
          key: _stage,
          child: ColoredBox(
            color: theme.colors.ground,
            child: Center(
              child: SizedBox(
                key: _part,
                width: 200,
                height: 48,
                child: ClayButtonFace(label: 'OK', states: states, kind: kind),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  return (tester.getRect(find.byKey(_part)), theme.colors);
}

void main() {
  for (final ratio in const [1.0, 2.0]) {
    for (final kind in const [ClayButtonKind.filled, ClayButtonKind.clay]) {
      for (final brightness in Brightness.values) {
        for (final direction in TextDirection.values) {
          final name =
              '${kind.name} key, ${brightness.name}, ${direction.name}, '
              '${ratio.round()}x';
          testWidgets('$name: pressed, its shadow goes and a shade comes up '
              'inside its top-leading edge', (tester) async {
            await _key(
              tester,
              kind: kind,
              brightness: brightness,
              direction: direction,
              ratio: ratio,
              states: const {},
            );
            await tester.pumpAndSettle();
            final (r, c) = await _key(
              tester,
              kind: kind,
              brightness: brightness,
              direction: direction,
              ratio: ratio,
              states: const {WidgetState.pressed},
            );
            // Mid-press: the shadow is on its way out.
            await tester.pump(const Duration(milliseconds: 40));
            final midway = await _shoot(tester, ratio);
            await tester.pumpAndSettle();
            final shot = await _shoot(tester, ratio);
            final rtl = direction == TextDirection.rtl;
            // The sides, a quarter in from each end (clear of the words).
            final startX = rtl ? r.right - r.width / 4 : r.left + r.width / 4;
            final endX = rtl ? r.left + r.width / 4 : r.right - r.width / 4;
            // Under the key, past where the sunk face reaches.
            final under = [
              for (final dy in const [2.5, 3.5, 5.0, 7.0])
                for (final x in [startX, r.center.dx, endX])
                  Offset(x, r.bottom + dy),
            ];
            final shadow = under
                .map((p) => shot.off(p, c.ground))
                .reduce((a, b) => a > b ? a : b);
            expect(shadow, lessThanOrEqualTo(2), reason: 'a shadow under it');
            // The face, sunk 1.5: its top band, its middle and its foot.
            final top = r.top + 1.5 + 2;
            final mid = r.center.dy + 1.5;
            final foot = r.bottom + 1.5 - 2;
            for (final x in [startX, endX]) {
              expect(
                shot.lum(Offset(x, top)),
                lessThan(shot.lum(Offset(x, mid)) - 2),
                reason: 'no shade inside its top edge at $x',
              );
            }
            // The dent is lit from the top start: the shade at the top start,
            // the light on the lower trailing lip.
            final leading = rtl ? r.right - 2 : r.left + 2;
            final trailing = rtl ? r.left + 2 : r.right - 2;
            expect(
              shot.lum(Offset(leading, mid)),
              lessThan(shot.lum(Offset(trailing, mid))),
              reason: 'its leading side is no darker than its trailing one',
            );
            expect(
              shot.lum(Offset(r.center.dx, top)),
              lessThan(shot.lum(Offset(r.center.dx, foot))),
              reason: 'its top is no darker than its foot',
            );
            // Its lower trailing edge is not shaded: the dent's shade stays
            // at the top start, as a well's does.
            expect(
              shot.lum(Offset(endX, foot)),
              greaterThanOrEqualTo(shot.lum(Offset(endX, mid)) - 2),
              reason: 'its lower trailing edge is in shade',
            );
            // Half-way, the shadow is fading, not gone and not whole: the
            // press moves continuously.
            final atRest = await (() async {
              await _key(
                tester,
                kind: kind,
                brightness: brightness,
                direction: direction,
                ratio: ratio,
                states: const {},
              );
              await tester.pumpAndSettle();
              return _shoot(tester, ratio);
            })();
            final p = Offset(r.center.dx, r.bottom + 3.5);
            final rest = atRest.off(p, c.ground);
            final half = midway.off(p, c.ground);
            expect(rest, greaterThan(2), reason: 'a raised key casts a shadow');
            expect(half, lessThan(rest), reason: 'mid-press shadow');
          });
        }
      }
    }
  }

  // The shadow fades as the key sinks, and is all but gone before the press
  // settles: no snap from a shadow to none at the end of the press.
  for (final kind in const [ClayButtonKind.filled, ClayButtonKind.clay]) {
    for (final brightness in Brightness.values) {
      testWidgets('${kind.name} key, ${brightness.name}: through a press its '
          'shadow fades smoothly out, with no snap', (tester) async {
        Future<(Rect, ClayColors)> show(Set<WidgetState> states) => _key(
          tester,
          kind: kind,
          brightness: brightness,
          direction: TextDirection.ltr,
          ratio: 1,
          states: states,
        );
        await show(const {});
        await tester.pumpAndSettle();
        Future<int> shadow() async {
          final (r, c) = await show(const {WidgetState.pressed});
          final shot = await _shoot(tester, 1);
          return [
            for (final dy in const [2.5, 3.5, 5.0])
              shot.off(Offset(r.center.dx, r.bottom + dy), c.ground),
          ].reduce((a, b) => a > b ? a : b);
        }

        final rest = await (() async {
          final (r, c) = await show(const {});
          final shot = await _shoot(tester, 1);
          return [
            for (final dy in const [2.5, 3.5, 5.0])
              shot.off(Offset(r.center.dx, r.bottom + dy), c.ground),
          ].reduce((a, b) => a > b ? a : b);
        })();
        final frames = [rest];
        for (var i = 0; i < 30; i++) {
          await tester.pump(const Duration(milliseconds: 16));
          frames.add(await shadow());
        }
        for (var i = 1; i < frames.length; i++) {
          expect(
            frames[i],
            lessThanOrEqualTo(frames[i - 1] + 1),
            reason: 'the shadow came back: $frames',
          );
          if (frames[i] == 0) {
            expect(
              frames[i - 1],
              lessThanOrEqualTo(3),
              reason: 'the shadow snapped off: $frames',
            );
          }
        }
        expect(frames.last, 0, reason: 'a shadow under a pressed key');
      });
    }
  }
}

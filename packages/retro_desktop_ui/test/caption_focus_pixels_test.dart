import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';
import 'package:retro_desktop_ui/retro_desktop_host.dart';

import 'support.dart';

class _Frame {
  const _Frame(this.bytes, this.width, this.height, this.dpr);
  final Uint8List bytes;
  final int width, height;
  final double dpr;

  int at(int x, int y) {
    final i = (y * width + x) * 4;
    return bytes[i + 3] << 24 |
        bytes[i] << 16 |
        bytes[i + 1] << 8 |
        bytes[i + 2];
  }

  int colorAt(Offset point) =>
      at((point.dx * dpr).floor(), (point.dy * dpr).floor());

  Rect? bounds(Rect region, int color) =>
      _bounds(region, (x, y) => at(x, y) == color);

  Rect? changes(Rect region, _Frame other) =>
      _bounds(region, (x, y) => at(x, y) != other.at(x, y));

  int difference(_Frame other, int x, int y) {
    final i = (y * width + x) * 4;
    return (bytes[i] - other.bytes[i]).abs() +
        (bytes[i + 1] - other.bytes[i + 1]).abs() +
        (bytes[i + 2] - other.bytes[i + 2]).abs();
  }

  Rect? _bounds(Rect region, bool Function(int, int) matches) {
    int x0 = width, y0 = height, x1 = -1, y1 = -1;
    for (int y = region.top.ceil(); y < region.bottom.floor(); y++) {
      for (int x = region.left.ceil(); x < region.right.floor(); x++) {
        if (!matches(x, y)) continue;
        if (x < x0) x0 = x;
        if (y < y0) y0 = y;
        if (x > x1) x1 = x;
        if (y > y1) y1 = y;
      }
    }
    return x1 < 0
        ? null
        : Rect.fromLTRB(x0.toDouble(), y0.toDouble(), x1 + 1.0, y1 + 1.0);
  }

  Rect device(Rect rect) => Rect.fromLTRB(
    rect.left * dpr,
    rect.top * dpr,
    rect.right * dpr,
    rect.bottom * dpr,
  );
}

Future<_Frame> _read(WidgetTester tester, GlobalKey key) async {
  final layer =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final dpr = tester.view.devicePixelRatio;
  return (await tester.runAsync(() async {
    final image = await layer.toImage(pixelRatio: dpr);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    final frame = _Frame(
      bytes!.buffer.asUint8List(),
      image.width,
      image.height,
      dpr,
    );
    image.dispose();
    return frame;
  }))!;
}

Future<GlobalKey> _pump(
  WidgetTester tester,
  Widget child, {
  required double width,
  required double dpr,
  required RetroDesktopThemeData theme,
  TextDirection direction = TextDirection.ltr,
}) async {
  tester.view.devicePixelRatio = dpr;
  tester.view.physicalSize = Size(width * dpr, 260 * dpr);
  addTearDown(tester.view.reset);
  final previous = FocusManager.instance.highlightStrategy;
  FocusManager.instance.highlightStrategy =
      FocusHighlightStrategy.alwaysTraditional;
  addTearDown(() => FocusManager.instance.highlightStrategy = previous);
  final key = GlobalKey();
  await tester.pumpWidget(
    RepaintBoundary(
      key: key,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        builder: (context, app) => RetroDesktopTheme(data: theme, child: app!),
        home: Directionality(
          textDirection: direction,
          child: Align(alignment: Alignment.topLeft, child: child),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return key;
}

void main() {
  setUpAll(loadRetroDesktopFonts);
  for (final width in [390.0, 1440.0]) {
    for (final brightness in Brightness.values) {
      final platinum = RetroDesktopThemeData.classic(brightness)
          .copyWith(appearance: RetroDesktopAppearance.platinum);
      for (final direction in TextDirection.values) {
        for (final appearance in RetroDesktopAppearance.values) {
          testWidgets(
            'switch lever and radio dot have even insets at $width $appearance $brightness $direction',
            (tester) async {
              final enabled = ValueNotifier(false);
              addTearDown(enabled.dispose);
              final key = await _pump(
                tester,
                ValueListenableBuilder<bool>(
                  valueListenable: enabled,
                  builder: (context, checked, _) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      RetroDesktopSwitch(
                        value: checked,
                        onChanged: (_) {},
                        style: const RetroDesktopStyle(
                          fill: WidgetStatePropertyAll(Color(0xff558877)),
                        ),
                      ),
                      RetroDesktopRadioGroup<int>(
                        labelText: 'Option',
                        showLabel: false,
                        value: checked ? 1 : null,
                        onChanged: (_) {},
                        options: const [RetroDesktopRadio(1, 'One')],
                      ),
                    ],
                  ),
                ),
                width: width,
                dpr: 2,
                theme: platinum.copyWith(appearance: appearance),
                direction: direction,
              );
              final off = await _read(tester, key);
              enabled.value = true;
              await tester.pumpAndSettle();
              final on = await _read(tester, key);
              Rect box(double wide, double high, Finder parent) {
                final bounds = off.device(
                  tester.getRect(
                    find
                        .descendant(
                          of: parent,
                          matching: find.byWidgetPredicate(
                            (w) =>
                                w is SizedBox &&
                                w.width == wide &&
                                w.height == high,
                          ),
                        )
                        .first,
                  ),
                );
                final area = bounds.inflate(2);
                final ground = off.at(
                  bounds.center.dx.floor(),
                  area.top.ceil(),
                );
                return off._bounds(area, (x, y) => off.at(x, y) != ground)!;
              }

              const dpr = 2.0;
              final track = box(48, 28, find.byType(RetroDesktopSwitch));
              for (final left in [true, false]) {
                final half = Rect.fromLTRB(
                  left ? track.left : track.center.dx,
                  track.top,
                  left ? track.center.dx : track.right,
                  track.bottom,
                );
                final lever = off.changes(half, on)!;
                expect(lever.size, const Size(18 * dpr, 20 * dpr));
                expect(lever.top - track.top, 4 * dpr);
                expect(track.bottom - lever.bottom, 4 * dpr);
                expect(
                  left ? lever.left - track.left : track.right - lever.right,
                  4 * dpr,
                );
              }
              final outer = box(
                18,
                18,
                find.byType(RetroDesktopRadioGroup<int>),
              );
              final full = off.difference(
                on,
                outer.center.dx.floor(),
                outer.center.dy.floor(),
              );
              expect(full, greaterThan(0));
              final dot = off._bounds(
                outer,
                (x, y) => off.difference(on, x, y) * 2 >= full,
              )!;
              expect(
                dot.size.width,
                dot.size.height,
                reason:
                    'The selected disc inside $outer paints $dot at half coverage.',
              );
              expect(
                (dot.center - outer.center).distance,
                lessThanOrEqualTo(.71),
                reason:
                    'Each axis centers the disc within half a device pixel.',
              );
              expect(dot.left - outer.left, greaterThan(0));
              expect(
                on.at(dot.left.toInt(), dot.top.toInt()),
                off.at(dot.left.toInt(), dot.top.toInt()),
              );
            },
          );
        }
        for (final appearance in RetroDesktopAppearance.values) {
          testWidgets(
            'radio focus marks the words in Chisel and the disc in Platinum at $width $appearance $brightness $direction',
            (tester) async {
              final key = await _pump(
                tester,
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: SizedBox(
                    width: 220,
                    child: RetroDesktopRadioGroup<int>(
                      labelText: 'Sort by',
                      showLabel: false,
                      value: 1,
                      onChanged: (_) {},
                      options: const [
                        RetroDesktopRadio(1, 'Name'),
                        RetroDesktopRadio(2, 'Date changed'),
                      ],
                    ),
                  ),
                ),
                width: width,
                dpr: 2,
                theme: platinum.copyWith(appearance: appearance),
                direction: direction,
              );
              final rest = await _read(tester, key);
              final words = find.text('Name');
              Focus.of(tester.element(words)).requestFocus();
              await tester.pumpAndSettle();
              final focused = await _read(tester, key);
              final option = rest.device(
                tester.getRect(
                  find
                      .ancestor(
                        of: words,
                        matching: find.byWidgetPredicate((w) => w is RawRadio),
                      )
                      .first,
                ),
              );
              final disc = rest.device(
                tester.getRect(
                  find
                      .descendant(
                        of: find.byType(RetroDesktopRadioGroup<int>),
                        matching: find.byWidgetPredicate(
                          (w) => w is SizedBox && w.width == 18,
                        ),
                      )
                      .first,
                ),
              );
              final text = rest.device(tester.getRect(words));
              final everything = Rect.fromLTWH(
                0,
                0,
                rest.width.toDouble(),
                rest.height.toDouble(),
              );
              final mark = rest.changes(everything, focused);
              expect(mark, isNotNull, reason: 'Focus shows.');
              if (appearance == RetroDesktopAppearance.platinum) {
                expect(
                  mark!.overlaps(text),
                  isFalse,
                  reason: 'Platinum rings the disc: $mark, words $text.',
                );
                expect(mark.overlaps(disc), isTrue);
                return;
              }
              expect(
                rest.changes(disc.inflate(2), focused),
                isNull,
                reason: 'The disc keeps its bevel and its dot.',
              );
              expect(
                rest.changes(text.inflate(1), focused),
                isNull,
                reason: 'The dots stand a pixel clear of the words.',
              );
              expect(
                mark!.contains(text.topLeft) &&
                    mark.contains(text.bottomRight - const Offset(1, 1)),
                isTrue,
                reason: 'The rectangle $mark goes round the words $text.',
              );
              expect(
                option.inflate(.5).contains(mark.topLeft) &&
                    option
                        .inflate(.5)
                        .contains(mark.bottomRight - const Offset(1, 1)),
                isTrue,
                reason: 'The rectangle $mark stays inside the option $option.',
              );
              // One on, one off: along its top edge about half of the
              // rectangle's pixels change, never a solid line.
              var on = 0;
              final y = mark.top.toInt();
              for (var x = mark.left.toInt(); x < mark.right; x++) {
                if (focused.difference(rest, x, y) > 0) on++;
              }
              expect(on / mark.width, inInclusiveRange(.3, .7));
            },
          );
        }
        for (final kind in ['buttons', 'toggles', 'split', 'segmented']) {
          testWidgets(
            '$kind focus follows both Platinum ends at $width $brightness $direction',
            (tester) async {
              final target = switch (kind) {
                'segmented' => RetroDesktopSegmentedButton<String>(
                  label: 'View',
                  showLabel: false,
                  segments: const [
                    RetroDesktopButtonSegment('First', 'First'),
                    RetroDesktopButtonSegment('Last', 'Last'),
                  ],
                  onChanged: (_) {},
                ),
                'buttons' => RetroDesktopButtonGroup(
                  items: [
                    for (final word in ['First', 'Last'])
                      RetroDesktopButtonGroupItem(
                        label: word,
                        onPressed: () {},
                      ),
                  ],
                ),
                'toggles' => RetroDesktopToggleGroup<String>(
                  values: const ['First', 'Last'],
                  selected: const {},
                  onChanged: (_) {},
                  labelOf: (s) => s,
                ),
                _ => RetroDesktopSplitButton(
                  label: 'First',
                  onPressed: () {},
                  actions: [RawSplitAction(label: 'Last', onPressed: () {})],
                ),
              };
              final key = await _pump(
                tester,
                Padding(padding: const EdgeInsets.all(10), child: target),
                width: width,
                dpr: 2,
                theme: platinum,
                direction: direction,
              );
              for (final first in [true, false]) {
                final finder = first || kind != 'split'
                    ? find.text(first ? 'First' : 'Last')
                    : find.byType(RetroDesktopTriangleMark);
                Focus.of(tester.element(finder)).requestFocus();
                await tester.pumpAndSettle();
                final frame = await _read(tester, key);
                final ink = platinum.focus.color.toARGB32();
                final band = frame.bounds(
                  frame.device(Rect.fromLTWH(0, 0, width, 100)),
                  ink,
                );
                expect(
                  band,
                  isNotNull,
                  reason: 'The focused cell paints an accent ring.',
                );
                final endAtLeft = first == (direction == TextDirection.ltr);
                final x = endAtLeft
                    ? band!.left.toInt()
                    : band!.right.toInt() - 1;
                final dx = endAtLeft ? 1 : -1;
                final y = band.top.toInt();
                expect(
                  frame.at(x, y),
                  isNot(ink),
                  reason: 'The exterior corner follows the strip.',
                );
                expect(frame.at(x + 4 * dx, y), ink);
                expect(frame.at(x, y + 4), ink);
                final seam = endAtLeft
                    ? band.right.toInt() - 1
                    : band.left.toInt();
                expect(
                  frame.at(seam, y),
                  ink,
                  reason: 'The edge adjoining another segment is square.',
                );
              }
            },
          );
        }
      }

      // Whole ratios and, for Platinum, a fractional one (a browser zoomed on a 2x screen): the boxes' own ruling.
      for (final dpr in [1.0, 1.5, 2.0]) {
        for (final appearance in RetroDesktopAppearance.values) {
          for (final scale in [1.0, 2.0]) {
            if (dpr == 1.5 && appearance == RetroDesktopAppearance.chisel) {
              continue;
            }
            testWidgets(
              '$appearance caption boxes and glyphs on device pixels at $width $brightness $dpr, text $scale',
              (tester) async {
                tester.platformDispatcher.textScaleFactorTestValue = scale;
                addTearDown(
                  tester.platformDispatcher.clearTextScaleFactorTestValue,
                );
                final whole = dpr == dpr.roundToDouble();
                final theme = platinum.copyWith(appearance: appearance);
                final key = await _pump(
                  tester,
                  SizedBox(
                    width: width - 40,
                    child: RetroDesktopWindowScope(
                      active: true,
                      compact: false,
                      child: RetroDesktopWindow(
                        title: 'Notes',
                        onClose: () {},
                        child: const SizedBox(height: 20),
                      ),
                    ),
                  ),
                  width: width,
                  dpr: dpr,
                  theme: theme,
                );
                final frame = await _read(tester, key);
                final chisel = appearance == RetroDesktopAppearance.chisel;
                final barFinder = find.byWidgetPredicate(
                  (w) => w.runtimeType.toString() == '_TitleBar',
                );
                final bar = frame.device(tester.getRect(barFinder));
                final boxes = find.descendant(
                  of: barFinder,
                  matching: find.byWidgetPredicate(
                    (w) =>
                        w is RetroDesktopPixelPaint &&
                        w.painter.runtimeType.toString() ==
                            (chisel ? '_CaptionPainter' : '_BoxPainter'),
                  ),
                );
                // Platinum keeps invisible boxes for layout on a phone.
                final rects = [
                  for (final e in boxes.evaluate())
                    if (e
                            .findAncestorWidgetOfExactType<Visibility>()
                            ?.visible !=
                        false)
                      frame.device(
                        tester.getRect(find.byElementPredicate((x) => x == e)),
                      ),
                ]..sort((a, b) => a.left.compareTo(b.left));
                final painted = <Rect>[];
                for (final rect in rects) {
                  final x = rect.center.dx.floor();
                  final bg = frame.at(x, bar.top.ceil() + 1);
                  final ys = [
                    for (
                      int y = bar.top.ceil() + 1;
                      y < bar.bottom.floor() - 1;
                      y++
                    )
                      if (frame.at(x, y) != bg) y,
                  ];
                  if (ys.isEmpty) continue;
                  final box = Rect.fromLTRB(
                    rect.left,
                    ys.first.toDouble(),
                    rect.right,
                    ys.last + 1.0,
                  );
                  if (whole) {
                    expect(box.height, (chisel ? 14 : 13) * dpr);
                  }
                  expect(
                    (box.center.dy - bar.center.dy).abs(),
                    lessThanOrEqualTo(whole ? .5 : 1),
                    reason: 'Equal space above and below the painted box.',
                  );
                  painted.add(box);
                }
                expect(painted, hasLength(width == 390 ? 1 : 3));
                final ink =
                    (chisel
                            ? theme.colors.text
                            : theme.colors.brightness == Brightness.dark
                            ? theme.colors.control
                            : theme.colors.outline)
                        .toARGB32();
                // Every glyph on its box's middle, measured on the painted pixels: within half a device pixel across
                // and down. Inside the box's frame and bevel, two of its lines (a glyph hugging a corner fails).
                final ring = 2 * (dpr.round() < 1 ? 1 : dpr.round()).toDouble();
                for (final (i, box) in painted.indexed) {
                  final glyph = frame.bounds(box.deflate(ring), ink);
                  final name = chisel
                      ? const [
                          'minimize',
                          'maximize',
                          'close',
                        ][painted.length == 3 ? i : 2]
                      : const ['close', 'zoom', 'shade'][i];
                  if (name == 'close' && !chisel) {
                    expect(
                      glyph,
                      isNull,
                      reason: 'The Platinum close box is blank.',
                    );
                    continue;
                  }
                  expect(glyph, isNotNull, reason: '$name paints a glyph');
                  expect(
                    (glyph!.center.dx - box.center.dx).abs(),
                    lessThanOrEqualTo(.5),
                    reason: '$name glyph $glyph across its box $box',
                  );
                  if (name == 'minimize') {
                    // Windows 95's minimize bar stands low in its button, centred across it.
                    expect(glyph.top, greaterThan(box.center.dy));
                    continue;
                  }
                  expect(
                    (glyph.center.dy - box.center.dy).abs(),
                    lessThanOrEqualTo(.5),
                    reason: '$name glyph $glyph down its box $box',
                  );
                }
                if (!whole) return;
                if (chisel) {
                  final close = painted.last;
                  final cross = frame.bounds(close.deflate(2 * dpr), ink)!;
                  expect(cross.size, Size(8 * dpr, 6 * dpr));
                  expect(cross.center, close.center);
                  if (painted.length > 1) {
                    final zoom = painted[1];
                    final glyph = frame.bounds(zoom.deflate(2 * dpr), ink)!;
                    expect(glyph.size, Size(9 * dpr, 8 * dpr));
                    expect(
                      (glyph.center.dx - zoom.center.dx).abs(),
                      lessThanOrEqualTo(.5),
                    );
                    expect(glyph.center.dy, zoom.center.dy);
                  }
                } else if (painted.length > 1) {
                  final zoom = painted[1];
                  final glyph = frame.bounds(zoom.deflate(2 * dpr), ink)!;
                  expect(
                    glyph,
                    Rect.fromCenter(
                      center: zoom.center,
                      width: 7 * dpr,
                      height: 7 * dpr,
                    ),
                  );
                  final shade = painted.last;
                  final bars = frame.bounds(shade.deflate(2 * dpr), ink)!;
                  expect(bars.center, shade.center);
                  expect(bars.height, 3 * dpr);
                }
              },
            );
          }
        }
      }

      // A part joined to its neighbours rings focus inside its own rim, clear of them (the folder tab's ring met the next
      // tab, the menu bar's showed as one line at the place's end, the number field's sat on the outline it shares).
      for (final dpr in [1.0, 2.0]) {
        for (final part in ['folder tab', 'menu bar place', 'number field']) {
          // The menu bar stands on a desk only.
          if (part == 'menu bar place' && width < 1000) continue;
          testWidgets(
            'Platinum rings a $part inside its rim at $width $brightness $dpr',
            (tester) async {
              final theme = platinum.atWidth(width);
              final key = await _pump(
                tester,
                switch (part) {
                  'folder tab' => Padding(
                    padding: const EdgeInsets.all(12),
                    child: RetroDesktopTabBar(
                      tabs: const ['First', 'Second', 'Third'],
                      onChanged: (_) {},
                      child: const SizedBox(height: 40),
                    ),
                  ),
                  'menu bar place' => SizedBox(
                    width: width,
                    height: 200,
                    child: RetroDesktopChromeScope(
                      brand: 'Notes',
                      active: 0,
                      nav: [
                        for (final word in ['Today', 'Places', 'You'])
                          RetroDesktopNavItem(
                            label: word,
                            short: word,
                            icon: RetroDesktopGlyphs.clock,
                            onPressed: () {},
                          ),
                      ],
                      child: const RetroDesktopScaffold(
                        body: SizedBox(height: 40),
                      ),
                    ),
                  ),
                  _ => Padding(
                    padding: const EdgeInsets.all(12),
                    child: RetroDesktopNumberField(
                      labelText: 'Count',
                      value: 2,
                      max: 5,
                      unit: 'a day',
                      onChanged: (_) {},
                    ),
                  ),
                },
                width: width,
                dpr: dpr,
                theme: theme,
              );
              Rect face;
              final faces = find.byWidgetPredicate(
                (w) => w.runtimeType.toString() == '_Face',
              );
              switch (part) {
                case 'folder tab':
                  Focus.of(tester.element(find.text('Second'))).requestFocus();
                  face = tester.getRect(
                    find.ancestor(of: find.text('Second'), matching: faces),
                  );
                case 'menu bar place':
                  Focus.of(tester.element(find.text('You'))).requestFocus();
                  face = tester.getRect(
                    find
                        .ancestor(
                          of: find.text('You'),
                          matching: find.byWidgetPredicate(
                            (w) =>
                                w is DecoratedBox &&
                                w.decoration is ShapeDecoration,
                          ),
                        )
                        .first,
                  );
                default:
                  tester
                      .state<EditableTextState>(find.byType(EditableText))
                      .requestKeyboard();
                  final boxes = [
                    for (final e
                        in find
                            .descendant(
                              of: find.byType(RetroDesktopNumberField),
                              matching: faces,
                            )
                            .evaluate())
                      tester.getRect(find.byElementPredicate((x) => x == e)),
                  ]..sort((a, b) => a.left.compareTo(b.left));
                  expect(boxes, hasLength(3), reason: '- , the value, +');
                  face = boxes[1];
              }
              await tester.pumpAndSettle();
              final frame = await _read(tester, key);
              final at = frame.device(face);
              final ring = frame.bounds(
                at
                    .inflate(6 * dpr)
                    .intersect(
                      Rect.fromLTWH(
                        0,
                        0,
                        frame.width.toDouble(),
                        frame.height.toDouble(),
                      ),
                    ),
                theme.focus.color.toARGB32(),
              );
              expect(ring, isNotNull, reason: 'the focused $part rings');
              // Inside the rim (outline and bevel, where the part draws one) and the ring's gap.
              final rim = part == 'menu bar place'
                  ? 0
                  : theme.strokes.regular + theme.strokes.hairline;
              final inset = (rim + theme.focus.gap) * dpr;
              final room = at.deflate(inset);
              for (final (side, apart) in [
                ('start', ring!.left - room.left),
                ('top', ring.top - room.top),
                ('end', room.right - ring.right),
                ('foot', room.bottom - ring.bottom),
              ]) {
                expect(
                  apart,
                  greaterThanOrEqualTo(-.5),
                  reason:
                      'the ring $ring stands inside the $part $at, '
                      '$inset device px clear of its edge at its $side',
                );
              }
            },
          );
        }
      }

      testWidgets(
        'leaving the menu clears its title and row on the first paint at $width $brightness',
        (tester) async {
          var opened = false;
          final key = await _pump(
            tester,
            RetroDesktopMenuBar(
              menus: [
                RawMenuEntry(
                  label: 'File',
                  children: [
                    RawMenuEntry(label: 'Open', onPressed: () => opened = true),
                  ],
                ),
              ],
            ),
            width: width,
            dpr: 2,
            theme: platinum,
          );
          final mouse = await tester.createGesture(
            kind: PointerDeviceKind.mouse,
          );
          addTearDown(mouse.removePointer);
          final title = tester.getCenter(find.text('File'));
          await mouse.addPointer(location: title);
          await mouse.down(title);
          await mouse.up();
          await tester.pumpAndSettle();
          final row = tester.getCenter(find.text('Open'));
          await mouse.moveTo(row);
          await tester.pump();
          final lit = await _read(tester, key);
          Offset sample(String text) =>
              tester.getTopLeft(find.text(text)) + const Offset(-2, 5);
          final ink = platinum.colors.highlight.toARGB32();
          expect(lit.colorAt(sample('File')), ink);
          expect(lit.colorAt(sample('Open')), ink);
          await mouse.moveTo(Offset(width - 5, 240));
          await tester.pump();
          final left = await _read(tester, key);
          expect(left.colorAt(sample('File')), isNot(ink));
          expect(left.colorAt(sample('Open')), isNot(ink));
          await mouse.moveTo(row);
          await mouse.down(row);
          await mouse.up();
          await tester.pumpAndSettle();
          expect(opened, isTrue);
        },
      );
    }
  }
}

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:material_expressive_ui/material_expressive_ui.dart';
import 'package:material_expressive_ui/material_expressive_host.dart';

import 'gallery_support.dart';

const _boundary = ValueKey('painted control');
const _paper = Color(0xff192c39);
const _track = Color(0xff30af76);
const _ratio = 2.0;

class _Raster {
  const _Raster(this.width, this.height, this.data);
  final int width;
  final int height;
  final ByteData data;

  Color colorAt(int x, int y) {
    final offset = (y * width + x) * 4;
    return Color.fromARGB(
      data.getUint8(offset + 3),
      data.getUint8(offset),
      data.getUint8(offset + 1),
      data.getUint8(offset + 2),
    );
  }

  bool matches(int x, int y, Color color) {
    final argb = color.toARGB32();
    final start = (y * width + x) * 4;
    for (var channel = 0; channel < 3; channel++) {
      final expected = (argb >> ((2 - channel) * 8)) & 255;
      if ((data.getUint8(start + channel) - expected).abs() > 24) return false;
    }
    return true;
  }

  Rect bounds(Color color) {
    var left = width;
    var top = height;
    var right = -1;
    var bottom = -1;
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        if (!matches(x, y, color)) continue;
        if (x < left) left = x;
        if (y < top) top = y;
        if (x > right) right = x;
        bottom = y;
      }
    }
    expect(right, greaterThanOrEqualTo(left), reason: 'Missing paint $color');
    return Rect.fromLTRB(
      left / _ratio,
      top / _ratio,
      (right + 1) / _ratio,
      (bottom + 1) / _ratio,
    );
  }

  // On a quarter circle the first painted pixel on the diagonal is
  // r * (1 - 1 / sqrt(2)) from the bounding corner.
  double cornerRadius(
    Rect rect,
    Color color, {
    bool right = false,
    bool bottom = false,
  }) {
    for (var i = 0; i < rect.shortestSide * _ratio / 2; i++) {
      final x = right
          ? (rect.right * _ratio).round() - 1 - i
          : (rect.left * _ratio).round() + i;
      final y = bottom
          ? (rect.bottom * _ratio).round() - 1 - i
          : (rect.top * _ratio).round() + i;
      if (matches(x, y, color)) return (i + .5) / _ratio / .2928932188;
    }
    throw StateError('No painted corner on $rect');
  }
}

Future<_Raster> _read(WidgetTester tester) async {
  final box = tester.renderObject<RenderRepaintBoundary>(find.byKey(_boundary));
  return (await tester.runAsync(() async {
    final image = await box.toImage(pixelRatio: _ratio);
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      return _Raster(image.width, image.height, data!);
    } finally {
      image.dispose();
    }
  }))!;
}

Widget _host(
  ExpressiveThemeData theme,
  TextDirection direction,
  Widget child,
) => MaterialApp(
  home: ExpressiveHost(
    theme: theme,
    darkTheme: theme,
    brightness: theme.brightness,
    child: Directionality(
      textDirection: direction,
      child: Center(
        child: RepaintBoundary(
          key: _boundary,
          child: ColoredBox(
            color: _paper,
            child: Padding(padding: const EdgeInsets.all(12), child: child),
          ),
        ),
      ),
    ),
  ),
);

void main() {
  setUpAll(loadExpressiveFonts);
  for (final appearance in Brightness.values) {
    testWidgets(
      'the plotted target and legend share an accessible colour in ${appearance.name}',
      (tester) async {
        tester.view.devicePixelRatio = _ratio;
        tester.view.physicalSize = const Size(780, 1688);
        addTearDown(tester.view.reset);
        final theme = ExpressiveThemeData.preset('baseline', appearance);
        await tester.pumpWidget(
          _host(
            theme,
            TextDirection.ltr,
            ColoredBox(
              color: theme.colors.surface,
              child: const SizedBox(
                width: 330,
                child: ExpressiveChart.paired(
                  first: ExpressiveChartSeries('High', [
                    ExpressiveChartPoint('Mon', 140),
                    ExpressiveChartPoint('Tue', 143),
                  ]),
                  second: ExpressiveChartSeries('Low', [
                    ExpressiveChartPoint('Mon', 65),
                    ExpressiveChartPoint('Tue', 68),
                  ]),
                  band: ExpressiveChartBand(80, 120, label: 'Goal range'),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final row = find
            .ancestor(of: find.text('Goal range'), matching: find.byType(Row))
            .first;
        final mark =
            tester.getCenter(
              find
                  .descendant(of: row, matching: find.byType(CustomPaint))
                  .first,
            ) -
            tester.getTopLeft(find.byKey(_boundary));
        final pixels = await _read(tester);
        final fill = pixels.colorAt(
          (mark.dx * _ratio).floor(),
          (mark.dy * _ratio).floor(),
        );
        double contrast(Color a, Color b) {
          final l = a.computeLuminance(), r = b.computeLuminance();
          return l > r ? (l + .05) / (r + .05) : (r + .05) / (l + .05);
        }

        expect(contrast(fill, theme.colors.surface), greaterThanOrEqualTo(3));
        for (final label in ['High', 'Low']) {
          final row = find
              .ancestor(of: find.text(label), matching: find.byType(Row))
              .first;
          final center =
              tester.getCenter(
                find
                    .descendant(of: row, matching: find.byType(CustomPaint))
                    .first,
              ) -
              tester.getTopLeft(find.byKey(_boundary));
          final ink = pixels.colorAt(
            (center.dx * _ratio).floor(),
            (center.dy * _ratio).floor(),
          );
          expect(
            contrast(ink, fill),
            greaterThanOrEqualTo(3),
            reason: '$label over target band',
          );
          expect(
            contrast(ink, theme.colors.surface),
            greaterThanOrEqualTo(3),
            reason: '$label outside target band',
          );
        }
        // The same actual RGB covers the broad range across the plot.
        var painted = 0;
        for (var y = 0; y < (mark.dy * _ratio).floor() - 20; y++) {
          if (pixels.colorAt(pixels.width ~/ 2, y) == fill) painted++;
        }
        expect(painted, greaterThan(45));
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
  for (final width in [390.0, 1440.0]) {
    for (final dir in TextDirection.values) {
      testWidgets(
        'connected segments and list rows paint separate faces at $width ${dir.name}',
        (tester) async {
          tester.view.devicePixelRatio = _ratio;
          tester.view.physicalSize = Size(width * _ratio, 1800);
          addTearDown(tester.view.reset);
          final t = ExpressiveThemeData.preset('baseline', Brightness.light);
          const selected = Color(0xffd5388c);
          await tester.pumpWidget(
            _host(
              t,
              dir,
              SizedBox(
                width: 300,
                child: ExpressiveSegmentedButton<int>(
                  segments: const [
                    ExpressiveButtonSegment(0, 'Day'),
                    ExpressiveButtonSegment(1, 'Week'),
                  ],
                  value: 0,
                  onChanged: (_) {},
                  style: ExpressiveComponentThemeData(
                    backgroundColor: WidgetStateProperty.resolveWith(
                      (states) => states.contains(WidgetState.selected)
                          ? selected
                          : _track,
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          var frame = await _read(tester);
          final choice = frame.bounds(selected), other = frame.bounds(_track);
          final gap = dir == TextDirection.ltr
              ? other.left - choice.right
              : choice.left - other.right;
          expect(gap, closeTo(2, .5));
          expect(
            frame.matches(
              ((choice.center.dx + other.center.dx) * _ratio / 2).floor(),
              (choice.center.dy * _ratio).floor(),
              _paper,
            ),
            isTrue,
          );
          await tester.pumpWidget(
            _host(
              t,
              dir,
              const SizedBox(
                width: 300,
                child: ExpressiveListSection(
                  children: [
                    ExpressiveListTile(title: Text('First'), tileColor: _track),
                    ExpressiveListTile(
                      title: Text('Last'),
                      tileColor: selected,
                    ),
                  ],
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          frame = await _read(tester);
          final first = frame.bounds(_track), last = frame.bounds(selected);
          expect(last.top - first.bottom, closeTo(2, .5));
          expect(
            frame.matches(
              (first.center.dx * _ratio).floor(),
              ((first.bottom + last.top) * _ratio / 2).floor(),
              _paper,
            ),
            isTrue,
          );
        },
      );

      testWidgets(
        'the slider handle stands between the painted tracks at $width ${dir.name}',
        (tester) async {
          tester.view.devicePixelRatio = _ratio;
          tester.view.physicalSize = Size(width * _ratio, 1800);
          addTearDown(tester.view.reset);
          final t = ExpressiveThemeData.preset('baseline', Brightness.light);
          const thumb = Color(0xffec56aa);
          await tester.pumpWidget(
            _host(
              t,
              dir,
              SizedBox(
                width: 280,
                child: ExpressiveSlider(
                  value: .5,
                  onChanged: (_) {},
                  style: const ExpressiveComponentThemeData(
                    foregroundColor: WidgetStatePropertyAll(thumb),
                    backgroundColor: WidgetStatePropertyAll(_track),
                    outline: WidgetStatePropertyAll(Color(0xffbe9f22)),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final pixels = await _read(tester);
          final handle = pixels.bounds(thumb);
          expect(handle.width, closeTo(4, .5));
          expect(handle.height, closeTo(44, .5));
          final y = (handle.center.dy * _ratio).floor();
          for (final edge in [handle.left - 2, handle.right + 2]) {
            expect(pixels.matches((edge * _ratio).floor(), y, _paper), isTrue);
          }
        },
      );
      testWidgets(
        'the nav pill and tab underline sit on flat bars at $width ${dir.name}',
        (tester) async {
          tester.view.devicePixelRatio = _ratio;
          tester.view.physicalSize = Size(width * _ratio, 1800);
          addTearDown(tester.view.reset);
          const plate = Color(0xffd5388c);
          const barStyle = ExpressiveComponentThemeData(
            backgroundColor: WidgetStatePropertyAll(_track),
          );
          final t = ExpressiveThemeData.preset('baseline', Brightness.light);
          await tester.pumpWidget(
            _host(
              t,
              dir,
              SizedBox(
                width: 320,
                child: ExpressiveNavigationBar(
                  style: barStyle,
                  destinations: const [
                    ExpressiveNavItem(
                      ExpressiveSymbols.home,
                      'Home',
                      style: ExpressiveComponentThemeData(
                        backgroundColor: WidgetStatePropertyAll(plate),
                      ),
                    ),
                    ExpressiveNavItem(ExpressiveSymbols.inbox, 'Inbox'),
                  ],
                  selectedIndex: 0,
                  onDestinationSelected: (_) {},
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final nav = await _read(tester);
          final bar = nav.bounds(_track), pill = nav.bounds(plate);
          expect(nav.cornerRadius(bar, _track), lessThan(2));
          expect(nav.cornerRadius(pill, plate), closeTo(pill.height / 2, 3));
          const tabs = [
            ExpressiveTab(label: 'Day'),
            ExpressiveTab(label: 'Week'),
          ];
          await tester.pumpWidget(
            _host(
              t,
              dir,
              SizedBox(
                width: 320,
                child: ExpressiveTabBar(
                  tabs: tabs,
                  style: barStyle,
                  selectedIndex: 0,
                  onChanged: (_) {},
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final image = await _read(tester);
          final edge = image.bounds(_track).bottom;
          final centre =
              tester.getCenter(find.text('Day')).dx -
              tester.getTopLeft(find.byKey(_boundary)).dx;
          final x = (centre * _ratio).floor();
          var rows = 0;
          for (
            var y = ((edge - 5) * _ratio).floor();
            y < ((edge + 2) * _ratio).floor();
            y++
          ) {
            if (image.matches(x, y, t.colors.primary)) rows++;
          }
          expect(rows / _ratio, closeTo(3, .5));
        },
      );
      testWidgets('radio dot and ring share a centre at $width ${dir.name}', (
        tester,
      ) async {
        tester.view.devicePixelRatio = _ratio;
        tester.view.physicalSize = Size(width * _ratio, 1800);
        addTearDown(tester.view.reset);
        const dot = Color(0xffe7729c);
        for (final brightness in Brightness.values) {
          final theme = ExpressiveThemeData.preset('baseline', brightness);
          await tester.pumpWidget(
            _host(
              theme,
              dir,
              const ExpressiveRadio.mark(
                selected: true,
                style: ExpressiveComponentThemeData(
                  foregroundColor: WidgetStatePropertyAll(dot),
                  outline: WidgetStatePropertyAll(_track),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final pixels = await _read(tester);
          final inner = pixels.bounds(dot);
          final outer = pixels.bounds(_track);
          expect(outer.width, closeTo(20, .5));
          expect(inner.width, closeTo(10, .5));
          expect(inner.center.dx, closeTo(outer.center.dx, .5));
          expect(inner.center.dy, closeTo(outer.center.dy, .5));
        }
        await tester.pumpWidget(const SizedBox.shrink());
      });

      testWidgets(
        'removable chips have equal painted field insets at $width ${dir.name}',
        (tester) async {
          tester.view.devicePixelRatio = _ratio;
          tester.view.physicalSize = Size(width * _ratio, 1800);
          addTearDown(tester.view.reset);
          const chip = Color(0xffcb4089);
          for (final density in [
            ExpressiveDensity.standard,
            ExpressiveDensity.compact,
          ]) {
            for (final scale in [1.0, 2.0]) {
              final theme =
                  ExpressiveThemeData.preset(
                    'baseline',
                    Brightness.light,
                  ).copyWith(
                    density: density,
                    chipTheme: const ExpressiveComponentThemeData(
                      backgroundColor: WidgetStatePropertyAll(chip),
                      side: WidgetStatePropertyAll(BorderSide.none),
                    ),
                  );
              await tester.pumpWidget(
                _host(
                  theme,
                  dir,
                  Builder(
                    builder: (context) => MediaQuery(
                      data: MediaQuery.of(context)
                          .copyWith(textScaler: TextScaler.linear(scale)),
                      child: SizedBox(
                        width: 350,
                        child: ExpressiveMultiSelect<String>(
                          values: const ['Tea'],
                          options: const [ExpressiveSelectOption('Tea', 'Tea')],
                          onChanged: (_) {},
                        ),
                      ),
                    ),
                  ),
                ),
              );
              await tester.pumpAndSettle();
              final pixels = await _read(tester);
              final outer = pixels.bounds(theme.colors.outline);
              final inner = pixels.bounds(chip);
              final leading = dir == TextDirection.ltr
                  ? inner.left - outer.left
                  : outer.right - inner.right;
              final top = inner.top - outer.top;
              final bottom = outer.bottom - inner.bottom;
              expect(
                top,
                closeTo(leading, .5),
                reason:
                    'painted chip $inner in field $outer at $scale and $density',
              );
              expect(bottom, closeTo(leading, .5));
              final outerRadius = pixels.cornerRadius(
                outer,
                theme.colors.outline,
                right: dir == TextDirection.rtl,
              );
              final innerRadius = pixels.cornerRadius(
                inner,
                chip,
                right: dir == TextDirection.rtl,
              );
              expect(outerRadius - innerRadius, closeTo(leading, 3));
            }
          }
          await tester.pumpWidget(const SizedBox.shrink());
        },
      );

      testWidgets(
        'the unread digit is visibly inside the badge at $width ${dir.name}',
        (tester) async {
          tester.view.devicePixelRatio = _ratio;
          tester.view.physicalSize = Size(width * _ratio, 1800);
          addTearDown(tester.view.reset);
          const badgeColor = Color(0xffe02e58);
          const ink = Color(0xff30ee83);
          for (final appearance in Brightness.values) {
            final theme = ExpressiveThemeData.preset('baseline', appearance);
            for (final scale in [1.0, 2.0]) {
              await tester.pumpWidget(
                _host(
                  theme,
                  dir,
                  Builder(
                    builder: (context) => MediaQuery(
                      data: MediaQuery.of(context)
                          .copyWith(textScaler: TextScaler.linear(scale)),
                      child: SizedBox(
                        width: 350,
                        child: ExpressiveNavigationBar(
                          selectedIndex: 0,
                          onDestinationSelected: (_) {},
                          destinations: const [
                            ExpressiveNavItem(ExpressiveSymbols.home, 'Home'),
                            ExpressiveNavItem(
                              ExpressiveSymbols.inbox,
                              'Inbox',
                              badge: ExpressiveBadge.count(
                                8,
                                style: ExpressiveComponentThemeData(
                                  backgroundColor: WidgetStatePropertyAll(
                                    badgeColor,
                                  ),
                                  foregroundColor: WidgetStatePropertyAll(ink),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
              await tester.pumpAndSettle();
              final frame = await _read(tester);
              final badge = frame.bounds(badgeColor);
              final digit = frame.bounds(ink);
              expect(
                badge.top,
                greaterThan(12),
                reason: 'Badge reaches the edge of the bar',
              );
              expect(digit.top, greaterThan(badge.top));
              expect(digit.bottom, lessThan(badge.bottom));
              expect(digit.left, greaterThan(badge.left));
              expect(digit.right, lessThan(badge.right));
            }
          }
          await tester.pumpWidget(const SizedBox.shrink());
        },
      );

      testWidgets(
        'a menu row follows its group corners at $width ${dir.name}',
        (tester) async {
          tester.view.devicePixelRatio = _ratio;
          tester.view.physicalSize = Size(width * _ratio, 1800);
          addTearDown(tester.view.reset);
          const row = Color(0xffd3318c);
          for (final density in [
            ExpressiveDensity.standard,
            ExpressiveDensity.compact,
          ]) {
            final t = ExpressiveThemeData.preset('baseline', Brightness.light)
                .copyWith(
                  density: density,
                  menuTheme: const ExpressiveComponentThemeData(
                    backgroundColor: WidgetStatePropertyAll(_track),
                  ),
                );
            await tester.pumpWidget(
              _host(
                t,
                dir,
                ExpressiveMenuSurface(
                  groups: [
                    ExpressiveMenuGroup([
                      ExpressiveMenuRadioItem(
                        'First',
                        selected: true,
                        onSelected: () {},
                        style: const ExpressiveComponentThemeData(
                          backgroundColor: WidgetStatePropertyAll(row),
                        ),
                      ),
                    ]),
                  ],
                ),
              ),
            );
            await tester.pumpAndSettle();
            Future<void> measure(double radius) async {
              final pixels = await _read(tester);
              final outer = pixels.bounds(_track), inner = pixels.bounds(row);
              for (final inset in [
                inner.left - outer.left,
                outer.right - inner.right,
                inner.top - outer.top,
                outer.bottom - inner.bottom,
              ]) {
                expect(
                  inset,
                  closeTo(4, .5),
                  reason: 'painted row $inner in panel $outer, $density',
                );
              }
              expect(pixels.cornerRadius(outer, _track), closeTo(radius, 3));
              expect(pixels.cornerRadius(inner, row), closeTo(radius - 4, 3));
            }

            await measure(16);
            final pointer = await tester.createGesture(
              kind: PointerDeviceKind.mouse,
            );
            await pointer.addPointer();
            await pointer.moveTo(tester.getCenter(find.text('First')));
            await tester.pumpAndSettle();
            await pointer.moveTo(Offset.zero);
            await tester.pumpAndSettle();
            await measure(8);
            await pointer.removePointer();
            await tester.pumpWidget(const SizedBox.shrink());
          }
        },
      );
      testWidgets(
        'message action state layers fit their panel at $width ${dir.name}',
        (tester) async {
          tester.view.devicePixelRatio = _ratio;
          tester.view.physicalSize = Size(width * _ratio, 1800);
          addTearDown(tester.view.reset);
          const layer = Color(0xffd5388c);
          final button = ExpressiveComponentThemeData(
            backgroundColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.hovered) ? layer : null,
            ),
            overlayColor: const WidgetStatePropertyAll(Color(0x00000000)),
          );
          for (final density in [
            ExpressiveDensity.standard,
            ExpressiveDensity.compact,
          ]) {
            final t = ExpressiveThemeData.preset('baseline', Brightness.light)
                .copyWith(
                  density: density,
                  buttonTheme: button,
                  bannerTheme: const ExpressiveComponentThemeData(
                    backgroundColor: WidgetStatePropertyAll(_track),
                  ),
                  snackBarTheme: const ExpressiveComponentThemeData(
                    backgroundColor: WidgetStatePropertyAll(_track),
                  ),
                );
            for (final isBanner in [true, false]) {
              final action = isBanner
                  ? ExpressiveBanner(
                      message: 'Draft saved',
                      actions: [
                        ExpressiveBannerAction('Undo', onPressed: () {}),
                      ],
                    )
                  : ExpressiveSnackBar(
                      'Draft saved',
                      actionLabel: 'Undo',
                      onAction: () {},
                    );
              await tester.pumpWidget(
                _host(t, dir, SizedBox(width: 314, child: action)),
              );
              await tester.pumpAndSettle();
              final mouse = await tester.createGesture(
                kind: PointerDeviceKind.mouse,
              );
              await mouse.addPointer();
              await mouse.moveTo(tester.getCenter(find.text('Undo')));
              await tester.pumpAndSettle();
              final frame = await _read(tester);
              final outer = frame.bounds(_track), inner = frame.bounds(layer);
              final end = dir == TextDirection.ltr
                  ? outer.right - inner.right
                  : inner.left - outer.left;
              final bottom = outer.bottom - inner.bottom;
              final radius = frame.cornerRadius(
                inner,
                layer,
                right: dir == TextDirection.ltr,
                bottom: true,
              );
              if (isBanner) {
                expect(
                  bottom,
                  closeTo(end, .5),
                  reason: 'action $inner in banner $outer, $density',
                );
                final outerRadius = frame.cornerRadius(
                  outer,
                  _track,
                  right: dir == TextDirection.ltr,
                  bottom: true,
                );
                expect(
                  radius,
                  closeTo((outerRadius - end).clamp(0, double.infinity), 3),
                );
              } else {
                expect(
                  radius,
                  lessThan(3),
                  reason: 'snackbar action $inner inside $outer, $density',
                );
                expect(end, greaterThanOrEqualTo(0));
                expect(bottom, greaterThanOrEqualTo(0));
              }
              await mouse.removePointer();
              await tester.pumpWidget(const SizedBox.shrink());
            }
          }
        },
      );
    }
  }
  const style = ExpressiveComponentThemeData(
    backgroundColor: WidgetStatePropertyAll(_track),
    outline: WidgetStatePropertyAll(_track),
    overlayColor: WidgetStatePropertyAll(Color(0x00000000)),
  );
  for (final width in [390.0, 1440.0]) {
    for (final density in [
      ExpressiveDensity.compact,
      ExpressiveDensity.comfortable,
      ExpressiveDensity.standard,
    ]) {
      for (final direction in TextDirection.values) {
        testWidgets(
          'switch track and thumb at $width, $density, ${direction.name}',
          (tester) async {
            tester.view.devicePixelRatio = _ratio;
            tester.view.physicalSize = Size(width * _ratio, 900 * _ratio);
            addTearDown(tester.view.reset);
            final focus = FocusNode();
            addTearDown(focus.dispose);
            for (final brightness in Brightness.values) {
              final theme = ExpressiveThemeData.preset(
                'baseline',
                brightness,
              ).copyWith(density: density);
              final colors = theme.colors;
              for (final checked in [false, true]) {
                Future<void> pump({
                  bool enabled = true,
                  bool marked = false,
                  bool withIcon = false,
                }) async {
                  const mark = Icon(ExpressiveSymbols.check);
                  final icon = withIcon ? mark : null;
                  final child = marked
                      ? ExpressiveSwitch.mark(
                          value: checked,
                          enabled: enabled,
                          uncheckedIcon: icon,
                          checkedIcon: icon,
                          style: style,
                        )
                      : ExpressiveSwitch(
                          value: checked,
                          onChanged: enabled ? (_) {} : null,
                          focusNode: focus,
                          uncheckedIcon: icon,
                          checkedIcon: icon,
                          style: style,
                        );
                  await tester.pumpWidget(_host(theme, direction, child));
                  await tester.pumpAndSettle();
                }

                Future<void> measure(
                  double diameter,
                  Color thumb, {
                  bool? atEnd,
                }) async {
                  final frame = await _read(tester);
                  final track = frame.bounds(_track);
                  final handle = frame.bounds(thumb);
                  // A boundary can cross a device pixel. Its antialiased fringe
                  // is excluded from the solid-colour measurements.
                  const fringe = 1 / _ratio;
                  expect(track.width, closeTo(52, fringe));
                  expect(track.height, closeTo(32, fringe));
                  expect(
                    handle.width,
                    closeTo(diameter, fringe),
                    reason: 'painted thumb $handle in track $track',
                  );
                  expect(handle.height, closeTo(diameter, fringe));
                  final gap = (32 - diameter) / 2;
                  expect(handle.top - track.top, closeTo(gap, fringe));
                  expect(track.bottom - handle.bottom, closeTo(gap, fringe));
                  final right =
                      (atEnd ?? checked) == (direction == TextDirection.ltr);
                  expect(
                    right
                        ? track.right - handle.right
                        : handle.left - track.left,
                    closeTo(gap, fringe),
                  );
                  // The actual pixels of the round ends enclose a circular thumb.
                  expect(
                    frame.matches(
                      (handle.left * _ratio).floor(),
                      (handle.top * _ratio).floor(),
                      thumb,
                    ),
                    isFalse,
                  );
                  expect(
                    frame.matches(
                      (track.left * _ratio).floor(),
                      (track.top * _ratio).floor(),
                      _paper,
                    ),
                    isTrue,
                  );
                }

                final normal = checked ? colors.onPrimary : colors.outline;
                final disabled = checked
                    ? colors.surface
                    : Color.alphaBlend(
                        colors.onSurface.withValues(alpha: .38),
                        colors.surface,
                      );
                await pump();
                await measure(checked ? 24 : 16, normal);
                focus.requestFocus();
                await tester.pumpAndSettle();
                await measure(checked ? 24 : 16, normal);
                focus.unfocus();
                final mouse = await tester.createGesture(
                  kind: PointerDeviceKind.mouse,
                );
                await mouse.addPointer();
                await mouse.moveTo(
                  tester.getCenter(find.byType(ExpressiveSwitch)),
                );
                await tester.pumpAndSettle();
                await measure(checked ? 24 : 16, normal);
                await mouse.removePointer();
                final gesture = await tester.startGesture(
                  tester.getCenter(find.byType(ExpressiveSwitch)),
                );
                await tester.pump();
                await measure(28, normal);
                // Cross the drag slop, then reach the opposite well.
                final sign = checked == (direction == TextDirection.ltr)
                    ? -1.0
                    : 1.0;
                await gesture.moveBy(Offset(21 * sign, 0));
                await gesture.moveBy(Offset(24 * sign, 0));
                await tester.pump();
                await measure(28, normal, atEnd: !checked);
                await gesture.cancel();
                await tester.pumpAndSettle();
                await pump(withIcon: true);
                await measure(24, normal);
                await pump(enabled: false);
                await measure(checked ? 24 : 16, disabled);
                await pump(marked: true);
                await measure(checked ? 24 : 16, normal);
                await pump(marked: true, enabled: false, withIcon: true);
                await measure(24, disabled);
              }
            }
            await tester.pumpWidget(const SizedBox.shrink());
          },
        );
      }
    }
  }
}

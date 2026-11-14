// design6 P, added 11-11 noon, each from what is drawn:
// (a) from 600 up no select, button, stepper or segmented control stretches
//     to its column: at most 320 px (free text entries and tables may span);
// (b) a chosen or pressed fill covers the whole cell the user sees;
// (c) a glyph beside a title: its middle on the capitals' middle, both on
//     the row's centre line, within half a device pixel;
// (d) a select at 600, 1024, 1440 and 1920: closed at most 320, its list
//     opening on the field's leading edge and at least as wide;
// (e) buttons sharing a row show one top and one bottom by what they draw,
//     each variant beside the others, on each ground, by day and by night.
// At each density Minimal ships.
// ignore_for_file: avoid_relative_lib_imports
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:minimal_ui/minimal_host.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../example/lib/main.dart';
import 'keylines_test.dart' show keylineScreens, loadKeylineFonts;

const Map<String, MinimalDensity> _densities = {
  'standard': MinimalDensity.standard,
  'compact': MinimalDensity.compact,
};

String _kind(Widget w) => w.runtimeType.toString().split('<').first;

const Set<String> _capped = {
  'MinimalSelect',
  'MinimalButton',
  'MinimalSplitButton',
  'MinimalCounter',
  'MinimalSegmentedButton',
  'MinimalDatePicker',
  'MinimalDateRangePicker',
  'MinimalTimePicker',
  'MinimalCombobox',
};

const Key _frame = Key('frame');

Widget _host(
  MinimalDensity density,
  Widget child, {
  Brightness brightness = Brightness.light,
}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  builder: (context, navigator) => MinimalHost(
    light: MinimalThemeData.preset(
      'standard',
      Brightness.light,
    ).copyWith(density: density),
    dark: MinimalThemeData.preset(
      'standard',
      Brightness.dark,
    ).copyWith(density: density),
    brightness: brightness,
    child: RepaintBoundary(key: _frame, child: navigator!),
  ),
  home: Scaffold(
    body: Center(
      child: Padding(padding: const EdgeInsets.all(24), child: child),
    ),
  ),
);

/// The frame at [ratio] device pixels per logical pixel.
class _Shot {
  _Shot(this.width, this.ratio, this.bytes);

  final int width;
  final double ratio;
  final ByteData bytes;

  static Future<_Shot> take(WidgetTester tester, {double ratio = 1}) async {
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(_frame),
    );
    late _Shot shot;
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: ratio);
      final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      shot = _Shot(image.width, ratio, data!);
      image.dispose();
    });
    return shot;
  }

  /// The colour at device pixel ([x], [y]).
  int px(int x, int y) => bytes.getUint32((y * width + x) * 4);

  /// The colour at logical point [p].
  int at(Offset p) => px((p.dx * ratio).floor(), (p.dy * ratio).floor());

  /// The rows (device pixels) inside [r] whose pixels differ from [ground].
  (int, int)? inkRows(Rect r, int ground, {int over = 60}) {
    int? top, bottom;
    for (var y = (r.top * ratio).floor(); y < (r.bottom * ratio).ceil(); y++) {
      for (
        var x = (r.left * ratio).floor();
        x < (r.right * ratio).ceil();
        x++
      ) {
        if (_far(px(x, y), ground, over: over)) {
          top ??= y;
          bottom = y;
          break;
        }
      }
    }
    return top == null ? null : (top, bottom!);
  }
}

bool _far(int a, int b, {int over = 60}) {
  int c(int v, int s) => (v >> s) & 0xff;
  var d = 0;
  for (final s in const [24, 16, 8]) {
    d += (c(a, s) - c(b, s)).abs();
  }
  return d > over;
}

/// The face under a control's measure: its own Align and cap, which a
/// stretching column makes as wide as itself, are not drawn.
RenderBox _faceOf(RenderBox outer) {
  var box = outer;
  while (true) {
    final RenderBox? child = switch (box) {
      RenderPositionedBox(:final child) => child,
      RenderConstrainedBox(:final child) => child,
      _ => null,
    };
    if (child == null || !child.hasSize) return box;
    box = child;
  }
}

Rect _rectOf(RenderBox box) => box.localToGlobal(Offset.zero) & box.size;

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  setUpAll(loadKeylineFonts);

  group('(a) on a wide layout no control stretches past 320', () {
    Future<void> holds(WidgetTester tester, String at) async {
      for (final e
          in find
              .byWidgetPredicate((w) => _capped.contains(_kind(w)))
              .evaluate()) {
        final outer = e.renderObject;
        if (outer is! RenderBox || !outer.hasSize || !outer.attached) continue;
        final box = _faceOf(outer);
        if (MediaQuery.sizeOf(e).width < MinimalLayout.compact) continue;
        final rect = _rectOf(box);
        if (!rect.overlaps(Offset.zero & const Size(1440, 900))) continue;
        expect(
          box.size.width,
          lessThanOrEqualTo(MinimalLayout.controlMax),
          reason: '$at: ${_kind(e.widget)} is ${box.size.width} wide at $rect',
        );
      }
    }

    Future<void> open(WidgetTester tester, String query) async {
      tester.view
        ..physicalSize = const Size(1440, 900)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(
        GalleryApp.at(Uri.parse('http://localhost/?$query')),
      );
      await _settle(tester);
    }

    for (final page in examplePages) {
      testWidgets(page.name, (tester) async {
        await open(tester, 'page=${GalleryApp.pageSlug(page.name)}');
        await holds(tester, page.name);
      });
    }
    for (final screen in keylineScreens) {
      testWidgets(screen.name, (tester) async {
        await open(tester, 'app=${screen.app}');
        await screen.open(tester);
        await holds(tester, screen.name);
      });
    }
  });

  group('(b) a pressed fill covers its cell', () {
    // Each control with three items, the first chosen; the second is
    // pressed and held. Its cell runs half way to its neighbours' marks and
    // over the control's face; the wash beside its mark is the fill.
    final controls = <String, Widget Function(ValueChanged<int>)>{
      'segmented': (on) => MinimalSegmentedButton<int>(
        segments: const [
          MinimalButtonSegment(0, 'Day'),
          MinimalButtonSegment(1, 'Week'),
          MinimalButtonSegment(2, 'Month'),
        ],
        value: 0,
        onChanged: on,
      ),
      'tabs': (on) => MinimalTabBar(
        tabs: const ['Open', 'Done', 'All'],
        selectedIndex: 0,
        onChanged: on,
      ),
      'toggle group': (on) => MinimalToggleGroup<int>(
        items: const [
          MinimalToggleItem(0, icon: LucideIcons.bold, semanticLabel: 'Bold'),
          MinimalToggleItem(1, icon: LucideIcons.italic, semanticLabel: 'It'),
          MinimalToggleItem(2, icon: LucideIcons.underline, semanticLabel: 'U'),
        ],
        selected: const {0},
        onChanged: (_) {},
      ),
    };
    for (final MapEntry(key: name, value: build) in controls.entries) {
      for (final MapEntry(key: d, value: density) in _densities.entries) {
        testWidgets('$name, $d', (tester) async {
          await tester.pumpWidget(_host(density, build((_) {})));
          await tester.pumpAndSettle();
          final control = find.byWidgetPredicate(
            (w) => _kind(w) == _kind(build((_) {})),
          );
          final marks =
              find
                  .descendant(
                    of: control,
                    // A word's or a glyph's line (an icon draws one too).
                    matching: find.byType(RichText),
                  )
                  .evaluate()
                  .map((e) => (e.renderObject! as RenderBox))
                  .map((b) => b.localToGlobal(Offset.zero) & b.size)
                  .toList()
                ..sort((a, b) => a.left.compareTo(b.left));
          expect(marks.length, 3, reason: '$name: three marks');
          final face = tester.getRect(control);
          final mark = marks[1];
          final gesture = await tester.startGesture(mark.center);
          await tester.pump(const Duration(milliseconds: 200));
          final shot = await _Shot.take(tester);
          final fill = shot.at(Offset(mark.left - 2, mark.center.dy));
          final left = (marks[0].right + mark.left) / 2;
          final right = (mark.right + marks[2].left) / 2;
          for (final p in [
            Offset(left + 4, mark.center.dy),
            Offset(right - 4, mark.center.dy),
            Offset(mark.center.dx, face.top + 4),
            Offset(mark.center.dx, face.bottom - 5),
          ]) {
            expect(
              shot.at(p),
              fill,
              reason:
                  '$name ($d): the pressed fill stops short of $p '
                  '(cell ${left.toStringAsFixed(1)}..'
                  '${right.toStringAsFixed(1)}, face $face)',
            );
          }
          await gesture.up();
          await tester.pumpAndSettle();
        }, tags: 'goldens');
      }
    }
  });

  group('(c) a glyph beside a title shares its middle', () {
    final rows = <String, Widget>{
      'list tile': const MinimalListTile(
        icon: LucideIcons.bell,
        title: 'HABIT',
      ),
      'form row': MinimalFormRow(
        label: 'HABIT',
        icon: LucideIcons.bell,
        onPressed: () {},
      ),
      'button': MinimalButton(
        'SAVE',
        icon: LucideIcons.check,
        onPressed: () {},
      ),
    };
    for (final MapEntry(key: name, value: row) in rows.entries) {
      for (final MapEntry(key: d, value: density) in _densities.entries) {
        testWidgets('$name, $d', (tester) async {
          tester.view
            ..physicalSize = const Size(780, 400)
            ..devicePixelRatio = 2;
          addTearDown(tester.view.reset);
          await tester.pumpWidget(
            _host(density, SizedBox(width: 320, child: row)),
          );
          await tester.pumpAndSettle();
          // The form row draws its own rule under its line: the line's
          // middle is its Row's, above the rule.
          final rowRect = tester.getRect(
            name == 'form row'
                ? find
                      .descendant(
                        of: find.byWidget(row),
                        matching: find.byType(Row),
                      )
                      .first
                : find.byWidget(row),
          );
          final icon = tester.getRect(
            find
                .descendant(of: find.byWidget(row), matching: find.byType(Icon))
                .first,
          );
          final words = tester.getRect(
            find.text(name == 'button' ? 'SAVE' : 'HABIT'),
          );
          final shot = await _Shot.take(tester, ratio: 2);
          // What the words stand on: the gap between the glyph and them.
          final ground = shot.at(Offset(words.left - 2, words.top + 1));
          // The capitals are drawn up to a few pixels off the laid-out line
          // (DesignCapCenter moves only what it paints).
          final caps = shot.inkRows(
            Rect.fromLTRB(
              words.left,
              words.top - 4,
              words.right,
              words.bottom + 4,
            ),
            ground,
          )!;
          final capsMid = (caps.$1 + caps.$2 + 1) / 2;
          final glyphMid = icon.center.dy * 2;
          final rowMid = rowRect.center.dy * 2;
          final at =
              '$name ($d): capitals ${caps.$1}..${caps.$2}, glyph '
              'middle $glyphMid, row middle $rowMid (device px)';
          expect(
            (capsMid - glyphMid).abs(),
            lessThanOrEqualTo(0.5),
            reason: at,
          );
          expect((capsMid - rowMid).abs(), lessThanOrEqualTo(0.5), reason: at);
        }, tags: 'goldens');
      }
    }
  });

  group('(d) a select: closed at most 320, open from its leading edge', () {
    for (final width in const [600.0, 1024.0, 1440.0, 1920.0]) {
      testWidgets('Pickers at ${width.round()}', (tester) async {
        tester.view
          ..physicalSize = Size(width, 1000)
          ..devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          GalleryApp.at(
            Uri.parse(
              'http://localhost/?page=${GalleryApp.pageSlug('Pickers')}',
            ),
          ),
        );
        await _settle(tester);
        final selects = find.byWidgetPredicate(
          (w) => _kind(w) == 'MinimalSelect',
        );
        expect(selects, findsWidgets);
        Element? first;
        for (final e in selects.evaluate()) {
          final face = _faceOf(e.renderObject! as RenderBox);
          final rect = _rectOf(face);
          expect(
            rect.width,
            lessThanOrEqualTo(MinimalLayout.controlMax),
            reason: 'closed select ${rect.width} wide at $rect',
          );
          final press =
              find
                      .descendant(
                        of: find.byElementPredicate((x) => x == e),
                        matching: find.byType(MinimalPressable),
                      )
                      .evaluate()
                      .first
                      .widget
                  as MinimalPressable;
          final enabled = press.enabled && press.onPressed != null;
          if (first == null && enabled && rect.bottom < 900) first = e;
        }
        // Open the first one the window shows and read the list's card.
        final field = _rectOf(_faceOf(first!.renderObject! as RenderBox));
        await tester.tapAt(field.centerLeft + const Offset(24, 0));
        await _settle(tester);
        final card = _rectOf(
          tester
              .renderObject<RenderCustomSingleChildLayoutBox>(
                find.byType(CustomSingleChildLayout).last,
              )
              .child!,
        );
        final at = 'field $field, list $card';
        expect(
          card.left,
          moreOrLessEquals(field.left, epsilon: 0.5),
          reason: at,
        );
        expect(card.width, greaterThanOrEqualTo(field.width - 0.5), reason: at);
      });
    }
  });

  group('(e) buttons sharing a row show one top and one bottom', () {
    // The ghost variant draws no outline (its words alone, a wash under the
    // pointer), so the outlines compared are the filled and the bordered.
    const variants = [
      MinimalButtonVariant.primary,
      MinimalButtonVariant.secondary,
      MinimalButtonVariant.destructive,
    ];
    for (final brightness in Brightness.values) {
      for (final size in MinimalButtonSize.values) {
        for (final ground in const ['page', 'card']) {
          final at = '${brightness.name} · ${size.name} · on the $ground';
          testWidgets(at, (tester) async {
            tester.view
              ..physicalSize = const Size(1200, 400)
              ..devicePixelRatio = 2;
            addTearDown(tester.view.reset);
            final theme = MinimalThemeData.preset('standard', brightness);
            final paint = ground == 'page' ? theme.background : theme.card;
            await tester.pumpWidget(
              _host(
                MinimalDensity.standard,
                brightness: brightness,
                Container(
                  color: paint,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final v in variants) ...[
                        MinimalButton(
                          v == MinimalButtonVariant.secondary
                              ? 'Cancel'
                              : 'Sign out',
                          variant: v,
                          size: size,
                          onPressed: () {},
                        ),
                        const SizedBox(width: 8),
                      ],
                    ],
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();
            final shot = await _Shot.take(tester, ratio: 2);
            final ink = shot.at(
              tester.getTopLeft(find.byType(Row).first) - const Offset(8, 8),
            );
            final edges = <String>[];
            for (final v in variants) {
              final r = tester.getRect(
                find.byWidgetPredicate(
                  (w) => w is MinimalButton && w.variant == v,
                ),
              );
              // Rows (device px) where the button draws anything off the
              // ground, across its middle half (clear of the corners).
              final drawn = shot.inkRows(
                Rect.fromLTRB(
                  r.left + r.width / 4,
                  r.top - 4,
                  r.right - r.width / 4,
                  r.bottom + 4,
                ),
                ink,
                over: 12,
              )!;
              edges.add('${v.name} ${drawn.$1}..${drawn.$2}');
            }
            // One top and one bottom: every button's drawn rows the same.
            final spans = {for (final e in edges) e.split(' ')[1]};
            expect(spans, hasLength(1), reason: '$at: ${edges.join(', ')}');
          }, tags: 'goldens');
        }
      }
    }
  });
}

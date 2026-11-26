// The light stands at the top start of the reading direction: the top left in a left-to-right app, the top right in a
// right-to-left one. Every bevel, groove, drop shadow and press takes its light and its shade from it, in both
// appearances, so a part right to left is drawn as the mirror of itself left to right, its light and shade mirrored with
// it. Measured at its edges, a raised face right to left is lit inside its right side and shaded inside its left, a
// held one the other way round, and a window's or a floating plate's shadow falls beside its left side. The grid it
// is drawn on snaps right to left as the mirror of left to right, and its hatching and dotted lines run from the start.
//
// The words are drawn in the test's own face, a box to a letter (the look's faces are not loaded), and are left out of
// the comparison: a Latin word reads left to right in either direction.
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';
import 'package:retro_desktop_ui/src/retro_desktop/internal/parts.dart'
    show RetroDesktopSunkenPainter;

const _size = Size(480, 480);

/// The screen a test draws on: [_size], or a desk's.
var _screen = _size;

/// How many pixels a mirror may differ in, all told: a round edge drawn without smoothing (a radio's disc) can fall a
/// pixel apart near its top either way round, four or five pixels to a disc. A bevel lit from the wrong side differs in
/// hundreds.
const _smoothing = 12;
final _shot = GlobalKey();
const _part = ValueKey('part');

/// A part in the middle of the screen, and what to do to it before it is drawn.
typedef _Case = ({
  Widget Function() part,
  Future<TestGesture?> Function(WidgetTester tester)? act,
});

/// [child] at a whole, even number of pixels wide, so that its middle stands on the screen's and a pixel edge
/// mirrors onto a pixel edge.
class _Even extends SingleChildRenderObjectWidget {
  const _Even({super.child});
  @override
  RenderObject createRenderObject(BuildContext context) => _RenderEven();
}

class _RenderEven extends RenderProxyBox {
  @override
  void performLayout() {
    final loose = constraints.loosen();
    child!.layout(loose, parentUsesSize: true);
    final width = math.min(
      (child!.size.width / 2).ceil() * 2.0,
      constraints.maxWidth,
    );
    child!.layout(
      BoxConstraints(
        minWidth: width,
        maxWidth: width,
        maxHeight: loose.maxHeight,
      ),
      parentUsesSize: true,
    );
    size = constraints.constrain(child!.size);
  }
}

Widget _app(
  Widget part,
  TextDirection direction,
  RetroDesktopAppearance appearance,
  bool dark,
) => MaterialApp(
  debugShowCheckedModeBanner: false,
  builder: (context, home) => RetroDesktopTheme(
    data: RetroDesktopThemeData.classic(
      dark ? Brightness.dark : Brightness.light,
    ).copyWith(appearance: appearance),
    child: Directionality(textDirection: direction, child: home!),
  ),
  home: RepaintBoundary(
    key: _shot,
    child: Builder(
      builder: (context) => Material(
        type: MaterialType.transparency,
        child: ColoredBox(
          color: RetroDesktopTheme.of(context).colors.platinum,
          child: Center(
            child: _Even(
              child: KeyedSubtree(key: _part, child: part),
            ),
          ),
        ),
      ),
    ),
  ),
);

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// A screen's pixels, RGBA, and where its words and glyphs are drawn.
typedef _Shot = ({Uint8List pixels, List<Rect> words});

Future<Uint8List> _pixels(WidgetTester tester) async {
  final boundary =
      _shot.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  return (await tester.runAsync(() async {
    final image = await boundary.toImage();
    final data = await image.toByteData();
    image.dispose();
    return data!.buffer.asUint8List();
  }))!;
}

/// Where the words and the font glyphs are drawn.
List<Rect> _words() {
  final words = <Rect>[];
  void visit(RenderObject o) {
    if (o is RenderParagraph || o is RenderEditable) {
      final transform = o.getTransformTo(null);
      words.add(MatrixUtils.transformRect(transform, o.paintBounds).inflate(2));
      // A glyph in a line set tighter than its face stands out over the
      // paragraph's box (a day tile's numeral): its own box, too.
      if (o is RenderParagraph) {
        final length = o.text.toPlainText().length;
        for (final box in o.getBoxesForSelection(
          TextSelection(baseOffset: 0, extentOffset: length),
        )) {
          words.add(
            MatrixUtils.transformRect(transform, box.toRect()).inflate(2),
          );
        }
      }
    }
    o.visitChildren(visit);
  }

  _shot.currentContext!.findRenderObject()!.visitChildren(visit);
  return words;
}

Future<_Shot> _take(WidgetTester tester) async =>
    (pixels: await _pixels(tester), words: _words());

/// The pixels of [b] that differ from the pixel of [a] at [mirror] (across the screen, or the same place) by more than
/// [tolerance] in a channel, the words of either aside: how many, and the box around them.
(int, Rect) _differing(
  _Shot a,
  _Shot b, {
  bool mirror = true,
  int tolerance = 8,
}) {
  final w = _screen.width.toInt(), h = _screen.height.toInt();
  final words = [
    ...b.words,
    for (final r in a.words)
      mirror ? Rect.fromLTRB(w - r.right, r.top, w - r.left, r.bottom) : r,
  ];
  var count = 0;
  var box = Rect.zero;
  for (var y = 0; y < h; y++) {
    final row = [
      for (final r in words)
        if (r.top <= y + .5 && y + .5 < r.bottom) r,
    ];
    for (var x = 0; x < w; x++) {
      if (row.any((r) => r.left <= x + .5 && x + .5 < r.right)) continue;
      final i = (y * w + x) * 4, j = (y * w + (mirror ? w - 1 - x : x)) * 4;
      for (var c = 0; c < 3; c++) {
        if ((b.pixels[i + c] - a.pixels[j + c]).abs() > tolerance) {
          final pixel = Rect.fromLTWH(x.toDouble(), y.toDouble(), 1, 1);
          box = count == 0 ? pixel : box.expandToInclude(pixel);
          count++;
          break;
        }
      }
    }
  }
  return (count, box);
}

/// The mean brightness of the pixels in [r].
double _brightness(Uint8List px, Rect r) {
  final w = _screen.width.toInt();
  var sum = 0.0, n = 0;
  for (var y = r.top.round(); y < r.bottom.round(); y++) {
    for (var x = r.left.round(); x < r.right.round(); x++) {
      final i = (y * w + x) * 4;
      sum += .2126 * px[i] + .7152 * px[i + 1] + .0722 * px[i + 2];
      n++;
    }
  }
  return sum / n;
}

/// Holds the pointer down on the middle of the part.
Future<TestGesture?> _hold(WidgetTester tester) async {
  final gesture = await tester.startGesture(
    tester.getCenter(find.byKey(_part)),
  );
  await _settle(tester);
  return gesture;
}

Future<TestGesture?> _focus(WidgetTester tester) async {
  await tester.sendKeyEvent(LogicalKeyboardKey.tab);
  await _settle(tester);
  return null;
}

void _drop(Object? _) {}

Widget _wide(Widget child, [double width = 320]) =>
    SizedBox(width: width, child: child);

const _appearances = <String, RetroDesktopAppearance>{
  'Platinum': RetroDesktopAppearance.platinum,
  'Chisel': RetroDesktopAppearance.chisel,
};

enum _Relief { raised, held, casts }

void main() {
  Widget button() => RetroDesktopButton('Cancel', onPressed: () {});
  Widget defaultButton() =>
      RetroDesktopButton('Save', isDefaultAction: true, onPressed: () {});
  Widget tile() => _wide(
    RetroDesktopListTile(
      title: 'Port Linden',
      subtitle: 'Cloudy',
      figure: '10°',
      onPressed: () {},
    ),
  );
  Widget rating() => const RetroDesktopRating(
    label: 'Your rating',
    value: 4,
    onChanged: _drop,
  );
  Widget slider() => _wide(
    const RetroDesktopSlider(label: 'Volume', value: .5, onChanged: _drop),
  );
  Widget card() => _wide(
    const RetroDesktopCard(title: 'Documents', child: Text('Three documents')),
  );
  Widget floatingPlate() =>
      const RetroDesktopSurface(floating: true, child: Text('A desktop plate'));
  Widget menu() => const RetroDesktopMenu(
    label: 'Document actions',
    items: [
      RetroDesktopMenuItem('open', 'Open'),
      RetroDesktopMenuItem('rename', 'Rename'),
    ],
    onSelected: _drop,
  );
  Widget window() => _wide(
    const RetroDesktopWindow(
      title: 'Recent',
      info: '6 of 40',
      status: ['Synced'],
      child: RetroDesktopWell(child: SizedBox(height: 60)),
    ),
    360,
  );

  Widget group() => RetroDesktopButtonGroup(
    items: [
      RetroDesktopButtonGroupItem(label: 'Bold', onPressed: () {}),
      RetroDesktopButtonGroupItem(label: 'Italic', onPressed: () {}),
    ],
  );
  Widget select() => _wide(
    const RetroDesktopSelect(
      labelText: 'Sort by',
      value: 'name',
      options: [
        RetroDesktopOption('name', 'Name'),
        RetroDesktopOption('date', 'Date'),
      ],
      onChanged: _drop,
    ),
  );

  final cases = <String, _Case>{
    'a button': (part: button, act: null),
    'a button held down': (part: button, act: _hold),
    'a focused button': (part: button, act: _focus),
    'a button out of use': (
      part: () => const RetroDesktopButton('Cancel'),
      act: null,
    ),
    'a default button': (part: defaultButton, act: null),
    'a default button held down': (part: defaultButton, act: _hold),
    'an icon button': (
      part: () => RetroDesktopIconButton(
        RetroDesktopGlyphs.tag,
        label: 'Tag',
        onPressed: () {},
      ),
      act: null,
    ),
    'a popup button': (
      part: () => RetroDesktopPopupButton('Workshop', onPressed: () {}),
      act: null,
    ),
    'a segmented button and its chosen segment': (
      part: () => const RetroDesktopSegmentedButton(
        label: 'View',
        value: 'list',
        segments: [
          RetroDesktopButtonSegment('list', 'List'),
          RetroDesktopButtonSegment('grid', 'Grid'),
        ],
        onChanged: _drop,
      ),
      act: null,
    ),
    'a toggle group and its chosen toggle': (
      part: () => RetroDesktopToggleGroup<String>(
        values: const ['b', 'i', 'u'],
        selected: const {'b'},
        labelOf: (v) => v.toUpperCase(),
        multiple: true,
        onChanged: _drop,
      ),
      act: null,
    ),
    'a checkbox': (
      part: () => const RetroDesktopCheckbox(
        value: false,
        label: 'Option',
        onChanged: _drop,
      ),
      act: null,
    ),
    'a radio group': (
      part: () => const RetroDesktopRadioGroup(
        labelText: 'Appearance',
        value: 'day',
        options: [
          RetroDesktopRadio('day', 'Day'),
          RetroDesktopRadio('night', 'Night'),
        ],
        onChanged: _drop,
      ),
      act: null,
    ),
    'a switch': (
      part: () => const RetroDesktopSwitch(
        value: true,
        label: 'Notifications',
        onChanged: _drop,
      ),
      act: null,
    ),
    'a slider': (part: slider, act: null),
    'a slider held by its grip': (part: slider, act: _hold),
    'a range slider': (
      part: () => _wide(
        const RetroDesktopRangeSlider(
          label: 'Price',
          values: RawRangeValues(20, 80),
          max: 100,
          onChanged: _drop,
        ),
      ),
      act: null,
    ),
    'a number field': (
      part: () => const RetroDesktopNumberField(
        value: 2,
        unit: 'coats',
        onChanged: _drop,
      ),
      act: null,
    ),
    'a text field': (
      part: () => _wide(const RetroDesktopTextField(hintText: 'Search')),
      act: null,
    ),
    'a select': (part: select, act: null),
    'a select held down': (part: select, act: _hold),
    'a progress bar': (
      part: () => _wide(
        const RetroDesktopLinearProgressIndicator(
          value: .6,
          label: 'Uploading files',
        ),
      ),
      act: null,
    ),
    'a group box': (
      part: () => _wide(
        const RetroDesktopGroupBox(
          title: 'Checklist',
          count: '6 of 10',
          child: SizedBox(height: 40),
        ),
      ),
      act: null,
    ),
    'a tab bar': (
      part: () => _wide(
        const RetroDesktopTabBar(
          tabs: ['Today', 'Later'],
          onChanged: _drop,
          selectedIndex: 0,
          child: SizedBox(height: 40),
        ),
      ),
      act: null,
    ),
    'a window': (part: window, act: null),
    'a toolbar and its rule': (
      part: () => _wide(
        RetroDesktopToolbar(
          children: [
            RetroDesktopButton('New', onPressed: () {}),
            const RetroDesktopToolRule(),
            RetroDesktopButton('Open', onPressed: () {}),
          ],
        ),
        360,
      ),
      act: null,
    ),
    'a list row': (part: tile, act: null),
    'a list row held down': (part: tile, act: _hold),
    'a row of figures and their rules': (
      part: () => _wide(
        const RetroDesktopStats([
          ('Open tasks', '18', null),
          ('Rain today', '6.4', 'mm'),
        ]),
      ),
      act: null,
    ),
    'a card': (part: card, act: null),
    'a floating plate': (part: floatingPlate, act: null),
    'a menu': (part: menu, act: null),
    'a dialog': (
      part: () => _wide(
        const RetroDesktopDialog(
          title: 'Save changes?',
          message: 'Your document has changed.',
          actions: [
            RetroDesktopDialogAction(
              'Save',
              value: true,
              isDefaultAction: true,
            ),
          ],
        ),
        360,
      ),
      act: null,
    ),
    'a gauge': (
      part: () => _wide(
        const RetroDesktopGaugeBlock(
          value: '1.38 GB',
          of: 'of 5 GB',
          share: .28,
          endLabel: '28%',
          footStart: 'Used',
          footEnd: '3.62 GB free',
        ),
      ),
      act: null,
    ),
    // One band: a band's hatch keeps its slant either way round (a texture, not the light).
    'a scale bar': (
      part: () => _wide(const RetroDesktopScaleBar(at: .14, bands: ['Good'])),
      act: null,
    ),
    'a span bar': (
      part: () => _wide(
        const RetroDesktopSpanBar(
          from: .31,
          to: .68,
          at: .39,
          fromLabel: '07:22',
          toLabel: '16:21',
          startLabel: '00',
          endLabel: '24',
        ),
      ),
      act: null,
    ),
    'a folder grid and its chosen folder': (
      part: () => _wide(
        const RetroDesktopFolderGrid(
          items: [
            RetroDesktopFolder('Workshop', subtitle: '9 notes', selected: true),
            RetroDesktopFolder('Garden', subtitle: '4 notes'),
          ],
        ),
      ),
      act: null,
    ),
    'a list table and its heads': (
      part: () => _wide(
        const RetroDesktopListTable(
          columns: [
            RetroDesktopListTableColumn('Name'),
            RetroDesktopListTableColumn('Edited', width: 100, sorted: true),
          ],
          rows: [
            RetroDesktopListTableRow(
              title: 'A note',
              subtitle: 'Where it is',
              cells: [('09:14', 'today')],
            ),
          ],
          total: 40,
        ),
        360,
      ),
      act: null,
    ),
    'a rating': (part: rating, act: null),
    'a rating held on a star': (part: rating, act: _hold),
    'an alert': (
      part: () => _wide(
        RetroDesktopAlert(
          title: 'Due at 14:00',
          body: 'The next step wants a warm room.',
          actions: [
            RetroDesktopButton('Snooze', onPressed: () {}),
            RetroDesktopButton('Open', isDefaultAction: true, onPressed: () {}),
          ],
        ),
        360,
      ),
      act: null,
    ),
    'a plate': (
      part: () => const RetroDesktopSurface(child: Text('A desktop plate')),
      act: null,
    ),
    'a chosen choice box': (
      part: () => RetroDesktopChoiceBox(
        onPressed: () {},
        selected: true,
        child: const Text('Today'),
      ),
      act: null,
    ),
    'a day tile': (
      part: () => const RetroDesktopDayTile(month: 'March', day: '14'),
      act: null,
    ),
    'the sunken painter': (
      part: () => Builder(
        builder: (context) => SizedBox(
          width: 120,
          height: 40,
          child: CustomPaint(
            painter: RetroDesktopSunkenPainter(
              RetroDesktopTheme.of(context).colors,
              textDirection: Directionality.of(context),
            ),
          ),
        ),
      ),
      act: null,
    ),
  };

  for (final MapEntry(key: look, value: appearance) in _appearances.entries) {
    for (final dark in [false, true]) {
      final mode = '$look, ${dark ? 'by night' : 'by day'}';

      for (final MapEntry(key: name, value: c) in cases.entries) {
        // Chisel's dotted focus rectangle keeps its dots on the screen's own grid either way round, a dot off its
        // mirror: a mark, not the light.
        if (appearance == RetroDesktopAppearance.chisel &&
            name == 'a focused button') {
          continue;
        }
        testWidgets('$mode, $name right to left is its mirror, light and '
            'shade too', (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = _size;
          addTearDown(tester.view.reset);
          Future<_Shot> shoot(TextDirection direction) async {
            await tester.pumpWidget(
              _app(c.part(), direction, appearance, dark),
            );
            await _settle(tester);
            final gesture = await c.act?.call(tester);
            final shot = await _take(tester);
            await gesture?.up();
            await tester.pumpWidget(const SizedBox());
            await _settle(tester);
            return shot;
          }

          final ltr = await shoot(TextDirection.ltr);
          final rtl = await shoot(TextDirection.rtl);
          final (count, box) = _differing(ltr, rtl);
          expect(count, lessThanOrEqualTo(_smoothing), reason: 'in $box');
        });
      }

      // Raised, a face is lit inside its side toward the light; held in, it is shaded there; a window, a floating card
      // or a menu casts its shadow beside its side away from the light (Platinum's: Chisel's stand on their bevels).
      for (final (name, part, type, relief, act) in [
        ('a button', button, RetroDesktopButton, _Relief.raised, null),
        ('a button held in', button, RetroDesktopButton, _Relief.held, _hold),
        if (appearance == RetroDesktopAppearance.platinum) ...[
          (
            'a floating plate',
            floatingPlate,
            RetroDesktopSurface,
            _Relief.casts,
            null,
          ),
          ('a window', window, RetroDesktopWindow, _Relief.casts, null),
        ],
      ]) {
        for (final direction in TextDirection.values) {
          final right = direction == TextDirection.rtl;
          testWidgets('$mode, ${direction.name}: $name is lit from the top '
              '${right ? 'right' : 'left'}', (tester) async {
            tester.view.devicePixelRatio = 1;
            tester.view.physicalSize = _size;
            addTearDown(tester.view.reset);
            await tester.pumpWidget(_app(part(), direction, appearance, dark));
            await _settle(tester);
            final gesture = await act?.call(tester);
            final px = await _pixels(tester);
            final f = tester.getRect(find.byType(type).first);
            final band = f.height / 4;
            // A strip 2 wide beside a side of the face: inside it, a pixel in from the side, or outside it.
            double strip(bool leftSide, bool outside) {
              final (from, to) = switch ((leftSide, outside)) {
                (true, true) => (f.left - 2, f.left),
                (true, false) => (f.left + 1, f.left + 3),
                (false, false) => (f.right - 3, f.right - 1),
                (false, true) => (f.right, f.right + 2),
              };
              return _brightness(
                px,
                Rect.fromLTRB(from, f.center.dy - band, to, f.center.dy + band),
              );
            }

            final (toward, away) = switch (relief) {
              _Relief.raised => (strip(!right, false), strip(right, false)),
              _Relief.held => (strip(right, false), strip(!right, false)),
              _Relief.casts => (strip(!right, true), strip(right, true)),
            };
            expect(
              toward,
              greaterThan(away + 1),
              reason: 'toward the light $toward, away from it $away',
            );
            await gesture?.up();
            await tester.pumpWidget(const SizedBox());
            await _settle(tester);
          });
        }
      }

      // A press keeps its light through the whole sink and the rise after it: every frame right to left is the mirror
      // of the same frame left to right.
      testWidgets('$mode, a press and its release keep the mirrored light at '
          'every frame', (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = _size;
        addTearDown(tester.view.reset);
        Future<List<_Shot>> frames(TextDirection direction) async {
          await tester.pumpWidget(_app(button(), direction, appearance, dark));
          await _settle(tester);
          final shots = <_Shot>[await _take(tester)];
          final gesture = await tester.startGesture(
            tester.getCenter(find.byType(RetroDesktopButton)),
          );
          for (var i = 0; i < 8; i++) {
            await tester.pump(const Duration(milliseconds: 20));
            shots.add(await _take(tester));
          }
          await gesture.up();
          for (var i = 0; i < 8; i++) {
            await tester.pump(const Duration(milliseconds: 20));
            shots.add(await _take(tester));
          }
          await tester.pumpWidget(const SizedBox());
          await _settle(tester);
          return shots;
        }

        final ltr = await frames(TextDirection.ltr);
        final rtl = await frames(TextDirection.rtl);
        // The press changes the face: held, it is not the idle one.
        expect(
          _differing(ltr.first, ltr[8], mirror: false).$1,
          greaterThan(20),
        );
        for (var i = 0; i < ltr.length; i++) {
          final (count, box) = _differing(ltr[i], rtl[i]);
          expect(
            count,
            lessThanOrEqualTo(_smoothing),
            reason: 'frame $i, in $box',
          );
        }
      });

      // At a desk (1024 wide up) a window stands in its desk chrome: its title boxes, its caption buttons, its grow
      // box.
      testWidgets('$mode, at a desk, a window right to left is its mirror', (
        tester,
      ) async {
        _screen = const Size(1100, 480);
        addTearDown(() => _screen = _size);
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = _screen;
        addTearDown(tester.view.reset);
        Future<_Shot> shoot(TextDirection direction) async {
          await tester.pumpWidget(_app(window(), direction, appearance, dark));
          await _settle(tester);
          final shot = await _take(tester);
          await tester.pumpWidget(const SizedBox());
          await _settle(tester);
          return shot;
        }

        final ltr = await shoot(TextDirection.ltr);
        final rtl = await shoot(TextDirection.rtl);
        final (count, box) = _differing(ltr, rtl);
        expect(count, lessThanOrEqualTo(_smoothing), reason: 'in $box');
      });

      // Held, a part's words sink a step down and toward the end, away from the light (Chisel's buttons; a button
      // group's items, in either appearance): the word masks above leave them out, so they are measured.
      for (final (name, part, word) in [
        if (appearance == RetroDesktopAppearance.chisel)
          ('a button', button, 'Cancel'),
        ("a button group's item", group, 'Bold'),
      ]) {
        testWidgets("$mode, $name's words sink away from the light when held", (
          tester,
        ) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = _size;
          addTearDown(tester.view.reset);
          final sink = <TextDirection, Offset>{};
          for (final direction in TextDirection.values) {
            await tester.pumpWidget(_app(part(), direction, appearance, dark));
            await _settle(tester);
            final idle = tester.getRect(find.text(word));
            final gesture = await tester.startGesture(idle.center);
            await _settle(tester);
            sink[direction] =
                tester.getRect(find.text(word)).topLeft - idle.topLeft;
            await gesture.up();
            await tester.pumpWidget(const SizedBox());
            await _settle(tester);
          }
          final ltr = sink[TextDirection.ltr]!, rtl = sink[TextDirection.rtl]!;
          expect(ltr.dx, greaterThan(0), reason: 'left to right: $ltr');
          expect(ltr.dy, greaterThan(0), reason: 'left to right: $ltr');
          expect(rtl, Offset(-ltr.dx, ltr.dy));
        });
      }
    }
  }

  testWidgets("a day tile's words stand as their mirror right to left", (
    tester,
  ) async {
    tester.view
      ..physicalSize = _size
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final edges = <TextDirection, (double, double)>{};
    for (final direction in TextDirection.values) {
      await tester.pumpWidget(
        _app(
          const RetroDesktopDayTile(month: 'March', day: '14'),
          direction,
          _appearances.values.first,
          false,
        ),
      );
      await _settle(tester);
      final tile = tester.getRect(find.byKey(_part));
      final day = tester.getRect(find.text('14'));
      // From the tile's start edge to the day's, and from its end edge: the
      // sheets behind the face step out toward the end, so the words keep to
      // the face at the start.
      edges[direction] = direction == TextDirection.ltr
          ? (day.left - tile.left, tile.right - day.right)
          : (tile.right - day.right, day.left - tile.left);
    }
    final (ltrStart, ltrEnd) = edges[TextDirection.ltr]!;
    final (rtlStart, rtlEnd) = edges[TextDirection.rtl]!;
    expect(rtlStart, moreOrLessEquals(ltrStart, epsilon: .5));
    expect(rtlEnd, moreOrLessEquals(ltrEnd, epsilon: .5));
  });
}

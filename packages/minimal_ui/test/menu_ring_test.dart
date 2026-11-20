// A menu marks the command the keyboard is on as Minimal marks focus
// everywhere, with the thin accent ring, drawn inside the row's edge so it
// fits between the rows above and below. The row the pointer is on keeps the
// muted fill alone, so in either appearance the pointer's row never reads as
// the keyboard's. Every menu does it: a menu button's, a menu bar's, a
// context menu's and a split button's.
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:minimal_ui/minimal_host.dart';

const _labels = ['Rename', 'Duplicate', 'Archive', 'Delete'];

List<MinimalMenuItem> _items() => [
  for (final label in _labels) MinimalMenuItem(label, onPressed: () {}),
];

Widget _host(Widget child, {Brightness brightness = Brightness.light}) =>
    RepaintBoundary(
      key: const ValueKey('screen'),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        builder: (context, navigator) => MinimalHost(
          light: MinimalThemeData.preset('standard', Brightness.light),
          dark: MinimalThemeData.preset('standard', Brightness.dark),
          brightness: brightness,
          child: navigator!,
        ),
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(18),
            child: Align(alignment: Alignment.topLeft, child: child),
          ),
        ),
      ),
    );

/// The menu button the first three groups open.
Widget _button() => MinimalMenu.button(
  Icons.more_horiz,
  text: 'More',
  label: 'Habit actions',
  items: _items(),
);

/// The row box under [label]'s words: the fill under them, the ring over.
Finder _box(String label) => find
    .ancestor(
      of: find.text(label).last,
      matching: find.byWidgetPredicate(
        (w) => w is Container && w.decoration != null,
      ),
    )
    .first;

Color? _fill(Decoration? d) => switch (d) {
  BoxDecoration(:final color) => color,
  ShapeDecoration(:final color) => color,
  _ => null,
};

Color? _rim(Decoration? d) => switch (d) {
  BoxDecoration(border: final Border border) => border.top.color,
  ShapeDecoration(shape: final OutlinedBorder shape)
      when shape.side != BorderSide.none =>
    shape.side.color,
  _ => null,
};

/// The rows of [labels] on the muted fill, and the rows wearing the ring,
/// their words joined by commas.
({String lit, String ringed}) _marks(
  WidgetTester tester,
  MinimalThemeData t, [
  List<String> labels = _labels,
]) {
  final lit = <String>[], ringed = <String>[];
  for (final label in labels) {
    if (find.text(label).evaluate().isEmpty) continue;
    final box = tester.widget<Container>(_box(label));
    if (_fill(box.decoration) == t.muted) lit.add(label);
    if (_rim(box.foregroundDecoration) == t.ring) ringed.add(label);
  }
  return (lit: lit.join(','), ringed: ringed.join(','));
}

Future<void> _key(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyEvent(key);
  await tester.pumpAndSettle();
}

Future<TestGesture> _mouse(WidgetTester tester) async {
  final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
  await mouse.addPointer(location: Offset.zero);
  addTearDown(mouse.removePointer);
  return mouse;
}

/// The relative luminance of the pixel at [i] in [rgba], as WCAG reckons it.
double _luminance(Uint8List rgba, int i) {
  double channel(int v) {
    final c = v / 255;
    return c <= .04045
        ? c / 12.92
        : math.pow((c + .055) / 1.055, 2.4).toDouble();
  }

  return .2126 * channel(rgba[i]) +
      .7152 * channel(rgba[i + 1]) +
      .0722 * channel(rgba[i + 2]);
}

Future<({Uint8List rgba, int width, int height})> _shot(
  WidgetTester tester,
) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('screen')),
  );
  final image = (await tester.runAsync(() => boundary.toImage()))!;
  final data = (await tester.runAsync(
    () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
  ))!;
  final shot = (
    rgba: data.buffer.asUint8List(),
    width: image.width,
    height: image.height,
  );
  image.dispose();
  return shot;
}

void main() {
  final t = MinimalThemeData.preset('standard', Brightness.light);

  // The keyboard's highlights on throughout, as on a desktop once a key is
  // pressed: the pointer's row must still not wear the ring.
  setUp(() {
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
    final view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.physicalSize = const Size(600, 600);
    view.devicePixelRatio = 1;
  });
  tearDown(() {
    FocusManager.instance.highlightStrategy = FocusHighlightStrategy.automatic;
    TestWidgetsFlutterBinding.instance.platformDispatcher.views.first.reset();
  });

  testWidgets("a menu button's menu: the keys' item is lit and ringed, the "
      "pointer's lit alone, and the next key rings the item it moves to", (
    tester,
  ) async {
    await tester.pumpWidget(_host(_button()));
    await _key(tester, LogicalKeyboardKey.tab);
    await _key(tester, LogicalKeyboardKey.arrowDown);
    expect(_marks(tester, t), (lit: 'Rename', ringed: 'Rename'));
    await _key(tester, LogicalKeyboardKey.arrowDown);
    expect(_marks(tester, t), (lit: 'Duplicate', ringed: 'Duplicate'));
    final mouse = await _mouse(tester);
    await mouse.moveTo(tester.getCenter(_box('Archive')));
    await tester.pumpAndSettle();
    expect(_marks(tester, t), (
      lit: 'Archive',
      ringed: '',
    ), reason: "the pointer's item took the keyboard's ring");
    await _key(tester, LogicalKeyboardKey.arrowDown);
    expect(_marks(tester, t), (lit: 'Delete', ringed: 'Delete'));
    await mouse.moveTo(tester.getCenter(_box('Rename')));
    await tester.pumpAndSettle();
    expect(_marks(tester, t), (lit: 'Rename', ringed: ''));
    await mouse.moveTo(Offset.zero);
    await tester.pumpAndSettle();
    expect(_marks(tester, t), (lit: '', ringed: ''));
  });

  testWidgets('a menu the pointer opened shows no ring until a key', (
    tester,
  ) async {
    await tester.pumpWidget(_host(_button()));
    final mouse = await _mouse(tester);
    final more = tester.getCenter(find.text('More'));
    await mouse.moveTo(more);
    await mouse.down(more);
    await mouse.up();
    await tester.pumpAndSettle();
    expect(_marks(tester, t), (lit: '', ringed: ''));
    await mouse.moveTo(tester.getCenter(_box('Duplicate')));
    await tester.pumpAndSettle();
    expect(_marks(tester, t), (lit: 'Duplicate', ringed: ''));
    await _key(tester, LogicalKeyboardKey.arrowUp);
    expect(_marks(tester, t), (lit: 'Rename', ringed: 'Rename'));
  });

  testWidgets("a menu bar's menu: the keys' row is ringed, the pointer's lit "
      'alone', (tester) async {
    await tester.pumpWidget(
      _host(
        SizedBox(
          width: 320,
          child: MinimalMenuBar(
            menus: [
              MinimalMenuEntry(
                'File',
                children: [
                  for (final label in _labels)
                    MinimalMenuEntry(label, onPressed: () {}),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    await _key(tester, LogicalKeyboardKey.tab);
    await _key(tester, LogicalKeyboardKey.arrowDown);
    expect(_marks(tester, t), (lit: 'Rename', ringed: 'Rename'));
    final mouse = await _mouse(tester);
    await mouse.moveTo(tester.getCenter(_box('Archive')));
    await tester.pumpAndSettle();
    expect(_marks(tester, t), (lit: 'Archive', ringed: ''));
    await _key(tester, LogicalKeyboardKey.arrowDown);
    expect(_marks(tester, t), (lit: 'Delete', ringed: 'Delete'));
  });

  testWidgets("a context menu: the keys' row is ringed, the pointer's lit "
      'alone', (tester) async {
    await tester.pumpWidget(
      _host(
        MinimalMenu(
          label: 'Row actions',
          trigger: MinimalMenuTrigger.longPress,
          items: _items(),
          child: const Text('Morning run'),
        ),
      ),
    );
    await _key(tester, LogicalKeyboardKey.tab);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.f10);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pumpAndSettle();
    await _key(tester, LogicalKeyboardKey.arrowDown);
    final keys = _marks(tester, t);
    expect(keys.ringed, isNotEmpty, reason: 'no row took the ring');
    expect(keys.lit, keys.ringed);
    final other = _labels.firstWhere((l) => l != keys.ringed);
    final mouse = await _mouse(tester);
    await mouse.moveTo(tester.getCenter(_box(other)));
    await tester.pumpAndSettle();
    expect(_marks(tester, t), (lit: other, ringed: ''));
  });

  testWidgets("a split button's menu: the keys' row is ringed", (tester) async {
    await tester.pumpWidget(
      _host(
        MinimalSplitButton(
          'Save',
          onPressed: () {},
          actions: [
            MinimalMenuItem('Save as…', onPressed: () {}),
            MinimalMenuItem('Save a copy', onPressed: () {}),
          ],
        ),
      ),
    );
    const actions = ['Save as…', 'Save a copy'];
    await _key(tester, LogicalKeyboardKey.tab);
    await _key(tester, LogicalKeyboardKey.arrowDown);
    expect(_marks(tester, t, actions), (lit: 'Save as…', ringed: 'Save as…'));
    await _key(tester, LogicalKeyboardKey.arrowDown);
    expect(_marks(tester, t, actions), (
      lit: 'Save a copy',
      ringed: 'Save a copy',
    ));
  });

  // Drawn pixels: the rasterizer's, as a golden's. Tagged goldens, so Linux CI
  // leaves them to the macOS goldens job.
  for (final brightness in Brightness.values) {
    final theme = MinimalThemeData.preset('standard', brightness);
    testWidgets(
      '${brightness.name}: the ring is a whole 2 px outline inside the row, '
      "at 3:1 against the pointer's row, clear of its words and its "
      'neighbours',
      (tester) async {
        final mouse = await _mouse(tester);
        await tester.pumpWidget(_host(_button(), brightness: brightness));
        await _key(tester, LogicalKeyboardKey.tab);
        await _key(tester, LogicalKeyboardKey.arrowDown);
        await mouse.moveTo(tester.getCenter(_box('Duplicate')));
        await tester.pumpAndSettle();
        expect(_marks(tester, theme), (lit: 'Duplicate', ringed: ''));
        final pointer = await _shot(tester);
        // The keys come back to the same row, the pointer still over it.
        await _key(tester, LogicalKeyboardKey.arrowDown);
        await _key(tester, LogicalKeyboardKey.arrowUp);
        expect(_marks(tester, theme), (lit: 'Duplicate', ringed: 'Duplicate'));
        final keys = await _shot(tester);
        expect((keys.width, keys.height), (pointer.width, pointer.height));

        final row = tester.getRect(_box('Duplicate'));
        final words = tester.getRect(find.text('Duplicate').last);
        var inWords = 0, outside = 0;
        for (var y = 0; y < keys.height; y++) {
          for (var x = 0; x < keys.width; x++) {
            final i = (y * keys.width + x) * 4;
            if (keys.rgba[i] == pointer.rgba[i] &&
                keys.rgba[i + 1] == pointer.rgba[i + 1] &&
                keys.rgba[i + 2] == pointer.rgba[i + 2]) {
              continue;
            }
            final p = Offset(x + .5, y + .5);
            if (words.contains(p)) inWords++;
            if (!row.inflate(.5).contains(p)) outside++;
          }
        }
        expect(inWords, 0, reason: 'the ring touched the words');
        expect(outside, 0, reason: 'the ring left its row');
        // Each side's middle, a pixel inside the edge, changes at 3:1.
        double contrast(Offset at) {
          final i = (at.dy.floor() * keys.width + at.dx.floor()) * 4;
          final a = _luminance(keys.rgba, i), b = _luminance(pointer.rgba, i);
          return (math.max(a, b) + .05) / (math.min(a, b) + .05);
        }

        final sides = {
          'top': Offset(row.center.dx, row.top + 1),
          'bottom': Offset(row.center.dx, row.bottom - 1),
          'start': Offset(row.left + 1, row.center.dy),
          'end': Offset(row.right - 1, row.center.dy),
        };
        for (final MapEntry(key: side, value: at) in sides.entries) {
          expect(
            contrast(at),
            greaterThanOrEqualTo(3),
            reason: 'the ring is under 3:1 on its $side side',
          );
        }
      },
      tags: 'goldens',
    );
  }
}

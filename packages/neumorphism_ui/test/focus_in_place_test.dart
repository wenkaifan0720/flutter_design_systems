// Keyboard focus and out of use, read from the drawn pixels by day and by night:
// - A checkbox's box, a radio's socket and a switch's slot are hollows in the wall. Focus deepens them and lifts a
//   switch's thumb inside its slot; nothing rises round them, so no pixel outside the hollow changes.
// - The hollows inside a part that rises for focus (a list row's icon well) keep their depth: the row's rise already
//   says where focus is.
// - A part out of use keeps its moulding, shallower: its light and shade stand between none and a live part's.
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

import 'support.dart';

typedef _Shot = (ByteData, int, int);

class _Stage {
  _Stage(this.tester, this.dark);
  final WidgetTester tester;
  final bool dark;
  final key = GlobalKey();
  late Color ground;

  Future<void> pump(Widget child) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(400, 240);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      neumorphicApp(
        RepaintBoundary(
          key: key,
          child: Builder(
            builder: (context) {
              ground = NeumorphicTheme.of(context).colors.ground;
              return ColoredBox(
                color: ground,
                child: Center(child: SizedBox(width: 320, child: child)),
              );
            },
          ),
        ),
        dark: dark,
        width: 400,
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<_Shot> shot() async {
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(key),
    );
    final image = (await tester.runAsync(() => boundary.toImage()))!;
    final bytes = (await tester.runAsync(
      () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
    ))!;
    final shot = (bytes, image.width, image.height);
    image.dispose();
    return shot;
  }

  Future<void> focusByTab() async {
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
  }
}

/// Whether the pixel at [x], [y] differs between [a] and [b] by more than a rounding step in any channel.
bool _moved(_Shot a, _Shot b, int x, int y) {
  final (da, w, _) = a;
  final (db, _, _) = b;
  final i = (y * w + x) * 4;
  for (var k = 0; k < 3; k++) {
    if ((da.getUint8(i + k) - db.getUint8(i + k)).abs() > 2) return true;
  }
  return false;
}

/// The pixels that change from [a] to [b] inside [inside] (or anywhere) and outside [outside].
int _changed(_Shot a, _Shot b, {Rect? inside, Rect? outside}) {
  final (_, w, h) = a;
  var n = 0;
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final p = Offset(x + .5, y + .5);
      if (inside != null && !inside.contains(p)) continue;
      if (outside != null && outside.contains(p)) continue;
      if (_moved(a, b, x, y)) n++;
    }
  }
  return n;
}

/// How far the drawn pixels stand from [ground], summed over the stage: the light and shade a part casts.
double _relief(_Shot shot, Color ground) {
  final (d, w, h) = shot;
  final g = [
    (ground.r * 255).round(),
    (ground.g * 255).round(),
    (ground.b * 255).round(),
  ];
  var sum = 0.0;
  for (var i = 0; i < w * h; i++) {
    for (var k = 0; k < 3; k++) {
      sum += (d.getUint8(i * 4 + k) - g[k]).abs();
    }
  }
  return sum;
}

/// The painted box of [size] under [of]: a checkbox's box, a radio's socket; with no [size], a switch's slot, centred
/// in its painter's box at the switch's own size.
Rect _hollow(WidgetTester tester, Finder of, Size? size) {
  for (final element
      in find
          .descendant(of: of, matching: find.byType(CustomPaint))
          .evaluate()) {
    final box = element.renderObject as RenderBox?;
    if (box == null || !box.hasSize) continue;
    final painter = (element.widget as CustomPaint).painter;
    if (size == null) {
      if (painter.runtimeType.toString() != '_SwitchPainter') continue;
      final slot = (painter as dynamic).size as Size;
      final at = box.localToGlobal(Offset.zero) & box.size;
      return Rect.fromCenter(
        center: at.center,
        width: slot.width,
        height: slot.height,
      );
    }
    if ((box.size.width - size.width).abs() < 1 &&
        (box.size.height - size.height).abs() < 1) {
      return box.localToGlobal(Offset.zero) & box.size;
    }
  }
  throw StateError('No $size face under $of');
}

class _Value<T> extends StatefulWidget {
  const _Value(this.initial, this.builder);
  final T initial;
  final Widget Function(T value, ValueChanged<T> onChanged) builder;
  @override
  State<_Value<T>> createState() => _ValueState<T>();
}

class _ValueState<T> extends State<_Value<T>> {
  late T value = widget.initial;
  @override
  Widget build(BuildContext context) =>
      widget.builder(value, (next) => setState(() => value = next));
}

void main() {
  setUpAll(() async {
    await loadNeumorphicFonts();
    await loadNeumorphicGlyphs();
  });

  final hollows = <String, (Size?, Widget Function())>{
    'a checkbox': (
      const Size.square(28),
      () => Align(
        alignment: AlignmentDirectional.centerStart,
        child: _Value<bool?>(
          false,
          (v, set) =>
              NeumorphicCheckbox(value: v, label: 'Receipt', onChanged: set),
        ),
      ),
    ),
    'a checked checkbox': (
      const Size.square(28),
      () => Align(
        alignment: AlignmentDirectional.centerStart,
        child: _Value<bool?>(
          true,
          (v, set) =>
              NeumorphicCheckbox(value: v, label: 'Receipt', onChanged: set),
        ),
      ),
    ),
    'a check row': (
      const Size.square(28),
      () => _Value<bool?>(
        false,
        (v, set) =>
            NeumorphicCheckRow(value: v, label: 'Remember', onChanged: set),
      ),
    ),
    'a radio': (
      const Size.square(24),
      () => _Value<String?>(
        null,
        (v, set) => NeumorphicRadioGroup<String>(
          label: 'Delivery',
          value: v,
          options: const [
            NeumorphicRadio('standard', 'Standard'),
            NeumorphicRadio('express', 'Express'),
          ],
          onChanged: set,
        ),
      ),
    ),
    'a switch': (
      null,
      () => Align(
        alignment: AlignmentDirectional.centerStart,
        child: _Value<bool>(
          false,
          (v, set) =>
              NeumorphicSwitch(value: v, label: 'Share', onChanged: set),
        ),
      ),
    ),
    'a switch that is on': (
      null,
      () => Align(
        alignment: AlignmentDirectional.centerStart,
        child: _Value<bool>(
          true,
          (v, set) =>
              NeumorphicSwitch(value: v, label: 'Share', onChanged: set),
        ),
      ),
    ),
    'a switch row': (
      null,
      () => _Value<bool>(
        false,
        (v, set) =>
            NeumorphicSwitchRow(value: v, label: 'Weekly', onChanged: set),
      ),
    ),
  };

  for (final dark in [false, true]) {
    final mode = dark ? 'night' : 'day';
    for (final MapEntry(key: name, value: (size, build)) in hollows.entries) {
      testWidgets('$name shows focus inside its own hollow, by $mode', (
        tester,
      ) async {
        final previous = FocusManager.instance.highlightStrategy;
        FocusManager.instance.highlightStrategy =
            FocusHighlightStrategy.alwaysTraditional;
        addTearDown(() => FocusManager.instance.highlightStrategy = previous);
        final stage = _Stage(tester, dark);
        await stage.pump(build());
        final rest = await stage.shot();
        await stage.focusByTab();
        final focused = await stage.shot();
        final hollow = _hollow(tester, find.byKey(stage.key), size);
        expect(
          _changed(rest, focused, inside: hollow),
          greaterThan(hollow.width + hollow.height),
          reason: 'focus shows in the hollow',
        );
        expect(
          _changed(rest, focused, outside: hollow.inflate(1)),
          0,
          reason: 'nothing rises round the hollow',
        );
      });
    }

    testWidgets('a list row rises for focus and its icon well keeps its depth, '
        'by $mode', (tester) async {
      final previous = FocusManager.instance.highlightStrategy;
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;
      addTearDown(() => FocusManager.instance.highlightStrategy = previous);
      final stage = _Stage(tester, dark);
      await stage.pump(
        NeumorphicListTile(
          title: 'Wi-Fi',
          subtitle: 'Home',
          leading: const NeumorphicWell(
            small: true,
            padding: EdgeInsets.all(8),
            child: SizedBox.square(dimension: 20),
          ),
          onPressed: () {},
        ),
      );
      final rest = await stage.shot();
      await stage.focusByTab();
      final focused = await stage.shot();
      final well = tester.getRect(find.byType(NeumorphicWell));
      expect(
        _changed(rest, focused, outside: well.inflate(1)),
        greaterThan(0),
        reason: 'the row rises',
      );
      expect(
        _changed(rest, focused, inside: well.deflate(1)),
        0,
        reason: 'the well inside it keeps its depth',
      );
    });

    final parts = <String, Widget Function(bool live)>{
      'a key': (live) => Align(
        alignment: AlignmentDirectional.centerStart,
        child: NeumorphicIconButton(
          NeumorphicGlyphs.check,
          label: 'Done',
          onPressed: live ? () {} : null,
        ),
      ),
      'a checkbox': (live) => Align(
        alignment: AlignmentDirectional.centerStart,
        child: NeumorphicCheckbox(
          value: false,
          label: 'Receipt',
          onChanged: live ? (_) {} : null,
        ),
      ),
      'a switch': (live) => Align(
        alignment: AlignmentDirectional.centerStart,
        child: NeumorphicSwitch(
          value: false,
          label: 'Share',
          onChanged: live ? (_) {} : null,
        ),
      ),
    };
    for (final MapEntry(key: name, value: build) in parts.entries) {
      testWidgets('$name out of use keeps its moulding, shallower, by $mode', (
        tester,
      ) async {
        final stage = _Stage(tester, dark);
        await stage.pump(build(true));
        final live = _relief(await stage.shot(), stage.ground);
        await stage.pump(build(false));
        final off = _relief(await stage.shot(), stage.ground);
        // Out of use, its colours move halfway toward the wall, so its light and shade come out about half as strong.
        expect(off, greaterThan(live * .15), reason: 'its relief stays');
        expect(off, lessThan(live * .75), reason: 'shallower than in use');
      });
    }
  }
}

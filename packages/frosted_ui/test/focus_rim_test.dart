// Keyboard focus clears a part's frost and lights its rim; a resting pointer
// only clears it, a little, with no rim light. Every focusable part places a
// FrostedCleared round itself: lit while the keyboard holds it, never under
// a pointer. A filled button, which has no rim of its own, takes a white
// hairline just inside its outline.
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:frosted_ui/frosted_host.dart';
import 'package:frosted_ui/src/frosted/internal/face.dart';

void _none() {}

void _drop(Object? _) {}

final _parts = <String, Widget Function()>{
  'filled button': () => const FrostedButton('Save', onPressed: _none),
  'glass button': () => const FrostedButton.glass('Share', onPressed: _none),
  'field': () => const FrostedTextField(label: 'Title', value: 'Workshop'),
  'list row': () => const FrostedListTile(
    title: 'Print workshop',
    meta: 'Tomorrow',
    onPressed: _none,
  ),
  'chip': () => const FrostedChip('Warm', onPressed: _none),
  'switch': () =>
      const FrostedSwitch(value: false, label: 'Share', onChanged: _drop),
  'check': () =>
      const FrostedCheckbox(value: false, label: 'Walk', onChanged: _drop),
  'radio': () => const FrostedRadioGroup<String>(
    label: 'Plan',
    value: 'free',
    onChanged: _drop,
    options: [FrostedRadio('free', 'Free'), FrostedRadio('pro', 'Pro')],
  ),
  'tab': () => const FrostedTabBar(
    tabs: ['Spending', 'Income'],
    selectedIndex: 0,
    onChanged: _drop,
  ),
  'slider': () => const FrostedSlider(
    value: 40,
    min: 0,
    max: 100,
    label: 'Alert at',
    onChanged: _drop,
  ),
  'card': () => const FrostedCreditCard(
    balance: 1326.44,
    limit: 4000,
    mask: '4821',
    brand: 'Harbor',
    onPressed: _none,
  ),
  'menu row': () => const FrostedMenu<String>(
    items: [
      FrostedMenuItem('new', 'New document'),
      FrostedMenuItem('open', 'Open'),
    ],
    onSelected: _drop,
  ),
};

final _stage = GlobalKey();

Future<void> _pump(WidgetTester t, Widget part, Brightness mode) async {
  t.view.physicalSize = const Size(600, 400);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  final previous = FocusManager.instance.highlightStrategy;
  FocusManager.instance.highlightStrategy =
      FocusHighlightStrategy.alwaysTraditional;
  addTearDown(() => FocusManager.instance.highlightStrategy = previous);
  await t.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (context, page) => FrostedHost(brightness: mode, child: page!),
      home: RepaintBoundary(
        key: _stage,
        child: Center(child: SizedBox(width: 360, child: part)),
      ),
    ),
  );
  await t.pumpAndSettle();
}

Iterable<FrostedCleared> _cleared(WidgetTester t) =>
    t.widgetList<FrostedCleared>(find.byType(FrostedCleared));

void main() {
  for (final MapEntry(key: name, value: part) in _parts.entries) {
    testWidgets('$name: focus lights the rim, a pointer only clears', (
      t,
    ) async {
      await _pump(t, part(), Brightness.light);
      expect(_cleared(t).where((c) => c.lit > 0), isEmpty, reason: 'at rest');

      await t.sendKeyEvent(LogicalKeyboardKey.tab);
      await t.pumpAndSettle();
      final focused = _cleared(t).where((c) => c.level == 1 && c.lit == 1);
      expect(focused, isNotEmpty, reason: 'Tab focus clears and lights');
      final box =
          FocusManager.instance.primaryFocus!.context!.findRenderObject()!
              as RenderBox;
      final centre = box.localToGlobal(box.size.center(Offset.zero));

      FocusManager.instance.primaryFocus?.unfocus();
      await t.pumpAndSettle();
      final mouse = await t.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(mouse.removePointer);
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(centre);
      await t.pumpAndSettle();
      expect(
        _cleared(t).where((c) => c.lit > 0),
        isEmpty,
        reason: 'a pointer never lights the rim',
      );
    });
  }

  testWidgets('a filled button takes a white hairline inside its outline', (
    t,
  ) async {
    await _pump(
      t,
      const Center(child: FrostedButton('Save', onPressed: _none)),
      Brightness.light,
    );
    Future<ui.Color> edgePixel() async {
      final face = t.getRect(find.byType(FrostedFace).first);
      final boundary =
          _stage.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = (await t.runAsync(() => boundary.toImage()))!;
      final data = (await t.runAsync(
        () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
      ))!;
      // The middle of the face's top edge, half a pixel in.
      final x = face.center.dx.round(), y = face.top.ceil();
      final i = (y * image.width + x) * 4;
      image.dispose();
      return ui.Color.fromARGB(
        255,
        data.getUint8(i),
        data.getUint8(i + 1),
        data.getUint8(i + 2),
      );
    }

    final rest = await edgePixel();
    await t.sendKeyEvent(LogicalKeyboardKey.tab);
    await t.pumpAndSettle();
    final lit = await edgePixel();
    expect(
      lit.computeLuminance(),
      greaterThan(rest.computeLuminance() + .3),
      reason: 'rest $rest, focused $lit',
    );
    expect(lit.r, closeTo(lit.g, .02), reason: 'no colour of its own');
    expect(lit.g, closeTo(lit.b, .02), reason: 'no colour of its own');
  });
}

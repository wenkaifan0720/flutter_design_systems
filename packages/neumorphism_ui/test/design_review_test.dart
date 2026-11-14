import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';
import 'package:neumorphism_ui/src/neumorphism/theme.dart'
    show NeumorphicPigment;

import 'support.dart';

double _contrast(Color a, Color b) =>
    (math.max(a.computeLuminance(), b.computeLuminance()) + .05) /
    (math.min(a.computeLuminance(), b.computeLuminance()) + .05);

Color _pixel(ByteData data, int width, int x, int y) {
  final at = (y * width + x) * 4;
  return Color.fromARGB(
    255,
    data.getUint8(at),
    data.getUint8(at + 1),
    data.getUint8(at + 2),
  );
}

Future<void> _pump(
  WidgetTester tester,
  NeumorphicThemeData theme,
  Widget child,
  GlobalKey stage,
) async {
  tester.view.physicalSize = const Size(600, 600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: NeumorphicTheme(
        data: theme,
        child: Center(
          child: RepaintBoundary(
            key: stage,
            child: ColoredBox(
              color: theme.colors.ground,
              child: Padding(padding: const EdgeInsets.all(24), child: child),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadNeumorphicFonts);
  for (final mode in Brightness.values) {
    testWidgets(
      'menu uses a tinted inset and a small keyboard-only lift in ${mode.name}',
      (tester) async {
        final theme = NeumorphicThemeData.porcelain(mode);
        final stage = GlobalKey();
        final previous = FocusManager.instance.highlightStrategy;
        FocusManager.instance.highlightStrategy =
            FocusHighlightStrategy.alwaysTraditional;
        addTearDown(() => FocusManager.instance.highlightStrategy = previous);
        await _pump(
          tester,
          theme,
          NeumorphicMenu<String>(
            items: const [
              NeumorphicMenuItem('one', 'First choice', selected: true),
              NeumorphicMenuItem('two', 'Second choice'),
            ],
            onSelected: (_) {},
          ),
          stage,
        );
        Finder tap(String label) => find.byWidgetPredicate(
          (w) => w is NeumorphicTap && w.label == label,
        );
        final selected = tester.widget<NeumorphicTap>(tap('First choice'));
        expect(
          selected.showFocus,
          isFalse,
          reason: 'autofocus alone does not imply keyboard input',
        );
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(stage),
        );
        final box = tester.renderObject<RenderBox>(tap('First choice'));
        final at = box.localToGlobal(
          Offset(box.size.width - 12, box.size.height / 2),
          ancestor: boundary,
        );
        final image = await tester.runAsync(() => boundary.toImage());
        final bytes = await tester.runAsync(
          () => image!.toByteData(format: ui.ImageByteFormat.rawRgba),
        );
        final fill = _pixel(bytes!, image!.width, at.dx.round(), at.dy.round());
        final expected = Color.alphaBlend(
          theme.colors.pigment.withValues(alpha: .08),
          theme.colors.ground,
        );
        expect(_contrast(fill, expected), lessThan(1.03));
        expect(_contrast(fill, theme.colors.ground), greaterThan(1.01));
        image.dispose();
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pumpAndSettle();
        final keyboard = tester.widget<NeumorphicTap>(tap('Second choice'));
        expect(keyboard.focusNode!.hasFocus, isTrue);
        expect(keyboard.showFocus, isTrue);
        expect(keyboard.focusReach, lessThan(1));
        expect(tester.takeException(), isNull);
      },
      tags: ['goldens'],
    );

    testWidgets(
      'selected menu preserves explicit fill and words in ${mode.name}',
      (tester) async {
        const fill = Color(0xFF203D35), ink = Color(0xFFF6F4E8);
        final stage = GlobalKey();
        await _pump(
          tester,
          NeumorphicThemeData.porcelain(mode),
          NeumorphicMenu<String>(
            items: const [
              NeumorphicMenuItem('active', 'Active', selected: true),
            ],
            onSelected: (_) {},
            style: const NeumorphicStyle(
              fill: WidgetStatePropertyAll(fill),
              foreground: WidgetStatePropertyAll(ink),
              textStyle: WidgetStatePropertyAll(TextStyle(fontSize: 18)),
            ),
          ),
          stage,
        );
        final words = tester.widget<Text>(find.text('Active'));
        expect(words.style!.color, ink);
        expect(words.style!.fontSize, 18);
        final tap = find.byWidgetPredicate(
          (w) => w is NeumorphicTap && w.label == 'Active',
        );
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(stage),
        );
        final box = tester.renderObject<RenderBox>(tap);
        final at = box.localToGlobal(
          Offset(box.size.width - 12, box.size.height / 2),
          ancestor: boundary,
        );
        final image = await tester.runAsync(() => boundary.toImage());
        final bytes = await tester.runAsync(
          () => image!.toByteData(format: ui.ImageByteFormat.rawRgba),
        );
        expect(
          _contrast(
            _pixel(bytes!, image!.width, at.dx.round(), at.dy.round()),
            fill,
          ),
          lessThan(1.03),
        );
        image.dispose();
      },
      tags: ['goldens'],
    );

    testWidgets('selected tab is an accent-coloured recess in ${mode.name}', (
      tester,
    ) async {
      final theme = NeumorphicThemeData.porcelain(mode);
      await _pump(
        tester,
        theme,
        NeumorphicTabBar(
          tabs: const ['Overview', 'Activity'],
          onChanged: (_) {},
        ),
        GlobalKey(),
      );
      final label = find.text('Overview');
      expect(
        tester.widget<Text>(label).style!.color,
        theme.colors.pigmentInkLit,
      );
      // The cells model: the chosen tab is its whole cell pressed in under the pigment's wash; the others are the
      // bank's raised face, with no face of their own.
      bool pressedIn(String text) => tester
          .widgetList<CustomPaint>(
            find.ancestor(
              of: find.text(text),
              matching: find.byType(CustomPaint),
            ),
          )
          .any((w) => w.painter.runtimeType.toString() == '_ChosenCell');
      expect(pressedIn('Overview'), isTrue);
      expect(pressedIn('Activity'), isFalse);
    });

    for (final value in [false, true]) {
      testWidgets('switch note stays secondary in ${mode.name} when $value', (
        tester,
      ) async {
        final theme = NeumorphicThemeData.porcelain(mode);
        await _pump(
          tester,
          theme,
          NeumorphicSwitchRow(
            label: 'Weekly summary',
            note: 'A short update every Friday.',
            value: value,
            onChanged: (_) {},
          ),
          GlobalKey(),
        );
        expect(
          tester
              .widget<Text>(find.text('A short update every Friday.'))
              .style!
              .color,
          theme.colors.inkTertiary,
        );
      });
    }
  }

  for (final value in <bool?>[false, true, null]) {
    testWidgets('checkbox $value keeps its rounded-square inset shape', (
      tester,
    ) async {
      await _pump(
        tester,
        NeumorphicThemeData.porcelain(),
        NeumorphicCheckbox(
          value: value,
          label: 'Remember these details',
          tristate: true,
          onChanged: (_) {},
        ),
        GlobalKey(),
      );
      final face = tester.widget<NeumorphicSurface>(
        find.byType(NeumorphicSurface),
      );
      expect(face.cast, NeumorphicSurfaceLevel.groove);
      expect(face.round, isFalse);
      final outline = face.shape!.getOuterPath(
        const Rect.fromLTWH(0, 0, 28, 28),
      );
      expect(
        outline.contains(const Offset(2, 2)),
        isTrue,
        reason: 'a checkbox is square enough to distinguish it from a radio',
      );
      expect(outline.contains(Offset.zero), isFalse);
      expect(tester.takeException(), isNull);
    });
  }

  // WCAG 1.4.11 asks 3:1 of what a person needs to identify a control or its state, not of every edge. Plaster's night
  // light is a faint rim, so its edges are held to showing, and each state and each part with no words of its own carries
  // a cue at 3:1 that is not a glow. High contrast (the device setting) prints the fine outline at 3:1: plaster_laws_test
  // holds that for every preset by day and by night.
  final palettes = <String, NeumorphicThemeData>{
    for (final brightness in Brightness.values) ...{
      for (final id in NeumorphicThemeData.presets)
        '$id ${brightness.name}': NeumorphicThemeData.preset(id, brightness),
      for (final (name, ground, pigment) in [
        ('custom pale', const Color(0xFFEEEEEE), const Color(0xFFFDFAED)),
        ('custom dark', const Color(0xFF080510), const Color(0xFFB4DF76)),
        ('custom grey', const Color(0xFF777777), const Color(0xFF777777)),
        ('custom saturated', const Color(0xFF00FF00), const Color(0xFFFF00FF)),
      ])
        '$name ${brightness.name}': NeumorphicThemeData.from(
          ground: ground,
          pigment: pigment,
          brightness: brightness,
        ),
    },
  };
  // Labelled parts (a button, a card, a panel, a field): their words or icon say what they are, so the edge only has to
  // show. A switch's or a check's state is held below, through its own cue.
  final parts = <String, Widget Function()>{
    'button': () => NeumorphicButton('Save', onPressed: () {}),
    'field': () => const NeumorphicFieldBox(child: SizedBox(height: 48)),
    'card': () => const NeumorphicCard(children: [SizedBox(height: 80)]),
    'search': () => const NeumorphicSearchField(hint: 'Search'),
    'checkbox': () =>
        NeumorphicCheckbox(value: false, label: 'Agree', onChanged: (_) {}),
  };
  for (final MapEntry(key: name, value: theme) in palettes.entries) {
    for (final MapEntry(key: part, value: build) in parts.entries) {
      testWidgets('$name $part: its edge shows without an outline', (
        tester,
      ) async {
        final stage = GlobalKey(), body = GlobalKey();
        await _pump(
          tester,
          theme,
          SizedBox(
            width: 240,
            child: KeyedSubtree(key: body, child: build()),
          ),
          stage,
        );
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(stage),
        );
        final face = find
            .descendant(
              of: find.byKey(body),
              matching: find.byType(NeumorphicSurface),
            )
            .first;
        final box = tester.renderObject<RenderBox>(face);
        final rect =
            box.localToGlobal(Offset.zero, ancestor: boundary) & box.size;
        final (bytes, width, _) = await _shot(tester, stage);
        final regions = [
          Rect.fromCenter(center: rect.centerLeft, width: 24, height: 6),
          Rect.fromCenter(center: rect.centerRight, width: 24, height: 6),
          Rect.fromCenter(center: rect.topCenter, width: 6, height: 24),
          Rect.fromCenter(center: rect.bottomCenter, width: 6, height: 24),
        ];
        var peak = 1.0, shown = 0;
        for (final area in regions) {
          for (var y = area.top.floor(); y < area.bottom.ceil(); y++) {
            for (var x = area.left.floor(); x < area.right.ceil(); x++) {
              final ratio = _contrast(
                _pixel(bytes, width, x, y),
                theme.colors.ground,
              );
              peak = math.max(peak, ratio);
              if (ratio >= 1.2) shown++;
            }
          }
        }
        debugPrint(
          '$name $part edge peak=${peak.toStringAsFixed(3)} shown=$shown',
        );
        expect(theme.highContrast, isFalse);
        expect(
          peak,
          greaterThanOrEqualTo(1.2),
          reason: 'the light and shadow show the shape on the material',
        );
        expect(shown, greaterThanOrEqualTo(2));
        expect(tester.takeException(), isNull);
      }, tags: ['goldens']);
    }
  }

  // A state reads at 3:1 through its own cue: the pigment of an on track, a chosen figure or a check mark, a knob, a
  // focus lift. The pixels that change from the plain state to this one hold at least a few at 3:1 against the material.
  final states = <String, (double, Widget Function(bool on))>{
    'checked box': (
      240,
      (on) => NeumorphicCheckbox(value: on, label: 'Agree', onChanged: (_) {}),
    ),
    'round check': (
      240,
      (on) => NeumorphicRoundCheckbox(value: on, onChanged: (_) {}),
    ),
    'on switch': (
      240,
      (on) => NeumorphicSwitch(value: on, label: 'Share', onChanged: (_) {}),
    ),
    'chosen radio': (
      240,
      (on) => NeumorphicRadioGroup<String>(
        label: 'Plan',
        options: const [
          NeumorphicRadio('m', 'Monthly'),
          NeumorphicRadio('y', 'Yearly'),
        ],
        value: on ? 'm' : null,
        onChanged: (_) {},
      ),
    ),
    'selected chip': (
      240,
      (on) => NeumorphicChip('Warm', selected: on, onPressed: () {}),
    ),
    'chosen box': (
      240,
      (on) => NeumorphicChoiceBox(
        selected: on,
        onPressed: () {},
        child: const Text('Monthly'),
      ),
    ),
    'chosen segment': (
      240,
      (on) => NeumorphicSegmentedButton<String>(
        label: 'Plan',
        segments: const [
          NeumorphicButtonSegment('m', 'Monthly'),
          NeumorphicButtonSegment('y', 'Yearly'),
        ],
        value: on ? 'm' : 'y',
        onChanged: (_) {},
      ),
    ),
    "slider's value": (
      240,
      (on) => NeumorphicSlider(
        value: on ? .8 : .2,
        label: 'Volume',
        onChanged: (_) {},
      ),
    ),
    'chosen day': (
      344,
      (on) => NeumorphicCalendar(
        controller: DesignCalendarController(
          firstDate: DateTime(2026),
          lastDate: DateTime(2027),
          initialMonth: DateTime(2026, 11),
          currentDate: DateTime(2026, 11, 12),
          selectedDate: on ? DateTime(2026, 11, 18) : null,
        ),
      ),
    ),
  };
  for (final MapEntry(key: name, value: theme) in palettes.entries) {
    for (final MapEntry(key: state, value: (width, build)) in states.entries) {
      testWidgets('$name $state: its cue reaches 3:1', (tester) async {
        final stage = GlobalKey();
        await _pump(
          tester,
          theme,
          SizedBox(width: width, child: build(false)),
          stage,
        );
        final off = await _shot(tester, stage);
        await _pump(
          tester,
          theme,
          SizedBox(width: width, child: build(true)),
          stage,
        );
        final on = await _shot(tester, stage);
        final cue = _cue(off, on, theme.colors.ground);
        debugPrint('$name $state cue=$cue');
        expect(theme.highContrast, isFalse);
        expect(
          cue,
          greaterThanOrEqualTo(_cueFloor),
          reason: 'the state shows at 3:1 through its own mark, not its edge',
        );
        expect(tester.takeException(), isNull);
      }, tags: ['goldens']);
    }
    testWidgets('$name focus: its lift reaches 3:1', (tester) async {
      final previous = FocusManager.instance.highlightStrategy;
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;
      addTearDown(() => FocusManager.instance.highlightStrategy = previous);
      final node = FocusNode();
      addTearDown(node.dispose);
      final stage = GlobalKey();
      await _pump(
        tester,
        theme,
        SizedBox(
          width: 240,
          child: NeumorphicButton('Save', focusNode: node, onPressed: () {}),
        ),
        stage,
      );
      final off = await _shot(tester, stage);
      node.requestFocus();
      await tester.pumpAndSettle();
      final on = await _shot(tester, stage);
      final cue = _cue(off, on, theme.colors.ground);
      debugPrint('$name focus cue=$cue');
      expect(
        cue,
        greaterThanOrEqualTo(_cueFloor),
        reason: 'focus shows at 3:1 through its pigment, not a glow',
      );
    }, tags: ['goldens']);
  }

  // Parts with no words on their face: a cue at 3:1 that is not a glow. A field's label or hint, a check row's words, the
  // caption a slider stands under, a lone round check's mark once it is checked (unchecked it sits beside the words it
  // answers, as in a list row). A bare checkbox's and a slider's own label is spoken, never drawn, so each is pumped as
  // the gallery uses it: the box in its row, the slider under its caption.
  final bare = <String, (Widget Function(), String)>{
    'empty field': (
      () => const NeumorphicTextField(label: 'Full name'),
      'Full name',
    ),
    'empty search': (
      () => const NeumorphicSearchField(hint: 'Search'),
      'Search',
    ),
    'open checkbox': (
      () => NeumorphicCheckRow(value: false, label: 'Agree', onChanged: (_) {}),
      'Agree',
    ),
    'slider track': (
      () => Builder(
        builder: (context) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(
              child: Text(
                'Volume',
                style: NeumorphicTheme.of(context).textTheme.caption,
              ),
            ),
            NeumorphicSlider(value: 0, label: 'Volume', onChanged: (_) {}),
          ],
        ),
      ),
      'Volume',
    ),
  };
  for (final MapEntry(key: name, value: theme) in palettes.entries) {
    for (final MapEntry(key: part, value: (build, words)) in bare.entries) {
      testWidgets('$name $part: its words reach 3:1', (tester) async {
        final stage = GlobalKey();
        await _pump(tester, theme, SizedBox(width: 240, child: build()), stage);
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(stage),
        );
        final text = find.text(words, findRichText: true);
        expect(text, findsWidgets, reason: '$part shows "$words"');
        final box = tester.renderObject<RenderBox>(text.first);
        final rect =
            box.localToGlobal(Offset.zero, ancestor: boundary) & box.size;
        final (bytes, width, height) = await _shot(tester, stage);
        // The words against what is just around them: their darkest-to-lightest spread inside their own box.
        var at3 = 0;
        final behind = _pixel(
          bytes,
          width,
          rect.left.floor(),
          rect.top.floor(),
        );
        for (
          var y = rect.top.floor();
          y < math.min(height, rect.bottom.ceil());
          y++
        ) {
          for (
            var x = rect.left.floor();
            x < math.min(width, rect.right.ceil());
            x++
          ) {
            if (_contrast(_pixel(bytes, width, x, y), behind) >= 3) at3++;
          }
        }
        debugPrint('$name $part words at3=$at3');
        expect(at3, greaterThanOrEqualTo(_cueFloor));
      }, tags: ['goldens']);
    }
  }
}

/// The fewest pixels a cue at 3:1 holds; a check mark, a knob or a figure holds many more.
const _cueFloor = 8;

/// The stage's pixels: bytes, width, height.
Future<(ByteData, int, int)> _shot(WidgetTester tester, GlobalKey stage) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(stage),
  );
  final image = await tester.runAsync(() => boundary.toImage());
  final bytes = await tester.runAsync(
    () => image!.toByteData(format: ui.ImageByteFormat.rawRgba),
  );
  final shot = (bytes!, image!.width, image.height);
  image.dispose();
  return shot;
}

/// The pixels that change from [off] to [on] and, in [on], stand at 3:1 against [ground].
int _cue((ByteData, int, int) off, (ByteData, int, int) on, Color ground) {
  final (a, w, h) = off;
  final (b, w2, h2) = on;
  expect((w2, h2), (w, h), reason: 'the two states lay out the same');
  var count = 0;
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final i = (y * w + x) * 4;
      var moved = false;
      for (var k = 0; k < 3; k++) {
        if ((a.getUint8(i + k) - b.getUint8(i + k)).abs() > 8) moved = true;
      }
      if (moved && _contrast(_pixel(b, w, x, y), ground) >= 3) count++;
    }
  }
  return count;
}

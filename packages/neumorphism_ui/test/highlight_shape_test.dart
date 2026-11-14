// Hover changes nothing (polish round 3, §1). Under the pointer every pressable paints exactly what it paints idle, in
// each corner family; the pointer itself says what a part does: a hand on what presses, the text beam on what takes
// words, grab on what drags, the arrow on what is disabled. A press sinks the part in its own outline, never a
// rectangle, and keyboard focus follows the face it belongs to: outside it, or (a pressed-in
// cell) inside it, its corners the face's moved by the gap, around the same centres.
import 'dart:math' as math;
import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

import 'support.dart';

void _hit() {}

/// How many washes were checked against a face of their own box.
var _faced = <String>{};

/// Whether any test checked a press: they read drawn pixels, so they run where the goldens do.
var _sank = false;

final _parts = <String, Widget Function()>{
  'NeumorphicButton': () => NeumorphicButton('Save', onPressed: _hit),
  'NeumorphicButton.filled': () =>
      NeumorphicButton.filled('Save', onPressed: _hit),
  'NeumorphicButton.text': () =>
      NeumorphicButton.text('Later', onPressed: _hit),
  'NeumorphicButton (destructive)': () =>
      NeumorphicButton('Delete', isDestructiveAction: true, onPressed: _hit),
  'NeumorphicIconButton': () => NeumorphicIconButton(
    NeumorphicGlyphs.plus,
    label: 'Add',
    onPressed: _hit,
  ),
  'NeumorphicRoundButton': () => NeumorphicRoundButton(
    NeumorphicGlyphs.plus,
    label: 'Add',
    onPressed: _hit,
  ),
  'NeumorphicChip': () => NeumorphicChip('Quiet', onPressed: _hit),
  'NeumorphicCheckbox': () =>
      NeumorphicCheckbox(value: false, label: 'Agree', onChanged: (_) {}),
  'NeumorphicCheckRow': () =>
      NeumorphicCheckRow(label: 'Agree', value: false, onChanged: (_) {}),
  'NeumorphicRoundCheckbox': () => NeumorphicRoundCheckbox(onChanged: (_) {}),
  'NeumorphicSwitch': () =>
      NeumorphicSwitch(value: false, label: 'Alerts', onChanged: (_) {}),
  'NeumorphicSwitchRow': () =>
      NeumorphicSwitchRow(label: 'Alerts', value: false, onChanged: (_) {}),
  'NeumorphicRadioGroup': () => NeumorphicRadioGroup<int>(
    label: 'Delivery',
    value: 0,
    options: const [
      NeumorphicRadio(0, 'Standard'),
      NeumorphicRadio(1, 'Express'),
    ],
    onChanged: (_) {},
  ),
  'NeumorphicSegmentedButton': () => NeumorphicSegmentedButton<int>(
    label: 'Period',
    value: 0,
    segments: const [
      NeumorphicButtonSegment(0, 'Day'),
      NeumorphicButtonSegment(1, 'Week'),
    ],
    onChanged: (_) {},
  ),
  'NeumorphicLatchGroup': () => NeumorphicLatchGroup(
    options: const [NeumorphicLatch('Day'), NeumorphicLatch('Night')],
    value: 'Day',
    onChanged: (_) {},
  ),
  'NeumorphicTabBar': () =>
      NeumorphicTabBar(tabs: const ['Overview', 'Activity'], onChanged: (_) {}),
  'NeumorphicSelect': () => NeumorphicSelect<int>(
    label: 'Country',
    value: 0,
    options: const [NeumorphicMenuItem(0, 'Canada')],
    onChanged: (_) {},
  ),
  'NeumorphicSelectField': () =>
      NeumorphicSelectField(value: 'Canada', onPressed: _hit),
  'NeumorphicTextField': () => const NeumorphicTextField(label: 'Name'),
  'NeumorphicSearchField': () => const NeumorphicSearchField(hint: 'Search'),
  'NeumorphicTextArea': () => const NeumorphicTextArea(label: 'Notes'),
  'NeumorphicInputOtp': () => const NeumorphicInputOtp(length: 4),
  'NeumorphicListTile': () =>
      NeumorphicListTile(title: 'Profile', onPressed: _hit),
  'NeumorphicChoiceBox': () => NeumorphicChoiceBox(
    selected: false,
    onPressed: _hit,
    child: const Text('Basic'),
  ),
  'NeumorphicNumberField': () =>
      NeumorphicNumberField(value: '2', onDecrease: _hit, onIncrease: _hit),
  'NeumorphicDisclosure': () => NeumorphicDisclosure(
    title: 'Details',
    expanded: false,
    onExpansionChanged: (_) {},
    child: const Text('More'),
  ),
  'NeumorphicSlider': () =>
      NeumorphicSlider(label: 'Volume', value: .4, onChanged: (_) {}),
  'NeumorphicDatePicker': () => NeumorphicDatePicker(
    value: DateTime(2026, 11, 6),
    first: DateTime(2026, 11, 1),
    last: DateTime(2026, 11, 30),
    onChanged: (_) {},
  ),
  'NeumorphicPagination': () =>
      NeumorphicPagination(count: 12, page: 5, onChanged: (_) {}),
  'NeumorphicBreadcrumb': () => NeumorphicBreadcrumb(
    crumbs: [
      NeumorphicCrumb('Home', onPressed: _hit),
      const NeumorphicCrumb('Kitchen'),
    ],
  ),
  'NeumorphicRating': () =>
      NeumorphicRating(label: 'Rating', value: 3, onChanged: (_) {}),
  'NeumorphicFileUpload': () => NeumorphicFileUpload(onPressed: _hit),
  'NeumorphicTimePicker': () => NeumorphicTimePicker(
    value: const NeumorphicTime(9, 0),
    minuteStep: 30,
    onChanged: (_) {},
  ),
};

/// The pointer over each part: a hand unless named here.
const _cursors = <String, MouseCursor>{
  'NeumorphicTextField': SystemMouseCursors.text,
  'NeumorphicSearchField': SystemMouseCursors.text,
  'NeumorphicTextArea': SystemMouseCursors.text,
  'NeumorphicInputOtp': SystemMouseCursors.text,
  'NeumorphicSlider': SystemMouseCursors.grab,
};

/// Where hover is information (polish round 3, §1): a rating previews the stars it would set.
// A rating previews its score; a day of a month rises under the pointer, its only face until it is chosen.
const _hoverShows = {
  'NeumorphicRating',
  'NeumorphicDatePicker',
  'NeumorphicCalendar',
};

/// Disabled parts: the arrow, and no change under it either.
final _disabled = <String, Widget Function()>{
  'NeumorphicButton': () => const NeumorphicButton('Save'),
  'NeumorphicButton.filled': () => const NeumorphicButton.filled('Save'),
  'NeumorphicIconButton': () =>
      const NeumorphicIconButton(NeumorphicGlyphs.plus, label: 'Add'),
  'NeumorphicChip': () => const NeumorphicChip('Quiet', enabled: false),
  'NeumorphicSwitch': () => const NeumorphicSwitch(value: true, label: 'On'),
  'NeumorphicCheckbox': () =>
      const NeumorphicCheckbox(value: true, label: 'Agree'),
  'NeumorphicTextField': () =>
      const NeumorphicTextField(label: 'Name', enabled: false),
  'NeumorphicSegmentedButton': () => const NeumorphicSegmentedButton<int>(
    label: 'Period',
    value: 0,
    segments: [
      NeumorphicButtonSegment(0, 'Day'),
      NeumorphicButtonSegment(1, 'Week'),
    ],
  ),
};

final _shot = GlobalKey();

/// The part's pixels, as the screen shows them.
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

/// Records the outlines a painter draws or clips to.
class _Paths implements Canvas {
  final paths = <Path>[];
  @override
  dynamic noSuchMethod(Invocation invocation) {
    final args = invocation.positionalArguments;
    if ({#drawPath, #clipPath}.contains(invocation.memberName)) {
      paths.add(Path.from(args.first as Path));
    } else if ({#drawRRect, #clipRRect}.contains(invocation.memberName)) {
      paths.add(Path()..addRRect(args.first as RRect));
    } else if (invocation.memberName == #drawRect) {
      paths.add(Path()..addRect(args.first as Rect));
    }
    if (invocation.memberName == #getSaveCount) return 1;
    return null;
  }
}

/// The corner radius of [path]'s top-left corner, from where the diagonal first enters it. A square corner is 0; a
/// circle or capsule reads its half height.
double _corner(Path path) {
  final b = path.getBounds();
  var lo = 0.0, hi = b.shortestSide / 2;
  for (var i = 0; i < 40; i++) {
    final mid = (lo + hi) / 2;
    if (path.contains(b.topLeft + Offset(mid, mid))) {
      hi = mid;
    } else {
      lo = mid;
    }
  }
  return hi / (1 - math.sqrt(.5));
}

List<(CustomPainter, Size, Element)> _painted(String type) => [
  for (final e in find.byType(CustomPaint).evaluate())
    if ((e.widget as CustomPaint).foregroundPainter.runtimeType.toString() ==
        type)
      (
        (e.widget as CustomPaint).foregroundPainter!,
        (e.renderObject! as RenderBox).size,
        e,
      ),
];

/// The face a highlight lies on: the first painter below it that holds a border and fills the same box. A row's wash
/// lies on the row, which has no face of its own; its marks inside are not its face.
OutlinedBorder? _face(Element highlight, Size box) {
  OutlinedBorder? found;
  void visit(Element e) {
    if (found != null) return;
    final w = e.widget;
    if (w is CustomPaint && w.painter != null) {
      try {
        final border = (w.painter! as dynamic).border;
        final size = (e.renderObject! as RenderBox).size;
        if (border is OutlinedBorder &&
            (size.width - box.width).abs() < 1 &&
            (size.height - box.height).abs() < 1) {
          found = border;
          return;
        }
      } on NoSuchMethodError {
        // Not a face painter.
      }
    }
    e.visitChildren(visit);
  }

  highlight.visitChildren(visit);
  return found;
}

/// A border's shape, apart from its side: what a highlight must share with the face it lights.
Object _kind(OutlinedBorder b) => switch (b) {
  NeumorphicCircleBorder() => 'circle',
  NeumorphicStadiumBorder(:final maxRadius) => ('stadium', maxRadius),
  NeumorphicRoundedBorder(:final radius) => ('rounded', radius),
  _ => b.copyWith(side: BorderSide.none),
};

void main() {
  setUpAll(loadNeumorphicFonts);
  // The comparison with the face is not vacuous: the parts that sink with the look's relief (not the moulded keys,
  // which draw their own depression) are checked against their own face.
  tearDownAll(() {
    if (_sank) {
      expect(
        _faced,
        isNotEmpty,
        reason: 'no press was checked against its face',
      );
    }
  });
  // The look's own corners (corner families are no longer a setting).
  for (final family in const ['drawn']) {
    final theme = NeumorphicThemeData.porcelain();

    Future<void> pump(WidgetTester tester, Widget part) async {
      tester.view.physicalSize = const Size(600, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: NeumorphicTheme(
            data: theme,
            child: MediaQuery(
              data: const MediaQueryData(
                size: Size(600, 800),
                disableAnimations: true,
              ),
              child: Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: RepaintBoundary(
                    key: _shot,
                    child: SizedBox(width: 400, child: part),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    /// The press's relief is the face's own outline: a round part sinks round, a square one square.
    void sinks(String name) {
      _sank = true;
      final reliefs = _painted('_PressRelief');
      for (final (painter, size, element) in reliefs) {
        final border = (painter as dynamic).border as OutlinedBorder?;
        expect(border, isNotNull, reason: '$name: a default rectangle press');
        final canvas = _Paths();
        painter.paint(canvas, size);
        if (canvas.paths.isEmpty) continue;
        final path = canvas.paths.first;
        final r = _corner(path);
        final half = path.getBounds().shortestSide / 2;
        if (border is NeumorphicCircleBorder) {
          expect(
            r,
            closeTo(half, .75),
            reason: '$name: a round part, a round press',
          );
        } else {
          expect(r, greaterThan(.75), reason: '$name: a rounded press');
        }
        final face =
            _face(element, path.getBounds().size) ?? _face(element, size);
        if (face != null) {
          _faced.add(name);
          expect(
            _kind(border!),
            _kind(face),
            reason: '$name: the press is the face\'s own shape',
          );
        }
      }
    }

    Future<TestGesture> hover(WidgetTester tester, Offset at) async {
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: const Offset(1, 1));
      addTearDown(mouse.removePointer);
      await tester.pumpAndSettle();
      await mouse.moveTo(at);
      await tester.pumpAndSettle();
      return mouse;
    }

    for (final MapEntry(key: name, value: build) in _parts.entries) {
      testWidgets(
        '$name $family: hover changes nothing, and the pointer says what it does',
        (tester) async {
          await pump(tester, build());
          final taps = find.byWidgetPredicate(
            (w) => w is NeumorphicTap && w.onPressed != null,
          );
          final fields = find.byType(EditableText);
          final target = taps.evaluate().isNotEmpty
              ? taps.first
              : fields.evaluate().isNotEmpty
              ? fields.first
              : find.byKey(_shot);
          final at = tester.getCenter(target);
          final idle = await _pixels(tester);
          final mouse = await hover(tester, at);
          expect(
            RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1),
            _cursors[name] ?? SystemMouseCursors.click,
            reason: '$name: the pointer over it',
          );
          if (!_hoverShows.contains(name)) {
            final hovered = await _pixels(tester);
            var changed = 0;
            for (var i = 0; i < idle.length; i += 4) {
              if (idle[i] != hovered[i] ||
                  idle[i + 1] != hovered[i + 1] ||
                  idle[i + 2] != hovered[i + 2] ||
                  idle[i + 3] != hovered[i + 3]) {
                changed++;
              }
            }
            expect(
              listEquals(idle, hovered),
              isTrue,
              reason: '$name $family: $changed pixels change under the pointer',
            );
          }
          if (taps.evaluate().isEmpty) return;
          await mouse.down(at);
          await tester.pump(const Duration(milliseconds: 300));
          sinks(name);
          if (name == 'NeumorphicSlider') {
            expect(
              RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1),
              SystemMouseCursors.grabbing,
              reason: 'a held thumb is grabbed',
            );
          }
          await mouse.up();
          await tester.pumpAndSettle();
        },
        tags: ['goldens'],
      );

      testWidgets('$name $family: keyboard focus shows in the material', (
        tester,
      ) async {
        FocusManager.instance.highlightStrategy =
            FocusHighlightStrategy.alwaysTraditional;
        addTearDown(
          () => FocusManager.instance.highlightStrategy =
              FocusHighlightStrategy.automatic,
        );
        await pump(tester, build());
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();
        // A control lifts round its own outline (`_FocusLift`, `_Lift`), the slider round its thumb (`_ThumbLift`); a
        // field, a code's cell and the wheel deepen their groove instead (`_CastPainter.focus`). Never a stroke.
        final lifts = [
          ..._painted('_FocusLift'),
          ..._painted('_Lift'),
          ..._painted('_ThumbLift'),
        ];
        final deepened = find.byType(CustomPaint).evaluate().where((e) {
          final painter = (e.widget as CustomPaint).painter;
          return painter.runtimeType.toString() == '_CastPainter' &&
              ((painter as dynamic).focus as double) > 0;
        });
        expect(
          lifts.isNotEmpty || deepened.isNotEmpty,
          isTrue,
          reason: '$name: focus shows nothing',
        );
        for (final (painter, _, _) in lifts) {
          expect(
            (painter as dynamic).border,
            isA<OutlinedBorder>(),
            reason: '$name: a lift follows the part\'s own outline',
          );
        }
      });
    }

    for (final MapEntry(key: name, value: build) in _disabled.entries) {
      testWidgets('disabled $name $family: the arrow, and no change under it', (
        tester,
      ) async {
        await pump(tester, build());
        final idle = await _pixels(tester);
        await hover(tester, tester.getCenter(find.byKey(_shot)));
        expect(
          RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1),
          SystemMouseCursors.basic,
          reason: '$name: disabled',
        );
        expect(listEquals(idle, await _pixels(tester)), isTrue, reason: name);
      }, tags: ['goldens']);
    }
  }

  testWidgets(
    'an app can still give hover a style: the hook reaches the part',
    (tester) async {
      tester.view.physicalSize = const Size(600, 400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final theme = NeumorphicThemeData.porcelain().copyWith(
        buttonTheme: NeumorphicStyle(
          overlay: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.hovered)
                ? const Color(0x40000000)
                : null,
          ),
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: NeumorphicTheme(
            data: theme,
            child: Center(
              child: RepaintBoundary(
                key: _shot,
                child: NeumorphicButton('Save', onPressed: _hit),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final idle = await _pixels(tester);
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await mouse.moveTo(tester.getCenter(find.byType(NeumorphicButton)));
      await tester.pumpAndSettle();
      expect(listEquals(idle, await _pixels(tester)), isFalse);
    },
    tags: ['goldens'],
  );
}

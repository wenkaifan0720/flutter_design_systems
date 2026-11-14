// Nested and ringed shapes are concentric, measured on the painted paths
// (polish3 §2): a ring, a second line, a selected fill, a thumb or an
// indicator that follows another outline is that outline moved by one
// constant distance, so the gap between the two at the middle of an edge
// equals the gap along each corner's diagonal, within half a pixel. A square
// corner stays square in its ring; an inner corner may close to square.
//
// Every part named there, focused by the keyboard or chosen, in the look's
// corners and strokes. The review renders the same parts at 4x
// (`nestedParts`, `nestedSettings`, `pumpNested`).
import 'dart:math' as math;
import 'dart:ui' show CheckedState, Tristate;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:frosted_ui/frosted_host.dart';

void _noop() {}

void _drop(Object? _) {}

/// A theme the parts are measured in: the look's corners and strokes are
/// its own, so one setting, kept as a list for the review's loop.
typedef NestedSetting = ({String name});

/// The look's corners at its strokes.
final List<NestedSetting> nestedSettings = [(name: 'look')];

/// A part as the review measures it: built, then focused by [tabs] presses
/// of Tab (0 leaves it as built, its chosen face showing; [focusChosen]
/// gives the keyboard's focus to the chosen one, so its ring stands round
/// its chosen face).
typedef NestedPart = ({String name, Widget Function() build, int tabs});

/// [NestedPart.tabs] for a part whose chosen one takes the keyboard's focus.
const focusChosen = -1;

NestedPart _n(String name, Widget Function() build, {int tabs = 1}) =>
    (name: name, build: build, tabs: tabs);

Widget _w(double width, Widget child) => SizedBox(width: width, child: child);

const _three = <FrostedButtonSegment<String>>[
  FrostedButtonSegment('d', 'Day'),
  FrostedButtonSegment('w', 'Week'),
  FrostedButtonSegment('m', 'Month'),
];

const _sizes = <FrostedSelectOption<String>>[
  FrostedSelectOption('s', 'Small'),
  FrostedSelectOption('m', 'Medium'),
];

/// The parts polish3 §2 names, in Frosted's widgets.
final List<NestedPart> nestedParts = [
  _n(
    'Text field',
    () => _w(280, const FrostedTextField(label: 'Name', value: 'Maya')),
  ),
  _n('Search field', () => _w(280, const FrostedSearchField(hint: 'Search'))),
  _n(
    'Text area',
    () => _w(280, const FrostedTextArea(label: 'Notes', value: 'Maya')),
  ),
  _n(
    'Select',
    () => _w(
      280,
      const FrostedSelect<String>(
        label: 'Size',
        value: 'm',
        options: _sizes,
        onChanged: _drop,
      ),
    ),
  ),
  for (final glass in [false, true])
    _n(
      'Button · ${glass ? 'glass' : 'ink'}',
      () => glass
          ? FrostedButton.glass('Book', onPressed: _noop)
          : FrostedButton('Book', onPressed: _noop),
    ),
  _n(
    'Icon button',
    () => const FrostedIconButton(
      FrostedGlyphs.add,
      label: 'Add',
      onPressed: _noop,
    ),
  ),
  _n(
    'Chip',
    () => const FrostedChip('Vegan', onPressed: _noop, selected: true),
  ),
  _n(
    'Checkbox',
    () => const FrostedCheckbox(value: true, label: 'Agree', onChanged: _drop),
  ),
  _n(
    'Radio',
    () => const FrostedRadioGroup<String>(
      label: 'Plan',
      value: 'a',
      options: [FrostedRadio('a', 'Monthly'), FrostedRadio('b', 'Yearly')],
      onChanged: _drop,
    ),
  ),
  _n(
    'Switch',
    () => const FrostedSwitch(value: true, label: 'Wi-Fi', onChanged: _drop),
  ),
  _n(
    'Slider thumb',
    () => _w(
      240,
      const FrostedSlider(value: .4, label: 'Volume', onChanged: _drop),
    ),
  ),
  for (final (i, place) in ['first', 'middle', 'last'].indexed) ...[
    _n(
      'Segmented · $place',
      () => FrostedSegmentedButton<String>(
        segments: _three,
        value: _three[i].value,
        label: 'Range',
        onChanged: _drop,
      ),
      tabs: 0,
    ),
    _n(
      'Tab bar · $place',
      () => _w(
        320,
        FrostedTabBar(
          tabs: const ['Day', 'Week', 'Month'],
          selectedIndex: i,
          onChanged: _drop,
        ),
      ),
      tabs: focusChosen,
    ),
    _n(
      'Step progress · $place',
      () => _w(
        320,
        FrostedStepProgress(count: 3, currentStep: i, name: 'Details'),
      ),
      tabs: 0,
    ),
    _n(
      'Pagination · $place',
      () => FrostedPagination(
        pageCount: 5,
        selectedIndex: i * 2,
        onChanged: _drop,
      ),
      tabs: focusChosen,
    ),
  ],
  _n(
    'Menu item',
    () => _w(
      240,
      const FrostedMenu<String>(
        items: [
          FrostedMenuItem('rename', 'Rename'),
          FrostedMenuItem('share', 'Share'),
        ],
        onSelected: _drop,
      ),
    ),
  ),
  // Frosted's rounded group is the settings tile.
  for (final (tabs, place) in [(1, 'first'), (3, 'last')])
    _n(
      'List row · $place in a group',
      () => _w(
        320,
        const FrostedSettingsGroup(
          children: [
            FrostedValueRow(title: 'Wi-Fi', onPressed: _noop),
            FrostedValueRow(title: 'Bluetooth', onPressed: _noop),
            FrostedValueRow(title: 'Battery', onPressed: _noop),
          ],
        ),
      ),
      tabs: tabs,
    ),
  _n(
    'Date cell',
    () => _w(
      340,
      FrostedCalendar(
        firstDate: DateTime(2026),
        lastDate: DateTime(2026, 12, 31),
        value: DateTime(2026, 11, 10),
        currentDate: DateTime(2026, 11, 12),
        onChanged: _drop,
      ),
    ),
    tabs: focusChosen,
  ),
  _n(
    'Time cell',
    () => const FrostedTimePicker(
      value: FrostedTime(hour: 9, minute: 30),
      onChanged: _drop,
    ),
  ),
  _n(
    'Dialog action',
    () => _w(
      340,
      const FrostedDialog(
        title: 'Discard draft?',
        message: 'Your words go with it.',
        confirmLabel: 'Discard',
        cancelLabel: 'Keep',
        onConfirm: _noop,
        onCancel: _noop,
      ),
    ),
  ),
  _n(
    'Badge on an avatar',
    () => const FrostedBadge(3, child: FrostedAvatar('MA')),
    tabs: 0,
  ),
];

/// The key on the box a review capture takes.
const nestedCapture = ValueKey('nested-cell');

/// [part] in [setting] on Opal by day (or [brightness]), focused as the part
/// says.
Future<void> pumpNested(
  WidgetTester tester,
  NestedPart part,
  NestedSetting setting, {
  Brightness brightness = Brightness.light,
}) async {
  final theme = FrostedThemeData.preset('opal', brightness);
  await tester.pumpWidget(SizedBox(key: ValueKey('${part.name} gap')));
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (BuildContext context, Widget? page) => FrostedHost(
        light: theme,
        dark: theme,
        brightness: brightness,
        child: page!,
      ),
      home: ColoredBox(
        color: theme.colorScheme.background,
        child: Center(
          child: RepaintBoundary(
            key: nestedCapture,
            child: ColoredBox(
              color: theme.colorScheme.background,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: part.build(),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 400));
  for (var i = 0; i < part.tabs; i++) {
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
  }
  if (part.tabs == focusChosen) {
    // A key press puts focus in the keyboard's mode, then the chosen node
    // takes focus as a screen reader would give it.
    await tester.sendKeyEvent(LogicalKeyboardKey.shiftLeft);
    final handle = tester.ensureSemantics();
    await tester.pump();
    final owner = tester.binding.renderViews.first.owner!.semanticsOwner!;
    SemanticsNode? chosen;
    // Where the chosen one stands on the screen.
    Rect? chosenAt;
    bool isChosen(SemanticsData d) =>
        d.flagsCollection.isSelected == Tristate.isTrue ||
        d.flagsCollection.isChecked == CheckedState.isTrue;
    void find(SemanticsNode node, Matrix4 toScreen) {
      final here = switch (node.transform) {
        final m? => toScreen.clone()..multiply(m),
        null => toScreen,
      };
      final d = node.getSemanticsData();
      if (isChosen(d)) {
        // Semantics stand in physical pixels; focus in logical ones.
        final px = MatrixUtils.transformRect(here, node.rect);
        final ratio = tester.view.devicePixelRatio;
        chosenAt ??= Rect.fromLTRB(
          px.left / ratio,
          px.top / ratio,
          px.right / ratio,
          px.bottom / ratio,
        );
        if (d.hasAction(SemanticsAction.focus)) {
          chosen = node;
          return;
        }
      }
      node.visitChildren((child) {
        find(child, here);
        return chosen == null;
      });
    }

    find(owner.rootSemanticsNode!, Matrix4.identity());
    if (chosen case final node?) {
      owner.performAction(node.id, SemanticsAction.focus);
      await tester.pump();
    }
    if (chosenAt case final at?) {
      // A chosen one held by a part that takes the keyboard's focus as one
      // (a calendar's grid: its arrows move the lit day, which starts on the
      // chosen) did not take it: Tab until the keyboard's focus stands over
      // it.
      for (var i = 0; i < 8; i++) {
        final on = FocusManager.instance.primaryFocus;
        if (on != null &&
            on is! FocusScopeNode &&
            on.rect.contains(at.center)) {
          break;
        }
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      }
    }
    await tester.pump();
    handle.dispose();
  }
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// One shape the part painted, in the capture's coordinates.
class _Outline {
  _Outline(this.path, this.paint) : bounds = path.getBounds();

  final Path path;
  final Paint paint;
  final Rect bounds;
}

/// Every filled or stroked shape under [root], shadows and the capture's own
/// ground left out.
List<_Outline> _outlines(RenderBox root) {
  final canvas = TestRecordingCanvas();
  final context = TestRecordingPaintingContext(canvas);
  root.paint(context, Offset.zero);
  context.dispose();
  final ground = Offset.zero & root.size;
  final stack = [Matrix4.identity()];
  final found = <_Outline>[];
  void add(Path path, Paint paint) {
    if (paint.maskFilter != null || paint.imageFilter != null) return;
    // Light glass's floor is added over the whole box inside the face's own
    // clip layer, which a recording canvas never sees: light, not an outline.
    if (paint.blendMode == BlendMode.plus) return;
    final moved = path.transform(stack.last.storage);
    final b = moved.getBounds();
    if (b.width < 4 || b.height < 4) return;
    if (b == ground) return;
    found.add(_Outline(moved, paint));
  }

  for (final call in canvas.invocations) {
    final a = call.invocation.positionalArguments;
    final name = call.invocation.memberName;
    if (name == #save || name == #saveLayer) {
      stack.add(stack.last.clone());
    } else if (name == #restore) {
      if (stack.length > 1) stack.removeLast();
    } else if (name == #translate) {
      stack.last.translateByDouble(a[0] as double, a[1] as double, 0, 1);
    } else if (name == #scale) {
      final sx = a[0] as double;
      final sy = a.length > 1 ? a[1] as double? : null;
      stack.last.scaleByDouble(sx, sy ?? sx, 1, 1);
    } else if (name == #transform) {
      stack.last.multiply(Matrix4.fromList(a[0] as List<double>));
    } else if (name == #drawRect) {
      add(Path()..addRect(a[0] as Rect), a[1] as Paint);
    } else if (name == #drawRRect) {
      add(Path()..addRRect(a[0] as RRect), a[1] as Paint);
    } else if (name == #drawDRRect) {
      add(
        Path()
          ..fillType = PathFillType.evenOdd
          ..addRRect(a[0] as RRect)
          ..addRRect(a[1] as RRect),
        a[2] as Paint,
      );
    } else if (name == #drawRSuperellipse) {
      add(Path()..addRSuperellipse(a[0] as RSuperellipse), a[1] as Paint);
    } else if (name == #drawOval) {
      add(Path()..addOval(a[0] as Rect), a[1] as Paint);
    } else if (name == #drawCircle) {
      add(
        Path()..addOval(
          Rect.fromCircle(center: a[0] as Offset, radius: a[1] as double),
        ),
        a[2] as Paint,
      );
    } else if (name == #drawPath) {
      add(a[0] as Path, a[1] as Paint);
    }
  }
  return found;
}

/// How far along [dir] from [from] the path's outer edge lies, to 1/64.
double? _edge(Path path, Offset from, Offset dir, double reach) {
  double? hit;
  for (var s = 0.0; s <= reach; s += .25) {
    if (path.contains(from + dir * s)) {
      hit = s;
      break;
    }
  }
  if (hit == null) return null;
  var lo = math.max(0.0, hit - .25), hi = hit;
  for (var i = 0; i < 4; i++) {
    final mid = (lo + hi) / 2;
    if (path.contains(from + dir * mid)) {
      hi = mid;
    } else {
      lo = mid;
    }
  }
  return hi;
}

/// What is wrong with the nesting of [outlines]: each pair standing one even
/// distance inside the other (ignoring hairline layers of one face) whose
/// corner gaps differ from its edge gap. Also the number of pairs measured.
(List<String>, int) _nestedFaults(List<_Outline> outlines) {
  final faults = <String>[];
  var pairs = 0;
  const half = math.sqrt1_2;
  final corners = [
    (const Offset(half, half), (Rect r) => r.topLeft),
    (const Offset(-half, half), (Rect r) => r.topRight),
    (const Offset(half, -half), (Rect r) => r.bottomLeft),
    (const Offset(-half, -half), (Rect r) => r.bottomRight),
  ];
  final seen = <String>{};
  for (final a in outlines) {
    for (final b in outlines) {
      if (identical(a, b)) continue;
      final o = a.bounds, i = b.bounds;
      final insets = [
        i.left - o.left,
        i.top - o.top,
        o.right - i.right,
        o.bottom - i.bottom,
      ];
      final d = insets.reduce((x, y) => x + y) / 4;
      if (d < .75 || d > 16) continue;
      if (insets.any((x) => (x - d).abs() > .3)) continue;
      // The same pair painted twice (a fill and its wash) is measured once.
      final key = '${o.toString()}|${i.toString()}';
      if (!seen.add(key)) continue;
      pairs++;
      final reach = math.min(o.width, o.height) / 2;
      final midLeft = Offset(o.left - 1, o.center.dy);
      final ea = _edge(a.path, midLeft, const Offset(1, 0), reach + 1);
      final eb = _edge(b.path, midLeft, const Offset(1, 0), reach + 1);
      if (ea == null || eb == null) continue;
      final edgeGap = eb - ea;
      for (final (dir, corner) in corners) {
        final from = corner(o) - dir;
        final sa = _edge(a.path, from, dir, reach * 1.5 + 1);
        final sb = _edge(b.path, from, dir, reach * 1.5 + 1);
        if (sa == null || sb == null) continue;
        final cornerGap = sb - sa;
        if ((cornerGap - edgeGap).abs() <= .5) continue;
        // b's own corner: how far its edge stands in from its box's corner.
        final ownB = sb - 1 - d * math.sqrt2;
        final ownA = sa - 1;
        final squareB = ownB.abs() < .35;
        final squareA = ownA.abs() < .35;
        if (squareA && squareB) continue; // a square corner stays square
        if (squareB && ownA <= edgeGap * (math.sqrt2 - 1) + .5) continue;
        faults.add(
          '${o.size} ⊃ ${i.size}: edge gap ${edgeGap.toStringAsFixed(2)}, '
          'corner ${cornerGap.toStringAsFixed(2)}',
        );
        break;
      }
    }
  }
  return (faults, pairs);
}

/// The parts that draw one outline, nothing following it, and why: any pair
/// they do draw is still measured, but none is required.
const nestedAlone = {
  'Text field':
      'focus turns the well\'s own edge to the accent; no second '
      'line',
  'Text area':
      'focus turns the well\'s own edge to the accent; no second '
      'line',
  'Slider thumb':
      'the thumb stands over a thinner track, and the keyboard ring rings '
      'the whole slider, not the thumb',
  'Step progress · first': 'display only: segments side by side',
  'Step progress · middle': 'display only: segments side by side',
  'Step progress · last': 'display only: segments side by side',
  'Badge on an avatar': 'the badge overlaps the avatar; it follows no outline',
  'Time cell':
      'wheels, not cells: the chosen row stands in one band across every '
      'wheel, and the keyboard ring rings a whole wheel, not the row',
};

void main() {
  for (final setting in nestedSettings) {
    testWidgets('every nested outline is its outer one moved by one distance '
        '(${setting.name})', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(600, 700);
      addTearDown(tester.view.reset);
      final faults = <String>[];
      for (final part in nestedParts) {
        await pumpNested(tester, part, setting);
        expect(tester.takeException(), isNull, reason: part.name);
        final root = tester.renderObject<RenderBox>(find.byKey(nestedCapture));
        final (wrong, pairs) = _nestedFaults(_outlines(root));
        for (final w in wrong) {
          faults.add('${part.name}: $w');
        }
        if (pairs == 0 && !nestedAlone.containsKey(part.name)) {
          faults.add('${part.name}: nothing nested to measure');
        }
      }
      expect(faults, isEmpty, reason: faults.join('\n'));
    });
  }
}

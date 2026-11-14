// Nested and ringed shapes are concentric, measured on what is painted (polish3 §2). Each part below is pumped in the
// state that draws its second outline (keyboard focus, a choice, a thumb, an active row), its paint calls are recorded,
// and every outline that follows another is measured: the gap from the inner outline's edge midpoints to the outer
// outline, and from its corner's diagonal point, must agree within half a pixel wherever both edges of that corner
// follow the outer outline. Facing edges are measured: a filled shape's own edge, a rim's inner edge, a ring's line.
// What is painted counts, not what is asked for: a fill is cut by the clips around it (an avatar's letters' ground is a
// square cut to the face's circle), and a fill whose edge lies under an opaque rim is not seen (Flutter's
// ShapeDecoration draws its fill half a rim inside the outline, at the outline's radius, so no seam shows under the rim;
// the rim's own edges are what the eye meets). Every corner family and both stroke settings.
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:comic_ui/comic_ui.dart';

// ignore_for_file: avoid_relative_lib_imports
import '../example/lib/main.dart';
import 'support.dart';

/// One painted outline: [kind] is `fill`, `ring` (a stroke's line), `inner` or `outer` (a rim's two edges).
class _Outline {
  _Outline(this.path, this.kind);
  final Path path;
  final String kind;

  /// A fill whose whole edge lies under an opaque rim: it is never seen.
  bool hidden = false;
  late final Rect bounds = path.getBounds();
  late final List<Offset> samples = () {
    final out = <Offset>[];
    for (final metric in path.computeMetrics()) {
      for (var d = 0.0; d <= metric.length; d += .25) {
        final at = metric.getTangentForOffset(d);
        if (at != null) out.add(at.position);
      }
    }
    return out;
  }();

  double distanceTo(Offset p) {
    var best = double.infinity;
    for (final s in samples) {
      final d = (s - p).distance;
      if (d < best) best = d;
    }
    return best;
  }
}

List<_Outline> _record(RenderObject part) {
  final canvas = TestRecordingCanvas();
  part.paint(TestRecordingPaintingContext(canvas), Offset.zero);
  var m = Matrix4.identity();
  Path? clip;
  final stack = <(Matrix4, Path?)>[];
  final out = <_Outline>[];
  // An opaque rim's band, between its outer and inner edges.
  final bands = <(Rect, Rect)>[];
  void add(Path path, String kind) {
    var drawn = path.transform(m.storage);
    if (kind == 'fill' && clip != null) {
      drawn = Path.combine(PathOperation.intersect, drawn, clip!);
      if (drawn.getBounds().isEmpty) return;
    }
    out.add(_Outline(drawn, kind));
  }

  void clipTo(Path path) {
    final region = path.transform(m.storage);
    clip = clip == null
        ? region
        : Path.combine(PathOperation.intersect, clip!, region);
  }

  for (final call in canvas.invocations) {
    final i = call.invocation;
    final a = i.positionalArguments;
    switch (i.memberName) {
      case #save || #saveLayer:
        stack.add((m.clone(), clip));
      case #restore:
        if (stack.isNotEmpty) (m, clip) = stack.removeLast();
      case #clipPath:
        clipTo(a[0] as Path);
      case #clipRRect:
        clipTo(Path()..addRRect(a[0] as RRect));
      case #clipRect:
        clipTo(Path()..addRect(a[0] as Rect));
      case #translate:
        m.multiply(
          Matrix4.translationValues(
            (a[0] as num).toDouble(),
            (a[1] as num).toDouble(),
            0,
          ),
        );
      case #scale:
        final sx = (a[0] as num).toDouble();
        final sy = a.length > 1 && a[1] != null ? (a[1] as num).toDouble() : sx;
        m.multiply(Matrix4.diagonal3Values(sx, sy, 1));
      case #transform:
        m.multiply(Matrix4.fromFloat64List(a[0] as Float64List));
      case #drawRRect:
        final paint = a[1] as Paint;
        add(
          Path()..addRRect(a[0] as RRect),
          paint.style == PaintingStyle.stroke ? 'ring' : 'fill',
        );
      case #drawDRRect:
        add(Path()..addRRect(a[0] as RRect), 'outer');
        add(Path()..addRRect(a[1] as RRect), 'inner');
        if ((a[2] as Paint).color.a == 1) {
          bands.add((out[out.length - 2].bounds, out.last.bounds));
        }
      case #drawPath:
        final paint = a[1] as Paint;
        add(
          a[0] as Path,
          paint.style == PaintingStyle.stroke ? 'ring' : 'fill',
        );
      case #drawCircle:
        final paint = a[2] as Paint;
        add(
          Path()..addOval(
            Rect.fromCircle(
              center: a[0] as Offset,
              radius: (a[1] as num).toDouble(),
            ),
          ),
          paint.style == PaintingStyle.stroke ? 'ring' : 'fill',
        );
      case #drawOval:
        final paint = a[1] as Paint;
        add(
          Path()..addOval(a[0] as Rect),
          paint.style == PaintingStyle.stroke ? 'ring' : 'fill',
        );
      case #drawRect:
        final paint = a[1] as Paint;
        add(
          Path()..addRect(a[0] as Rect),
          paint.style == PaintingStyle.stroke ? 'ring' : 'fill',
        );
      default:
        break;
    }
  }
  for (final o in out.where((o) => o.kind == 'fill')) {
    final b = o.bounds;
    o.hidden = bands.any(
      (band) =>
          band.$1.inflate(.01).contains(b.topLeft) &&
          band.$1.inflate(.01).contains(b.bottomRight) &&
          b.inflate(.01).contains(band.$2.topLeft) &&
          b.inflate(.01).contains(band.$2.bottomRight),
    );
  }
  return out;
}

/// The point on [b]'s outline along its [corner]'s 45° line, from the bounds' corner inwards.
Offset _diagonal(_Outline b, Alignment corner) {
  final r = b.bounds;
  final start = corner.withinRect(r);
  final toward = (r.center - start);
  final step = Offset(toward.dx.sign, toward.dy.sign) / math.sqrt2;
  var lo = 0.0, hi = math.min(r.width, r.height) / 2 * math.sqrt2;
  for (var k = 0; k < 40; k++) {
    final mid = (lo + hi) / 2;
    if (b.path.contains(start + step * mid)) {
      hi = mid;
    } else {
      lo = mid;
    }
  }
  return start + step * hi;
}

/// Failures for [inner] following [outer].
List<String> _concentric(_Outline outer, _Outline inner, String what) {
  final out = <String>[];
  final o = outer.bounds, i = inner.bounds;
  // A line that follows another stands 1 to 8 px off it (a ring, a thumb, an active row, a rim's inner edge). A shape
  // further in is content laid inside (a dialog's button 14 px in from its rim), not a second line of that outline.
  const near = 10.0;
  if (!(i.left > o.left + .5 &&
      i.top > o.top + .5 &&
      i.right < o.right - .5 &&
      i.bottom < o.bottom - .5)) {
    return out;
  }
  if (i.width < 4 || i.height < 4) return out;
  final c = i.center;
  final gaps = {
    'top': outer.distanceTo(Offset(c.dx, i.top)),
    'bottom': outer.distanceTo(Offset(c.dx, i.bottom)),
    'left': outer.distanceTo(Offset(i.left, c.dy)),
    'right': outer.distanceTo(Offset(i.right, c.dy)),
  };
  for (final (corner, a, b) in [
    (Alignment.topLeft, 'top', 'left'),
    (Alignment.topRight, 'top', 'right'),
    (Alignment.bottomLeft, 'bottom', 'left'),
    (Alignment.bottomRight, 'bottom', 'right'),
  ]) {
    final ga = gaps[a]!, gb = gaps[b]!;
    if (ga > near || gb > near) continue;
    if ((ga - gb).abs() > .5) continue; // the inner shape doesn't follow this corner (it slides, or stands off)
    final gd = outer.distanceTo(_diagonal(inner, corner));
    final g = (ga + gb) / 2;
    if ((gd - g).abs() > .5) {
      out.add(
        '$what: ${inner.kind} in ${outer.kind} at $corner: edges ${g.toStringAsFixed(2)}, '
        'diagonal ${gd.toStringAsFixed(2)} (inner $i, outer $o)',
      );
    }
  }
  return out;
}

/// Every pair of painted outlines in [part] where one follows the other.
(List<String>, int) _check(RenderObject part, String what) {
  final outlines = _record(part).where((o) => !o.hidden).toList();
  final failures = <String>[];
  var pairs = 0;
  for (final a in outlines.where((o) => o.kind != 'outer')) {
    for (final b in outlines.where(
      (o) => o.kind == 'fill' || o.kind == 'outer',
    )) {
      if (identical(a, b)) continue;
      final f = _concentric(a, b, what);
      final o = a.bounds, i = b.bounds;
      if (i.left > o.left + .5 &&
          i.top > o.top + .5 &&
          i.right < o.right - .5 &&
          i.bottom < o.bottom - .5) {
        pairs++;
      }
      failures.addAll(f);
    }
  }
  return (failures, pairs);
}

Future<void> _focusIn(WidgetTester tester, Finder part, {int index = 0}) async {
  final nodes = find
      .descendant(of: part, matching: find.byType(Focus))
      .evaluate()
      .map((e) => (e.widget as Focus).focusNode)
      .whereType<FocusNode>()
      .where((n) => n.canRequestFocus && !n.skipTraversal)
      .toList();
  if (nodes.isEmpty) return;
  nodes[math.min(index, nodes.length - 1)].requestFocus();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

typedef _Part = ({String name, Widget Function() build, int? focus});

List<_Part> _parts() {
  final day = DateTime(2026, 11, 9);
  Widget seg(int chosen) => ComicSegmentedButton<int>(
    label: 'View',
    value: chosen,
    segments: const [
      ComicButtonSegment(0, 'Day'),
      ComicButtonSegment(1, 'Week'),
      ComicButtonSegment(2, 'Month'),
    ],
    onChanged: (_) {},
  );
  Widget tabs(int chosen) => ComicTabBar(
    tabs: const ['All', 'Saved', 'Read'],
    selectedIndex: chosen,
    onChanged: (_) {},
  );
  Widget group(bool first) => ComicListSection(
    children: [
      ComicListTile(
        title: 'One',
        isFirst: true,
        selected: first,
        onPressed: () {},
      ),
      const ComicListTile(title: 'Two'),
      ComicListTile(title: 'Three', selected: !first, onPressed: () {}),
    ],
  );
  return [
    (
      name: 'text field',
      build: () => const ComicTextField(label: 'Name', initialValue: 'Alex'),
      focus: 0,
    ),
    (
      name: 'search field',
      build: () => const ComicSearchField(hint: 'Search'),
      focus: 0,
    ),
    (
      name: 'text area',
      build: () => const ComicTextArea(label: 'Notes'),
      focus: 0,
    ),
    (
      name: 'select',
      build: () => ComicSelect<int>(
        label: 'Size',
        value: 1,
        options: const [
          ComicSelectOption(1, 'Small'),
          ComicSelectOption(2, 'Large'),
        ],
        onChanged: (_) {},
      ),
      focus: 0,
    ),
    (
      name: 'act button',
      build: () => ComicButton.filled('Save', onPressed: () {}),
      focus: 0,
    ),
    (
      name: 'line button',
      build: () => ComicButton('Later', onPressed: () {}),
      focus: 0,
    ),
    (
      name: 'icon button',
      build: () => ComicIconButton(
        ComicGlyphs.bell,
        label: 'Alerts',
        selected: true,
        onPressed: () {},
      ),
      focus: 0,
    ),
    (
      name: 'chip',
      build: () => ComicChip('Saved', selected: true, onPressed: () {}),
      focus: 0,
    ),
    (
      name: 'checkbox',
      build: () =>
          ComicCheckbox(value: true, label: 'Agree', onChanged: (_) {}),
      focus: 0,
    ),
    (
      name: 'radio',
      build: () => ComicRadioGroup<int>(
        label: 'Format',
        value: 1,
        options: const [ComicRadio(1, 'Print'), ComicRadio(2, 'Digital')],
        onChanged: (_) {},
      ),
      focus: 0,
    ),
    (
      name: 'switch',
      build: () => ComicSwitch(value: true, label: 'On', onChanged: (_) {}),
      focus: 0,
    ),
    (
      name: 'slider',
      build: () => ComicSlider(label: 'Volume', value: .4, onChanged: (_) {}),
      focus: 0,
    ),
    (name: 'segmented, first chosen', build: () => seg(0), focus: 0),
    (name: 'segmented, middle chosen', build: () => seg(1), focus: 1),
    (name: 'segmented, last chosen', build: () => seg(2), focus: 2),
    (name: 'tabs, first chosen', build: () => tabs(0), focus: 0),
    (name: 'tabs, middle chosen', build: () => tabs(1), focus: 1),
    (name: 'tabs, last chosen', build: () => tabs(2), focus: 2),
    (
      name: 'stepper',
      build: () =>
          ComicNumberField(value: 3, unit: 'nights', onChanged: (_) {}),
      focus: 0,
    ),
    (
      name: 'pagination, first',
      build: () => ComicPagination(count: 10, page: 0, onChanged: (_) {}),
      focus: null,
    ),
    (
      name: 'pagination, middle',
      build: () => ComicPagination(count: 10, page: 4, onChanged: (_) {}),
      focus: null,
    ),
    (
      name: 'pagination, last',
      build: () => ComicPagination(count: 10, page: 9, onChanged: (_) {}),
      focus: 0,
    ),
    (
      name: 'menu item',
      build: () => ComicMenu<int>(
        autofocus: true,
        items: const [
          ComicMenuItem(1, 'Save'),
          ComicMenuItem(2, 'Share'),
          ComicMenuItem(3, 'Print'),
        ],
        onSelected: (_) {},
      ),
      focus: null,
    ),
    (name: 'group, first row', build: () => group(true), focus: null),
    (name: 'group, last row', build: () => group(false), focus: null),
    (
      name: 'date cell',
      build: () =>
          ComicDatePicker(value: day, currentDate: day, onChanged: (_) {}),
      focus: 3,
    ),
    (
      name: 'time picker',
      build: () =>
          ComicTimePicker(value: const ComicTime(9, 30), onChanged: (_) {}),
      focus: 0,
    ),
    (
      name: 'dialog',
      build: () => ComicDialog(
        title: 'Keep it?',
        message: 'It stays in your collection.',
        actions: [
          ComicButton.text('Later', onPressed: () {}),
          ComicButton.filled('Keep', onPressed: () {}),
        ],
      ),
      focus: 1,
    ),
    (
      name: 'sheet',
      build: () => SizedBox(
        height: 260,
        child: ComicBottomSheet(
          title: 'Details',
          onClose: () {},
          child: const Text('More to read.'),
        ),
      ),
      focus: 0,
    ),
    (
      name: 'avatar, chosen',
      build: () => const ComicAvatar('AM', name: 'Alex Morgan', selected: true),
      focus: null,
    ),
  ];
}

void main() {
  setUpAll(() async {
    await loadComicFonts();
  });
  for (final corners in GalleryCorners.values) {
    for (final bold in [false, true]) {
      final custom = GalleryCustom(corners: corners, bold: bold);
      final setting = '${corners.name}${bold ? ', bold' : ''}';
      testWidgets('$setting: every nested outline is concentric', (
        tester,
      ) async {
        FocusManager.instance.highlightStrategy =
            FocusHighlightStrategy.alwaysTraditional;
        addTearDown(
          () => FocusManager.instance.highlightStrategy =
              FocusHighlightStrategy.automatic,
        );
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(480, 900);
        addTearDown(tester.view.reset);
        final failures = <String>[];
        var pairs = 0;
        for (final part in _parts()) {
          const key = ValueKey('part');
          await tester.pumpWidget(
            MaterialApp(
              home: ComicTheme(
                data: custom.theme('offset', Brightness.light),
                child: Builder(
                  builder: (context) => ColoredBox(
                    color: ComicTheme.of(context).colors.background,
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: SizedBox(
                          width: 440,
                          child: KeyedSubtree(key: key, child: part.build()),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 600));
          if (part.focus != null) {
            await _focusIn(tester, find.byKey(key), index: part.focus!);
          }
          expect(tester.takeException(), isNull, reason: part.name);
          final ro = tester.renderObject(find.byKey(key));
          final (f, n) = _check(ro, '$setting / ${part.name}');
          failures.addAll(f);
          pairs += n;
          FocusManager.instance.primaryFocus?.unfocus();
        }
        debugPrint('nested $setting: $pairs nested pairs measured');
        expect(pairs, greaterThan(20));
        expect(failures, isEmpty, reason: failures.join('\n'));
      });
    }
  }
}

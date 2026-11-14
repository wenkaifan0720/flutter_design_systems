// Keylines (design6 P, "Keylines and padding"): the edges a screen's things stand on, read off the screen as drawn.
// In each container (a card, a list section, a settings group, the sidebar) every run of words and every glyph is
// measured by its ink (the pixels of its own colour inside its text box), and every control and face (an avatar, a
// transaction's mark) by its box; words and glyphs inside a control or a face are the control's. Things that share a
// line form a row. A row's leading edge is its first thing's; a row that ends in a thing standing clear of the rest
// (an amount, a switch, a chevron, a value) has a trailing edge. A container keeps one leading keyline and one
// trailing keyline; the controls in one row keep one height.
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// The controls a keyline reads by their face (a control lays out at its face's size; its touch target overhangs).
const keylineControls = {
  'FrostedButton',
  'FrostedIconButton',
  'FrostedSwitch',
  'FrostedSelect',
  'FrostedSegmentedButton',
  'FrostedSearchField',
  'FrostedTextField',
  'FrostedFilterChipGroup',
  'FrostedCheckbox',
  'FrostedStepper',
};

/// The faces a keyline reads by their box: a mark drawn round a glyph or initials.
const keylineFaces = {
  'FrostedTransactionMark',
  'FrostedAvatar',
  'FrostedWordmark',
};

/// The edges one keyline may wander by: anti-aliasing and a glyph's own side bearing (Lucide draws 2 of 24 in from
/// its box, 1.5 at 18).
const keylineTolerance = 2.0;

/// One thing on a keyline: words, a glyph, a control or a face, by its box on the screen.
class KeyMark {
  /// A mark called [what] at [rect].
  KeyMark(this.what, this.rect, {this.control = false});

  /// Its words, or its type.
  final String what;

  /// Its ink's box, or its face's.
  final Rect rect;

  /// Whether it is a control.
  final bool control;

  @override
  String toString() {
    final glyph = what.runes.every((r) => r >= 0xE000 && r <= 0xF8FF);
    final name = glyph
        ? 'a glyph'
        : '"${what.length > 24 ? '${what.substring(0, 24)}…' : what}"';
    String f(double v) => v.toStringAsFixed(1);
    return '$name ${f(rect.left)}–${f(rect.right)} '
        '(y ${f(rect.top)}–${f(rect.bottom)})';
  }
}

/// The screen as drawn, one pixel a logical pixel.
class KeyShot {
  KeyShot._(this.width, this.height, this._px, this.image);

  /// Its size in pixels.
  final int width, height;
  final Uint8List _px;

  /// The image, for drawing keylines over.
  final ui.Image image;

  /// The pixel at ([x], [y]).
  Color at(int x, int y) {
    final i = (y * width + x) * 4;
    return Color.fromARGB(_px[i + 3], _px[i], _px[i + 1], _px[i + 2]);
  }
}

/// [boundary]'s pixels.
Future<KeyShot> keyShot(WidgetTester tester, Finder boundary) async {
  final box = tester.renderObject<RenderRepaintBoundary>(boundary);
  return (await tester.runAsync(() async {
    final image = await box.toImage();
    final data = await image.toByteData();
    return KeyShot._(
      image.width,
      image.height,
      data!.buffer.asUint8List(),
      image,
    );
  }))!;
}

String _typeName(Widget w) => w.runtimeType.toString().split('<').first;

double _distance(Color a, Color b) => math.sqrt(
  math.pow(a.r - b.r, 2) + math.pow(a.g - b.g, 2) + math.pow(a.b - b.b, 2),
);

Color? _inkOf(InlineSpan span) {
  Color? found;
  span.visitChildren((s) {
    final c = s.style?.color ?? s.style?.foreground?.color;
    if (c != null) {
      found = c;
      return false;
    }
    return true;
  });
  return found;
}

/// The columns of [box] holding [ink]: where a pixel is nearer the ink than half the way from the ink to the ground
/// (the box's top row, read as its most common colour).
Rect _inkBox(KeyShot shot, Rect box, Color ink) {
  final l = box.left.floor().clamp(0, shot.width - 1);
  final r = box.right.ceil().clamp(0, shot.width);
  final t = box.top.floor().clamp(0, shot.height - 1);
  final b = box.bottom.ceil().clamp(0, shot.height);
  if (r - l < 1 || b - t < 1) return box;
  final ground = shot.at((l + r) ~/ 2, t);
  final reach = _distance(ink, ground) / 2;
  if (reach < .04) return box;
  int? first, last;
  for (var x = l; x < r; x++) {
    for (var y = t; y < b; y++) {
      if (_distance(shot.at(x, y), ink) < reach) {
        first ??= x;
        last = x;
        break;
      }
    }
  }
  if (first == null) return box;
  return Rect.fromLTRB(first.toDouble(), box.top, last! + 1.0, box.bottom);
}

/// The marks inside [container] on [shot].
List<KeyMark> keyMarks(WidgetTester tester, Finder container, KeyShot shot) {
  final root = container.evaluate().single;
  final marks = <KeyMark>[];
  final screen = Rect.fromLTWH(
    0,
    0,
    shot.width.toDouble(),
    shot.height.toDouble(),
  );
  void visit(Element e) {
    final name = _typeName(e.widget);
    final control = keylineControls.contains(name);
    if (control || keylineFaces.contains(name)) {
      final ro = e.renderObject;
      if (ro is RenderBox && ro.hasSize && ro.attached) {
        final rect = ro.localToGlobal(Offset.zero) & ro.size;
        if (screen.overlaps(rect)) {
          marks.add(KeyMark(name, rect, control: control));
        }
      }
      return;
    }
    final ro = e.renderObject;
    if (e.widget is RichText && ro is RenderParagraph && ro.hasSize) {
      final text = ro.text.toPlainText();
      final ink = _inkOf(ro.text);
      if (text.trim().isNotEmpty && ink != null && ink.a > .3) {
        final boxes = ro.getBoxesForSelection(
          TextSelection(baseOffset: 0, extentOffset: text.length),
        );
        if (boxes.isNotEmpty) {
          var r = boxes.first.toRect();
          for (final b in boxes) {
            r = r.expandToInclude(b.toRect());
          }
          final at = ro.localToGlobal(r.topLeft) & r.size;
          if (screen.contains(at.topLeft) && screen.contains(at.bottomRight)) {
            marks.add(KeyMark(text.trim(), _inkBox(shot, at, ink)));
          }
        }
      }
    }
    e.visitChildren(visit);
  }

  root.visitChildren(visit);
  return marks;
}

/// [marks] in rows: things whose vertical spans overlap, joined through one another, so a title and the note under
/// it are one row through the mark, the switch or the amount beside them both.
List<List<KeyMark>> keyRows(List<KeyMark> marks) {
  final sorted = [...marks]..sort((a, b) => a.rect.top.compareTo(b.rect.top));
  final rows = <List<KeyMark>>[];
  for (final m in sorted) {
    final joined = [
      for (final row in rows)
        if (row.any((o) => _shareLine(o.rect, m.rect))) row,
    ];
    if (joined.isEmpty) {
      rows.add([m]);
      continue;
    }
    final home = joined.first..add(m);
    for (final other in joined.skip(1)) {
      home.addAll(other);
      rows.remove(other);
    }
  }
  return rows;
}

bool _shareLine(Rect a, Rect b) =>
    math.min(a.bottom, b.bottom) - math.max(a.top, b.top) > 2;

/// How far short of its container's furthest edge a row's last thing may end and still be set at the end (an
/// amount, a switch, a chevron); one that ends further in is words set from the start (a link's label), with no
/// trailing edge.
const keylineReach = 20.0;

/// The trailing thing of [row], when one is set at the end: it stands clear right of something beside it on its
/// line and ends within [keylineReach] of [end], the furthest any thing in the container reaches.
KeyMark? keyTrailing(List<KeyMark> row, double end) {
  final last = row.reduce((a, b) => a.rect.right >= b.rect.right ? a : b);
  if (last.rect.right < end - keylineReach) return null;
  final beside = row.where(
    (o) => !identical(o, last) && _shareLine(o.rect, last.rect),
  );
  if (beside.isEmpty) return null;
  final clear = beside.every((o) => o.rect.right + 4 <= last.rect.left);
  return clear ? last : null;
}

double _end(List<List<KeyMark>> rows) =>
    rows.expand((r) => r).map((m) => m.rect.right).reduce(math.max);

/// The distinct values in [edges], each within [keylineTolerance] of its keyline.
List<double> keyClusters(Iterable<double> edges) {
  final sorted = edges.toList()..sort();
  final lines = <double>[];
  for (final e in sorted) {
    if (lines.isEmpty || e - lines.last > keylineTolerance) lines.add(e);
  }
  return lines;
}

/// What [container] breaks of P, each a sentence; empty when it keeps one leading and one trailing keyline and every
/// row's controls share a height.
List<String> keylineFaults(
  String where,
  WidgetTester tester,
  Finder container,
  KeyShot shot,
) {
  final rows = keyRows(keyMarks(tester, container, shot));
  final faults = <String>[];
  if (rows.isEmpty) return faults;
  final leading = <double, List<KeyMark>>{};
  final trailing = <double, List<KeyMark>>{};
  final end = _end(rows);
  for (final row in rows) {
    final first = row.reduce((a, b) => a.rect.left <= b.rect.left ? a : b);
    leading.putIfAbsent(first.rect.left, () => []).add(first);
    final last = keyTrailing(row, end);
    if (last != null) trailing.putIfAbsent(last.rect.right, () => []).add(last);
    final controls = row.where((m) => m.control).toList();
    if (controls.length > 1) {
      final heights = keyClusters(controls.map((c) => c.rect.height));
      if (heights.length > 1) {
        faults.add(
          '$where: controls in one row at heights $heights: $controls',
        );
      }
    }
  }
  String describe(Map<double, List<KeyMark>> edges) {
    final lines = keyClusters(edges.keys);
    return [
      for (final line in lines)
        '${line.toStringAsFixed(1)} (${[for (final e in edges.entries)
          if ((e.key - line).abs() <= keylineTolerance) ...e.value].take(3).join(', ')})',
    ].join('; ');
  }

  if (keyClusters(leading.keys).length > 1) {
    faults.add('$where: leading keylines ${describe(leading)}');
  }
  if (keyClusters(trailing.keys).length > 1) {
    faults.add('$where: trailing keylines ${describe(trailing)}');
  }
  return faults;
}

/// Writes [shot] with each container's keylines drawn over it to `$KEYLINES_OUT/<name>.png` when that variable is
/// set: the review page's Keylines sheet.
Future<void> writeKeylines(
  WidgetTester tester,
  String name,
  KeyShot shot,
  Map<String, Finder> containers,
) async {
  final dir = Platform.environment['KEYLINES_OUT'];
  if (dir == null || dir.isEmpty) return;
  final lines = <(double, Rect)>[];
  for (final finder in containers.values) {
    for (final element in finder.evaluate()) {
      final rows = keyRows(
        keyMarks(tester, find.byElementPredicate((e) => e == element), shot),
      );
      if (rows.isEmpty) continue;
      final box = (element.renderObject! as RenderBox);
      final rect = box.localToGlobal(Offset.zero) & box.size;
      final end = _end(rows);
      for (final row in rows) {
        lines.add((row.map((m) => m.rect.left).reduce(math.min), rect));
        final last = keyTrailing(row, end);
        if (last != null) lines.add((last.rect.right, rect));
      }
    }
  }
  await tester.runAsync(() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)
      ..drawImage(shot.image, Offset.zero, Paint());
    final pen = Paint()
      ..color = const Color(0xCCFF2D55)
      ..strokeWidth = 1;
    for (final (x, rect) in lines) {
      canvas.drawLine(Offset(x, rect.top), Offset(x, rect.bottom), pen);
    }
    final image = await recorder.endRecording().toImage(
      shot.width,
      shot.height,
    );
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    final file = File('$dir/$name.png');
    file.parent.createSync(recursive: true);
    file.writeAsBytesSync(png!.buffer.asUint8List());
  });
}

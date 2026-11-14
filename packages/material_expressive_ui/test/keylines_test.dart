// design6 P, keylines: every screen of the trip planner at a phone's and a
// desktop's width, at touch density (Android) and a pointer's (macOS, the
// compact the web build gets on a desktop), read from its drawn pixels.
//
// Per container (a list section, a card, a page-level surface, a pane of a
// two-pane screen, and the screen's column as the page), two kinds of edge:
// surfaces (a section, a card, a field's or a filled button's container)
// and content (words, glyphs, an avatar, a switch's or a checkbox's ink).
// Each kind's lines start on one keyline, and each end-aligned line ends on
// that keyline mirrored: a glyph's ink, not its box. A line that starts or
// ends more than 32dp off its keyline is a decision (an indent, a value set
// at the end of a short row), not a miss, and is left alone; the misses P
// names are 4 to 24dp. The checkout bar's words stand on the page's margin,
// and controls with a container that share a line share a height and a
// centre. ui_core is getting a shared check; until then this is the look's.
// With EXPRESSIVE_DESIGN_REVIEW_OUT set, the review page's "Keylines" sheet:
// each screen with its keylines drawn over it.
//
// The check reads the drawn pixels, the rasterizer's as a golden's are:
// tagged `goldens`, so macOS runs it and Linux CI leaves it out.
@Tags(['goldens'])
library;

import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';

// ignore_for_file: avoid_relative_lib_imports
import '../example/lib/main.dart';
import '../example/lib/kit_gallery/trip.dart';
import 'gallery_support.dart';

const _capture = ValueKey('keylines');

/// How far two edges may differ and still stand on one keyline: antialiased
/// ink reads up to a pixel either way.
const _slack = 1.5;

/// Past this, an edge off its keyline is a decision, not a miss.
const _window = 32.0;

/// Controls: one mark each, their own words and glyphs inside them.
const _controls = {
  'ExpressiveAvatar',
  'ExpressiveButton',
  'ExpressiveCheckbox',
  'ExpressiveCheckboxRow',
  'ExpressiveDivider',
  'ExpressiveDockedDatePicker',
  'ExpressiveFloatingActionButton',
  'ExpressiveIconButton',
  'ExpressiveLinearProgressIndicator',
  'ExpressiveNumberField',
  'ExpressiveRadio',
  'ExpressiveRadioRow',
  'ExpressiveSearchBar',
  'ExpressiveSegmentedButton',
  'ExpressiveSelect',
  'ExpressiveSlider',
  'ExpressiveSwitch',
  'ExpressiveSwitchRow',
  'ExpressiveTextField',
};

/// Controls drawn as a container (when their ink is a container's height):
/// their edges are surfaces.
const _surfaces = {
  'ExpressiveButton',
  'ExpressiveDockedDatePicker',
  'ExpressiveFloatingActionButton',
  'ExpressiveSearchBar',
  'ExpressiveSegmentedButton',
  'ExpressiveSelect',
  'ExpressiveTextField',
};

/// Labelled rows whose words end where they end.
const _ragged = {
  'ExpressiveCheckboxRow',
  'ExpressiveRadioRow',
  'ExpressiveSwitchRow',
};

/// Bars docked at the window's edge whose content keeps the page's margin.
const _bars = {'checkout-bar'};

String _type(Widget w) {
  // Flutter's button classes (filled, tonal, outlined, elevated, text) are
  // one control: ExpressiveButton.
  if (w is ExpressiveButton) return 'ExpressiveButton';
  final s = w.runtimeType.toString();
  final i = s.indexOf('<');
  return i < 0 ? s : s.substring(0, i);
}

class _Frame {
  _Frame(this.bytes, this.width, this.height);
  final ByteData bytes;
  final int width;
  final int height;

  int at(int x, int y) => bytes.getUint32((y * width + x) * 4);

  static int diff(int a, int b) {
    var d = 0;
    for (var s = 8; s < 32; s += 8) {
      d = math.max(d, (((a >> s) & 0xff) - ((b >> s) & 0xff)).abs());
    }
    return d;
  }
}

class _Mark {
  _Mark(
    this.name,
    this.ink, {
    required this.text,
    required this.surface,
    this.ragged = false,
  });
  final String name;
  final Rect ink;
  final bool text;
  final bool surface;
  final bool ragged;
}

class _Box {
  _Box(this.name, this.rect);
  final String name;
  final Rect rect;
  final marks = <_Mark>[];

  /// Keylines by kind: surface, content.
  final keylines = <bool, double>{};
  final off = <(double, Rect)>[];

  double mirror(double keyline) => rect.right - (keyline - rect.left);
}

/// The bounding box of what [box] draws over its surroundings: the pixels
/// that differ from the commonest colour of a ring just outside it.
Rect? _ink(_Frame f, Rect box, {required int threshold}) {
  final x0 = math.max(0, box.left.floor());
  final x1 = math.min(f.width, box.right.ceil());
  final y0 = math.max(0, box.top.floor());
  final y1 = math.min(f.height, box.bottom.ceil());
  if (x1 <= x0 || y1 <= y0) return null;
  final counts = <int, int>{};
  void ring(int x, int y) {
    if (x < 0 || y < 0 || x >= f.width || y >= f.height) return;
    final c = f.at(x, y);
    counts[c] = (counts[c] ?? 0) + 1;
  }

  for (var x = x0 - 2; x < x1 + 2; x++) {
    ring(x, y0 - 2);
    ring(x, y1 + 1);
  }
  for (var y = y0; y < y1; y++) {
    ring(x0 - 2, y);
    ring(x1 + 1, y);
  }
  if (counts.isEmpty) return null;
  final bg = counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  int? l, t, r, b;
  for (var y = y0; y < y1; y++) {
    for (var x = x0; x < x1; x++) {
      if (_Frame.diff(f.at(x, y), bg) > threshold) {
        l = l == null ? x : math.min(l, x);
        r = r == null ? x + 1 : math.max(r, x + 1);
        t ??= y;
        b = y + 1;
      }
    }
  }
  if (l == null) return null;
  return Rect.fromLTRB(
    l.toDouble(),
    t!.toDouble(),
    r!.toDouble(),
    b!.toDouble(),
  );
}

Rect? _rectOf(Element e) {
  final ro = e.renderObject;
  if (ro is! RenderBox || !ro.attached || !ro.hasSize) return null;
  return ro.localToGlobal(Offset.zero) & ro.size;
}

/// The marks of each container, from the elements on stage.
List<_Box> _collect(WidgetTester tester, _Frame frame) {
  final boxes = <_Box>[];
  final screen = Rect.fromLTWH(
    0,
    0,
    frame.width.toDouble(),
    frame.height.toDouble(),
  );

  _Box open(_Box? parent, String name, Rect rect) {
    parent?.marks.add(_Mark(name, rect, text: false, surface: true));
    final box = _Box(name, rect);
    boxes.add(box);
    return box;
  }

  void visit(Element e, _Box? box, bool inControl, bool inRow) {
    final w = e.widget;
    final type = _type(w);
    var next = box;
    var inside = inControl;
    final rect = _rectOf(e);
    if (!inControl && rect != null && rect.overlaps(screen)) {
      final bar = _bars.where((k) => w.key == ValueKey(k)).firstOrNull;
      // A section or a card is the app's; a surface is, standing on the page
      // (the parts draw their own insides with surfaces too); so is a pane,
      // an expanded child of a row across a page.
      final pane =
          inRow &&
          w is Expanded &&
          box != null &&
          box.name == 'page' &&
          box.rect.width >= 600 &&
          rect.width >= 0.3 * box.rect.width;
      final opens =
          box != null &&
          rect.width >= 120 &&
          (w is ExpressiveListSection ||
              w is ExpressiveCard ||
              (w is ExpressiveSurface && box.name.startsWith('page')));
      if (w.key == const ValueKey('trip-column')) {
        next = open(null, 'page', rect);
      } else if (box == null && bar != null) {
        next = open(null, bar, rect);
      } else if (pane) {
        next = open(box, 'page pane ${rect.left.round()}', rect);
      } else if (opens) {
        next = open(
          box,
          w is ExpressiveListSection
              ? 'section "${w.header ?? ''}"'
              : '${type.replaceFirst('Expressive', '')} ${w.key ?? ''}'.trim(),
          rect,
        );
      } else if (box != null &&
          (_controls.contains(type) ||
              (w is ExpressiveSurface && rect.width < 120))) {
        final ink = _ink(frame, rect, threshold: 8);
        if (ink != null) {
          box.marks.add(
            _Mark(
              type,
              ink,
              text: false,
              surface: _surfaces.contains(type) && ink.height >= 28,
              ragged: _ragged.contains(type),
            ),
          );
        }
        inside = true;
      } else if (box != null && w is RichText) {
        final ink = _ink(frame, rect, threshold: 40);
        final text = w.text.toPlainText().trim();
        if (ink != null) {
          box.marks.add(
            _Mark(
              text.length > 24 ? '"${text.substring(0, 24)}…"' : '"$text"',
              ink,
              text: true,
              surface: false,
            ),
          );
        }
      }
    }
    final row = w is Flex && w.direction == Axis.horizontal;
    e.debugVisitOnstageChildren((c) => visit(c, next, inside, row));
  }

  visit(tester.binding.rootElement!, null, false, false);
  return boxes;
}

/// The marks grouped into lines: marks whose ink overlaps vertically.
List<List<_Mark>> _lines(List<_Mark> marks) {
  final parent = List<int>.generate(marks.length, (i) => i);
  int root(int i) => parent[i] == i ? i : parent[i] = root(parent[i]);
  for (var i = 0; i < marks.length; i++) {
    for (var j = i + 1; j < marks.length; j++) {
      final a = marks[i].ink, b = marks[j].ink;
      final overlap = math.min(a.bottom, b.bottom) - math.max(a.top, b.top);
      if (overlap > 0.3 * math.min(a.height, b.height)) {
        parent[root(i)] = root(j);
      }
    }
  }
  final groups = <int, List<_Mark>>{};
  for (var i = 0; i < marks.length; i++) {
    (groups[root(i)] ??= []).add(marks[i]);
  }
  return groups.values.toList()
    ..sort((a, b) => a.first.ink.top.compareTo(b.first.ink.top));
}

/// The value most of [values] stand on.
double _mode(List<double> values) {
  final sorted = [...values]..sort();
  var best = sorted.first, bestCount = 0;
  for (final v in sorted) {
    final n = sorted.where((u) => (u - v).abs() <= _slack).length;
    if (n > bestCount) {
      best = v;
      bestCount = n;
    }
  }
  return best;
}

Rect _union(Iterable<_Mark> marks) =>
    marks.map((m) => m.ink).reduce((a, b) => a.expandToInclude(b));

String _kind(bool surface) => surface ? 'surface' : 'content';

/// The findings of [boxes], and the keylines recorded on each box.
List<String> _check(List<_Box> boxes) {
  final findings = <String>[];
  _Box? page;
  for (final box in boxes) {
    if (box.name == 'page') page = box;
    final lines = _lines(box.marks);
    if (lines.isEmpty) continue;
    final firsts = [
      for (final l in lines)
        l.reduce((a, b) => a.ink.left <= b.ink.left ? a : b),
    ];
    for (final surface in [true, false]) {
      final leads = [
        for (final m in firsts)
          if (m.surface == surface) m.ink.left,
      ];
      if (leads.isNotEmpty) box.keylines[surface] = _mode(leads);
    }
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final first = firsts[i];
      final keyline = box.keylines[first.surface]!;
      final lead = first.ink.left;
      final miss = (lead - keyline).abs();
      if (miss > _slack && miss <= _window) {
        box.off.add((lead, _union(line)));
        findings.add(
          '${box.name}: ${first.name} starts at ${lead.round()}, its '
          '${_kind(first.surface)} keyline at ${keyline.round()}',
        );
      }
      // The end: a line whose last mark is a control, a container, or a
      // value set at the end (words starting past the middle).
      final last = line.reduce((a, b) => a.ink.right >= b.ink.right ? a : b);
      final ends =
          !last.ragged &&
          ((line.length > 1 &&
                  (!last.text || last.ink.left > box.rect.center.dx)) ||
              (line.length == 1 &&
                  !last.text &&
                  last.ink.width > box.rect.width / 2));
      final own = box.keylines[last.surface];
      if (ends && own != null) {
        final mirror = box.mirror(own);
        final end = (last.ink.right - mirror).abs();
        if (end > _slack && end <= _window) {
          box.off.add((last.ink.right, _union(line)));
          findings.add(
            '${box.name}: ${last.name} ends at ${last.ink.right.round()}, '
            'its ${_kind(last.surface)} keyline at ${mirror.round()}',
          );
        }
      }
      // Controls with a container that share a line: one height, one
      // centre.
      final controls = [
        for (final m in line)
          if (m.surface && _controls.contains(m.name)) m,
      ];
      for (final c in controls.skip(1)) {
        final a = controls.first.ink;
        if ((c.ink.height - a.height).abs() > 1 ||
            (c.ink.center.dy - a.center.dy).abs() > 1) {
          findings.add(
            '${box.name}: ${c.name} ${c.ink.height.round()} high at '
            '${c.ink.center.dy.toStringAsFixed(1)} beside '
            '${controls.first.name} ${a.height.round()} high at '
            '${a.center.dy.toStringAsFixed(1)}',
          );
        }
      }
    }
  }
  // A bar across the window keeps its words on the page's margin.
  for (final box in boxes) {
    final words = box.keylines[false];
    if (page != null &&
        words != null &&
        _bars.contains(box.name) &&
        (words - page.rect.left).abs() > _slack) {
      findings.add(
        '${box.name}: its content starts at ${words.round()}, '
        "the page's margin at ${page.rect.left.round()}",
      );
    }
  }
  return findings;
}

Future<_Frame> _grab(WidgetTester tester) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_capture),
  );
  late _Frame frame;
  await tester.runAsync(() async {
    final image = await boundary.toImage();
    try {
      final bytes = (await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      ))!;
      frame = _Frame(bytes, image.width, image.height);
    } finally {
      image.dispose();
    }
  });
  return frame;
}

/// The screen with its keylines over it: each container's surface keyline
/// in blue and content keyline in green (leading and mirrored trailing),
/// what stands off them in red.
Future<void> _sheet(WidgetTester tester, List<_Box> boxes, String path) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_capture),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage();
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)..drawImage(image, Offset.zero, Paint());
    final paints = {
      true: Paint()
        ..color = const Color(0xB02962FF)
        ..strokeWidth = 1,
      false: Paint()
        ..color = const Color(0xC000A86B)
        ..strokeWidth = 1,
    };
    final off = Paint()
      ..color = const Color(0xE0E0002A)
      ..strokeWidth = 2;
    for (final b in boxes) {
      for (final MapEntry(key: surface, value: x) in b.keylines.entries) {
        for (final at in [x, b.mirror(x)]) {
          canvas.drawLine(
            Offset(at, b.rect.top),
            Offset(at, b.rect.bottom),
            paints[surface]!,
          );
        }
      }
      for (final (x, r) in b.off) {
        canvas.drawLine(Offset(x, r.top - 2), Offset(x, r.bottom + 2), off);
      }
    }
    final drawn = await recorder.endRecording().toImage(
      image.width,
      image.height,
    );
    final png = await drawn.toByteData(format: ui.ImageByteFormat.png);
    File(path)
      ..parent.createSync(recursive: true)
      ..writeAsBytesSync(png!.buffer.asUint8List());
    drawn.dispose();
    image.dispose();
  });
}

void main() {
  setUpAll(loadExpressiveFonts);
  final output = Platform.environment['EXPRESSIVE_DESIGN_REVIEW_OUT'];
  final densities = TargetPlatformVariant(const {
    TargetPlatform.android,
    TargetPlatform.macOS,
  });

  for (final screen in TripScreens.all) {
    for (final width in [390.0, 1440.0]) {
      testWidgets('$screen ${width.round()}: one keyline per container', (
        tester,
      ) async {
        tester.view.devicePixelRatio = 1;
        // Tall enough that a phone's screen shows all of its content.
        tester.view.physicalSize = Size(width, width < 600 ? 1700 : 1100);
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          RepaintBoundary(
            key: _capture,
            child: GalleryApp(
              key: ValueKey('$screen/$width/${defaultTargetPlatform.name}'),
              initialPage: screen,
            ),
          ),
        );
        await settle(tester);
        expect(tester.takeException(), isNull);
        final frame = await _grab(tester);
        final boxes = _collect(tester, frame);
        final findings = _check(boxes);
        final density = defaultTargetPlatform == TargetPlatform.macOS
            ? 'compact'
            : 'standard';
        // The measurements, for the log.
        // ignore: avoid_print
        print(
          [
            'KEYLINES $screen ${width.round()} $density',
            for (final b in boxes)
              '  ${b.name} ${b.rect.left.round()}..${b.rect.right.round()}: '
                  'surface ${b.keylines[true]?.round()}, '
                  'content ${b.keylines[false]?.round()}, '
                  '${b.marks.length} marks',
            for (final f in findings) '  ! $f',
          ].join('\n'),
        );
        if (output != null) {
          await _sheet(
            tester,
            boxes,
            '$output/keylines/${screen}_${width.round()}_$density.png',
          );
        }
        expect(findings, isEmpty);
      }, variant: densities);
    }
  }
}

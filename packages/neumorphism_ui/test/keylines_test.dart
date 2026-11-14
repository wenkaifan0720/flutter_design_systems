// Keylines and padding (design6 P), measured on every Hearth screen and the Overview at a phone's and a desk's width.
// In each card, slab, list section and form group:
// - every line starts on the container's keyline, or on the one column of words that follows a glyph or a face
//   standing on that keyline (a list row's words; what stands under them, a stepper, a slider, is in that column too);
// - every line that places something at its end ends on one trailing keyline, and so does everything that runs from
//   the keyline (a field, a rule);
// - the controls that share a line share a height and a centre.
// Things are measured by what is drawn: words by their glyphs' boxes, an icon by its ink (Lucide strokes a 24 grid
// from one unit in), a part that composes several (a dial, a stepper, a segmented control, a switch) as the union of
// its faces and words, not its tap box, which may hang outside the keyline. Lines are the things whose heights overlap.
import 'dart:convert';
import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';
import 'package:ui_core/alignment.dart' show DesignKeylineCheck;

// ignore: avoid_relative_lib_imports
import '../example/lib/main.dart';
// ignore: avoid_relative_lib_imports
import '../example/lib/kit_gallery/hearth.dart';
// ignore: avoid_relative_lib_imports
import '../example/lib/kit_gallery/live.dart' show liveGalleryPages;
import 'gallery_support.dart' show loadBundledFonts, settle;
import 'support.dart' show loadNeumorphicFonts;

/// The parts that hold a keyline: a card, a slab, a list's section, a form's group.
const _containers = {
  NeumorphicCard,
  NeumorphicSlab,
  NeumorphicListSection,
  NeumorphicFormGroup,
};

/// Parts measured whole: what they draw inside is theirs to place.
const _parts = {
  'NeumorphicDial',
  'NeumorphicNumberField',
  'NeumorphicSegmentedButton',
  'NeumorphicStats',
  'NeumorphicRelief',
  'NeumorphicSlider',
  'NeumorphicRangeSlider',
  'NeumorphicSwitch',
  'NeumorphicAvatar',
};

/// Parts that paint what they are (a dial's ring, the house): measured by their box.
const _painted = {'NeumorphicDial', 'NeumorphicRelief', 'NeumorphicStats'};

/// A widget's class, its type arguments aside (a segmented control of strings is a segmented control).
String _type(Widget w) => '${w.runtimeType}'.split('<').first;

/// How close two edges are to count as one.
const _tolerance = 2.0;

enum _Kind { words, glyph, face, part, rule }

/// One thing on a line: what is drawn of it, what it is, and whether it is pressed or typed into.
typedef _Item = ({Rect rect, String what, _Kind kind, bool control});

Rect _box(RenderObject ro) {
  final box = ro as RenderBox;
  return box.localToGlobal(Offset.zero) & box.size;
}

bool _hidden(Element e) {
  var hidden = false;
  e.visitAncestorElements((a) {
    final w = a.widget;
    if ((w is Opacity && w.opacity == 0) ||
        (w is Offstage && w.offstage) ||
        (w is Visibility && !w.visible)) {
      hidden = true;
      return false;
    }
    return true;
  });
  return hidden;
}

bool _isGlyph(RenderParagraph p) {
  final text = p.text.toPlainText();
  final style = p.text is TextSpan ? (p.text as TextSpan).style : null;
  return text.runes.length == 1 &&
      '${style?.fontFamily}'.toLowerCase().contains('lucide');
}

/// What a paragraph draws: its glyphs' boxes, or an icon's ink.
Rect? _ink(RenderParagraph p) {
  final text = p.text.toPlainText();
  if (text.trim().isEmpty || !p.hasSize) return null;
  final origin = p.localToGlobal(Offset.zero);
  if (_isGlyph(p)) return (origin & p.size).deflate(p.size.shortestSide / 24);
  final boxes = p.getBoxesForSelection(
    TextSelection(baseOffset: 0, extentOffset: text.length),
  );
  if (boxes.isEmpty) return null;
  return boxes
      .map((b) => b.toRect())
      .reduce((a, b) => a.expandToInclude(b))
      .shift(origin);
}

/// What a part draws: its faces, its banks and its words, or its box when it draws none.
Rect _drawn(Element part) {
  Rect? r;
  void visit(Element e) {
    final ro = e.renderObject;
    Rect? here;
    // A face, or a bank of cells (a segmented control's track, which paints its own well).
    if ((e.widget is NeumorphicSurface ||
            _type(e.widget) == 'NeumorphicCellBank') &&
        ro is RenderBox &&
        ro.hasSize) {
      here = _box(ro);
    } else if (e.widget is RichText && ro is RenderParagraph && !_hidden(e)) {
      here = _ink(ro);
    }
    if (here != null) r = r == null ? here : r!.expandToInclude(here);
    e.visitChildren(visit);
  }

  part.visitChildren(visit);
  return r ?? _box(part.renderObject!);
}

typedef _Container = ({String name, Rect rect, List<_Item> items});

/// Every container on screen with the things it holds itself (a nested container's are its own).
List<_Container> _measure(WidgetTester tester) {
  final byElement = <Element, _Container>{};
  void add(Element container, _Item item) {
    final slot = byElement.putIfAbsent(container, () {
      final r = _box(container.renderObject!);
      final key = container.widget.key;
      return (
        name:
            '${container.widget.runtimeType}${key == null ? '' : ' $key'} at '
            '${r.left.round()},${r.top.round()} ${r.width.round()}x${r.height.round()}',
        rect: r,
        items: <_Item>[],
      );
    });
    if (!slot.items.any((i) => i.rect == item.rect)) slot.items.add(item);
  }

  for (final e in tester.allElements) {
    final w = e.widget;
    final ro = e.renderObject;
    final isPart = _parts.contains(_type(w));
    final isText = w is RichText && ro is RenderParagraph;
    final isRule = w is NeumorphicDivider;
    if ((!isPart && !isText && !isRule) || _hidden(e)) continue;
    Element? container;
    Element? part;
    final faces = <Element>[];
    var control = false;
    e.visitAncestorElements((a) {
      if (_containers.contains(a.widget.runtimeType)) {
        container = a;
        return false;
      }
      if (_parts.contains(_type(a.widget))) part = a;
      if (a.widget is NeumorphicSurface) faces.add(a);
      if (a.widget is DesignPressable || a.widget is EditableText) {
        control = true;
      }
      return true;
    });
    if (container == null || part != null) continue;
    final inner = _box(container!.renderObject!);
    if (isPart) {
      final controlPart =
          w is! NeumorphicDial &&
          w is! NeumorphicStats &&
          w is! NeumorphicRelief &&
          w is! NeumorphicAvatar;
      add(container!, (
        rect: _painted.contains(_type(w)) ? _box(ro!) : _drawn(e),
        what: _type(w),
        kind: _Kind.part,
        control: controlPart,
      ));
      continue;
    }
    // A face inside the container that is not a band across it (a chosen row's, a pressed row's) is the thing on
    // the line; otherwise the words, the glyph or the rule themselves.
    Element? face;
    for (final s in faces) {
      if (_box(s.renderObject!).width >= inner.width * .9) continue;
      face = s;
    }
    if (face != null) {
      add(container!, (
        rect: _box(face.renderObject!),
        what: 'a face',
        kind: _Kind.face,
        control: control,
      ));
    } else if (isRule) {
      add(container!, (
        rect: _box(ro!),
        what: 'a rule',
        kind: _Kind.rule,
        control: false,
      ));
    } else {
      final p = ro as RenderParagraph;
      final ink = _ink(p);
      if (ink == null) continue;
      add(container!, (
        rect: ink,
        what: _isGlyph(p) ? 'a glyph' : '"${p.text.toPlainText()}"',
        kind: _isGlyph(p) ? _Kind.glyph : _Kind.words,
        control: false,
      ));
    }
  }
  return byElement.values.toList();
}

/// The lines of a container: things whose heights overlap, joined through one another, each in reading order.
List<List<_Item>> _lines(List<_Item> items) {
  final lines = <List<_Item>>[];
  for (final i in items) {
    final touching = [
      for (final l in lines)
        if (l.any(
          (o) =>
              i.rect.top < o.rect.bottom - 2 && o.rect.top < i.rect.bottom - 2,
        ))
          l,
    ];
    final line = [i, for (final l in touching) ...l];
    lines
      ..removeWhere(touching.contains)
      ..add(line);
  }
  for (final l in lines) {
    l.sort((a, b) => a.rect.left.compareTo(b.rect.left));
  }
  return lines;
}

/// Distinct edges, each with what stands on it.
Map<double, List<String>> _edges(Iterable<(double, String)> edges) {
  final out = <double, List<String>>{};
  for (final (x, what) in edges) {
    final near = out.keys.where((k) => (k - x).abs() <= _tolerance);
    (near.isEmpty ? (out[x] = []) : out[near.first]!).add(what);
  }
  return out;
}

String _show(Map<double, List<String>> edges) => {
  for (final MapEntry(:key, :value) in edges.entries)
    key.toStringAsFixed(1): value,
}.toString();

List<String> _faults(WidgetTester tester) {
  final faults = <String>[];
  for (final c in _measure(tester)) {
    final lines = _lines(c.items);
    if (lines.isEmpty) continue;
    final keyline = lines
        .map((l) => l.first.rect.left)
        .reduce((a, b) => a < b ? a : b);
    bool on(double x, double k) => (x - k).abs() <= _tolerance;
    // The words column: what follows a glyph or a face that stands on the keyline.
    final columns = _edges([
      for (final l in lines)
        if (l.length > 1 &&
            on(l.first.rect.left, keyline) &&
            l.first.kind != _Kind.words)
          (l[1].rect.left, l[1].what),
    ]);
    if (columns.length > 1) {
      faults.add(
        '${c.name}: ${columns.length} columns of words ${_show(columns)}',
      );
    }
    final starts = _edges([
      for (final l in lines)
        if (!on(l.first.rect.left, keyline) &&
            !columns.keys.any((k) => on(l.first.rect.left, k)))
          (l.first.rect.left, l.first.what),
    ]);
    if (starts.isNotEmpty) {
      faults.add(
        '${c.name}: lines start off the keyline ${keyline.toStringAsFixed(1)} '
        'and the words column ${columns.keys.map((k) => k.toStringAsFixed(1))}: ${_show(starts)}',
      );
    }
    final mid = c.rect.center.dx;
    final ends = _edges([
      for (final l in lines)
        if ((l.length > 1 && l.last.rect.left > mid) ||
            (l.length == 1 &&
                (l.single.kind == _Kind.rule ||
                    (l.single.kind != _Kind.words &&
                        on(l.single.rect.left, keyline) &&
                        l.single.rect.right > mid))))
          (l.last.rect.right, l.last.what),
    ]);
    if (ends.length > 1) {
      faults.add('${c.name}: ${ends.length} trailing edges ${_show(ends)}');
    }
    for (final l in lines) {
      final controls = l.where((i) => i.control).toList();
      if (controls.length < 2) continue;
      final heights = {for (final i in controls) i.rect.height.round()};
      final centres = {for (final i in controls) i.rect.center.dy.round()};
      if (heights.length > 1 || centres.length > 1) {
        faults.add(
          '${c.name}: one line, controls of heights $heights centres $centres: '
          '${controls.map((i) => i.what).join(', ')}',
        );
      }
    }
  }
  return faults;
}

/// For the review page: with REVIEW_OUT set, what the probe measured on a screen (containers, their lines and items)
/// and what it found, as `keylines-probe-<screen>-<width>.json`.
void _record(
  String screen,
  double width,
  List<_Container> measured,
  List<String> faults,
) {
  final out = Platform.environment['REVIEW_OUT'];
  if (out == null) return;
  File('$out/keylines-probe-$screen-${width.toInt()}.json').writeAsStringSync(
    jsonEncode({
      'screen': screen,
      'width': width.toInt(),
      'containers': measured.length,
      'lines': [for (final c in measured) _lines(c.items).length]
          .fold(0, (a, b) => a + b),
      'items': [for (final c in measured) c.items.length]
          .fold(0, (a, b) => a + b),
      'faults': faults,
    }),
  );
}

void main() {
  setUpAll(() async {
    await loadNeumorphicFonts();
    await loadBundledFonts();
  });

  for (final screen in ['overview', for (final s in hearthScreens) s.id]) {
    for (final width in [390.0, 1440.0]) {
      testWidgets('$screen keeps its keylines at $width', (tester) async {
        tester.view.physicalSize = Size(width, width < 600 ? 844 : 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(GalleryApp(initialPage: screen));
        await settle(tester);
        final faults = _faults(tester);
        _record(screen, width, _measure(tester), faults);
        expect(faults, isEmpty, reason: faults.join('\n'));
      });
    }
  }

  // ui_core's check over the regions the look marks (every slab and the page): edges by what is drawn, rows of
  // controls by their faces, a face of the ground's colour where the look marks it (DesignKeylineFace).
  // The gallery's pages too, at a desk's width (design6 P, 11-12): every example's first drawn pixel on the column's
  // edge, its face's and never its target's.
  group('ui_core\'s keyline check', () {
    final app = ['overview', for (final s in hearthScreens) s.id];
    final runs = [
      for (final screen in app)
        for (final width in [390.0, 1440.0]) (screen, width),
      for (final p in liveGalleryPages)
        if (!app.contains(p.id)) (p.id, 1440.0),
    ];
    for (final (screen, width) in runs) {
      {
        testWidgets('$screen holds ui_core\'s keylines at $width', (
          tester,
        ) async {
          tester.view.physicalSize = Size(
            width,
            app.contains(screen) ? (width < 600 ? 844 : 900) : 2600,
          );
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          await tester.pumpWidget(GalleryApp(initialPage: screen));
          await settle(tester);
          final report = await const DesignKeylineCheck(look: 'Neumorphism')
              .check(
                tester.element(find.byType(GalleryApp)),
                runAsync: tester.runAsync,
              );
          final named = <String>[];
          final left = <String>[];
          for (final p in report.problems) {
            final why = _named(screen, p);
            (why == null ? left : named).add(why == null ? p : '$p  [$why]');
          }
          // ignore: avoid_print
          print(
            'KEYLINES $screen ${width.toInt()}: ${left.length} (named ${named.length})'
            '${report.problems.isEmpty ? '' : '\n  ${[...left, ...named].join('\n  ')}'}',
          );
          expect(left, isEmpty, reason: left.join('\n'));
        }, tags: ['goldens']);
      }
    }
  });
}

/// Why a problem ui_core's keyline check reports is not a fault of the look, or null: a fault. Each class is named.
String? _named(String screen, String problem) {
  // The Overview's dial stands alone in its column: its marked face fills the column, so the check takes it for the
  // column's ground and reads the scale's words inside the dial (10, 30, the now tag) as the column's items.
  if (screen == 'overview' &&
      RegExp(r'^column: "[\d.]+°?" (starts|ends)').hasMatch(problem)) {
    return "a dial alone in a column: its scale's words read as the column's";
  }
  // The type page's shadowless specimen: a switch beside a bare checkbox, two toggles each its own size. The switch's
  // marked face is its whole 48 target (its 32 track painted in it), the box read by its 28 mark.
  if (screen == 'type' &&
      problem ==
          'region 1: in one row, a switch "Alerts" is 48 px high and a checkbox "Receipt" 28 px') {
    return "a switch's target beside a box's mark: two toggles, each its size";
  }
  return null;
}

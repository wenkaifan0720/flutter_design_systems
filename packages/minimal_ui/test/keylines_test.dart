// Keylines and padding (design6 P) on the example's ordinary screens, at a
// phone's 390 and a laptop's 1440, read from the painted ink rather than
// from the boxes: in each page, card, bar and sheet the rows start on one
// leading keyline and what ends a row on a glyph or a control ends on one
// trailing keyline; controls sharing a row share a height and a centre line.
// ignore_for_file: avoid_relative_lib_imports
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';

import '../example/lib/main.dart';

String _kind(Widget w) => w.runtimeType.toString().split('<').first;

/// Parts measured whole: their frame, or their ink where they have none.
const Set<String> _controls = {
  'MinimalSwitch',
  'MinimalSegmentedButton',
  'MinimalSelect',
  'MinimalTextField',
  'MinimalTextArea',
  'MinimalButton',
  'MinimalIconButton',
  'MinimalCheckbox',
  'MinimalRadio',
  'MinimalSearchField',
  'MinimalChip',
  'MinimalDatePicker',
  'MinimalDivider',
  'MinimalSlider',
  'MinimalMenu',
  'MinimalPropertyPill',
  'MinimalSheetAction',
  'MinimalBadge',
  'MinimalAvatar',
  'MinimalFilter',
  'MinimalStatusIcon',
  'MinimalStatusBadge',
  'MinimalWeekDots',
  'MinimalPriorityIcon',
  'MinimalTag',
};

/// The marks a row carries that are no box: their size is their own.
const Set<String> _marks = {
  'MinimalSwitch',
  'MinimalCheckbox',
  'MinimalRadio',
  'MinimalDivider',
  'MinimalBadge',
  'MinimalAvatar',
  'MinimalStatusIcon',
  'MinimalWeekDots',
  'MinimalPriorityIcon',
};

/// Containers that are also a framed thing in the container around them.
const Set<String> _framed = {'MinimalCard', 'MinimalStatRow'};

/// What keeps keylines of its own: the page, a bar, a card, a sheet.
const Set<String> _containers = {
  'MinimalScaffold',
  'MinimalAppBar',
  'MinimalCard',
  'MinimalStatRow',
  'MinimalSheet',
  'MinimalBottomSheet',
  'MinimalDialog',
};

/// One measured thing on screen: its painted extent.
class KeylineAtom {
  KeylineAtom(this.label, this.kind, this.ink, this.flex, this.owner);

  /// Its words, `glyph`, or its part's name.
  final String label;

  /// `text`, `glyph`, `control` or `frame`.
  final String kind;
  final Rect ink;

  /// The horizontal flex it stands in, for the controls sharing a row.
  final RenderFlex? flex;

  /// The row part it belongs to (a tile, a form row), if any: a two-line
  /// row is one line here.
  final Element? owner;
}

/// How far from a container's first or last edge an edge still reads as
/// meant for it; beyond, it is something else (a centred line, a field's
/// ragged words, a pill mid-row).
const double _near = 40;

/// A container's measured keylines.
class KeylineBox {
  KeylineBox(this.kind, this.rect, this.atoms);

  final String kind;
  final Rect rect;
  final List<KeylineAtom> atoms;

  /// Its atoms by line: a row part's atoms together, then whatever
  /// overlaps vertically.
  late final List<List<KeylineAtom>> rows = () {
    final units = <List<KeylineAtom>>[];
    final byOwner = <Element, List<KeylineAtom>>{};
    for (final a in atoms) {
      final owner = a.owner;
      if (owner == null) {
        units.add([a]);
      } else {
        byOwner.putIfAbsent(owner, () => []).add(a);
      }
    }
    units.addAll(byOwner.values);
    double top(List<KeylineAtom> u) =>
        u.map((a) => a.ink.top).reduce((p, q) => p < q ? p : q);
    double bottom(List<KeylineAtom> u) =>
        u.map((a) => a.ink.bottom).reduce((p, q) => p > q ? p : q);
    units.sort((a, b) => top(a).compareTo(top(b)));
    final rows = <List<KeylineAtom>>[];
    var end = double.negativeInfinity;
    for (final u in units) {
      final b = bottom(u);
      if (rows.isNotEmpty && top(u) < end) {
        rows.last.addAll(u);
        if (b > end) end = b;
      } else {
        rows.add([...u]);
        end = b;
      }
    }
    return rows;
  }();

  /// Each line's first ink near the container's first edge, clustered
  /// within 3.5 px: a leading glyph stands on the keyline by its box, its
  /// ink as far in as the glyph draws it.
  late final List<(double, List<String>)> leading = () {
    final firsts = [
      for (final r in rows)
        r.reduce((p, q) => p.ink.left <= q.ink.left ? p : q),
    ];
    if (firsts.isEmpty) return <(double, List<String>)>[];
    final edge = firsts.map((a) => a.ink.left).reduce((p, q) => p < q ? p : q);
    return _cluster([
      for (final a in firsts)
        if (a.ink.left <= edge + _near) (a.ink.left, a.label),
    ], 3.5);
  }();

  /// Each line's last ink, where a glyph or a part ends it near the
  /// container's last edge (a line of words ends ragged), clustered within
  /// 1.5 px.
  late final List<(double, List<String>)> trailing = () {
    final lasts = [
      for (final r in rows)
        r.reduce((p, q) => p.ink.right >= q.ink.right ? p : q),
    ].where((a) => a.kind != 'text').toList();
    if (lasts.isEmpty) return <(double, List<String>)>[];
    final edge = lasts.map((a) => a.ink.right).reduce((p, q) => p > q ? p : q);
    return _cluster([
      for (final a in lasts)
        if (a.ink.right >= edge - _near) (a.ink.right, a.label),
    ], 1.5);
  }();

  /// Controls that share a row (one horizontal flex) at different heights
  /// or off one centre line.
  late final List<String> rowFaults = () {
    final byFlex = <RenderFlex, List<KeylineAtom>>{};
    for (final a in atoms) {
      final flex = a.flex;
      if (a.kind != 'control' ||
          flex == null ||
          _marks.contains('Minimal${a.label}') ||
          a.ink.height < 20) {
        continue;
      }
      byFlex.putIfAbsent(flex, () => []).add(a);
    }
    final faults = <String>[];
    for (final group in byFlex.values.where((g) => g.length > 1)) {
      final hs = group.map((a) => a.ink.height);
      final cs = group.map((a) => a.ink.center.dy);
      double spread(Iterable<double> v) =>
          v.reduce((p, q) => p > q ? p : q) - v.reduce((p, q) => p < q ? p : q);
      if (spread(hs) > 1 || spread(cs) > 1) {
        faults.add(
          group
              .map(
                (a) =>
                    '${a.label} h${a.ink.height.toStringAsFixed(1)} '
                    'c${a.ink.center.dy.toStringAsFixed(1)}',
              )
              .join(', '),
        );
      }
    }
    return faults;
  }();

  String describe() {
    String f(double v) => v.toStringAsFixed(1);
    String list(List<(double, List<String>)> c) => [
      for (final (x, ls) in c) '${f(x)}×${ls.length}(${ls.take(3).join('|')})',
    ].join('  ');
    return '$kind @${f(rect.left)},${f(rect.top)} '
        '${f(rect.width)}x${f(rect.height)}\n'
        '  lead: ${list(leading)}\n'
        '  trail: ${list(trailing)}'
        '${rowFaults.map((r) => '\n  row: $r').join()}';
  }
}

List<(double, List<String>)> _cluster(
  List<(double, String)> xs,
  double within,
) {
  xs.sort((a, b) => a.$1.compareTo(b.$1));
  final out = <(double, List<String>)>[];
  for (final (x, label) in xs) {
    if (out.isNotEmpty && (x - out.last.$1).abs() <= within) {
      out.last.$2.add(label);
    } else {
      out.add((x, [label]));
    }
  }
  return out;
}

class _Shot {
  _Shot(this.w, this.h, this.bytes);

  final int w, h;
  final ByteData bytes;

  int rgb(int x, int y) {
    final i = (y * w + x) * 4;
    return (bytes.getUint8(i) << 16) |
        (bytes.getUint8(i + 1) << 8) |
        bytes.getUint8(i + 2);
  }
}

int _diff(int a, int b) =>
    ((a >> 16 & 255) - (b >> 16 & 255)).abs() +
    ((a >> 8 & 255) - (b >> 8 & 255)).abs() +
    ((a & 255) - (b & 255)).abs();

/// The painted extent of what stands in [r]: the pixels off the ground
/// around it (the commonest colour on its rim).
Rect? _ink(_Shot s, Rect r, {required int threshold}) {
  final screen = Rect.fromLTWH(0, 0, s.w.toDouble(), s.h.toDouble());
  final e = r.inflate(2).intersect(screen);
  if (e.width < 3 || e.height < 3) return null;
  final l = e.left.floor(), t = e.top.floor();
  final rr = e.right.ceil() - 1, b = e.bottom.ceil() - 1;
  final counts = <int, int>{};
  void count(int x, int y) =>
      counts.update(s.rgb(x, y), (n) => n + 1, ifAbsent: () => 1);
  for (var x = l; x <= rr; x++) {
    count(x, t);
    count(x, b);
  }
  for (var y = t; y <= b; y++) {
    count(l, y);
    count(rr, y);
  }
  final ground = counts.entries
      .reduce((a, c) => a.value >= c.value ? a : c)
      .key;
  final inner = r.intersect(screen);
  int? x0, x1, y0, y1;
  for (var y = inner.top.floor(); y < inner.bottom.ceil(); y++) {
    for (var x = inner.left.floor(); x < inner.right.ceil(); x++) {
      if (_diff(s.rgb(x, y), ground) > threshold) {
        if (x0 == null || x < x0) x0 = x;
        if (x1 == null || x > x1) x1 = x;
        y0 ??= y;
        y1 = y;
      }
    }
  }
  if (x0 == null) return null;
  return Rect.fromLTRB(x0.toDouble(), y0!.toDouble(), x1! + 1.0, y1! + 1.0);
}

/// Whether [r] is painted: not in an IndexedStack's hidden child.
bool _painted(RenderObject r) {
  var child = r;
  var parent = r.parent;
  while (parent != null) {
    if (parent is RenderIndexedStack) {
      var i = 0;
      var c = parent.firstChild;
      while (c != null && c != child) {
        c = parent.childAfter(c);
        i++;
      }
      if (i != parent.index) return false;
    }
    child = parent;
    parent = parent.parent;
  }
  return true;
}

RenderFlex? _rowOf(RenderObject r) {
  var p = r.parent;
  while (p != null) {
    if (p is RenderFlex && p.direction == Axis.horizontal) return p;
    p = p.parent;
  }
  return null;
}

Rect _rectOf(RenderBox box) => box.localToGlobal(Offset.zero) & box.size;

/// Measures the screen on view: each container's atoms from the painted
/// frame, and the frame itself as a raw image for a sheet drawn over it.
/// [scope] keeps to what stands inside one part (a raised card).
Future<(List<KeylineBox>, ui.Image)> measureKeylines(
  WidgetTester tester, {
  Finder? scope,
}) async {
  final size = tester.view.physicalSize / tester.view.devicePixelRatio;
  final w = size.width.round(), h = size.height.round();
  late _Shot shot;
  late ui.Image image;
  await tester.runAsync(() async {
    final layer = tester.binding.renderViews.first.debugLayer! as OffsetLayer;
    image = await layer.toImage(Offset.zero & size);
    final data = await image.toByteData();
    shot = _Shot(w, h, data!);
  });
  final scopeRect = scope == null ? null : tester.getRect(scope.first);
  final screen = Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble());
  final boxes = <Element, List<KeylineAtom>>{};

  Element? containerOf(Element e) {
    Element? found;
    e.visitAncestorElements((a) {
      if (_containers.contains(_kind(a.widget))) {
        found = a;
        return false;
      }
      return true;
    });
    return found;
  }

  /// The row part [e] stands in: the outermost tile or row widget (not a
  /// bare Row) inside its container, so a row's inner lines join it.
  Element? ownerOf(Element e) {
    Element? found;
    e.visitAncestorElements((a) {
      final k = _kind(a.widget);
      if (_containers.contains(k)) return false;
      if ((k.endsWith('Tile') || k.endsWith('Row')) &&
          k != 'Row' &&
          k != 'TableRow') {
        found = a;
      }
      return true;
    });
    return found;
  }

  bool insideControl(Element e) {
    var inside = false;
    e.visitAncestorElements((a) {
      final k = _kind(a.widget);
      if (_controls.contains(k)) {
        inside = true;
        return false;
      }
      return !_containers.contains(k);
    });
    return inside;
  }

  final atoms = find.byElementPredicate((e) {
    final k = _kind(e.widget);
    return e.widget is RichText || _controls.contains(k) || _framed.contains(k);
  });
  for (final e in atoms.evaluate()) {
    final ro = e.renderObject;
    if (ro is! RenderBox || !ro.hasSize || !ro.attached || !_painted(ro)) {
      continue;
    }
    final k = _kind(e.widget);
    final isText = e.widget is RichText;
    if (isText && insideControl(e)) continue;
    final container = containerOf(e);
    if (container == null) continue;
    final rect = _rectOf(ro);
    if (!screen.contains(rect.topLeft) ||
        !screen.contains(rect.bottomRight - const Offset(0.01, 0.01))) {
      continue;
    }
    if (scopeRect != null) {
      // Only what stands in the scoped part, in a container inside it.
      final box = _rectOf(container.renderObject! as RenderBox);
      final within = scopeRect.inflate(1);
      if (!scopeRect.contains(rect.center) ||
          !within.contains(box.topLeft) ||
          !within.contains(box.bottomRight)) {
        continue;
      }
    }
    // A part's frame may be a faint fill; words and glyphs are ink.
    final ink = _ink(shot, rect, threshold: isText ? 60 : 12);
    if (ink == null) continue;
    String label;
    String kind;
    if (e.widget case RichText(:final text)) {
      final plain = text.toPlainText();
      final glyph = plain.runes.length == 1 && plain.runes.first >= 0xE000;
      kind = glyph ? 'glyph' : 'text';
      label = glyph
          ? 'glyph'
          : plain.length > 14
          ? '${plain.substring(0, 14)}…'
          : plain;
    } else {
      kind = _framed.contains(k) ? 'frame' : 'control';
      label = k.replaceFirst('Minimal', '');
    }
    boxes
        .putIfAbsent(container, () => [])
        .add(KeylineAtom(label, kind, ink, _rowOf(ro), ownerOf(e)));
  }
  return (
    [
      for (final MapEntry(key: c, value: list) in boxes.entries)
        KeylineBox(
          _kind(c.widget),
          _rectOf(c.renderObject! as RenderBox),
          list,
        ),
    ],
    image,
  );
}

/// Every family the bundle's FontManifest names, icons included, so no
/// screen draws a test font's boxes where a glyph belongs.
Future<void> _loadManifestFonts() async {
  final manifest =
      json.decode(await rootBundle.loadString('FontManifest.json')) as List;
  await Future.wait([
    for (final family in manifest.cast<Map<String, Object?>>())
      (FontLoader(family['family']! as String)..addAll(
            (family['fonts']! as List).cast<Map<String, Object?>>().map(
              (font) => rootBundle.load(font['asset']! as String),
            ),
          ))
          .load(),
  ]);
}

extension on FontLoader {
  void addAll(Iterable<Future<ByteData>> fonts) => fonts.forEach(addFont);
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// The example's ordinary screens, each reached through the app's own
/// navigation: (name, app, the steps after it opens, the part to keep to).
typedef KeylineScreen = ({
  String name,
  String app,
  Future<void> Function(WidgetTester tester) open,
  Finder? scope,
});

Future<void> _tapNav(WidgetTester tester, String label) async {
  await tester.tap(
    find
        .descendant(
          of: find.byWidgetPredicate(
            (w) => _kind(w).startsWith('MinimalNavigation'),
          ),
          matching: find.text(label),
        )
        .first,
  );
  await _settle(tester);
}

Future<void> _none(WidgetTester tester) async {}

final List<KeylineScreen> keylineScreens = [
  (name: 'habits/today', app: 'habits', open: _none, scope: null),
  (
    name: 'habits/list',
    app: 'habits',
    open: (tester) => _tapNav(tester, 'Habits'),
    scope: null,
  ),
  (
    name: 'habits/new',
    app: 'habits',
    open: (tester) async {
      await _tapNav(tester, 'Habits');
      await tester.tap(
        find
            .byWidgetPredicate(
              (w) => w is MinimalIconButton && w.label == 'New habit',
            )
            .first,
      );
      await _settle(tester);
    },
    scope: find.byWidgetPredicate((w) => _kind(w) == 'KitNewHabitPage'),
  ),
  (
    name: 'habits/settings',
    app: 'habits',
    open: (tester) => _tapNav(tester, 'Settings'),
    scope: null,
  ),
  (name: 'orders/orders', app: 'orders', open: _none, scope: null),
  (name: 'issues/mine', app: 'issues', open: _none, scope: null),
];

/// Opens [screen] at [size] through the gallery's address.
Future<void> openKeylineScreen(
  WidgetTester tester,
  KeylineScreen screen,
  Size size,
) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const SizedBox());
  await tester.pumpWidget(
    GalleryApp.at(Uri.parse('http://localhost/?app=${screen.app}')),
  );
  await _settle(tester);
  await screen.open(tester);
}

/// Decodes every image the screen shows (an [Image]'s, a [DecoratedBox]'s
/// picture) and draws the frame they land in, before a check reads pixels.
/// An image that cannot load (a media slot no app has filled yet) is left to
/// its widget, which draws its fallback in that frame.
Future<void> precacheShownImages(WidgetTester tester) async {
  final shown = <(ImageProvider, Element)>[
    for (final e in find.byType(Image).evaluate())
      ((e.widget as Image).image, e),
    for (final e in find.byType(DecoratedBox).evaluate())
      if ((e.widget as DecoratedBox).decoration case BoxDecoration(
        image: DecorationImage(:final image),
      ))
        (image, e),
  ];
  await tester.runAsync(
    () => Future.wait([
      for (final (image, e) in shown)
        precacheImage(image, e, onError: (_, _) {}),
    ]),
  );
  await tester.pump();
  await tester.pump();
}

Future<void> loadKeylineFonts() =>
    Future.wait([minimalLoadFonts(), _loadManifestFonts()]);

/// The keylines a container keeps beyond one, by screen and part, each a
/// decision with its reason.
const Map<String, ({int lead, int trail, String why})> _declared = {};

void main() {
  setUpAll(loadKeylineFonts);

  for (final size in const [Size(390, 844), Size(1440, 900)]) {
    for (final screen in keylineScreens) {
      testWidgets('${screen.name} at ${size.width.round()}', (tester) async {
        await openKeylineScreen(tester, screen, size);
        final (boxes, image) = await measureKeylines(
          tester,
          scope: screen.scope,
        );
        image.dispose();
        expect(boxes, isNotEmpty);
        for (final box in boxes) {
          final allowed = _declared['${screen.name} ${box.kind}'];
          final where =
              '${screen.name} at ${size.width.round()}\n'
              '${box.describe()}';
          expect(
            box.leading.length,
            lessThanOrEqualTo(allowed?.lead ?? 1),
            reason: 'leading keylines: $where',
          );
          expect(
            box.trailing.length,
            lessThanOrEqualTo(allowed?.trail ?? 1),
            reason: 'trailing keylines: $where',
          );
          expect(box.rowFaults, isEmpty, reason: 'controls in a row: $where');
        }
      }, tags: 'goldens');
    }
  }
}

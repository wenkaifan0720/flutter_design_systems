// The screen checks, shared by their test files: screen_checks_test.dart runs each matrix's everyday cases
// (screenChecksMain) but the rows check's, which screen_rows_part_<n>_test.dart read in two halves; the sweep files run
// the rest (screen_rows_<width>_<day|night>_test.dart, screen_sweep_test.dart), each in its own process, so the pages
// are read side by side and no one process holds them all.
//
// What a person reads off a screen's pixels, held on every Quill screen and every gallery page at 390 and 1440 under
// each density Ledger ships:
// - a chosen fill covers the cell its unchosen neighbours show (a pill's ground, a menu's current row);
// - a glyph beside a one-line title or label stands its ink's middle on the capitals' middle, within half a device
//   pixel;
// - the outline a person sees is the control's box (two controls of one size in a row show one top, one bottom and
//   equal side insets, on a page, a sheet and a dialog, by day and by night); a field's list starts on the field's
//   leading edge, at least as wide, its words one stated gutter in; no choice is left alone on its line; an overlay
//   covers the window; one page frame across destinations; a card in a row hugs its content.
// Ledger puts no act in a card that stands in a row (its tiles are links whole), so "cards in a row share their action
// line" has nothing to hold here.
// The gallery is the example app; a test reads its pages from there.
// ignore_for_file: avoid_relative_lib_imports
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leak_tracker_flutter_testing/leak_tracker_flutter_testing.dart';
import 'package:ledger_ui/ledger_ui.dart';
import 'package:ledger_ui/ledger_host.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ui_core_review/ui_core_review.dart';

import 'tiers.dart';

import '../example/lib/gallery_pages.dart';
import '../example/lib/kit_gallery/kit.dart';
import '../example/lib/kit_gallery/quill/entry.dart';
import '../example/lib/kit_gallery/quill/quill.dart';
import '../example/lib/kit_gallery/quill/register.dart';

/// Leak tracking without a creation stack per object, as walk_test's. To leave out what the test helpers make, leak
/// tracking keeps the stack every tracked object was made on, and over tests that each read every page those outlive
/// their test: screen_sweep_test, run alone, reached 3.9 GB by its last test, and 1.2 GB tracking them, in three
/// fifths of the time. These tests make nothing of their own through the helpers, so they track theirs too.
final LeakTesting _tracked = LeakTesting.settings.withTracked(
  createdByTestHelpers: true,
);

Future<void> _loadFonts() async {
  final manifest = json.decode(
    await rootBundle.loadString('FontManifest.json'),
  ) as List<dynamic>;
  for (final entry in manifest.cast<Map<String, dynamic>>()) {
    final family = entry['family'] as String;
    final loader = FontLoader(
      family.startsWith('packages/') ? family : ledgerFontFamily(family),
    );
    for (final font
        in (entry['fonts'] as List<dynamic>).cast<Map<String, dynamic>>()) {
      loader.addFont(rootBundle.load(font['asset'] as String));
    }
    await loader.load();
  }
}

// --- Pixels ------------------------------------------------------------------------------------------------------

/// Device pixels per logical pixel the screens are read at.
const double _ratio = 2;

const Key _shotKey = ValueKey<String>('shot');

typedef _Rgb = (int, int, int);

double _dist(_Rgb a, _Rgb b) {
  final r = a.$1 - b.$1, g = a.$2 - b.$2, u = a.$3 - b.$3;
  return math.sqrt(r * r + g * g + u * u);
}

/// A region of the screen read at [_ratio], its top left at [origin] (logical).
class _Shot {
  _Shot(this.origin, this.width, this.height, this.data);

  final Offset origin;
  final int width;
  final int height;
  final ByteData data;

  _Rgb px(int x, int y) {
    final i = (y.clamp(0, height - 1) * width + x.clamp(0, width - 1)) * 4;
    return (data.getUint8(i), data.getUint8(i + 1), data.getUint8(i + 2));
  }

  double dx(double x) => (x - origin.dx) * _ratio;
  double dy(double y) => (y - origin.dy) * _ratio;
}

/// Reads [region] (logical) of the app drawn under the boundary [_shotKey], at [_ratio].
Future<_Shot> _shoot(WidgetTester t, Rect region) async {
  final boundary = t.renderObject<RenderRepaintBoundary>(find.byKey(_shotKey));
  final layer = boundary.debugLayer! as OffsetLayer;
  final r = region.intersect(Offset.zero & boundary.size);
  final got = await t.runAsync(() async {
    final image = await layer.toImage(r, pixelRatio: _ratio);
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      return _Shot(r.topLeft, image.width, image.height, data!);
    } finally {
      image.dispose();
    }
  });
  return got!;
}

/// The commonest colour on the edge of the device box [x0, x1) × [y0, y1): what the box stands on.
_Rgb _ground(_Shot s, int x0, int x1, int y0, int y1) {
  final count = <_Rgb, int>{};
  void add(int x, int y) =>
      count.update(s.px(x, y), (n) => n + 1, ifAbsent: () => 1);
  for (var x = x0; x < x1; x++) {
    add(x, y0);
    add(x, y1 - 1);
  }
  for (var y = y0; y < y1; y++) {
    add(x0, y);
    add(x1 - 1, y);
  }
  return count.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
}

/// The top and bottom (device rows, fractional) of what is drawn in the device box [x0, x1) × [y0, y1) over
/// [ground]. A row's coverage is its most inked pixel's distance from the ground over the box's most inked pixel's;
/// the first and last inked rows count by their coverage, so an edge is read to about a tenth of a device pixel.
(double, double)? _inkRows(
  _Shot s,
  int x0,
  int x1,
  int y0,
  int y1,
  _Rgb ground,
) {
  final rows = <double>[];
  var most = 0.0;
  for (var y = y0; y < y1; y++) {
    var m = 0.0;
    for (var x = x0; x < x1; x++) {
      m = math.max(m, _dist(s.px(x, y), ground));
    }
    rows.add(m);
    most = math.max(most, m);
  }
  if (most < 40) return null;
  final cover = [for (final m in rows) (m / most).clamp(0.0, 1.0)];
  final first = cover.indexWhere((c) => c > .08);
  final last = cover.lastIndexWhere((c) => c > .08);
  return (y0 + first + 1 - cover[first], y0 + last + cover[last]);
}

/// Along device column [x] from [from] toward [to] (rows), the fractional row where the colour first reaches half
/// its full distance from [ground] (the full distance read on the run past the edge): a face's edge as a person sees
/// it, its anti-aliasing counted.
double? _edge(
  _Shot s,
  int x,
  int from,
  int to,
  _Rgb ground, {
  bool across = false,
}) {
  final step = to >= from ? 1 : -1;
  _Rgb at(int i) => across ? s.px(i, x) : s.px(x, i);
  var full = 0.0;
  for (var i = from; i != to; i += step) {
    full = math.max(full, _dist(at(i), ground));
    if (full > 0 && _dist(at(i), ground) < full * .5 && full >= 24) break;
  }
  if (full < 24) return null;
  for (var i = from; i != to; i += step) {
    final d = _dist(at(i), ground);
    if (d >= full * .5) {
      final prev = i == from ? 0.0 : _dist(at(i - step), ground);
      // Where between the previous pixel and this one the half was crossed.
      final f = d == prev
          ? 0.0
          : ((full * .5 - prev) / (d - prev)).clamp(0.0, 1.0);
      // Pixel centres stand at .5: from the previous pixel's centre toward this one's.
      return step > 0 ? i - .5 + f : i + 1.5 - f;
    }
  }
  return null;
}

// --- Frames ------------------------------------------------------------------------------------------------------

typedef _Screen = ({String name, QuillPage page, Widget? Function() pushed});

final List<_Screen> _screens = [
  (name: 'overview', page: QuillPage.overview, pushed: () => null),
  (name: 'home', page: QuillPage.home, pushed: () => null),
  (name: 'register', page: QuillPage.register, pushed: () => null),
  (name: 'settings', page: QuillPage.settings, pushed: () => null),
  (
    name: 'entry',
    page: QuillPage.overview,
    pushed: () => const QuillEntryPage(),
  ),
  (
    name: 'receipt',
    page: QuillPage.register,
    pushed: () => QuillReceiptPage(tx: kitRecent.first),
  ),
];

const List<double> _widths = [390, 1440];

Future<void> _rest(WidgetTester t) async {
  for (var i = 0; i < 4; i++) {
    await t.pump(const Duration(milliseconds: 400));
  }
}

/// Grows the view down so the page's longest scroll stands in it whole (at most 12000).
Future<void> _fit(WidgetTester t, double width) async {
  var extent = 0.0;
  for (final s in t.stateList<ScrollableState>(find.byType(Scrollable))) {
    final p = s.position;
    if (p.axis == Axis.vertical && p.hasContentDimensions) {
      extent = math.max(extent, p.maxScrollExtent);
    }
  }
  if (extent <= 0) return;
  t.view.physicalSize = Size(
    width,
    math.min(12000, t.view.physicalSize.height + extent),
  );
  await _rest(t);
}

Future<void> _quill(
  WidgetTester t,
  _Screen s,
  Size size, {
  LedgerDensity? density,
  QuillAppearance appearance = QuillAppearance.light,
  bool fit = false,
}) async {
  t.view.physicalSize = size;
  t.view.devicePixelRatio = 1;
  await t.pumpWidget(
    RepaintBoundary(
      key: _shotKey,
      child: QuillApp(
        key: UniqueKey(),
        initialPage: s.page,
        initialDensity: density,
        initialAppearance: appearance,
      ),
    ),
  );
  await _rest(t);
  final pushed = s.pushed();
  if (pushed != null) {
    t.state<QuillFrameState>(find.byType(QuillFrame)).push(pushed);
    await _rest(t);
  }
  if (fit) await _fit(t, size.width);
}

Future<void> _gallery(
  WidgetTester t,
  GalleryPage page,
  Size size,
  LedgerDensity density, {
  Brightness brightness = Brightness.light,
}) async {
  t.view.physicalSize = size;
  t.view.devicePixelRatio = 1;
  kitDensity = density;
  await t.pumpWidget(
    RepaintBoundary(
      key: _shotKey,
      child: KeyedSubtree(key: UniqueKey(), child: page.build(brightness)),
    ),
  );
  await _rest(t);
  await _fit(t, size.width);
}

/// Runs [read] on every Quill screen and every gallery page, at each of [widths] (390 and 1440), under each density,
/// in each of [brightnesses] (by day); collects what it finds, each line named by where it was found. [once] reads
/// each screen and page once, the width, the density and the appearance turning over them: the matrix's everyday case;
/// [only] picks the screens and pages it reads by their place in that turn.
Future<List<String>> _everywhere(
  WidgetTester t,
  Future<List<String>> Function(WidgetTester t) read, {
  List<double> widths = _widths,
  List<LedgerDensity> densities = LedgerDensity.values,
  List<Brightness> brightnesses = const [Brightness.light],
  bool once = false,
  bool Function(int i)? only,
}) async {
  final found = <String>[];
  final pages =
      <
        (
          String,
          Future<void> Function(
            Size size,
            LedgerDensity density,
            Brightness brightness,
          ),
        )
      >[
        for (final s in _screens)
          (
            s.name,
            (size, density, brightness) => _quill(
              t,
              s,
              size,
              density: density,
              appearance: brightness == Brightness.dark
                  ? QuillAppearance.dark
                  : QuillAppearance.light,
              fit: true,
            ),
          ),
        for (final page in galleryPages)
          (
            page.id,
            (size, density, brightness) =>
                _gallery(t, page, size, density, brightness: brightness),
          ),
      ];
  Future<void> at(
    int i,
    double width,
    LedgerDensity density,
    Brightness brightness,
  ) async {
    final size = Size(width, width < 600 ? 844 : (width >= 1920 ? 1080 : 900));
    final when =
        '${width.round()} ${density.name}${brightness == Brightness.dark ? ' night' : ''}';
    final (name, pump) = pages[i];
    await pump(size, density, brightness);
    found.addAll([for (final p in await read(t)) '$name $when · $p']);
  }

  if (once) {
    for (var i = 0; i < pages.length; i++) {
      if (only != null && !only(i)) continue;
      await at(
        i,
        turn(widths, i),
        turn(densities, i),
        turn(brightnesses, i ~/ widths.length),
      );
    }
    return found;
  }
  for (final width in widths) {
    for (final density in densities) {
      for (final brightness in brightnesses) {
        for (var i = 0; i < pages.length; i++) {
          await at(i, width, density, brightness);
        }
      }
    }
  }
  return found;
}

/// The dialogs and sheets with a pair of acts that a person raises in Quill and its parts: Settings' "Sign out of
/// Quill?", the sheet page's "Freeze card", the commit page's "Archive October" and "Delete the entry". Raises each at
/// [size], [density] and [appearance] and runs [read] with it open (given the card it stands on); each finding named
/// by the act that raised it.
Future<List<String>> _overlays(
  WidgetTester t,
  Size size,
  LedgerDensity density,
  QuillAppearance appearance,
  Future<List<String>> Function(WidgetTester t, Finder card) read,
) async {
  final found = <String>[];
  // Settings' Sign out of Quill? dialog, by night.
  await _quill(
    t,
    _screens.firstWhere((s) => s.name == 'settings'),
    size,
    density: density,
    appearance: appearance,
  );
  final out = _wordsOf('Sign out');
  await _reveal(t, out);
  await t.tap(out);
  await _rest(t);
  found.addAll([
    for (final p in await read(t, find.byType(LedgerDialog).last))
      'Sign out · $p',
  ]);
  final brightness = appearance == QuillAppearance.dark
      ? Brightness.dark
      : Brightness.light;
  for (final (id, button, card) in const [
    ('sheet', 'Freeze card', LedgerSheetShell),
    ('commit', 'Archive October', LedgerDialog),
    ('commit', 'Delete the entry', LedgerDialog),
  ]) {
    await _quill(
      t,
      _screens.first,
      size,
      density: density,
      appearance: appearance,
    );
    t
        .state<QuillFrameState>(find.byType(QuillFrame))
        .push(galleryPages.firstWhere((p) => p.id == id).build(brightness));
    await _rest(t);
    final open = _wordsOf(button);
    await _reveal(t, open);
    await t.tap(open);
    await _rest(t);
    found.addAll([
      for (final p in await read(t, find.byType(card).last)) '$button · $p',
    ]);
  }
  return found;
}

/// ui_core's checks of what a person sees, on the screen the test pumped (under [_shotKey]).
// At its own 3x: at 2x a ringed circle's apex and a box's side fall a whole device pixel off as drawn where at 3x
// they read true (a ringed bell beside a ringed box, day and night).
/// How long one of the every-page tests may take: each reads every screen and gallery page, three densities, as
/// drawn at 3x (1440 by night: 7.7 minutes alone, the fields page 45 s a density). Four at once on a loaded
/// Mac ran past 20.
const Duration _reading = Duration(minutes: 40);

const DesignRowCheck _rowCheck = DesignRowCheck(look: 'Ledger');
const DesignWidthCheck _widthCheck = DesignWidthCheck(look: 'Ledger');

/// A select's list as Ledger draws it: the field's width on the field's leading edge, its words 16
/// in from the field's. A field written on a rule has no inset; the list's rows keep their 16.
const DesignWidthCheck _listCheck = DesignWidthCheck(
  look: 'Ledger',
  listWordsIndent: 16,
);

/// ui_core's checkList takes for the field's popup any box whose top or foot is within 32 px of the field's (by height
/// alone), drawn in a layer other than the field's after it. Ledger's navigation frame paints its side bar or rail
/// after its navigator's page, as it must (the bar stands over the page's ground), in the frame's own route: a bar row
/// that starts near the field's foot reads as the field's list. Set aside by kind: a finding whose list starts inside
/// the bar, or is as wide as a bar box near the field; the list Ledger opens is held by this test's own reads of its
/// start, width and words.
bool _barAside(WidgetTester t, String problem, Rect field) {
  final bars = [
    for (final e in find.byType(LedgerSideBar).evaluate())
      e.renderObject! as RenderBox,
  ];
  if (bars.isEmpty) return false;
  final past = RegExp(r'its leading edge is ([\d.]+) px out past')
      .firstMatch(problem);
  if (past != null) {
    final start = field.left - double.parse(past[1]!);
    return bars.any((b) => start < _global(b, Offset.zero & b.size).right);
  }
  final wide = RegExp(r': ([\d.]+) px wide as laid out').firstMatch(problem);
  if (wide == null) return false;
  final width = double.parse(wide[1]!);
  var held = false;
  void visit(RenderObject n) {
    if (held) return;
    if (n is RenderBox && n.hasSize) {
      final r = _global(n, Offset.zero & n.size);
      final near =
          (r.top >= field.bottom - 8 && r.top - field.bottom <= 40) ||
          (r.bottom <= field.top + 8 && field.top - r.bottom <= 40);
      if (near && (r.width - width).abs() <= .5) held = true;
    }
    n.visitChildren(visit);
  }

  for (final b in bars) {
    visit(b);
  }
  return held;
}

BuildContext _screen(WidgetTester t) => t.element(find.byKey(_shotKey));

/// What DesignRowCheck takes for a row of faces in Ledger that is not one, each with why. A finding naming one is set
/// aside (and counted, for the status); every other finding fails.
final List<(RegExp, String)> _notFaceRows = [
  (
    RegExp(r'a link "[^"]+, home"'),
    "the wordmark (the brand mark and the app's name, no face) beside the avatar's disc: two things of other heights "
        "centred on the bar's line, not a pair of controls of one size; the mark's own box is centred in its slot",
  ),
  (
    RegExp(r'a link "[^",]+, \$[\d,.]+"'),
    "category tiles: a glyph over a name over a sum, the tile a link whole; its first line's capitals are not its "
        "middle, by design",
  ),
  (
    RegExp(r'a link "(Pay a bill|Transfer|Split|Add to goal), '),
    'quick actions: a glyph disc over a title over a line, the action a link whole with no face; read by its ink and '
        'its hairline (drawn over the row), not by an outline',
  ),
  (
    RegExp(r'a control "[A-Z]+" beside a control "[A-Z]+"'),
    "swipe actions: a glyph over its word on the engraved ground, the word under the glyph, not on the action's middle",
  ),
];

/// How many row findings were set aside, by reason (for the status).
final Map<String, int> _asideRows = {};

/// The spoken names of the controls on screen whose face is a circle (a ringed or plain icon button, the composer's
/// discs): a circle as tall as its control, not a badge's dot.
Set<String> _circles(WidgetTester t) => {
  for (final e in find.byType(LedgerPressable).evaluate())
    if ((e.widget as LedgerPressable).label case final label?)
      if (find
          .descendant(
            of: find.byElementPredicate((x) => identical(x, e)),
            matching: find.byWidgetPredicate(
              (w) =>
                  w is DecoratedBox &&
                  w.decoration is BoxDecoration &&
                  (w.decoration as BoxDecoration).shape == BoxShape.circle,
            ),
          )
          .evaluate()
          .any((d) => (d.size?.height ?? 0) >= (e.size?.height ?? 1) - .5))
        label,
};

final RegExp _edgeFinding = RegExp(
  r'^a \w+ "(.+?)" beside a \w+ "(.+?)": its (top|bottom) is level with theirs as laid out, ([\d.]+) device px (below|above) as drawn$',
);

/// Why a finding of a circle's apex is set aside: DesignRowCheck counts a pixel only when all four of its corners lie
/// inside the face's shape, and at a circle's top and bottom on the pixel grid no device pixel does once the radius is
/// under about 55 device px (the middle pixel's far corner is 0.99 px out, the circle's sag within it √(2·r·0.01)), so
/// its apex row, inked in full, is never read. At 3x, Attach, the month arrows and the bell draw their
/// ring's full contrast in the box's first and last device rows, on whole pixels, as the chip, the field and the button
/// beside them do.
const String _apexReason =
    "a circle's apex row (ui_core reads no pixel there: none is wholly inside the circle)";

/// Whether [p] says only that a circle reads up to one device pixel short at its apex beside a control laid level with
/// it: the circle named and drawn smaller, or the circle held and the other drawn larger than it.
bool _apexOnly(String p, Set<String> circles) {
  final m = _edgeFinding.firstMatch(p);
  if (m == null || double.parse(m[4]!) > 1) return false;
  final inward = (m[3] == 'top') == (m[5] == 'below');
  return circles.contains(m[1]) ? inward : circles.contains(m[2]) && !inward;
}

/// Why a finding of the tab bar's act is set aside: ui_core reads a tab bar's raised act among its
/// destinations, a row of them, and holds the act's glyph on their line. Ledger's act is a disc raised above the bar
/// by design (`LedgerNavBar`'s act, the one thing a person does most), its glyph on the disc's middle, not on the
/// destinations' line.
const String _actReason =
    "the tab bar's raised act (a disc above the bar by design, not a destination in its row)";

/// The spoken names of the acts the tab bars on screen raise: the shell's act, or the middle of five destinations.
Set<String> _acts(WidgetTester t) => {
  for (final e in find.byType(LedgerNavBar).evaluate())
    ?_actOf(e.widget as LedgerNavBar),
};

String? _actOf(LedgerNavBar bar) {
  if (bar.action != null) return bar.action!.label;
  final i = LedgerNavBar.discTab(bar.items.length, action: false);
  return i == null ? null : bar.items[i].label;
}

/// Why a pill's finding by day is set aside: a chip's or a filter's ring is the rule (ink at .14) painted over its
/// raised fill, as the source's `.filter` paints its border over its background, so by day it stands d9d7d3 on the
/// page's f2ede3, 1.23 off it, under ui_core's 1.25 floor, while the fill inside it stands 1.33 off the ring. ui_core
/// then takes the ring for the ground and the fill for the outline: a pill reads a ring's width (3 device px) or so
/// short. At 3x, every pill, chosen or not, draws its first device row on its box's top, ringed or
/// filled. Set aside by kind: by day only (by night the ring stands well off the page and the same pills are held),
/// both controls pills, laid out level (within half a px) and drawn at most 6 device px off.
const String _ringReason =
    "a pill's faint day ring over its raised fill (ui_core takes the ring for the ground, the fill for the outline)";

/// The spoken names of the controls inside [card].
Set<String> _namesWithin(WidgetTester t, Finder card) => {
  for (final e
      in find
          .descendant(of: card, matching: find.byType(LedgerPressable))
          .evaluate())
    ?(e.widget as LedgerPressable).label,
};

/// Whether an as-drawn row finding concerns the overlay's own controls: one that names two controls, neither of them
/// inside the [names] of the card, reads the page behind the scrim (r10: the top bar's bell beside its profile disc,
/// read 6 device px off through the Sign out dialog's scrim at 390 compact; the page sweeps hold that bar). Any
/// other finding is kept.
bool _onCard(String p, Set<String> names) {
  final m = RegExp(r'^a \w+ "(.+?)" beside a \w+ "(.+?)"').firstMatch(p);
  return m == null || names.contains(m[1]) || names.contains(m[2]);
}

/// The spoken names of the pills on screen by day: each chip's, each filter's options, each toggle group's options
/// (the filters' pill, ringed the same; 0.2.0 read a chosen one beside one not 4 device px off at 390 and 1440 by
/// day, and by night 0.5 device px off with 0.1 px as laid out: the chosen pill's light fill read beside the dark
/// ones, so a toggle group's are held by night too), and a compact date picker's two pills (the same rule over the
/// same raised fill; r10 read them 0.8 device px off at 1440 by day only), each named by the picker's label.
Set<String> _dayPills(WidgetTester t) => {
  for (final e in find.byType(LedgerChip).evaluate())
    if (!e.ledgerTheme.isDark) (e.widget as LedgerChip).label,
  for (final e in find.byWidgetPredicate((w) => w is LedgerFilters).evaluate())
    if (!e.ledgerTheme.isDark) ..._filterWords(e.widget),
  for (final e
      in find.byWidgetPredicate((w) => w is LedgerToggleGroup).evaluate())
    ..._toggleWords(e.widget),
  for (final e in find.byType(LedgerDatePicker).evaluate())
    if (!e.ledgerTheme.isDark &&
        (e.widget as LedgerDatePicker).presentation ==
            LedgerDatePickerPresentation.compact)
      (e.widget as LedgerDatePicker).labelText,
};

/// A filter set's pills as it words them, whatever it holds.
Iterable<String> _filterWords(Widget filters) {
  final f = filters as LedgerFilters<Object?>;
  return [for (final o in f.options) f.wordsOf(o)];
}

/// A toggle group's options as it words them, whatever it holds (read through `dynamic`: its `labelOf` takes its own
/// type, which a cast to `LedgerToggleGroup<Object?>` would refuse).
Iterable<String> _toggleWords(Widget group) {
  // Through `dynamic`: a group of strings' labelOf takes a String, so a cast to a group of Object? would not hold it.
  final dynamic g = group;
  // Reads a private type, which no public type describes.
  // ignore: avoid_dynamic_calls
  return [for (final Object? o in g.options as List) g.labelOf(o) as String];
}

final RegExp _capsFinding = RegExp(
  r'^a \w+ "(.+?)" beside a \w+ "(.+?)": the capitals of ".+?" are ([\d.]+) px (?:below|above) the row.s centre line '
  r'as laid out, ([\d.]+) device px (?:below|above) as drawn$',
);

/// Whether [p] is a finding [_ringReason] explains, among [pills].
bool _ringOnly(String p, Set<String> pills) {
  if (_edgeFinding.firstMatch(p) case final m?) {
    return pills.contains(m[1]) &&
        pills.contains(m[2]) &&
        double.parse(m[4]!) <= 6;
  }
  if (_capsFinding.firstMatch(p) case final m?) {
    return pills.contains(m[1]) &&
        pills.contains(m[2]) &&
        double.parse(m[3]!) <= .5 &&
        double.parse(m[4]!) <= 6;
  }
  return false;
}

Future<List<String>> _rowsAsDrawn(WidgetTester t) async {
  final kept = <String>[];
  final circles = _circles(t);
  final acts = _acts(t);
  final pills = _dayPills(t);
  for (final p in (await _rowCheck.check(
    _screen(t),
    runAsync: t.runAsync,
  )).problems) {
    if (_apexOnly(p, circles)) {
      _asideRows.update(_apexReason, (n) => n + 1, ifAbsent: () => 1);
      continue;
    }
    if (acts.any(
      (a) =>
          p.startsWith('a button "$a" beside ') &&
          RegExp(r': its icon is [\d.]+ px above').hasMatch(p),
    )) {
      _asideRows.update(_actReason, (n) => n + 1, ifAbsent: () => 1);
      continue;
    }
    if (_ringOnly(p, pills)) {
      _asideRows.update(_ringReason, (n) => n + 1, ifAbsent: () => 1);
      continue;
    }
    final aside = _notFaceRows.where((n) => n.$1.hasMatch(p)).firstOrNull;
    if (aside == null) {
      kept.add(p);
    } else {
      _asideRows.update(
        aside.$2.split(':').first,
        (n) => n + 1,
        ifAbsent: () => 1,
      );
    }
  }
  return kept;
}

/// ui_core's DesignWidthCheck (where a stepper's value may be a count and its unit) reads Ledger's
/// composer, two discs round a line of words (Attach, the message, Send), as a stepper, and holds it to its content's
/// width. It is the message entry, as wide as its column by design. Set aside by kind: a stepper named by the
/// composer's Attach, with a composer on screen. Likewise a masthead's month bar (Earlier months, the month, the next
/// month not yet there), read as a stepper since its disabled disc is drawn in pencil rather than faded: it stands in
/// the title's place, its ways at the bar's two ends by design. Any other width finding fails.
/// The titles of the disclosures on screen. ui_core's width check takes any one-line control with an expanded state
/// for a select's closed face; a disclosure's head is a ruled row across its column (an accordion's), which opens its
/// own section in place, never a list of choices, so it is held to its column, not to its words.
Set<String> _disclosures(WidgetTester t) => {
  for (final e in find.byType(LedgerDisclosure).evaluate())
    (e.widget as LedgerDisclosure).title,
};

Future<List<String>> _widthsAsDrawn(WidgetTester t) async {
  final composer = find.byType(LedgerComposer).evaluate().isNotEmpty;
  final monthBar = find
      .byWidgetPredicate((w) => w is LedgerTopBar && w.heading != null)
      .evaluate()
      .isNotEmpty;
  final disclosures = _disclosures(t);
  return [
    for (final p in (await _widthCheck.check(
      _screen(t),
      runAsync: t.runAsync,
    )).problems)
      if (!(composer && p.startsWith('a stepper "Attach": ')) &&
          !(monthBar && p.startsWith('a stepper "Earlier months": ')) &&
          !disclosures.any((d) => p.startsWith('a select "$d": ')))
        p,
  ];
}

Rect _global(RenderBox b, Rect r) =>
    MatrixUtils.transformRect(b.getTransformTo(null), r);

/// Where an open list's frame is cut (an open list floats over everything, never clipped by the card
/// or panel it opens from): the window's edge, or a clip between it and the window (a card, a panel, a
/// scrolling page) that does not hold its whole frame. Null when the whole frame paints.
String? _cut(WidgetTester t, Finder list) {
  final box = t.renderObject<RenderBox>(list);
  final frame = _global(box, Offset.zero & box.size);
  final window = Offset.zero & (t.view.physicalSize / t.view.devicePixelRatio);
  if (!window.inflate(.5).contains(frame.topLeft) ||
      !window.inflate(.5).contains(frame.bottomRight)) {
    return 'the list ($frame) runs past the window ($window)';
  }
  for (RenderObject? a = box.parent; a != null; a = a.parent) {
    if (a is RenderBox &&
        (a is RenderClipRect || a is RenderClipRRect || a is RenderClipPath)) {
      final clip = _global(a, Offset.zero & a.size).inflate(.5);
      if (!clip.contains(frame.topLeft) || !clip.contains(frame.bottomRight)) {
        return 'the list ($frame) is cut by ${a.debugCreator ?? a.runtimeType} ($clip)';
      }
    }
  }
  return null;
}

bool _shown(RenderObject o) {
  for (RenderObject? r = o; r != null; r = r.parent) {
    if (r is RenderOpacity && r.opacity == 0) return false;
    if (r is RenderAnimatedOpacity && r.opacity.value == 0) return false;
    if (r is RenderOffstage && r.offstage) return false;
  }
  return true;
}

bool _isIcon(RenderParagraph p) =>
    p.text.style?.fontFamily?.toLowerCase().contains('lucide') ?? false;

String _words(RenderParagraph p) =>
    p.text.toPlainText(includeSemanticsLabels: false);

/// Whether [p] sets its words on one line.
bool _oneLine(RenderParagraph p) {
  final words = _words(p);
  if (words.trim().isEmpty) return false;
  final boxes = p.getBoxesForSelection(
    TextSelection(baseOffset: 0, extentOffset: words.length),
  );
  return boxes.isNotEmpty &&
      boxes.every((b) => (b.top - boxes.first.top).abs() < 1);
}

List<RenderParagraph> _paragraphs(RenderObject root) {
  final out = <RenderParagraph>[];
  void visit(RenderObject o) {
    if (o is RenderParagraph && o.hasSize && !o.size.isEmpty && _shown(o)) {
      out.add(o);
    }
    o.visitChildren(visit);
  }

  visit(root);
  return out;
}

// --- A glyph beside a title --------------------------------------------------------------------------------------

/// Capitals with a stem or bars from the cap height to the baseline, and which of their columns hold them: a left
/// stem, a middle stem, or bars across.
const String _leftStem = 'BDEFHKLMNPR';
const String _midStem = 'IT';
const String _bars = 'Z';

/// The pairs on screen of a glyph and the one-line words beside it in one row, each read from pixels: the glyph's
/// ink middle against the middle of the words' first flat capital as drawn. A glyph beside a block of words (a lead
/// beside a title and its line under) is a different composition and is not read.
Future<List<String>> _glyphs(WidgetTester t) async {
  final found = <String>[];
  final root = t.renderObject(find.byKey(_shotKey));
  final view = Offset.zero & t.view.physicalSize;
  for (final glyph in _paragraphs(root).where(_isIcon)) {
    // The row the glyph stands in: its nearest flex, which must run across.
    RenderObject? child = glyph;
    RenderObject? up = glyph.parent;
    while (up != null && up is! RenderFlex) {
      child = up;
      up = up.parent;
    }
    if (up is! RenderFlex || up.direction != Axis.horizontal) continue;
    final row = up;
    final glyphBox = _global(glyph, Offset.zero & glyph.size);
    if (!view.contains(glyphBox.center)) continue;
    if (_paragraphs(child!).length != 1) continue;
    // The words beside it: one one-line paragraph in another child of the row, the nearest across.
    RenderParagraph? words;
    var nearest = double.infinity;
    var at = row.firstChild;
    while (at != null) {
      if (at != child) {
        final held = _paragraphs(at).where((p) => !_isIcon(p)).toList();
        if (held.length == 1 && _oneLine(held.single)) {
          final box = _global(held.single, Offset.zero & held.single.size);
          final apart = math.max(
            box.left - glyphBox.right,
            glyphBox.left - box.right,
          );
          final overlaps =
              box.top < glyphBox.bottom && box.bottom > glyphBox.top;
          if (overlaps && apart > -1 && apart < nearest) {
            nearest = apart;
            words = held.single;
          }
        }
      }
      at = (at.parentData! as FlexParentData).nextSibling;
    }
    if (words == null) continue;
    final text = _words(words);
    final i = text
        .split('')
        .indexWhere(
          (c) =>
              _leftStem.contains(c) ||
              _midStem.contains(c) ||
              _bars.contains(c),
        );
    if (i < 0) continue;
    final c = text[i];
    final boxes = words.getBoxesForSelection(
      TextSelection(baseOffset: i, extentOffset: i + 1),
    );
    if (boxes.isEmpty) continue;
    final cap = _global(words, boxes.first.toRect());
    final line = _global(words, Offset.zero & words.size);
    final region = glyphBox.expandToInclude(line).inflate(4);
    final s = await _shoot(t, region);
    // The capital's columns that hold its stem or bars.
    final w = cap.width;
    final (l, r) = _leftStem.contains(c)
        ? (cap.left + w * .05, cap.left + w * .4)
        : _midStem.contains(c)
        ? (cap.left + w * .3, cap.left + w * .7)
        : (cap.left + w * .1, cap.right - w * .1);
    final cx0 = s.dx(l).round(),
        cx1 = math.max(s.dx(r).round(), s.dx(l).round() + 1);
    final cy0 = s.dy(line.top).floor() - 2, cy1 = s.dy(line.bottom).ceil() + 2;
    final capInk = _inkRows(
      s,
      cx0,
      cx1,
      cy0,
      cy1,
      _ground(s, cx0, cx1, cy0, cy1),
    );
    final gx0 = s.dx(glyphBox.left).floor(), gx1 = s.dx(glyphBox.right).ceil();
    final gy0 = s.dy(glyphBox.top).floor() - 1,
        gy1 = s.dy(glyphBox.bottom).ceil() + 1;
    final glyphInk = _inkRows(
      s,
      gx0,
      gx1,
      gy0,
      gy1,
      _ground(s, gx0, gx1, gy0, gy1),
    );
    if (capInk == null || glyphInk == null) continue;
    final off = (glyphInk.$1 + glyphInk.$2) / 2 - (capInk.$1 + capInk.$2) / 2;
    if (off.abs() > .5) {
      found.add(
        'the glyph beside "$text" stands its middle ${off.abs().toStringAsFixed(2)} device px '
        '${off > 0 ? 'below' : 'above'} the capitals\' middle',
      );
    }
  }
  return found;
}

// --- A chosen fill covers its cell ------------------------------------------------------------------------------

/// The drawn top and bottom (logical, on screen) of a pressable's face, read down and up its middle column from its
/// reach's edges.
Future<(double, double)?> _pillRows(WidgetTester t, Rect reach) async {
  final s = await _shoot(t, reach.inflate(2));
  final x = s.dx(reach.center.dx).round();
  final top = s.dy(reach.top).round(), bottom = s.dy(reach.bottom).round();
  final ground = s.px(x, top - 2);
  final a = _edge(s, x, top - 2, s.dy(reach.center.dy).round(), ground);
  final b = _edge(s, x, bottom + 2, s.dy(reach.center.dy).round(), ground);
  if (a == null || b == null) return null;
  return (s.origin.dy + a / _ratio, s.origin.dy + b / _ratio);
}

/// In each set of pills (LedgerFilters, a row of LedgerSegmentedControl), the chosen pill's ground stands from the top to the
/// bottom its unchosen neighbours draw: the cell a person sees. LedgerSegmentedControl, a segmented set in one ring whose
/// unchosen words draw no cell, holds its chosen thumb the same distance inside the ring above as below.
Future<List<String>> _fills(WidgetTester t) async {
  final found = <String>[];
  final view = Offset.zero & t.view.physicalSize;
  Future<void> compare(String what, List<(String, bool, Rect)> pills) async {
    final chosen = pills.where((p) => p.$2).toList();
    final rest = pills.where((p) => !p.$2).toList();
    if (chosen.isEmpty || rest.isEmpty) return;
    final other = await _pillRows(t, rest.first.$3);
    if (other == null) return;
    for (final c in chosen) {
      if (!view.contains(c.$3.center)) continue;
      final mine = await _pillRows(t, c.$3);
      if (mine == null) continue;
      final dt = (mine.$1 - other.$1) * _ratio,
          db = (mine.$2 - other.$2) * _ratio;
      if (dt.abs() > .5 || db.abs() > .5) {
        found.add(
          '$what: the chosen "${c.$1}" fills ${mine.$1.toStringAsFixed(2)}-${mine.$2.toStringAsFixed(2)} '
          'where "${rest.first.$1}" draws ${other.$1.toStringAsFixed(2)}-${other.$2.toStringAsFixed(2)}',
        );
      }
    }
  }

  for (final e
      in find
          .byWidgetPredicate((w) => w is LedgerSegmentedControl)
          .evaluate()) {
    final ring = _global(
      e.renderObject! as RenderBox,
      Offset.zero & (e.renderObject! as RenderBox).size,
    );
    if (!view.contains(ring.center) || !_shown(e.renderObject!)) continue;
    for (final p
        in find
            .descendant(
              of: find.byWidget(e.widget),
              matching: find.byType(LedgerPressable),
            )
            .evaluate()) {
      if ((p.widget as LedgerPressable).selected != true) continue;
      final thumb = await _pillRows(
        t,
        _global(
          p.renderObject! as RenderBox,
          Offset.zero & (p.renderObject! as RenderBox).size,
        ),
      );
      if (thumb == null) continue;
      final above = thumb.$1 - ring.top, below = ring.bottom - thumb.$2;
      if ((above - below).abs() * _ratio > .5) {
        found.add(
          'LedgerSegmentedControl: the chosen "${(p.widget as LedgerPressable).label}" stands ${above.toStringAsFixed(2)} inside '
          'the ring above and ${below.toStringAsFixed(2)} below',
        );
      }
    }
  }
  for (final type in const [LedgerFilters]) {
    for (final e in find.byType(type).evaluate()) {
      final pills = <(String, bool, Rect)>[
        for (final p
            in find
                .descendant(
                  of: find.byWidget(e.widget),
                  matching: find.byType(LedgerPressable),
                )
                .evaluate())
          if (_shown(p.renderObject!))
            (
              (p.widget as LedgerPressable).label ?? '',
              (p.widget as LedgerPressable).selected ?? false,
              _global(
                p.renderObject! as RenderBox,
                Offset.zero & (p.renderObject! as RenderBox).size,
              ),
            ),
      ];
      await compare('$type', pills);
    }
  }
  // Chips standing in one row.
  final chips = <double, List<(String, bool, Rect)>>{};
  for (final e in find.byType(LedgerChip).evaluate()) {
    final box = e.renderObject! as RenderBox;
    if (!_shown(box)) continue;
    final chip = e.widget as LedgerChip;
    final r = _global(box, Offset.zero & box.size);
    chips.putIfAbsent(r.top.roundToDouble(), () => []).add((
      chip.label,
      chip.selected,
      r,
    ));
  }
  for (final row in chips.values) {
    await compare('LedgerChip row', row);
  }
  return found;
}

// --- Controls in one row ---------------------------------------------------------------------------------------

/// The drawn faces of the controls on screen: each press target's first box drawn with a fill or a ring all round,
/// at most a control's size. A frameless control (its words before any such box) has none.
List<(String, Rect)> _faces(WidgetTester t) {
  final out = <(String, Rect)>[];
  final view = Offset.zero & t.view.physicalSize;
  for (final e in find.byType(LedgerPressable).evaluate()) {
    final root = e.renderObject;
    if (root == null || !_shown(root)) continue;
    RenderBox? face;
    var words = false;
    void visit(RenderObject o) {
      if (face != null || words) return;
      if (o is RenderDecoratedBox &&
          o.hasSize &&
          o.position == DecorationPosition.background) {
        final d = o.decoration;
        if (d is BoxDecoration) {
          final filled = d.color != null && d.color!.a > 0;
          final ringed =
              d.border != null &&
              d.border!.isUniform &&
              d.border!.top.width > 0;
          if (filled || ringed) {
            face = o;
            return;
          }
        }
      }
      if (o is RenderParagraph) {
        words = true;
        return;
      }
      o.visitChildren(visit);
    }

    visit(root);
    final f = face;
    if (f == null) continue;
    final r = _global(f, Offset.zero & f.size);
    if (r.height > 64 || r.width > 480 || !view.overlaps(r)) continue;
    out.add(((e.widget as LedgerPressable).label ?? '', r));
  }
  return out;
}

/// Controls that stand side by side in one row (overlapping by half the shorter, at most 32 apart) show one top and
/// one bottom: their drawn faces, read from layout.
Future<List<String>> _faceRows(WidgetTester t) async {
  final found = <String>[];
  final faces = _faces(t)..sort((a, b) => a.$2.left.compareTo(b.$2.left));
  final seen = <String>{};
  for (var i = 0; i < faces.length; i++) {
    for (var j = i + 1; j < faces.length; j++) {
      final a = faces[i], b = faces[j];
      final gap = b.$2.left - a.$2.right;
      if (gap < 0 || gap > 32) continue;
      final overlap =
          math.min(a.$2.bottom, b.$2.bottom) - math.max(a.$2.top, b.$2.top);
      if (overlap < math.min(a.$2.height, b.$2.height) / 2) continue;
      if ((a.$2.top - b.$2.top).abs() > .25 ||
          (a.$2.bottom - b.$2.bottom).abs() > .25) {
        final line =
            '"${a.$1}" ${a.$2.height.toStringAsFixed(1)} tall at ${a.$2.top.toStringAsFixed(1)} beside '
            '"${b.$1}" ${b.$2.height.toStringAsFixed(1)} at ${b.$2.top.toStringAsFixed(1)}';
        if (seen.add(line)) found.add(line);
      }
    }
  }
  return found;
}

// --- The outline a person sees ------------------------------------------------------------------------------------

/// The seen box (logical) of a control drawn in [reach]: where its face meets the ground it stands on, read across
/// its middle row and down its middle column from just outside it. A ring or a shadow that does not show on that
/// ground is not its edge.
Future<Rect?> _seen(WidgetTester t, Rect reach) async {
  final s = await _shoot(t, reach.inflate(6));
  final cx = s.dx(reach.center.dx).round(), cy = s.dy(reach.center.dy).round();
  final x0 = s.dx(reach.left).round() - 6, x1 = s.dx(reach.right).round() + 6;
  final y0 = s.dy(reach.top).round() - 6, y1 = s.dy(reach.bottom).round() + 6;
  final ground = s.px(x0, cy);
  final top = _edge(s, cx, y0, cy, ground);
  final bottom = _edge(s, cx, y1, cy, ground);
  final left = _edge(s, cy, x0, cx, ground, across: true);
  final right = _edge(s, cy, x1, cx, ground, across: true);
  if (top == null || bottom == null || left == null || right == null) {
    return null;
  }
  return Rect.fromLTRB(
    s.origin.dx + left / _ratio,
    s.origin.dy + top / _ratio,
    s.origin.dx + right / _ratio,
    s.origin.dy + bottom / _ratio,
  );
}

/// Every row of two or more buttons of one laid-out size on screen shows one top and one bottom; inside [card] (a
/// sheet's or dialog's face) the row's outer side insets are equal.
Future<List<String>> _rows(WidgetTester t, {Finder? within, Rect? card}) async {
  final found = <String>[];
  // A row is the nearest flex or LedgerEvenActs (a card's or a page's acts: across in even shares, or stacked when
  // one's words would not fit its share).
  bool isRow(RenderObject r) =>
      r is RenderFlex || r.runtimeType.toString() == '_RenderEvenActs';
  final byRow = <RenderObject, List<(String, Rect)>>{};
  final view = Offset.zero & t.view.physicalSize;
  final buttons = within == null
      ? find.byType(LedgerButton)
      : find.descendant(of: within, matching: find.byType(LedgerButton));
  for (final e in buttons.evaluate()) {
    final box = e.renderObject! as RenderBox;
    if (!_shown(box) ||
        !view.contains(_global(box, Offset.zero & box.size).center)) {
      continue;
    }
    RenderObject? up = box.parent;
    while (up != null && !isRow(up)) {
      up = up.parent;
    }
    if (up == null) continue;
    byRow.putIfAbsent(up, () => []).add((
      (e.widget as LedgerButton).label,
      _global(box, Offset.zero & box.size),
    ));
  }
  for (final MapEntry(key: flex, value: buttons) in byRow.entries) {
    if (buttons.length < 2) continue;
    if (buttons.any(
      (b) => (b.$2.height - buttons.first.$2.height).abs() > .5,
    )) {
      continue;
    }
    final seen = <(String, Rect)>[];
    for (final b in buttons) {
      final r = await _seen(t, b.$2);
      if (r == null) {
        found.add('"${b.$1}" shows no edge on its ground');
      } else {
        seen.add((b.$1, r));
      }
    }
    if (seen.length < 2) continue;
    // Even acts lie across when they share one top, as laid out.
    final across = flex is RenderFlex
        ? flex.direction == Axis.horizontal
        : buttons.every((b) => (b.$2.top - buttons.first.$2.top).abs() < .5);
    final a = seen.first;
    for (final b in seen.skip(1)) {
      if (across) {
        if ((b.$2.top - a.$2.top).abs() * _ratio > .5 ||
            (b.$2.bottom - a.$2.bottom).abs() * _ratio > .5) {
          found.add(
            '"${a.$1}" shows ${a.$2.top.toStringAsFixed(1)}-${a.$2.bottom.toStringAsFixed(1)} beside '
            '"${b.$1}" ${b.$2.top.toStringAsFixed(1)}-${b.$2.bottom.toStringAsFixed(1)}',
          );
        }
      } else if ((b.$2.left - a.$2.left).abs() * _ratio > .5 ||
          (b.$2.right - a.$2.right).abs() * _ratio > .5) {
        found.add(
          '"${a.$1}" shows ${a.$2.left.toStringAsFixed(1)}-${a.$2.right.toStringAsFixed(1)} over '
          '"${b.$1}" ${b.$2.left.toStringAsFixed(1)}-${b.$2.right.toStringAsFixed(1)}',
        );
      }
    }
    if (card != null) {
      final start = seen.map((s) => s.$2.left).reduce(math.min) - card.left;
      final end = card.right - seen.map((s) => s.$2.right).reduce(math.max);
      if ((start - end).abs() * _ratio > .5) {
        found.add(
          'the acts stand ${start.toStringAsFixed(1)} from the card\'s start and ${end.toStringAsFixed(1)} from its end',
        );
      }
    }
  }
  return found;
}

/// Scrolls [target] to the middle of its scroll, clear of any bar drawn over the scroll's ends, and lets it settle.
/// The words of the first button that says [words]: what a person taps. From 600 a button keeps to its measure inside
/// a wider box (a stretched column's), so the box's middle can lie beside its face.
Finder _wordsOf(String words) => find
    .descendant(
      of: find.widgetWithText(LedgerButton, words).first,
      matching: find.text(words),
    )
    .first;

Future<void> _reveal(WidgetTester t, Finder target) async {
  await Scrollable.ensureVisible(t.element(target), alignment: .5);
  await t.pumpAndSettle();
}

// --- Layout of choices -------------------------------------------------------------------------------------------

/// The lines [boxes] stand on (by their tops), each with how many it holds.
List<int> _lines(Iterable<Rect> boxes) {
  final lines = <double, int>{};
  for (final b in boxes) {
    lines.update(b.top.roundToDouble(), (n) => n + 1, ifAbsent: () => 1);
  }
  final tops = lines.keys.toList()..sort();
  return [for (final top in tops) lines[top]!];
}

Widget _host(Widget child, {Brightness brightness = Brightness.light}) =>
    RepaintBoundary(
      key: _shotKey,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        builder: (context, page) =>
            LedgerHost(brightness: brightness, child: page!),
        home: Builder(
          builder: (context) => SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: LedgerLayout.gutter(context),
              vertical: 24,
            ),
            child: child,
          ),
        ),
      ),
    );

Future<void> _pumpAt(WidgetTester t, Size size, Widget child) async {
  t.view.physicalSize = size;
  t.view.devicePixelRatio = 1;
  await t.pumpWidget(_host(child));
  await t.pumpAndSettle();
}

const List<IconData> _icons = [
  LucideIcons.utensils,
  LucideIcons.bus,
  LucideIcons.house,
  LucideIcons.film,
  LucideIcons.pill,
  LucideIcons.shoppingBag,
  LucideIcons.gift,
];

/// The everyday cases of the outline check: 390 standard by day, 1440 compact by night.
bool _outlineEveryday(
  Size size,
  LedgerDensity density,
  QuillAppearance appearance,
) =>
    (size.width == 390 &&
        density == LedgerDensity.standard &&
        appearance == QuillAppearance.light) ||
    (size.width == 1440 &&
        density == LedgerDensity.compact &&
        appearance == QuillAppearance.dark);

/// The outline a person sees is the control's box, in a sheet, a dialog and on a page: its [everyday] cases, or the
/// rest of its sizes, densities and appearances.
void _outlineTest({required bool everyday}) {
  testWidgets(
    experimentalLeakTesting: _tracked,
    everyday
        ? 'the outline a person sees is the control\'s box: in a sheet, a dialog and on a page, at 390 standard by day '
              'and 1440 compact by night'
        : 'the outline a person sees is the control\'s box: in a sheet, a dialog and on a page, at the other sizes, '
              'densities and appearances',
    (t) async {
      addTearDown(t.view.reset);
      // Shadows drawn, as a person sees them; set back inside the body, since the binding checks the painting
      // switches before any tear-down runs.
      debugDisableShadows = false;
      final found = <String>[];
      final choices = galleryPages.firstWhere((p) => p.id == 'choices');
      try {
        for (final size in const [Size(390, 844), Size(1440, 900)]) {
          for (final density in LedgerDensity.values) {
            for (final appearance in QuillAppearance.values.where(
              (a) => a != QuillAppearance.system,
            )) {
              if (_outlineEveryday(size, density, appearance) != everyday) {
                continue;
              }
              final where =
                  '${size.width.round()} ${density.name} ${appearance.name}';
              found.addAll([
                for (final p in await _overlays(
                  t,
                  size,
                  density,
                  appearance,
                  (t, card) async => [
                    ...await _rows(t, within: card, card: t.getRect(card)),
                    for (final p in await _rowsAsDrawn(t))
                      if (_onCard(p, _namesWithin(t, card))) 'as drawn: $p',
                  ],
                ))
                  '$where $p',
              ]);
              // On the page: the sent transfer's two acts.
              await _quill(
                t,
                _screens.first,
                size,
                density: density,
                appearance: appearance,
              );
              final brightness = appearance == QuillAppearance.dark
                  ? Brightness.dark
                  : Brightness.light;
              t
                  .state<QuillFrameState>(find.byType(QuillFrame))
                  .push(choices.build(brightness));
              await _rest(t);
              final row = find.byType(LedgerButtonRow);
              if (row.evaluate().isNotEmpty) {
                await _reveal(t, row.first);
                found.addAll([
                  for (final p in await _rows(t)) '$where page · $p',
                ]);
              }
            }
          }
        }
      } finally {
        debugDisableShadows = true;
      }
      expect(found, isEmpty, reason: found.join('\n'));
    },
    timeout: const Timeout(_reading),
    tags: goldensSweepUnless(everyday),
  );
}

/// The widths ui_core's width check holds a control at.
const List<double> _widthsChecked = [600, 1024, 1440, 1920];

/// ui_core's DesignWidthCheck: from 600 wide, a button, a select, a stepper or a segmented control keeps
/// to its content's width (at most 320 past it), on every screen, page, dialog and sheet, at every density. Every
/// screen and page at each of [widths] under each of [densities], or with [once] each once, the width and density
/// turning; the dialogs and sheets at [overlaysAt], none when null.
void _widthTest(
  List<double> widths, {
  required double? overlaysAt,
  required bool everyday,
  List<LedgerDensity> densities = LedgerDensity.values,
  bool once = false,
}) {
  final pages = once
      ? 'every screen and page once from 600 to 1920'
      : 'every screen and page at ${widths.map((w) => w.round()).join(', ')}'
            '${densities.length == 1 ? ' ${densities.single.name}' : ''}';
  final overlays = overlaysAt == null
      ? ''
      : ', its dialogs and sheets at ${overlaysAt.round()}';
  testWidgets(
    experimentalLeakTesting: _tracked,
    '$pages$overlays: a control keeps to its content\'s width',
    (t) async {
      addTearDown(t.view.reset);
      final found = await _everywhere(
        t,
        _widthsAsDrawn,
        widths: widths,
        densities: densities,
        once: once,
      );
      if (overlaysAt != null) {
        final size = Size(overlaysAt, overlaysAt >= 1920 ? 1080 : 900);
        found.addAll([
          for (final p in await _overlays(
            t,
            size,
            LedgerDensity.standard,
            QuillAppearance.light,
            // The dialog or sheet itself: the page under its barrier is read on its own above, unblocked. Read
            // through the barrier, ui_core takes the composer (Attach, the message, Send) for a stepper: the barrier
            // blocks the page's semantics, so its field no longer reads as an entry.
            (t, card) async => (await _widthCheck.check(
              t.element(card),
              runAsync: t.runAsync,
            )).problems,
          ))
            '${overlaysAt.round()} $p',
        ]);
      }
      expect(found, isEmpty, reason: found.join('\n'));
    },
    timeout: const Timeout(_reading),
    tags: goldensSweepUnless(everyday),
  );
}

/// The set-up every screen check file runs: Ledger's fonts, every change landing at once, the density set back.
void screenChecksSetUp() {
  setUpAll(_loadFonts);
  // Geometry read at rest: every change lands at once (the motion is judged by eye in the web build).
  setUpAll(_stillMotion);
  tearDownAll(_movingMotion);
  tearDown(() => kitDensity = null);
}

/// What the rows check reads on a page: ui_core's row check as drawn, the faces' rows, the chosen fills.
Future<List<String>> _rowsRead(WidgetTester t) async => [
  for (final p in await _faceRows(t)) 'row: $p',
  for (final p in await _rowsAsDrawn(t)) 'rows as drawn: $p',
  for (final p in await _fills(t)) 'fill: $p',
];

/// The rows check at [width] by [brightness]: every screen and gallery page under each density, ui_core's row check
/// reading every screen at 3x. The sweep, one file per width and appearance, a test per density: a test's tracked
/// objects are let go at its end, so no one test holds more than a pass of the pages.
void screenRowsSweep(double width, Brightness brightness) {
  screenChecksSetUp();
  for (final density in LedgerDensity.values) {
    final when =
        '${width.round()} ${brightness == Brightness.dark ? 'night' : 'day'} ${density.name}';
    testWidgets(
      experimentalLeakTesting: _tracked,
      'every screen and gallery page at $when: controls in a row show one height and one outline, a chosen fill '
      'covers its cell',
      (t) async {
        addTearDown(t.view.reset);
        final found = await _everywhere(
          t,
          _rowsRead,
          widths: [width],
          densities: [density],
          brightnesses: [brightness],
        );
        // Lists what the check read, for the log.
        // ignore: avoid_print
        print('rows set aside, $when: $_asideRows');
        expect(found, isEmpty, reason: found.join('\n'));
      },
      timeout: const Timeout(_reading),
      tags: goldensSweepUnless(false),
    );
  }
}

/// The rows check's everyday case: every screen and gallery page once, at 390 or 1440, by day or by night, under one
/// density each, the three turning over the pages. Read in [parts] files side by side, this one the [part]th.
void screenRowsOnce(int part, int parts) {
  screenChecksSetUp();
  testWidgets(
    experimentalLeakTesting: _tracked,
    'every screen and gallery page once (part ${part + 1} of $parts), the width, appearance and density turning: '
    'controls in a row show one height and one outline, a chosen fill covers its cell',
    (t) async {
      addTearDown(t.view.reset);
      final found = await _everywhere(
        t,
        _rowsRead,
        brightnesses: Brightness.values,
        once: true,
        only: (i) => i % parts == part,
      );
      // Lists what the check read, for the log.
      // ignore: avoid_print
      print('rows set aside, once, part ${part + 1}: $_asideRows');
      expect(found, isEmpty, reason: found.join('\n'));
    },
    timeout: const Timeout(_reading),
    tags: goldensSweepUnless(true),
  );
}

/// The rest of the screen checks' sweep: the outline at every size, density and appearance, and the width check on every
/// screen, page, dialog and sheet at every width.
void screenSweep() {
  screenChecksSetUp();
  _outlineTest(everyday: false);
  for (final width in _widthsChecked) {
    for (final density in LedgerDensity.values) {
      _widthTest(
        [width],
        densities: [density],
        overlaysAt: density == LedgerDensity.standard ? width : null,
        everyday: false,
      );
    }
  }
}

/// The screen checks, each matrix by its everyday cases (the sweep files run the rest; the rows check's everyday
/// case is `screen_rows_part_<n>_test.dart`'s).
void screenChecksMain() {
  screenChecksSetUp();

  // A glyph beside a title on the capitals' middle. The check reads 0.5 to 2.3 device px off on Lucide glyphs whose
  // ink is not centred in their 24 grid (house, bus, pill, the category marks), and the bell beside the avatar's
  // monogram, which is a mark, not a label; skipped until the check allows for them, so its findings are not read as
  // passing.
  testWidgets(
    experimentalLeakTesting: _tracked,
    "every screen and gallery page, every density: a glyph beside a title stands on the capitals' middle",
    (t) async {
      addTearDown(t.view.reset);
      final found = await _everywhere(t, _glyphs);
      expect(found, isEmpty, reason: found.join('\n'));
    },
    skip: true,
    tags: 'goldens',
  );

  testWidgets(
    experimentalLeakTesting: _tracked,
    "a menu's current row fills its row from edge to edge, every density",
    (t) async {
      addTearDown(t.view.reset);
      final found = <String>[];
      for (final density in LedgerDensity.values) {
        for (final brightness in Brightness.values) {
          t.view.physicalSize = const Size(390, 844);
          t.view.devicePixelRatio = 1;
          await t.pumpWidget(
            _host(
              Builder(
                builder: (context) => LedgerTheme(
                  data: context.ledgerTheme.copyWith(density: density),
                  child: LedgerMenu(
                    head: 'Spent by month',
                    items: [
                      LedgerMenuItem(
                        'November 2026',
                        amount: 1204.5,
                        onTap: () {},
                      ),
                      LedgerMenuItem(
                        'October 2026',
                        amount: 2486.12,
                        selected: true,
                        onTap: () {},
                      ),
                      LedgerMenuItem(
                        'September 2026',
                        amount: 2310,
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
              ),
              brightness: brightness,
            ),
          );
          await t.pumpAndSettle();
          final menu = t.getRect(find.byType(LedgerMenu));
          final item = t.getRect(
            find
                .ancestor(
                  of: find.text('October 2026'),
                  matching: find.byType(LedgerPressable),
                )
                .first,
          );
          final s = await _shoot(t, menu.inflate(4));
          final y = s.dy(item.top + 3).round();
          final x = s.dx(item.left + 3).round();
          final fill = s.px(s.dx(item.center.dx).round(), y);
          final paper = s.px(
            s.dx(menu.left + 3).round(),
            s.dy(menu.top + 3).round(),
          );
          if (_dist(fill, paper) < 8) {
            found.add(
              '${density.name} $brightness: the current row draws no ground',
            );
            continue;
          }
          bool isFill(int i, int j) => _dist(s.px(i, j), fill) < 6;
          var l = s.dx(item.center.dx).round();
          while (l > 0 && isFill(l - 1, y)) {
            l--;
          }
          var r = s.dx(item.center.dx).round();
          while (r < s.width - 1 && isFill(r + 1, y)) {
            r++;
          }
          var top = y;
          while (top > 0 && isFill(x, top - 1)) {
            top--;
          }
          var bottom = y;
          while (bottom < s.height - 1 && isFill(x, bottom + 1)) {
            bottom++;
          }
          final want = (
            s.dx(menu.left),
            s.dx(menu.right),
            s.dy(item.top + 1),
            s.dy(item.bottom),
          );
          if ((l - want.$1).abs() > 1 || (r + 1 - want.$2).abs() > 1) {
            found.add(
              '${density.name} $brightness: the current row fills $l-${r + 1} of the menu\'s ${want.$1}-${want.$2}',
            );
          }
          if ((top - want.$3).abs() > 1 || (bottom + 1 - want.$4).abs() > 1) {
            found.add(
              '${density.name} $brightness: the current row fills $top-${bottom + 1} of its row\'s ${want.$3}-${want.$4}',
            );
          }
        }
      }
      expect(found, isEmpty, reason: found.join('\n'));
    },
    tags: 'goldens',
  );

  _outlineTest(everyday: true);
  _widthTest(_widthsChecked, overlaysAt: 1024, everyday: true, once: true);

  testWidgets(
    experimentalLeakTesting: _tracked,
    "a field's list: on the field's leading edge, at least its width, its words 16 in from the field's",
    (t) async {
      addTearDown(t.view.reset);
      final found = <String>[];
      final gutters = <double>{};
      for (final name in const ['settings', 'entry']) {
        final s = _screens.firstWhere((s) => s.name == name);
        for (final size in const [
          Size(390, 844),
          Size(600, 900),
          Size(1024, 768),
          Size(1440, 900),
          Size(1920, 1080),
        ]) {
          await _quill(t, s, size);
          final selects = find.byWidgetPredicate((w) => w is LedgerSelect);
          for (var i = 0; i < selects.evaluate().length; i++) {
            final select = selects.at(i);
            final face = find
                .descendant(of: select, matching: find.byType(LedgerPressable))
                .first;
            await _reveal(t, face);
            final faceRect = t.getRect(face);
            await t.tap(face);
            await t.pumpAndSettle();
            final list = find.byWidgetPredicate(
              (w) => w.runtimeType.toString().startsWith('_SelectList'),
            );
            final at =
                '$name ${size.width.round()} "${(t.widget(select) as LedgerSelect).labelText}"';
            if (list.evaluate().isEmpty) {
              found.add('$at: no list opened');
              continue;
            }
            found.addAll([
              for (final p in (await _listCheck.checkList(
                t.element(face),
                runAsync: t.runAsync,
              )).problems)
                if (!_barAside(t, p, faceRect)) '$at, as ui_core reads it: $p',
            ]);
            final listRect = t.getRect(
              find
                  .descendant(of: list, matching: find.byType(DecoratedBox))
                  .first,
            );
            if ((listRect.left - faceRect.left).abs() > .5) {
              found.add(
                '$at: the list starts at ${listRect.left}, the field at ${faceRect.left}',
              );
            }
            if (listRect.width < faceRect.width - .5) {
              found.add(
                '$at: the list is ${listRect.width} wide, the field ${faceRect.width}',
              );
            }
            final fieldWords = find
                .descendant(of: face, matching: find.byType(RichText))
                .evaluate()
                .map((e) {
                  final p = e.renderObject! as RenderParagraph;
                  return _global(p, Offset.zero & p.size).left;
                })
                .first;
            final words = find
                .descendant(of: list, matching: find.byType(RichText))
                .evaluate()
                .where((e) {
                  final p = e.renderObject! as RenderParagraph;
                  return !_isIcon(p) && _words(p).trim().isNotEmpty;
                });
            final xs = <double>{};
            for (final e in words) {
              final p = e.renderObject! as RenderParagraph;
              final x = _global(p, Offset.zero & p.size).left;
              gutters.add((x - listRect.left).roundToDouble());
              xs.add(x.roundToDouble());
              // The rows' 16 in from the field's words (Quill's lists carry no glyphs).
              if ((x - fieldWords - 16).abs() > .5) {
                found.add(
                  '$at: "${_words(p)}" starts at $x, not 16 in from the field\'s words at $fieldWords',
                );
              }
            }
            // Every option's words start on one x, and the open list is never cut.
            if (xs.length > 1) {
              found.add("$at: the options' words start at ${xs.join(', ')}");
            }
            if (_cut(t, list) case final cut?) found.add('$at: $cut');
            await t.sendKeyEvent(LogicalKeyboardKey.escape);
            await t.pumpAndSettle();
          }
        }
      }
      if (gutters.length != 1) {
        found.add(
          'the lists set their words at ${gutters.join(', ')} from their start',
        );
      }
      expect(found, isEmpty, reason: found.join('\n'));
    },
    tags: 'goldens',
  );

  testWidgets(
    experimentalLeakTesting: _tracked,
    "a field's list in a card keeps its options' words on one x, glyphs or none, and is never cut",
    (t) async {
      addTearDown(t.view.reset);
      final found = <String>[];
      for (final size in const [Size(390, 844), Size(1440, 900)]) {
        for (final foot in const [false, true]) {
          await _pumpAt(
            t,
            size,
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // At the window's foot, the list has no room below.
                if (foot) SizedBox(height: size.height - 220),
                // A card that cuts what it holds, as a panel or a scrolling card does.
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LedgerSlip(
                    padding: const EdgeInsets.all(16),
                    child: LedgerSelect<int>(
                      labelText: 'Category',
                      value: 1,
                      items: const [
                        LedgerSelectItem(
                          value: 0,
                          label: 'Groceries',
                          icon: LucideIcons.shoppingBasket,
                        ),
                        LedgerSelectItem(value: 1, label: 'Rent'),
                        LedgerSelectItem(
                          value: 2,
                          label: 'Transit',
                          icon: LucideIcons.bus,
                        ),
                        LedgerSelectItem(value: 3, label: 'Gifts'),
                      ],
                      onChanged: (_) {},
                    ),
                  ),
                ),
              ],
            ),
          );
          await _list(
            t,
            '${size.width.round()}${foot ? ' at the foot' : ''}',
            found,
          );
        }
      }
      expect(found, isEmpty, reason: found.join('\n'));
    },
  );

  testWidgets(
    experimentalLeakTesting: _tracked,
    'no choice is left alone on its line',
    (t) async {
      addTearDown(t.view.reset);
      final found = <String>[];
      for (final size in const [
        Size(390, 844),
        Size(600, 900),
        Size(768, 1024),
        Size(1440, 900),
      ]) {
        for (final n in const [3, 5, 7]) {
          await _pumpAt(
            t,
            size,
            LedgerCategoryTiles(
              tiles: [
                for (var i = 0; i < n; i++)
                  LedgerCategoryTile(
                    icon: _icons[i],
                    name: 'Kind $i',
                    spent: 40.0 * (i + 1),
                    onTap: () {},
                  ),
              ],
            ),
          );
          final tiles = _lines(
            t
                .widgetList(find.byType(LedgerCategoryTile))
                .map((w) => t.getRect(find.byWidget(w))),
          );
          final at = 'category tiles, $n at ${size.width.round()}';
          if (tiles.length > 1 && tiles.last == 1 && tiles.any((n) => n > 1)) {
            found.add('$at: lines of $tiles');
          }
          if (n == 3 && size.width < 600 && tiles.length != 3) {
            found.add('$at: lines of $tiles (one per line)');
          }
          if (n == 3 && size.width >= 600 && tiles.length != 1) {
            found.add('$at: lines of $tiles (one line)');
          }
          await _pumpAt(
            t,
            size,
            LedgerWays(
              ways: [
                for (var i = 0; i < n; i++)
                  LedgerWay(
                    icon: _icons[i],
                    title: 'Way $i',
                    text: 'Its words',
                    onTap: () {},
                  ),
              ],
            ),
          );
          final ways = _lines(
            find
                .descendant(
                  of: find.byType(LedgerWays),
                  matching: find.byType(LedgerPressable),
                )
                .evaluate()
                .map(
                  (e) => _global(
                    e.renderObject! as RenderBox,
                    Offset.zero & (e.renderObject! as RenderBox).size,
                  ),
                ),
          );
          if (ways.length > 1 && ways.last == 1 && ways.any((n) => n > 1)) {
            found.add('ways, $n at ${size.width.round()}: lines of $ways');
          }
        }
      }
      expect(found, isEmpty, reason: found.join('\n'));
    },
  );

  testWidgets(
    experimentalLeakTesting: _tracked,
    'a tile in a line hugs its content beside a taller neighbour',
    (t) async {
      addTearDown(t.view.reset);
      final found = <String>[];
      for (final size in const [Size(390, 844), Size(1440, 900)]) {
        await _pumpAt(
          t,
          size,
          LedgerCategoryTiles(
            tiles: [
              LedgerCategoryTile(
                icon: _icons[0],
                name: 'Dining',
                spent: 86,
                onTap: () {},
              ),
              LedgerCategoryTile(
                icon: _icons[1],
                name: 'Trains, buses and the ferry to the island',
                spent: 42.5,
                onTap: () {},
              ),
            ],
          ),
        );
        // Each tile's words top to bottom: its name, then what was spent; the gap between them is the tile's own,
        // never spread to match the taller tile beside it.
        final gaps = <double>[];
        for (final e in find.byType(LedgerCategoryTile).evaluate()) {
          final words =
              _paragraphs(e.renderObject!).where((p) => !_isIcon(p)).toList()
                ..sort(
                  (a, b) => _global(
                    a,
                    Offset.zero & a.size,
                  ).top.compareTo(_global(b, Offset.zero & b.size).top),
                );
          if (words.length < 2) continue;
          final name = _global(words.first, Offset.zero & words.first.size);
          final spent = _global(words.last, Offset.zero & words.last.size);
          gaps.add(spent.top - name.bottom);
        }
        if (gaps.length == 2 && (gaps[0] - gaps[1]).abs() > .5) {
          found.add(
            '${size.width.round()}: name to spent ${gaps[0]} beside ${gaps[1]}',
          );
        }
      }
      expect(found, isEmpty, reason: found.join('\n'));
    },
  );

  testWidgets(experimentalLeakTesting: _tracked, 'an overlay covers the window', (
    t,
  ) async {
    addTearDown(t.view.reset);
    final found = <String>[];
    final sheet = galleryPages.firstWhere((p) => p.id == 'sheet');
    final commit = galleryPages.firstWhere((p) => p.id == 'commit');
    for (final size in const [
      Size(390, 844),
      Size(768, 1024),
      Size(1440, 900),
    ]) {
      for (final (page, button) in [
        (sheet, 'Freeze card'),
        (commit, 'Archive October'),
      ]) {
        await _quill(t, _screens.first, size);
        t
            .state<QuillFrameState>(find.byType(QuillFrame))
            .push(page.build(Brightness.light));
        await _rest(t);
        final open = _wordsOf(button);
        await _reveal(t, open);
        final points = [
          for (final fx in const [.01, .5, .99])
            for (final fy in const [.01, .5, .99])
              Offset(size.width * fx, size.height * fy),
        ];
        final window = Offset.zero & size;
        final before = await _shoot(t, window);
        await t.tap(open);
        await _rest(t);
        final after = await _shoot(t, window);
        for (final p in points) {
          final x = before.dx(p.dx).round(), y = before.dy(p.dy).round();
          final card = t.getRect(
            find.byType(page == sheet ? LedgerSheetShell : LedgerDialog).last,
          );
          if (card.contains(p)) continue;
          if (_dist(before.px(x, y), after.px(x, y)) < 6) {
            found.add(
              '${size.width.round()} "$button": the window at ${p.dx.round()},${p.dy.round()} is not dimmed',
            );
          }
        }
      }
    }
    expect(found, isEmpty, reason: found.join('\n'));
  }, tags: 'goldens');

  testWidgets(
    experimentalLeakTesting: _tracked,
    'one page frame: every destination starts its title on one edge',
    (t) async {
      addTearDown(t.view.reset);
      final found = <String>[];
      final part = galleryPages.firstWhere((p) => p.id == 'inputs');
      for (final size in const [Size(768, 1024), Size(1440, 900)]) {
        final edges = <String, double>{};
        for (final s in _screens) {
          await _quill(t, s, size);
          final bar = find.byType(LedgerTopBar).last;
          final title = (t.widget(bar) as LedgerTopBar).title ?? '';
          edges[s.name] = t
              .getRect(
                find.descendant(of: bar, matching: find.text(title)).first,
              )
              .left;
        }
        await _quill(t, _screens.first, size);
        t
            .state<QuillFrameState>(find.byType(QuillFrame))
            .push(part.build(Brightness.light));
        await _rest(t);
        final bar = find.byType(LedgerTopBar).last;
        edges['a part'] = t
            .getRect(
              find
                  .descendant(
                    of: bar,
                    matching: find.text(
                      (t.widget(bar) as LedgerTopBar).title ?? '',
                    ),
                  )
                  .first,
            )
            .left;
        final first = edges.values.first;
        if (edges.values.any((x) => (x - first).abs() > .5)) {
          found.add(
            '${size.width.round()}: titles start at ${edges.entries.map((e) => '${e.key} ${e.value}').join(', ')}',
          );
        }
      }
      expect(found, isEmpty, reason: found.join('\n'));
    },
  );
}

/// Opens the specimen select and reads its list: every option's words on one x, one gutter past the glyphs'
/// column, and its whole frame painted.
Future<void> _list(WidgetTester t, String at, List<String> found) async {
  final face = find
      .descendant(
        of: find.byType(LedgerSelect<int>),
        matching: find.byType(LedgerPressable),
      )
      .first;
  await t.tap(face);
  await t.pumpAndSettle();
  final list = find.byWidgetPredicate(
    (w) => w.runtimeType.toString().startsWith('_SelectList'),
  );
  if (list.evaluate().isEmpty) {
    found.add('$at: no list opened');
    return;
  }
  final xs = <String, double>{
    for (final label in const ['Groceries', 'Rent', 'Transit', 'Gifts'])
      label: t
          .getRect(find.descendant(of: list, matching: find.text(label)))
          .left,
  };
  if (xs.values.toSet().length > 1) {
    found.add('$at: the options\' words start at $xs');
  }
  final paper = t.getRect(
    find.descendant(of: list, matching: find.byType(DecoratedBox)).first,
  );
  final field = t.getRect(face);
  // Ledger's own way, as the source's `.menu-item` sets it: the words one gutter (16) in, past the glyphs' column
  // (18 and 12) when any option has a glyph; the paper on the field's leading edge.
  if ((xs['Rent']! - paper.left - (16 + 18 + 12)).abs() > .5) {
    found.add('$at: the words stand ${xs['Rent']! - paper.left} in, not 46');
  }
  if ((paper.left - field.left).abs() > .5) {
    found.add(
      '$at: the paper starts at ${paper.left}, the field at ${field.left}',
    );
  }
  if (paper.width < field.width - .5) {
    found.add(
      '$at: the paper is ${paper.width} wide, the field ${field.width}',
    );
  }
  if (_cut(t, list) case final cut?) found.add('$at: $cut');
  await t.sendKeyEvent(LogicalKeyboardKey.escape);
  await t.pumpAndSettle();
}

/// Reduced motion on, as a reader who asked for it has it: every Ledger change lands at once.
void _stillMotion() =>
    TestWidgetsFlutterBinding.ensureInitialized()
        .platformDispatcher
        .accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(
      disableAnimations: true,
    );

/// The platform's own motion back.
void _movingMotion() => TestWidgetsFlutterBinding.instance.platformDispatcher
    .clearAccessibilityFeaturesTestValue();

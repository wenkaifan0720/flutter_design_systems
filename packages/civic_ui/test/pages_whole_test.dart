// No page reports a layout or paint error. Every gallery page (the specimen
// page among them) at 390 and 1440, at the reader's text and at twice it,
// left to right and right to left in Arabic: walked from top to bottom as it
// opens, each of its buttons pressed in turn as it comes on screen (so
// each dialog, sheet, palette, picker and toast it opens is laid out) and
// whatever says it is shut opened (a menu, a select's list, a fold), each
// shut again; then with all that opens in place opened (every fold, a chart's
// table among them; an accordion's sections; a tree's branches) and walked
// again. Any FlutterError reported while it lays out or paints, an overflow
// among them, fails it, named with the page, the setting and where.
//
// Each run takes each page in one of the eight settings, dealt round the
// pages so every setting is met; every page in every setting is the sweep
// (tagged `sweep`).
// ignore_for_file: avoid_relative_lib_imports
import 'dart:math' as math;
import 'dart:ui' show Tristate;

import 'package:civic_ui/civic_ui.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../example/lib/gallery_pages.dart';
import 'flutter_test_config.dart' show longWalkLeakTesting;
import 'screens_matrix.dart';

typedef _Setting = (double width, double height, double text, TextDirection);

const List<_Setting> _settings = [
  (390, 844, 1, TextDirection.ltr),
  (390, 844, 2, TextDirection.ltr),
  (390, 844, 1, TextDirection.rtl),
  (390, 844, 2, TextDirection.rtl),
  (1440, 900, 1, TextDirection.ltr),
  (1440, 900, 2, TextDirection.ltr),
  (1440, 900, 1, TextDirection.rtl),
  (1440, 900, 2, TextDirection.rtl),
];

Future<void> _frames(WidgetTester tester, [int n = 10]) async {
  for (var i = 0; i < n; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

// What the framework said of each error since the last look, with the
// widget it names as the cause.
final _said = <FlutterErrorDetails>[];

void _clean(WidgetTester tester, String where) {
  final error = tester.takeException();
  final told = [
    for (final d in _said)
      d
          .toString()
          .split('\n')
          .where(
            (l) =>
                l.contains('overflowed') ||
                l.contains('error-causing widget') ||
                l.contains('.dart:'),
          )
          .take(4)
          .join(' / '),
  ];
  _said.clear();
  expect(
    error,
    isNull,
    reason: 'a layout or paint error $where: $error ${told.join('; ')}',
  );
}

bool _presses(SemanticsNode n) {
  final d = n.getSemanticsData();
  final f = d.flagsCollection;
  return d.hasAction(SemanticsAction.tap) &&
      !f.isLink &&
      !f.isTextField &&
      (f.isButton || f.isExpanded == Tristate.isFalse);
}

// Presses each button on screen not yet pressed, checks the page, and
// shuts what it opened (Escape; any route above a navigator's first
// popped; what says it is open, pressed again).
Future<void> _press(WidgetTester tester, String where, Set<String> met) async {
  for (final node in find.semantics.byPredicate(_presses).evaluate().toList()) {
    final name = node.getSemanticsData().label;
    if (!node.attached || !_presses(node) || !met.add('$name#${node.id}')) {
      continue;
    }
    final id = node.id;
    final it = find.semantics.byPredicate((n) => n.id == id);
    tester.semantics.tap(it);
    await _frames(tester);
    _clean(tester, '$where, "$name" pressed');
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await _frames(tester, 4);
    for (final nav in tester.stateList<NavigatorState>(
      find.byType(Navigator),
    )) {
      if (nav.mounted) nav.popUntil((r) => r.isFirst);
    }
    await _frames(tester, 6);
    final still = it.evaluate();
    if (still.isNotEmpty &&
        still.first.getSemanticsData().flagsCollection.isExpanded ==
            Tristate.isTrue &&
        still.first.getSemanticsData().hasAction(SemanticsAction.tap)) {
      tester.semantics.tap(it);
      await _frames(tester, 6);
    }
    _clean(tester, '$where, "$name" shut again');
  }
}

// Every vertical scroll view on the page, from its top to its end and back,
// with [atEach] at each stop.
Future<void> _walk(
  WidgetTester tester,
  String where, [
  Future<void> Function(String where)? atEach,
]) async {
  await atEach?.call(where);
  final views = tester
      .stateList<ScrollableState>(find.byType(Scrollable))
      .where((s) => axisDirectionToAxis(s.axisDirection) == Axis.vertical)
      .toList();
  for (final view in views) {
    if (!view.mounted) continue;
    final at = view.position;
    if (!at.hasContentDimensions || at.maxScrollExtent <= 0) continue;
    for (var y = 0.0; ; y += at.viewportDimension * 0.8) {
      at.jumpTo(math.min(y, at.maxScrollExtent));
      await _frames(tester, 2);
      final stop = '$where, scrolled to ${at.pixels.round()}';
      _clean(tester, stop);
      await atEach?.call(stop);
      if (!view.mounted || at.pixels >= at.maxScrollExtent) break;
    }
    if (view.mounted) at.jumpTo(0);
    await _frames(tester, 2);
  }
}

// Opens all that opens in place: a tree's branches, an accordion's
// sections, then each fold shut at the start, from the top.
Future<void> _openAll(WidgetTester tester, String where) async {
  for (final w in tester.widgetList(
    find.byWidgetPredicate((w) => w is CivicTree<Object>),
  )) {
    (w as CivicTree<Object>).controller.expandAll();
  }
  await _frames(tester);
  _clean(tester, '$where, its trees open');
  for (final accordion
      in tester
          .widgetList<CivicAccordion>(find.byType(CivicAccordion))
          .toList()) {
    final show = find.descendant(
      of: find.byWidget(accordion),
      matching: find.text(accordion.showAllLabel),
    );
    if (show.evaluate().isEmpty) continue;
    await tester.ensureVisible(show.first);
    await tester.pump();
    await tester.tap(show.first, warnIfMissed: false);
    await _frames(tester);
    _clean(tester, '$where, its sections open');
  }
  final folds = tester
      .widgetList<CivicDetails>(find.byType(CivicDetails))
      .where((d) => !d.initiallyExpanded)
      .toList();
  for (final fold in folds) {
    final title = find.descendant(
      of: find.byWidget(fold),
      matching: find.text(fold.title),
    );
    if (title.evaluate().isEmpty) continue;
    await tester.ensureVisible(title.first);
    await tester.pump();
    await tester.tap(title.first, warnIfMissed: false);
    await _frames(tester);
    _clean(tester, '$where, "${fold.title}" open');
  }
}

void main() {
  setUpAll(loadScreenFonts);
  for (final (p, page) in galleryPages.indexed) {
    for (final (s, (width, height, text, direction)) in _settings.indexed) {
      final setting =
          'at ${width.round()}, text ×${text.round()}, ${direction.name}';
      testWidgets(
        '${page.id} $setting: no layout or paint error, shut or open',
        (tester) async {
          final framework = FlutterError.onError;
          FlutterError.onError = (details) {
            _said.add(details);
            framework?.call(details);
          };
          try {
            await _run(tester, page, width, height, text, direction, setting);
          } finally {
            FlutterError.onError = framework;
            _said.clear();
          }
        },
        tags: s == p % _settings.length ? null : 'sweep',
        experimentalLeakTesting: longWalkLeakTesting,
      );
    }
  }
}

Future<void> _run(
  WidgetTester tester,
  GalleryPage page,
  double width,
  double height,
  double text,
  TextDirection direction,
  String setting,
) async {
  await showScreen(
    tester,
    Directionality(
      textDirection: direction,
      child: page.build(Brightness.light),
    ),
    width: width,
    height: height,
    text: text,
  );
  final where = 'in ${page.id} $setting';
  _clean(tester, where);
  final met = <String>{};
  final semantics = tester.ensureSemantics();
  try {
    await _walk(tester, where, (stop) => _press(tester, stop, met));
  } finally {
    semantics.dispose();
  }
  await _openAll(tester, where);
  await _walk(tester, '$where, all open');
  // What a press set going (a toast, a refresh) ends.
  for (var i = 0; i < 4; i++) {
    await tester.pump(const Duration(seconds: 15));
  }
  _clean(tester, '$where, at rest');
}

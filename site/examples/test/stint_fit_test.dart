// Words whole and notices in their place in every edition: a week chart's
// day readings each on one line and in one form (each day's duration, or
// h:mm under a caption naming the hours, when a duration doesn't fit);
// Stint's paired buttons and place names neither cut nor broken; a saved
// notice inside its pane at two-pane widths, and on a phone clear of the
// Save foot; a task's label chips 8 apart, face to face.
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:design_system_examples/generated/studies.dart' as studies;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stint_core/stint_core.dart';
import 'package:ui_core/ui_core.dart'
    show RenderChipGroup, RenderTapTargetPadding;

final looks = (jsonDecode(File('../looks.json').readAsStringSync()) as Map).keys
    .cast<String>()
    .toList();

/// Flutter's own two stay as Flutter makes them (Material's snackbar along
/// the window, Cupertino's none), and set their words in the platform's
/// faces, which the test runner lacks: the browser walk checks them.
const references = {'material', 'cupertino'};

/// Comic raises its notices on the navigator's overlay, with no toaster to
/// stand in a pane: one per pane waits on the look.
const overlayNotices = {'comic'};

void main() {
  final fixture = StintController(StintRepository());
  var week = <int>[];
  setUpAll(() async {
    await fixture.refresh();
    week = fixture.dailyMinutes(mondayOf(studyToday));
  });
  const phone = Size(390, 844), desktop = Size(1440, 960);

  // A task's labels are chips in a group: their faces stand 8 apart along a
  // line and between lines, or as far apart as their tap targets need where
  // that is more, and each chip is its own control to assistive technology
  // (merged into one node, a tap on any would go to the first). Civic sets labels as checkboxes, not chips; Terminal sets
  // its chips a cell apart on its grid, and its chip's target is its own, not
  // a TapTargetPadding a group can reach into (the look's to change).
  for (final look in looks.where(
    (l) => !references.contains(l) && l != 'civic' && l != 'terminal',
  )) {
    testWidgets('$look: a task\'s label chips stand 8 apart, each its own', (
      tester,
    ) async {
      final w = StintWords();
      final problems = <String>[];
      final semantics = tester.ensureSemantics();
      for (final scale in [1.0, 2.0]) {
        if (!await open(
          tester,
          look,
          StintLaunch(place: Place.tasks, detail: true, scale: scale),
          phone,
        )) {
          return;
        }
        // Terminal's chips set their mark before the name ([x] Planning).
        final first = find.textContaining(
          w.labelName(Label.values.first),
          findRichText: true,
        );
        expect(first, findsWidgets, reason: 'no label chips');
        // The label's chip, not a title that names it.
        final chip = first.evaluate().firstWhere(
          (e) => groupOf(e.renderObject) != null,
          orElse: () => first.evaluate().first,
        );
        await tester.ensureVisible(find.byWidget(chip.widget).first);
        await tester.pump(const Duration(milliseconds: 400));
        problems.addAll(
          chipGaps(chip.renderObject).map((p) => 'at ${scale}x: $p'),
        );
        // Its own control: the smallest node that holds the chip's words and
        // takes a tap says its name and no other label's, where a field that
        // merges its chips' taps says its own ("Labels").
        final name = w.labelName(Label.values.first);
        final others = Label.values.skip(1).map(w.labelName).toList();
        final reached = controlAt(
          tester,
          tester.getCenter(find.byWidget(chip.widget).first),
        );
        final said = reached?.getSemanticsData().label ?? '';
        if (!said.contains(name) || others.any(said.contains)) {
          problems.add(
            'at ${scale}x: one node says "${said.replaceAll('\n', ' / ')}"',
          );
        }
        await close(tester);
      }
      semantics.dispose();
      expect(problems, isEmpty);
    });
  }

  for (final look in looks.where((l) => !references.contains(l))) {
    group(look, () {
      testWidgets('readings and paired buttons whole', (tester) async {
        final problems = <String>[];
        for (final size in [phone, desktop]) {
          // Readings English shows at this width show in every language.
          final shownIn = <Place, bool>{};
          // The test runner has no Japanese face, and no Arabic one where a
          // look brings none (the web fetches Noto): those widths are a
          // stand-in's, so the browser walk checks Arabic and Japanese.
          for (final language in const [StintLanguage.en, StintLanguage.de]) {
            final w = StintWords(language);
            for (final place in [Place.today, Place.tasks, Place.time]) {
              final where =
                  '${language.name} ${place.name} ${size.width.round()}';
              if (!await open(
                tester,
                look,
                StintLaunch(place: place, language: language),
                size,
              )) {
                return;
              }
              final texts = visibleParagraphs(tester);
              if (place != Place.tasks) {
                final r = readings(
                  visibleParagraphs(tester, onScreen: false),
                  w,
                  week,
                );
                if (language == StintLanguage.en) {
                  shownIn[place] = r.shown;
                } else if (shownIn[place]! && !r.shown) {
                  problems.add('$where: day readings dropped');
                }
                problems.addAll(r.problems.map((p) => '$where: $p'));
              }
              final labels = {
                w.switchTask,
                w.stopTimer,
                w.startTimer,
                w.select,
                w.stopSelecting,
                w.addEntry,
              }.map(bare).toSet();
              for (final p in texts) {
                final text = bare(plain(p));
                if (!labels.contains(text) &&
                    !text.startsWith(bare(w.filters))) {
                  continue;
                }
                if (cut(p)) problems.add('$where: "${plain(p)}" cut');
                if (lines(p) > 1) {
                  problems.add('$where: "${plain(p)}" on ${lines(p)} lines');
                }
              }
              await close(tester);
            }
          }
        }
        expect(problems, isEmpty);
      });

      // German's place for the timesheet, 'Zeiterfassung' (or 'Stunden' in a
      // slot too narrow for it), is as whole as its neighbours: whole at 1x,
      // and at 1.5x and 2x wherever the navigation keeps its labels whole.
      testWidgets('the Time place whole in German at 1x, 1.5x and 2x', (
        tester,
      ) async {
        final problems = <String>[];
        const w = StintWords(StintLanguage.de);
        final names = {w.time, w.timeShort};
        for (final size in [phone, desktop]) {
          for (final scale in [1.0, 1.5, 2.0]) {
            for (final place in [Place.today, Place.time]) {
              if (!await open(
                tester,
                look,
                StintLaunch(
                  place: place,
                  language: StintLanguage.de,
                  scale: scale,
                ),
                size,
              )) {
                return;
              }
              final texts = visibleParagraphs(tester);
              // Where a neighbour breaks too, the bar is too narrow for any
              // German word at this scale: the look's to answer.
              final neighbours = {w.today, w.tasks, w.settings};
              final crowded = texts.any(
                (p) =>
                    neighbours.contains(plain(p).trim()) &&
                    (cut(p) || lines(p) > 1),
              );
              for (final p in texts) {
                if (!names.contains(plain(p).trim())) continue;
                final where = '${place.name} ${size.width.round()} ${scale}x';
                if (crowded) {
                  if (cut(p) || lines(p) > 1) {
                    debugPrint(
                      '$look $where: crowded bar, "${plain(p)}" '
                      'and a neighbour broken (look-level)',
                    );
                  }
                  continue;
                }
                if (cut(p)) problems.add('$where: "${plain(p)}" cut');
                if (lines(p) > 1) {
                  problems.add(
                    '$where: "${plain(p)}" broken over ${lines(p)} lines',
                  );
                }
              }
              await close(tester);
            }
          }
        }
        expect(problems, isEmpty);
      });

      testWidgets('Changes saved clear of the phone Save foot', (tester) async {
        const w = StintWords();
        if (!await openDetail(tester, look, phone, fixture)) return;
        await save(tester, w);
        final toast = noticeRect(tester, w);
        expect(toast, isNotNull, reason: 'no Changes saved notice');
        for (final f in paragraphsWhere(tester, (t) => t == bare(w.save))) {
          expect(
            toast!.overlaps(rectOf(f)),
            isFalse,
            reason: 'notice $toast over Save ${rectOf(f)}',
          );
        }
        await close(tester);
      });

      testWidgets(
        'Changes saved inside the detail pane at 1440',
        skip: overlayNotices.contains(look),
        (tester) async {
          const w = StintWords();
          if (!await openDetail(tester, look, desktop, fixture)) return;
          await save(tester, w);
          final toast = noticeRect(tester, w);
          expect(toast, isNotNull, reason: 'no Changes saved notice');
          // The list pane: the rows of the tasks not open.
          final titles = {
            for (final t in fixture.visible.skip(1))
              bare(t.title.inLanguage(StintLanguage.en)),
          };
          final rows = paragraphsWhere(tester, titles.contains).map(rectOf);
          expect(rows, isNotEmpty, reason: 'no list rows beside the detail');
          final list = rows.reduce((a, b) => a.expandToInclude(b));
          final apart = toast!.right <= list.left || toast.left >= list.right;
          expect(apart, isTrue, reason: 'notice $toast across the list $list');
          await close(tester);
        },
      );

      testWidgets(
        'Changes saved clear of a Save scrolled to the end at 1440',
        skip: overlayNotices.contains(look),
        (tester) async {
          const w = StintWords();
          if (!await openDetail(tester, look, desktop, fixture)) return;
          // Scrolled to the end, as after a pass down the form.
          final words = find.text(w.save, skipOffstage: false);
          if (words.evaluate().isEmpty) return;
          await tester.ensureVisible(words.last);
          await tester.pump(const Duration(milliseconds: 400));
          await save(tester, w);
          final toast = noticeRect(tester, w);
          expect(toast, isNotNull, reason: 'no Changes saved notice');
          final button = paragraphsWhere(tester, (t) => t == bare(w.save));
          for (final b in button.map(rectOf)) {
            expect(
              toast!.overlaps(b.inflate(4)),
              isFalse,
              reason: 'notice $toast over Save $b',
            );
          }
          await close(tester);
        },
      );
    });
  }
}

Future<bool> open(
  WidgetTester tester,
  String look,
  StintLaunch launch,
  Size size,
) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  // Opening loads the look's fonts, real I/O the fake clock would never finish.
  final app = await tester.runAsync(() => studies.openStudy(look, launch));
  if (app == null) return false;
  await tester.pumpWidget(app);
  for (var i = 0; i < 4; i++) {
    await tester.pump(const Duration(milliseconds: 400));
  }
  return true;
}

Future<void> close(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(seconds: 1));
}

/// Opens the first task's detail and changes its title.
Future<bool> openDetail(
  WidgetTester tester,
  String look,
  Size size,
  StintController fixture,
) async {
  if (!await open(
    tester,
    look,
    const StintLaunch(place: Place.tasks, detail: true),
    size,
  )) {
    return false;
  }
  final title = fixture.visible.first.title.inLanguage(StintLanguage.en);
  final field = find.byWidgetPredicate(
    (w) => w is EditableText && w.controller.text == title,
  );
  expect(field, findsWidgets, reason: 'no title field');
  await tester.enterText(field.first, '$title x');
  await tester.pump(const Duration(milliseconds: 400));
  return true;
}

/// Saves with Ctrl+S, else with the Save button.
Future<void> save(WidgetTester tester, StintWords w) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
  await tester.sendKeyEvent(LogicalKeyboardKey.keyS);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
  for (var i = 0; i < 3; i++) {
    await tester.pump(const Duration(milliseconds: 300));
  }
  if (noticeRect(tester, w) != null) return;
  final button = paragraphsWhere(tester, (t) => t == bare(w.save));
  if (button.isEmpty) return;
  await tester.tapAt(rectOf(button.first).center);
  for (var i = 0; i < 3; i++) {
    await tester.pump(const Duration(milliseconds: 300));
  }
}

/// The shown Changes saved notice: its toast, else its words.
Rect? noticeRect(WidgetTester tester, StintWords w) {
  final words = find.textContaining(w.saved, findRichText: true);
  if (words.evaluate().isEmpty) return null;
  final toast = find.ancestor(
    of: words.first,
    matching: find.byType(Dismissible),
  );
  return toast.evaluate().isEmpty
      ? tester.getRect(words.first)
      : tester.getRect(toast.first);
}

String plain(RenderParagraph p) => p.text.toPlainText(
  includeSemanticsLabels: false,
  includePlaceholders: false,
);

/// [s] without spaces, breaks and joiners.
String bare(String s) =>
    s.replaceAll(RegExp('[\\s\u{a0}\u{200b}\u{2060}]'), '');

Rect rectOf(RenderBox box) =>
    MatrixUtils.transformRect(box.getTransformTo(null), Offset.zero & box.size);

/// The paragraphs shown: laid out, not offstage, not faded out, not an
/// indexed stack's hidden child, and inside the window unless [onScreen] is
/// false (a chart below the fold is still shown).
List<RenderParagraph> visibleParagraphs(
  WidgetTester tester, {
  bool onScreen = true,
}) {
  final screen = Offset.zero & tester.view.physicalSize;
  bool visible(RenderParagraph p) {
    if (!p.attached || !p.hasSize || p.size.isEmpty) return false;
    RenderObject child = p;
    for (var node = p.parent; node != null; child = node, node = node.parent) {
      if (node is RenderOffstage && node.offstage) return false;
      if (node is RenderOpacity && node.opacity == 0) return false;
      if (node is RenderAnimatedOpacity && node.opacity.value == 0) {
        return false;
      }
      if (node is RenderIndexedStack) {
        var shown = node.firstChild;
        for (var i = 0; i < (node.index ?? -1) && shown != null; i++) {
          shown = node.childAfter(shown);
        }
        if (!identical(shown, child)) return false;
      }
    }
    return !onScreen || rectOf(p).overlaps(screen);
  }

  return tester.allRenderObjects
      .whereType<RenderParagraph>()
      .where(visible)
      .toList();
}

List<RenderParagraph> paragraphsWhere(
  WidgetTester tester,
  bool Function(String bareText) test,
) => [
  for (final p in visibleParagraphs(tester))
    if (test(bare(plain(p)))) p,
];

/// How many lines [p] sets.
int lines(RenderParagraph p) {
  final length = plain(p).length;
  if (length == 0) return 0;
  final boxes = p.getBoxesForSelection(
    TextSelection(baseOffset: 0, extentOffset: length),
  )..sort((a, b) => a.top.compareTo(b.top));
  var count = 0;
  var bottom = double.negativeInfinity;
  for (final b in boxes) {
    if (b.top >= bottom - 1) {
      count++;
      bottom = b.bottom;
    } else if (b.bottom > bottom) {
      bottom = b.bottom;
    }
  }
  return count;
}

/// Whether [p] cuts its words: an ellipsis, or one line clipped at its end.
bool cut(RenderParagraph p) =>
    p.didExceedMaxLines ||
    (lines(p) == 1 &&
        p.getMaxIntrinsicWidth(double.infinity) > p.size.width + 0.5);

/// The week's readings on screen, matched by either form.
({bool shown, List<String> problems}) readings(
  List<RenderParagraph> texts,
  StintWords w,
  List<int> minutes,
) {
  final days = minutes.where((m) => m > 0).toSet();
  final full = {for (final m in days) bare(w.duration(m))};
  final compact = {for (final m in days) bare(w.hours(m))};
  final asFull = [
    for (final p in texts)
      if (full.contains(bare(plain(p)))) p,
  ];
  final asCompact = [
    for (final p in texts)
      if (compact.contains(bare(plain(p)))) p,
  ];
  // A chart shows at least three of the week's working days' readings; fewer
  // matches are other figures that happen to agree.
  bool shown(List<RenderParagraph> ps) =>
      ps.map((p) => bare(plain(p))).toSet().length >= 3;
  final fullShown = shown(asFull), compactShown = shown(asCompact);
  final problems = <String>[
    if (fullShown && compactShown) 'readings in two forms',
    for (final p in [if (fullShown) ...asFull, if (compactShown) ...asCompact])
      if (lines(p) > 1)
        'reading "${plain(p)}" on ${lines(p)} lines'
      else if (cut(p))
        'reading "${plain(p)}" cut',
  ];
  return (shown: fullShown || compactShown, problems: problems);
}

/// The chip group or wrap [o] stands in, if any.
RenderBox? groupOf(RenderObject? o) {
  for (var at = o; at != null; at = at.parent) {
    if (at is RenderChipGroup || at is RenderWrap) return at as RenderBox;
  }
  return null;
}

/// How the faces of the chips around [chip] stand apart, as problems: each
/// two in a line, and each two lines, are 8 apart face to face, or as far
/// apart as their tap targets need where that is more.
List<String> chipGaps(RenderObject? chip) {
  final group = groupOf(chip);
  if (group == null) return ['no group around the chips'];
  final floor = group is RenderChipGroup ? 40.0 : 0.0;
  Rect rectOf(RenderBox box) => MatrixUtils.transformRect(
    box.getTransformTo(null),
    Offset.zero & box.size,
  );
  // A chip's face: what its tap target pads, else the chip itself.
  Rect face(RenderBox child) {
    RenderBox? padded;
    void visit(RenderObject o) {
      if (padded != null) return;
      if (o is RenderTapTargetPadding) {
        o.visitChildren((c) => padded ??= c as RenderBox);
        return;
      }
      o.visitChildren(visit);
    }

    visit(child);
    return rectOf(padded ?? child);
  }

  final faces = <Rect>[];
  group.visitChildren((c) => faces.add(face(c as RenderBox)));
  if (faces.length < 2) return ['fewer than two chips'];
  // Lines, top to bottom; each line's faces start to end.
  final lines = <List<Rect>>[];
  for (final f in [...faces]..sort((a, b) => a.top.compareTo(b.top))) {
    if (lines.isNotEmpty && f.top < lines.last.first.bottom - 0.5) {
      lines.last.add(f);
    } else {
      lines.add([f]);
    }
  }
  double need(double a, double b) =>
      math.max(8, (math.max(0, floor - a) + math.max(0, floor - b)) / 2);
  final problems = <String>[];
  for (final line in lines) {
    line.sort((a, b) => a.left.compareTo(b.left));
    for (var i = 1; i < line.length; i++) {
      final gap = line[i].left - line[i - 1].right;
      final want = need(line[i - 1].width, line[i].width);
      if ((gap - want).abs() > 0.6) {
        problems.add(
          'faces ${gap.toStringAsFixed(1)} apart in a line, not ${want.toStringAsFixed(1)}',
        );
      }
    }
  }
  for (var i = 1; i < lines.length; i++) {
    final above = lines[i - 1], below = lines[i];
    final gap =
        below.map((r) => r.top).reduce(math.min) -
        above.map((r) => r.bottom).reduce(math.max);
    final want = need(above.first.height, below.first.height);
    if ((gap - want).abs() > 0.6) {
      problems.add(
        'lines ${gap.toStringAsFixed(1)} apart, not ${want.toStringAsFixed(1)}',
      );
    }
  }
  return problems;
}

/// The smallest semantics node whose box holds [point] and that takes a tap,
/// of those the platform sees (not merged into a parent): the control a
/// screen reader's touch there acts on.
SemanticsNode? controlAt(WidgetTester tester, Offset point) {
  final root = tester.binding.renderViews.first.debugSemantics;
  if (root == null) return null;
  final at = point * tester.view.devicePixelRatio;
  SemanticsNode? best;
  var bestArea = double.infinity;
  void visit(SemanticsNode node) {
    var box = node.rect;
    for (SemanticsNode? n = node; n != null; n = n.parent) {
      final transform = n.transform;
      if (transform != null) box = MatrixUtils.transformRect(transform, box);
    }
    if (node.isMergedIntoParent || !box.contains(at)) return;
    final area = box.width * box.height;
    if (node.getSemanticsData().hasAction(SemanticsAction.tap) &&
        area <= bestArea) {
      best = node;
      bestArea = area;
    }
    node.visitChildren((child) {
      visit(child);
      return true;
    });
  }

  visit(root);
  return best;
}

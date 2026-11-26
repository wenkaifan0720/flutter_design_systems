import 'dart:ui' as ui;

import 'package:flutter/rendering.dart'
    show OffsetLayer, RenderParagraph, SemanticsNode;
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stint_core/stint_core.dart';

/// The timer and week may share a plate, or a centred timer strip can sit
/// above a separate weekly chart. Both compositions exercise the same marks.
enum TodayHero { columns, centredStrip }

// One subtree painted alone onto transparent glass. Counting its ink
// excludes surrounding hit padding, centred loose children and row gutters.
// It paints the subtree itself rather than through the widget inspector's
// screenshot, whose recording canvas in Flutter 3.47 has no
// drawRSuperellipse, the shape Clay's parts are drawn in.
class _InkContext extends PaintingContext {
  _InkContext(super.containerLayer, super.estimatedBounds);

  @override
  void paintChild(RenderObject child, Offset offset) {
    // A repaint boundary paints into this glass too, not its own layer.
    if (child.isRepaintBoundary) {
      child.paint(this, offset);
    } else {
      super.paintChild(child, offset);
    }
  }

  void finish() => stopRecordingIfNeeded();
}

class _PaintProbe {
  // The union of [object]'s and its descendants' bounds in [transform]'s
  // space, each cut by the clips above it.
  static Rect _subtree(RenderObject object, Matrix4 transform) {
    var bounds = MatrixUtils.transformRect(transform, object.semanticBounds);
    object.visitChildren((child) {
      final childTransform = transform.clone();
      object.applyPaintTransform(child, childTransform);
      var childBounds = _subtree(child, childTransform);
      final clip = object.describeApproximatePaintClip(child);
      if (clip != null) {
        childBounds = childBounds.intersect(
          MatrixUtils.transformRect(transform, clip),
        );
      }
      if (childBounds.isFinite && !childBounds.isEmpty) {
        bounds = bounds.isEmpty
            ? childBounds
            : bounds.expandToInclude(childBounds);
      }
    });
    return bounds;
  }

  Future<Rect> ink(RenderBox box) async {
    const ratio = 2.0;
    // The glass is the subtree's own bounds, as the inspector's screenshot
    // took them: a shadow a part casts past every box in it is not its ink.
    final bounds = _subtree(box, Matrix4.identity());
    final glass = OffsetLayer();
    final context = _InkContext(glass, bounds);
    box.paint(context, Offset.zero);
    context.finish();
    final ui.Image image;
    try {
      image = await glass.toImage(bounds, pixelRatio: ratio);
    } finally {
      // The subtree's own layers were lent to the glass: paint them home.
      void home(RenderObject object) {
        object.markNeedsPaint();
        object.visitChildren(home);
      }

      home(box);
      glass.dispose();
    }
    try {
      final rgba = (await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      ))!;
      // Some quiet marks deliberately use translucent ink.
      var peak = 0;
      for (var i = 3; i < rgba.lengthInBytes; i += 4) {
        final alpha = rgba.getUint8(i);
        if (alpha > peak) peak = alpha;
      }
      if (peak < 16) throw StateError('No visible ink for $box');
      final threshold = (peak + 1) ~/ 2;
      var left = image.width, right = -1, top = image.height, bottom = -1;
      for (var y = 0; y < image.height; y++) {
        for (var x = 0; x < image.width; x++) {
          if (rgba.getUint8((y * image.width + x) * 4 + 3) < threshold) {
            continue;
          }
          if (x < left) left = x;
          if (x > right) right = x;
          if (y < top) top = y;
          if (y > bottom) bottom = y;
        }
      }
      if (right < left) throw StateError('No visible ink for $box');
      return MatrixUtils.transformRect(
        box.getTransformTo(null),
        Rect.fromLTRB(
          bounds.left + left / ratio,
          bounds.top + top / ratio,
          bounds.left + (right + 1) / ratio,
          bounds.top + (bottom + 1) / ratio,
        ),
      );
    } finally {
      image.dispose();
    }
  }
}

/// The first shaped line of [paragraph] from [start] to [end], in the
/// paragraph's own coordinates. Font fallback can split one line into several
/// boxes (a bundled Arabic face for the letters, the look's face for the
/// spaces), listed in visual order, so the line joins every box on it rather
/// than trusting the first. The max height style gives each box on a line
/// the same top.
Rect _firstLine(RenderParagraph paragraph, int start, int end) {
  final boxes = paragraph.getBoxesForSelection(
    TextSelection(baseOffset: start, extentOffset: end),
    boxHeightStyle: ui.BoxHeightStyle.max,
  );
  final top = boxes.fold(
    double.infinity,
    (y, box) => y < box.top ? y : box.top,
  );
  return boxes
      .where((box) => (box.top - top).abs() < .5)
      .map((box) => box.toRect())
      .reduce((a, b) => a.expandToInclude(b));
}

Future<({Rect line, Rect ink})> _heading(
  WidgetTester tester,
  String title,
  Future<Rect> Function(Finder) painted,
) async {
  // Read the first shaped line of the title itself. A section can
  // append a progress count to the same paragraph, and accents and
  // descenders can differ between words on the same type line.
  final label = title.toLowerCase();
  final heading = find.byWidgetPredicate(
    (widget) =>
        widget is RichText &&
        widget.text.toPlainText().toLowerCase().contains(label),
    description: 'section heading "$title"',
  );
  expect(heading, findsOneWidget);
  final paragraph = tester.renderObject<RenderParagraph>(heading);
  final offset = paragraph.text.toPlainText().toLowerCase().indexOf(label);
  final line = _firstLine(paragraph, offset, offset + label.length);
  return (
    line: MatrixUtils.transformRect(paragraph.getTransformTo(null), line),
    ink: await painted(heading),
  );
}

/// Run from every edition that provides the Today alignment keys. It also
/// runs the running-task rule ([_checkRunningMark]) on the same editions.
/// Side-by-side section headings share a line within 1 px or start at least
/// 24 px apart. Editions with paired rows also key the painted list faces
/// `today-plan-face` and `today-team-face` and pass `pairedSections: true`.
void checkTodayAlignment({
  required TodayHero hero,
  bool hasTimerLamp = false,
  bool pairedSections = false,
  required Future<void> Function() loadFonts,
  required Widget Function(StintLaunch, StintRepository) app,
}) {
  for (final width in [390, 768, 1024, 1280, 1440]) {
    for (final rtl in [false, true]) {
      testWidgets('Today painted alignment at $width ${rtl ? "RTL" : "LTR"}', (
        tester,
      ) async {
        await tester.runAsync(loadFonts);
        tester.view.devicePixelRatio = 1;
        // Keep every seeded list row in the painted viewport at its actual width.
        tester.view.physicalSize = Size(width.toDouble(), 4100);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final repo = StintRepository(clock: () => studyMorning);
        final fixture = StintController(repo)..data = repo.snapshot;
        addTearDown(fixture.dispose);
        await tester.pumpWidget(app(StintLaunch(language: rtl ? StintLanguage.ar : StintLanguage.en), repo));
        await tester.pumpAndSettle();
        final probe = _PaintProbe();
        Future<Rect> painted(Finder finder) async {
          expect(finder, findsOneWidget);
          final box = tester.renderObject<RenderBox>(finder);
          return (await tester.runAsync(() => probe.ink(box)))!;
        }

        Future<Rect> ink(String key) =>
            painted(find.byKey(ValueKey('today-$key')));

        void aligned(double actual, double expected, String why) =>
            expect(actual, closeTo(expected, 1), reason: why);
        double start(Rect rect) => rtl ? rect.right : rect.left;
        double end(Rect rect) => rtl ? rect.left : rect.right;

        final tasks = await ink('stat-tasks'), hours = await ink('stat-hours');
        final chart = await ink('chart');
        aligned(tasks.width, hours.width, 'equal stat faces');
        aligned(tasks.top, hours.top, 'stat tops');
        aligned(tasks.bottom, hours.bottom, 'stat bottoms');
        aligned(start(tasks), start(chart), 'first stat and chart start');
        aligned(end(hours), end(chart), 'last stat and chart end');
        expect(
          rtl ? hours.right < tasks.left : tasks.right < hours.left,
          isTrue,
          reason: 'stat gap',
        );
        expect(chart.top, greaterThan(tasks.bottom));
        double? prev;
        final words = StintWords(rtl ? StintLanguage.ar : StintLanguage.en);
        final total = await painted(
          find.descendant(
            of: find.byKey(const ValueKey('today-stat-hours')),
            matching: find.text(
              words.duration(fixture.totalMinutes(mondayOf(studyToday))),
            ),
          ),
        );
        expect(
          hours.deflate(1).contains(total.topLeft),
          isTrue,
          reason: 'weekly value starts inside its tile',
        );
        expect(
          hours.deflate(1).contains(total.bottomRight),
          isTrue,
          reason: 'weekly value ends inside its tile',
        );
        for (var i = 0; i < 7; i++) {
          final mark = await ink('day-slot-$i');
          final label = await ink('day-label-$i');
          final day = addDays(mondayOf(studyToday), i);
          final text = tester
              .widget<Text>(find.byKey(ValueKey('today-day-label-$i')))
              .data;
          expect([
            words.weekdayShort(day),
            words.weekdayNarrow(day),
          ], contains(text));
          aligned(label.center.dx, mark.center.dx, 'day $i label and mark');
          expect(
            label.top,
            greaterThanOrEqualTo(mark.bottom),
            reason: 'day $i',
          );
          if (prev != null) {
            expect(rtl ? mark.center.dx < prev : mark.center.dx > prev, isTrue);
          }
          prev = mark.center.dx;
        }
        final first = await ink('action-first'),
            last = await ink('action-last');
        if (hero == TodayHero.columns) {
          final well = await ink('timer-well');
          if (hasTimerLamp) {
            final lamp = await ink('timer-lamp'),
                label = await ink('timer-label');
            expect(
              well.intersect(lamp),
              lamp,
              reason: 'the entire lamp paints inside the timer well',
            );
            aligned(
              lamp.center.dy,
              label.center.dy,
              'lamp on the timer label centre line',
            );
            expect(
              rtl ? lamp.left > label.right : lamp.right < label.left,
              isTrue,
              reason: 'lamp leads the timer label',
            );
          }
          final digits = await ink('timer-digits');
          final card = await ink('timer-card');
          expect(card.contains(well.center), isTrue);
          expect(well.contains(digits.center), isTrue);
          aligned(start(well), start(first), 'well and buttons start');
          aligned(end(well), end(last), 'well and buttons end');
          aligned(first.width, last.width, 'equal timer keys');
          if (width > 390) {
            aligned(well.top, tasks.top, 'hero column tops');
            aligned(last.bottom, chart.bottom, 'hero column bottoms');
          } else {
            expect(
              tasks.top,
              greaterThan(last.bottom),
              reason: 'stacked weekly panel',
            );
          }
        } else {
          expect(
            centredStripProblems(
              width: width.toDouble(),
              rtl: rtl,
              title: await ink('timer-title'),
              digits: await ink('timer-digits'),
              first: first,
              last: last,
              card: await ink('timer-card'),
              tasks: tasks,
            ),
            isEmpty,
          );
        }

        if (width >= 768) {
          final headings = {
            for (final title in [
              words.todaysPlan,
              words.timeBlocks,
              words.laterThisWeek,
              words.teamActivity,
              words.recentActivity,
            ])
              title: await _heading(tester, title, painted),
          };
          for (final (index, a) in headings.entries.indexed) {
            for (final b in headings.entries.skip(index + 1)) {
              if (a.value.line.right <= b.value.line.left ||
                  b.value.line.right <= a.value.line.left) {
                final lineGap = (a.value.line.top - b.value.line.top).abs();
                final inkGap = (a.value.ink.top - b.value.ink.top).abs();
                expect(
                  lineGap <= 1 || (lineGap >= 24 && inkGap >= 24),
                  isTrue,
                  reason:
                      '"${a.key}" and "${b.key}" must share a top or sit 24 px apart '
                      '(type lines $lineGap px, painted ink $inkGap px)',
                );
              }
            }
          }
          if (pairedSections) {
            aligned(
              headings[words.todaysPlan]!.line.top,
              headings[words.teamActivity]!.line.top,
              'paired plan and team headings',
            );
            aligned(
              (await ink('plan-face')).bottom,
              (await ink('team-face')).bottom,
              'paired plan and team card bottoms',
            );
            aligned(
              headings[words.timeBlocks]!.line.top,
              headings[words.recentActivity]!.line.top,
              'paired time blocks and recent activity headings',
            );
          }
        }

        final plan = find.byKey(const ValueKey('today-plan'));
        final allTasks = find.descendant(
          of: plan,
          matching: find.text(words.viewTasks),
        );
        final hasActionRow = allTasks.evaluate().isNotEmpty;
        if (hasActionRow) {
          double titleEdge(Finder text) {
            final paragraph = tester.renderObject<RenderParagraph>(text);
            final line = _firstLine(
              paragraph,
              0,
              paragraph.text.toPlainText().length,
            );
            return paragraph.localToGlobal(Offset(start(line), 0)).dx;
          }

          for (final task in fixture.todayTasks) {
            aligned(
              titleEdge(allTasks),
              titleEdge(
                find.descendant(
                  of: plan,
                  matching: find.text(words.text(task.title)),
                ),
              ),
              'View all tasks and ${task.id} title edges',
            );
          }
        }

        final leads = <String, List<String>>{
          'plan': [
            for (final t in fixture.todayTasks) t.id,
            if (hasActionRow) 'all',
          ],
          'blocks': [for (var i = 0; i < fixture.todayBlocks.length; i++) '$i'],
          'later': [for (final t in fixture.laterThisWeek) t.id],
          'team': [for (final p in team) p.id],
          'feed': [for (var i = 0; i < fixture.data.activity.length; i++) '$i'],
        };
        for (final section in leads.entries) {
          double? centre;
          for (final id in section.value) {
            final mark = await ink('${section.key}-lead-$id');
            centre ??= mark.center.dx;
            aligned(
              mark.center.dx,
              centre,
              '${section.key} $id leading centre',
            );
          }
        }
        if (hero == TodayHero.centredStrip && width >= 1024) {
          final original = words.text(fixture.currentTask('maya')!.title);
          final other = fixture.openTasks.firstWhere(
            (t) => words.text(t.title).length != original.length,
          );
          await tester.tap(find.byKey(const ValueKey('today-action-last')));
          await tester.pumpAndSettle();
          await tester.enterText(
            find.byType(EditableText),
            words.text(other.title),
          );
          await tester.pumpAndSettle();
          await tester.sendKeyEvent(LogicalKeyboardKey.enter);
          await tester.pumpAndSettle();
          expect(
            find.descendant(
              of: find.byKey(const ValueKey('today-timer-title')),
              matching: find.text(words.text(other.title)),
            ),
            findsOneWidget,
          );
          aligned(
            start(await ink('timer-digits')),
            start(tasks),
            'changing task keeps the clock on the same track',
          );
        }
        expect(tester.takeException(), isNull);
      });
    }
  }
  _checkRunningMark(loadFonts: loadFonts, app: app);
}

/// The plan marks the task whose timer runs, in the look's own way, and says
/// so: [StintWords.runningTimer] joins that row's spoken name. The mark is
/// keyed `today-plan-running` (a glyph, a lamp, a dot), or, where a look
/// says it in words, the row paints [StintWords.runningTimer] itself. Either
/// way it paints once, inside the plan on the running row, follows a switch
/// to another of today's tasks and goes on stop.
void _checkRunningMark({
  required Future<void> Function() loadFonts,
  required Widget Function(StintLaunch, StintRepository) app,
}) {
  for (final width in [390, 768, 1024, 1280, 1440]) {
    for (final rtl in [false, true]) {
      testWidgets('Today running task mark at $width ${rtl ? "RTL" : "LTR"}', (
        tester,
      ) async {
        await tester.runAsync(loadFonts);
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(width.toDouble(), 4100);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final repo = StintRepository(clock: () => studyMorning);
        final fixture = StintController(repo)..data = repo.snapshot;
        addTearDown(fixture.dispose);
        await tester.pumpWidget(app(StintLaunch(language: rtl ? StintLanguage.ar : StintLanguage.en), repo));
        await tester.pumpAndSettle();
        final probe = _PaintProbe();
        final words = StintWords(rtl ? StintLanguage.ar : StintLanguage.en);
        final plan = find.byKey(const ValueKey('today-plan'));
        final rows = [
          for (final t in fixture.todayTasks)
            if (find
                .descendant(
                  of: plan,
                  matching: find.byKey(ValueKey('today-plan-lead-${t.id}')),
                )
                .evaluate()
                .isNotEmpty)
              t,
        ];
        expect(rows, isNotEmpty, reason: 'today\'s plan lists its tasks');

        Finder title(Task task) => find.descendant(
          of: plan,
          matching: find.text(words.text(task.title), findRichText: true),
        );

        // The row's band: its lead mark and its title's line, grown to the
        // smallest box that holds both (the row, with any line under the
        // title) when that box holds no other row's lead.
        Future<Rect> band(Task task) async {
          final leadBox = tester.renderObject<RenderBox>(
            find.byKey(ValueKey('today-plan-lead-${task.id}')),
          );
          final lead = await tester.runAsync(() => probe.ink(leadBox));
          final line = lead!.expandToInclude(tester.getRect(title(task).first));
          bool holds(RenderObject box, RenderObject child) {
            for (RenderObject? o = child; o != null; o = o.parent) {
              if (identical(o, box)) return true;
            }
            return false;
          }

          for (
            RenderObject? o = tester.renderObject(title(task).first).parent;
            o != null;
            o = o.parent
          ) {
            if (o is! RenderBox || !holds(o, leadBox)) continue;
            final others = [
              for (final t in rows)
                if (t.id != task.id)
                  tester.renderObject(
                    find.byKey(ValueKey('today-plan-lead-${t.id}')),
                  ),
            ];
            if (others.any((other) => holds(o!, other))) return line;
            return line.expandToInclude(
              MatrixUtils.transformRect(o.getTransformTo(null), o.paintBounds),
            );
          }
          return line;
        }

        // The row's spoken name: the nearest node over its lead mark or its
        // title that names the task (a row may speak through its checkbox).
        List<String> names(Task task) {
          final name = words.text(task.title);
          final found = <String>[];
          for (final finder in [
            find.byKey(ValueKey('today-plan-lead-${task.id}')),
            title(task).first,
          ]) {
            for (
              SemanticsNode? node = tester.getSemantics(finder);
              node != null;
              node = node.parent
            ) {
              final label = node.getSemanticsData().label;
              if (label.contains(name)) {
                found.add(label);
                break;
              }
            }
          }
          return found;
        }

        final keyed = find.byKey(const ValueKey('today-plan-running'));
        final worded = find.descendant(
          of: plan,
          matching: find.textContaining(words.runningTimer, findRichText: true),
        );
        Future<void> marked(String? id, String when) async {
          final mark = keyed.evaluate().isNotEmpty ? keyed : worded;
          if (id == null) {
            expect(keyed, findsNothing, reason: 'no mark $when');
            expect(worded, findsNothing, reason: 'no running words $when');
          } else {
            expect(mark, findsOneWidget, reason: 'one mark $when');
            expect(
              find.descendant(of: plan, matching: mark),
              findsOneWidget,
              reason: 'the mark stands in the plan $when',
            );
            final ink = (await tester.runAsync(
              () => probe.ink(tester.renderObject<RenderBox>(mark)),
            ))!;
            final bands = {for (final t in rows) t.id: await band(t)};
            final own = bands[id]!;
            expect(
              ink.top < own.bottom && ink.bottom > own.top,
              isTrue,
              reason: 'the mark paints on the $id row $when: $ink, row $own',
            );
            for (final other in bands.entries) {
              if (other.key == id) continue;
              expect(
                (ink.center.dy - own.center.dy).abs() <
                    (ink.center.dy - other.value.center.dy).abs(),
                isTrue,
                reason: 'the mark sits nearer $id than ${other.key} $when',
              );
            }
          }
          for (final t in rows) {
            final said = names(t);
            expect(said, isNotEmpty, reason: '${t.id} has a spoken name');
            expect(
              said.any((label) => label.contains(words.runningTimer)),
              t.id == id,
              reason: '${t.id} spoken name $when: $said',
            );
          }
        }

        final first = repo.snapshot.timer!.taskId;
        expect(rows.map((t) => t.id), contains(first));
        await marked(first, 'at launch');

        final next = rows.firstWhere((t) => t.id != first && !t.done);
        final key = find.byKey(const ValueKey('today-action-last'));
        await tester.ensureVisible(key);
        await tester.tap(key);
        await tester.pumpAndSettle();
        final search = find.byType(EditableText);
        if (search.evaluate().length == 1) {
          await tester.enterText(search, words.text(next.title));
          await tester.pumpAndSettle();
          await tester.sendKeyEvent(LogicalKeyboardKey.enter);
          await tester.pumpAndSettle();
        }
        if (repo.snapshot.timer?.taskId != next.id) {
          // A picker without a search field lists the tasks to tap.
          await tester.tap(find.text(words.text(next.title)).last);
          await tester.pumpAndSettle();
        }
        expect(repo.snapshot.timer?.taskId, next.id, reason: 'switched');
        await marked(next.id, 'after a switch');

        final stop = find.byKey(const ValueKey('today-action-first'));
        await tester.ensureVisible(stop);
        await tester.tap(stop);
        await tester.pumpAndSettle();
        expect(repo.snapshot.timer, isNull, reason: 'stopped');
        await marked(null, 'after stop');
        expect(tester.takeException(), isNull);
      });
    }
  }
}

/// What a centred timer strip's painted marks get wrong at [width], each as
/// a reason; empty where they hold. Every rect is painted ink in global
/// coordinates, and starts and ends read from the right where [rtl].
///
/// From 768 the title, the digits and the keys share one centre line, or
/// the keys stand on a row of their own under the digits, set close (8 to
/// 24 px, the strip's own gap, as a compact strip sets clock and title
/// apart), still sharing a centre line with each other. Either way the
/// last key ends at the card's inset. Below 768 they stack.
List<String> centredStripProblems({
  required double width,
  required bool rtl,
  required Rect title,
  required Rect digits,
  required Rect first,
  required Rect last,
  required Rect card,
  required Rect tasks,
}) {
  final problems = <String>[];
  void aligned(double actual, double expected, String why) {
    if ((actual - expected).abs() > 1) {
      problems.add('$why: $actual, expected $expected within 1');
    }
  }

  double start(Rect rect) => rtl ? rect.right : rect.left;
  double end(Rect rect) => rtl ? rect.left : rect.right;
  if (width < 768) {
    if (digits.top <= title.bottom) problems.add('digits under the title');
    if (first.top <= digits.bottom) problems.add('buttons under the digits');
    return problems;
  }
  aligned(title.center.dy, digits.center.dy, 'timer title and digits centre');
  aligned(first.center.dy, last.center.dy, 'timer button centres');
  if (first.top > digits.bottom) {
    final gap = first.top - digits.bottom;
    if (gap < 8 || gap > 24) {
      problems.add('timer keys row under the digits: $gap apart, not 8 to 24');
    }
  } else {
    aligned(
      digits.center.dy,
      last.center.dy,
      'timer digits and controls centre',
    );
  }
  if (width >= 1024) {
    aligned(
      start(digits),
      start(tasks),
      'clock starts on the Open tasks track',
    );
  } else {
    final separation = rtl
        ? title.left - digits.right
        : digits.left - title.right;
    final onGrid = (start(digits) - start(tasks)).abs() <= 1;
    if (!onGrid && (separation < 8 || separation > 24)) {
      problems.add('compact strip groups clock and title or uses the grid');
    }
  }
  aligned(
    (end(card) - end(last)).abs(),
    (start(title) - start(card)).abs(),
    'trailing control has the card inset',
  );
  return problems;
}

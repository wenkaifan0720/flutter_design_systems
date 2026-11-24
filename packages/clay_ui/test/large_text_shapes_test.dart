// At twice the text size on a phone, the parts that hold words in a shape keep
// them whole and inside it: a face's initials and a group's count keep their
// size (as Material's avatars do), a badge's count grows to 1.3 times and runs
// on past the corner it marks, tags grow with their words, a ring's, a donut's
// and a step's figures stand inside the round, a month's days are drawn at one
// size, the wheel's half of the day keeps clear of its pill's ends, a
// time field's well grows round its figures, and a dock place's name keeps
// clear of its pill's ends.
import 'dart:math' as math;

import 'package:clay_ui/clay_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;

Future<void> _phone(
  WidgetTester tester,
  Widget child, {
  required TextDirection direction,
  double scale = 2,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 844);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, app) => ClayTheme(
        data: ClayThemeData.clay(Brightness.light),
        child: MediaQuery.withClampedTextScaling(
          minScaleFactor: scale,
          maxScaleFactor: scale,
          child: app!,
        ),
      ),
      home: Directionality(
        textDirection: direction,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: child,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

// [text] lays out whole: on [lines] lines, none cut short at its end, none
// cut at its foot.
void _expectWhole(WidgetTester tester, Finder text, {int lines = 1}) {
  final paragraph = tester.renderObject<RenderParagraph>(text);
  final words = paragraph.text.toPlainText();
  expect(
    paragraph.didExceedMaxLines,
    isFalse,
    reason: '"$words" runs past its lines',
  );
  final boxes = paragraph.getBoxesForSelection(
    TextSelection(baseOffset: 0, extentOffset: words.length),
  );
  expect(
    {for (final box in boxes) box.top.round()},
    hasLength(lines),
    reason: '"$words" lies on the wrong number of lines',
  );
  expect(
    paragraph.size.height,
    greaterThanOrEqualTo(
      paragraph.getMaxIntrinsicHeight(paragraph.size.width) - 0.5,
    ),
    reason: '"$words" is cut at its foot',
  );
  if (lines == 1) {
    expect(
      paragraph.size.width,
      greaterThanOrEqualTo(
        paragraph.getMaxIntrinsicWidth(double.infinity) - 0.5,
      ),
      reason: '"$words" is cut at its end',
    );
  }
}

// [inner] lies inside [outer].
void _expectWithin(Rect inner, Rect outer, String what) {
  expect(
    inner.left >= outer.left - 0.5 &&
        inner.top >= outer.top - 0.5 &&
        inner.right <= outer.right + 0.5 &&
        inner.bottom <= outer.bottom + 0.5,
    isTrue,
    reason: '$what ($inner) leaves its shape ($outer)',
  );
}

// Every corner of [inner] lies within [radius] of [centre].
void _expectInRound(Rect inner, Offset centre, double radius, String what) {
  for (final corner in [
    inner.topLeft,
    inner.topRight,
    inner.bottomLeft,
    inner.bottomRight,
  ]) {
    expect(
      (corner - centre).distance,
      lessThanOrEqualTo(radius + 0.5),
      reason: '$what ($inner) reaches past the round of $radius',
    );
  }
}

Finder _nearest(Finder of, Type type) =>
    find.ancestor(of: of, matching: find.byType(type)).first;

void main() {
  setUpAll(clayLoadFonts);
  for (final direction in TextDirection.values) {
    final side = direction.name;

    testWidgets('a face\'s initials and a group\'s count keep their size '
        'and stay inside their ball ($side)', (tester) async {
      await _phone(
        tester,
        direction: direction,
        const Align(
          alignment: AlignmentDirectional.topStart,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClayAvatar(name: 'Mia Okafor'),
              SizedBox(height: 24),
              ClayAvatarGroup(
                max: 3,
                avatars: [
                  ClayAvatar(name: 'Mia Okafor'),
                  ClayAvatar(name: 'Jun Park'),
                  ClayAvatar(name: 'Ade Bello'),
                  ClayAvatar(name: 'Lena Vogel'),
                  ClayAvatar(name: 'Sam Reyes'),
                ],
              ),
            ],
          ),
        ),
      );
      for (final initials in ['MO', 'JP', 'AB', '+2']) {
        final text = find.text(initials).first;
        _expectWhole(tester, text);
        expect(
          tester.renderObject<RenderParagraph>(text).textScaler,
          TextScaler.noScaling,
          reason: '$initials grows with the text',
        );
        final ball = initials.startsWith('+')
            ? tester.getRect(_nearest(text, ClaySurface))
            : tester.getRect(_nearest(text, ClayAvatar));
        _expectWithin(tester.getRect(text), ball, initials);
      }
    });

    testWidgets('a badge\'s count grows to 1.3 times, whole, and runs on '
        'past the corner it marks ($side)', (tester) async {
      await _phone(
        tester,
        direction: direction,
        const Align(
          alignment: AlignmentDirectional.topStart,
          child: Padding(
            padding: EdgeInsets.all(16),
            child: ClayBadge(
              count: 120,
              child: Icon(LucideIcons.bell, size: 24),
            ),
          ),
        ),
      );
      final count = find.text('99+');
      _expectWhole(tester, count);
      expect(
        tester.renderObject<RenderParagraph>(count).textScaler.scale(10),
        moreOrLessEquals(13),
      );
      final pill = tester.getRect(_nearest(count, ClaySurface));
      final bell = tester.getRect(find.byIcon(LucideIcons.bell));
      _expectWithin(tester.getRect(count), pill, '99+');
      // It starts 12 inside the bell's top end corner and grows outward.
      if (direction == TextDirection.ltr) {
        expect(pill.left, moreOrLessEquals(bell.right - 12));
        expect(pill.right, greaterThan(bell.right));
      } else {
        expect(pill.right, moreOrLessEquals(bell.left + 12));
        expect(pill.left, lessThan(bell.left));
      }
    });

    testWidgets('a tag grows with its words ($side)', (tester) async {
      await _phone(
        tester,
        direction: direction,
        const Align(
          alignment: AlignmentDirectional.topStart,
          child: ClayTag('Morning', icon: LucideIcons.sunrise),
        ),
      );
      final words = find.text('Morning');
      _expectWhole(tester, words);
      _expectWithin(
        tester.getRect(words),
        tester.getRect(_nearest(words, ClaySurface)),
        'Morning',
      );
    });

    testWidgets('a tag input\'s pills grow with their words ($side)', (
      tester,
    ) async {
      await _phone(
        tester,
        direction: direction,
        ClayTagInput<String>(
          labelText: 'Tags',
          values: const ['Morning', 'With friends'],
          options: const ['Morning', 'Outdoors', 'With friends'],
          onCreate: (text) => text,
          onChanged: (_) {},
        ),
      );
      for (final tag in ['Morning', 'With friends']) {
        final words = find.text(tag);
        _expectWhole(tester, words);
        _expectWithin(
          tester.getRect(words),
          tester.getRect(_nearest(words, AnimatedClaySurface)),
          tag,
        );
      }
    });

    testWidgets('a table keeps its figures and its headings whole ($side)', (
      tester,
    ) async {
      await _phone(
        tester,
        direction: direction,
        const ClayTable(
          columns: [
            ClayTableColumn('Habit', flex: 2),
            ClayTableColumn('This week', numeric: true),
            ClayTableColumn('Streak', numeric: true),
          ],
          rows: [
            ['Drink water', '6 of 7', '12'],
            ['Morning walk', '5 of 7', '9'],
            ['Read', '4 of 7', '4'],
            ['Stretch', '7 of 7', '21'],
          ],
        ),
      );
      for (final cell in [
        'Streak',
        '6 of 7',
        '5 of 7',
        '4 of 7',
        '7 of 7',
        '12',
        '9',
        '21',
      ]) {
        _expectWhole(tester, find.text(cell));
      }
    });

    testWidgets('a ring\'s figure stands inside its hole ($side)', (
      tester,
    ) async {
      await _phone(
        tester,
        direction: direction,
        Align(
          alignment: AlignmentDirectional.topStart,
          child: Builder(
            builder: (context) => ClayProgressRing(
              value: 0.6,
              size: 84,
              thickness: 11,
              child: Text('3/5', style: context.clayTheme.textTheme.title),
            ),
          ),
        ),
      );
      final figure = find.text('3/5');
      _expectWhole(tester, figure);
      _expectInRound(
        tester.getRect(figure),
        tester.getCenter(find.byType(ClayProgressRing)),
        84 / 2 - 11,
        '3/5',
      );
    });

    testWidgets('a donut\'s words stand inside its well ($side)', (
      tester,
    ) async {
      await _phone(
        tester,
        direction: direction,
        const ClayPieChart(
          semanticLabel: 'Minutes by habit this week',
          centerLabel: '5 h',
          centerCaption: 'this week',
          slices: [
            ClayPieSlice(label: 'Walk', value: 40),
            ClayPieSlice(label: 'Read', value: 25),
            ClayPieSlice(label: 'Stretch', value: 20),
          ],
        ),
      );
      final centre = tester.getCenter(_nearest(find.text('5 h'), FittedBox));
      // The well: the hole (0.58 of the radius of 100) less its rim of 7.
      for (final words in ['5 h', 'this week']) {
        _expectWhole(tester, find.text(words));
        _expectInRound(
          tester.getRect(find.text(words)),
          centre,
          100 * 0.58 - 7,
          words,
        );
      }
    });

    testWidgets('a step\'s figure stands inside its ball ($side)', (
      tester,
    ) async {
      await _phone(
        tester,
        direction: direction,
        const ClayStepProgress(
          steps: ['Name', 'Time', 'Reminder', 'Done'],
          currentStep: 1,
        ),
      );
      for (final n in ['2', '3', '4']) {
        final figure = find.text(n);
        _expectWhole(tester, figure);
        final ball = find
            .ancestor(
              of: figure,
              matching: find.byWidgetPredicate(
                (w) => w is SizedBox && w.width == 32 && w.height == 32,
              ),
            )
            .first;
        _expectInRound(
          tester.getRect(figure),
          tester.getCenter(ball),
          16,
          'step $n',
        );
      }
    });

    testWidgets('a month\'s days are all drawn at one size ($side)', (
      tester,
    ) async {
      await _phone(
        tester,
        direction: direction,
        ClayCalendar(
          firstDate: DateTime(2026),
          lastDate: DateTime(2026, 12, 31),
          currentDate: DateTime(2026, 11, 19),
          selectedDate: DateTime(2026, 11, 19),
          onDateChanged: (_) {},
        ),
      );
      final heights = [
        for (var d = 1; d <= 30; d++)
          tester.getRect(find.text('$d').first).height,
      ];
      final tallest = heights.reduce(math.max);
      for (final (i, h) in heights.indexed) {
        expect(
          h,
          moreOrLessEquals(tallest, epsilon: 0.5),
          reason: 'day ${i + 1} is drawn at another size',
        );
      }
    });

    testWidgets('the wheel\'s half of the day keeps clear of its pill\'s '
        'ends ($side)', (tester) async {
      await _phone(
        tester,
        direction: direction,
        ClayTimePicker(
          value: const ClayTime(hour: 9, minute: 30),
          onChanged: (_) {},
        ),
      );
      final am = find.text('AM');
      _expectWhole(tester, am);
      final surfaces = find.descendant(
        of: find.byType(ClayTimePicker),
        matching: find.byType(ClaySurface),
      );
      // The pill: the flattest of the picker's clay.
      final pill = [
        for (final e in surfaces.evaluate())
          tester.getRect(find.byWidget(e.widget)),
      ].reduce((a, b) => a.height <= b.height ? a : b);
      final word = tester.getRect(am);
      expect(
        math.min(word.left - pill.left, pill.right - word.right),
        greaterThanOrEqualTo(8),
        reason: 'AM ($word) stands against its pill ($pill)',
      );
    });

    testWidgets('a time field grows with its figures and keeps them inside '
        'their pills and its well ($side)', (tester) async {
      await _phone(
        tester,
        direction: direction,
        ClayTimeField(
          labelText: 'Remind me at',
          value: const ClayTime(hour: 21, minute: 0),
          onChanged: (_) {},
        ),
      );
      final well = tester.getRect(
        find
            .descendant(
              of: find.byType(ClayTimeField),
              matching: find.byType(AnimatedClaySurface),
            )
            .first,
      );
      for (final figure in ['9', '00', 'PM']) {
        final text = find.text(figure);
        _expectWhole(tester, text);
        final at = tester.getRect(text);
        _expectWithin(at, well, figure);
        final pill = tester.getRect(_nearest(text, AnimatedClaySurface));
        _expectWithin(at, pill, '$figure in its pill');
        expect(
          pill.height - at.height,
          greaterThanOrEqualTo(8),
          reason: '$figure ($at) stands against its pill ($pill)',
        );
      }
    });

    testWidgets('a dock place\'s name keeps clear of its pill\'s ends '
        '($side)', (tester) async {
      await _phone(
        tester,
        direction: direction,
        ClayNavigationBar(
          destinations: const [
            ClayDestination(icon: LucideIcons.sparkles, label: 'Clay'),
            ClayDestination(icon: LucideIcons.sun, label: 'Today'),
            ClayDestination(icon: LucideIcons.listChecks, label: 'Habits'),
            ClayDestination(icon: LucideIcons.settings, label: 'Settings'),
          ],
          selectedIndex: 3,
          onDestinationSelected: (_) {},
          action: const SizedBox.square(dimension: 48),
        ),
      );
      final name = find.text('Settings');
      final at = tester.getRect(name);
      final pill = tester.getRect(_nearest(name, AnimatedClaySurface));
      expect(
        math.min(at.left - pill.left, pill.right - at.right),
        greaterThanOrEqualTo(ClaySpacing.tight - 0.5),
        reason: 'Settings ($at) runs to its pill\'s ends ($pill)',
      );
    });
  }

  testWidgets('at the reader\'s own size a ring\'s figure keeps its size', (
    tester,
  ) async {
    await _phone(
      tester,
      direction: TextDirection.ltr,
      scale: 1,
      Align(
        alignment: AlignmentDirectional.topStart,
        child: Builder(
          builder: (context) => ClayProgressRing(
            value: 0.6,
            size: 84,
            thickness: 11,
            child: Text('3/5', style: context.clayTheme.textTheme.title),
          ),
        ),
      ),
    );
    final figure = find.text('3/5');
    expect(
      tester.getRect(figure).size,
      tester.renderObject<RenderParagraph>(figure).size,
    );
  });
}

// Words on ruled paper stand on its rules: the blank page's head unruled,
// its title's last line on the first rule and every line of its body and
// its act's words on the rules after it, each rule running whole to the
// slip's end (no patch of plain paper behind them), on a phone and on a
// desk; the failed
// page's margin ruled in the vermilion; the blank page's margin one ink where
// it crosses a rule; and the memo's hint and first line
// on its first line, clear of the rule under it.
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_ui/ledger_ui.dart';
import 'package:ledger_ui/ledger_host.dart';

const Key _slip = ValueKey<String>('slip');

void _size(WidgetTester t, Size size) {
  t.view.physicalSize = size;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
}

Widget _host(Widget child, {double width = 360}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  builder: (context, page) =>
      LedgerHost(brightness: Brightness.light, child: page!),
  home: Align(
    alignment: Alignment.topLeft,
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: SizedBox(
        width: width,
        child: RepaintBoundary(key: _slip, child: child),
      ),
    ),
  ),
);

/// The slip's pixels, one per logical pixel.
Future<(ByteData, int)> _pixels(WidgetTester t) async {
  final boundary = t.renderObject<RenderRepaintBoundary>(find.byKey(_slip));
  final bytes = (await t.runAsync(() async {
    final image = await boundary.toImage();
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    image.dispose();
    return data!;
  }))!;
  return (bytes, boundary.size.width.round());
}

List<int> _at(ByteData bytes, int width, int x, int y) {
  final i = (y * width + x) * 4;
  return [bytes.getUint8(i), bytes.getUint8(i + 1), bytes.getUint8(i + 2)];
}

int _apart(List<int> a, List<int> b) =>
    [for (var c = 0; c < 3; c++) (a[c] - b[c]).abs()]
        .reduce((p, q) => p > q ? p : q);

/// The baselines of every line of [text], in the slip's own pixels.
List<double> _baselines(WidgetTester t, Finder text) {
  final paragraph = t.renderObject<RenderParagraph>(text);
  final origin = t.getTopLeft(find.byKey(_slip));
  final painter = TextPainter(
    text: paragraph.text,
    textDirection: paragraph.textDirection,
    textScaler: paragraph.textScaler,
    textAlign: paragraph.textAlign,
    strutStyle: paragraph.strutStyle,
    textHeightBehavior: paragraph.textHeightBehavior,
    textWidthBasis: paragraph.textWidthBasis,
  )..layout(maxWidth: paragraph.constraints.maxWidth);
  final lines = painter.computeLineMetrics();
  painter.dispose();
  return [
    for (final line in lines)
      paragraph.localToGlobal(Offset(0, line.baseline)).dy - origin.dy,
  ];
}

void main() {
  for (final (name, screen) in [
    ('phone', const Size(390, 844)),
    ('desk', const Size(1440, 900)),
  ]) {
    testWidgets('every line of the blank page\'s words stands on a rule '
        '($name)', (t) async {
      _size(t, screen);
      await t.pumpWidget(
        _host(
          LedgerEmptyState(
            title: 'Nothing for this week',
            body:
                'There are no open tasks coming up this week, so there is '
                'time to plan the next one.',
            actionLabel: 'New task',
            onActionPressed: () {},
          ),
        ),
      );
      final (bytes, width) = await _pixels(t);
      // Past the words, at the slip's end: the rule each line stands on
      // runs whole to the edge.
      final x = width - 4;
      // Below the slip's rounded corner.
      const head = 16;
      final paper = _at(bytes, width, x, head);
      int ink(int y) => _apart(_at(bytes, width, x, y), paper);
      final title = _baselines(
        t,
        find.text('Nothing for this week', findRichText: true).first,
      );
      final body = _baselines(t, find.textContaining('There are no open'));
      final act = _baselines(t, find.text('New task')).single;
      expect(body.length, greaterThanOrEqualTo(2), reason: '$body');
      // The head is unruled; the title's last line stands on the first rule,
      // each of the body's lines on the next.
      for (final y in [title.last, ...body]) {
        expect(
          ink(y.round()),
          greaterThan(8),
          reason: 'no rule under the line at $y (paper $paper)',
        );
      }
      expect(
        [for (var y = head; y < title.last.round(); y++) ink(y)]
            .every((d) => d <= 4),
        isTrue,
        reason: 'a rule over the title\'s last line',
      );
      // The act's words stand on a rule too, its own paper under its face.
      expect(
        [for (var y = act.round() - 3; y <= act.round() + 3; y++) ink(y)]
            .any((d) => d > 8),
        isTrue,
        reason: 'no rule by the act\'s words at $act',
      );
    });
  }

  for (final brightness in Brightness.values) {
    testWidgets('the blank page\'s margin crosses its rules in one ink, no '
        'darker knot where the two meet (${brightness.name})', (t) async {
      _size(t, const Size(390, 844));
      await t.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          builder: (context, page) =>
              LedgerHost(brightness: brightness, child: page!),
          home: Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: 360,
                child: RepaintBoundary(
                  key: _slip,
                  child: LedgerEmptyState(
                    title: 'Nothing for this week',
                    body:
                        'There are no open tasks coming up this week, so '
                        'there is time to plan the next one.',
                    actionLabel: 'New task',
                    onActionPressed: () {},
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      final (bytes, width) = await _pixels(t);
      // A rule's row: under the body's first line, at the slip's end.
      final ruled = _baselines(
        t,
        find.textContaining('There are no open'),
      ).first.round();
      final paper = _at(bytes, width, width - 4, 16);
      expect(
        _apart(_at(bytes, width, width - 4, ruled), paper),
        greaterThan(8),
      );
      for (final x in [
        LedgerChromeMetrics.emptyMarginRule.round(),
        LedgerChromeMetrics.emptyMarginRule2.round(),
      ]) {
        // The margin on bare paper (the unruled head) and where it crosses
        // the rule print the same.
        expect(
          _apart(_at(bytes, width, x, ruled), _at(bytes, width, x, 16)),
          lessThanOrEqualTo(2),
          reason:
              'margin at $x: ${_at(bytes, width, x, ruled)} on the rule, '
              '${_at(bytes, width, x, 16)} on paper',
        );
      }
    });
  }

  testWidgets('the failed page rules its margin in the vermilion', (t) async {
    _size(t, const Size(390, 844));
    await t.pumpWidget(
      _host(
        SizedBox(
          height: 320,
          child: LedgerErrorState(
            title: 'Couldn’t load the workspace',
            message: 'Try again to load the team’s latest work.',
            onRetryPressed: () {},
          ),
        ),
      ),
    );
    final theme = t.element(find.byType(LedgerErrorState)).ledgerTheme;
    final (bytes, width) = await _pixels(t);
    final danger = [
      (theme.danger.r * 255).round(),
      (theme.danger.g * 255).round(),
      (theme.danger.b * 255).round(),
    ];
    for (final x in [
      LedgerChromeMetrics.emptyMarginRule.round(),
      LedgerChromeMetrics.emptyMarginRule2.round(),
    ]) {
      expect(
        _apart(_at(bytes, width, x, 160), danger),
        lessThanOrEqualTo(2),
        reason: 'the margin rule at $x is ${_at(bytes, width, x, 160)}',
      );
    }
  });

  testWidgets('the memo\'s hint and first line stand on its first line', (
    t,
  ) async {
    _size(t, const Size(390, 844));
    await t.pumpWidget(
      _host(
        const LedgerTextArea(
          label: 'Work note',
          hint: 'What did you work on?',
          minLines: 2,
          maxLines: 5,
        ),
      ),
    );
    // The ruled paper: the painted box the words are written in.
    final paper = t.getRect(
      find
          .ancestor(
            of: find.byType(EditableText),
            matching: find.byWidgetPredicate(
              (w) => w is CustomPaint && w.painter != null,
            ),
          )
          .first,
    );
    final step = (paper.height / 2).roundToDouble();
    final hint = t.getRect(find.text('What did you work on?'));
    expect(hint.top, moreOrLessEquals(paper.top, epsilon: .5));
    expect(hint.bottom, lessThanOrEqualTo(paper.top + step + .5));

    await t.enterText(find.byType(EditableText), 'Wrote the brief');
    await t.pump();
    expect(
      t.getRect(find.byType(EditableText)).top,
      moreOrLessEquals(paper.top, epsilon: .5),
    );
  });
}

/// The progress family: the indicators' geometry from the generated tokens
/// (flat and wavy, linear and circular), the 240dp default and `expand`,
/// the progress semantics, the wavy variants' hero requirement, the
/// indeterminate indicators running without error, and the step
/// indicator's steps and semantics.
library;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';
import 'package:material_expressive_ui/material_expressive_host.dart';
import 'package:material_expressive_ui/src/material_expressive/internal/tokens/behavior.g.dart';
import 'package:material_expressive_ui/src/material_expressive/internal/tokens/circular_progress_indicator_tokens.g.dart';
import 'package:material_expressive_ui/src/material_expressive/internal/tokens/linear_progress_indicator_tokens.g.dart';

final ExpressiveThemeData _theme = ExpressiveThemeData.preset(
  'baseline',
  Brightness.light,
);

Widget _app(Widget child, {double width = 360, bool hero = false}) =>
    ExpressiveHost(
      light: _theme,
      brightness: Brightness.light,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: const MediaQueryData(),
          child: Center(
            child: SizedBox(
              width: width,
              child: Center(
                child: hero ? ExpressiveHeroMoment(child: child) : child,
              ),
            ),
          ),
        ),
      ),
    );

Size _paint(WidgetTester tester, Type type) => tester.getSize(
  find.descendant(of: find.byType(type), matching: find.byType(CustomPaint)),
);

void main() {
  group('geometry', () {
    testWidgets('linear: 240 x 4dp, or the width available when expanded', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(const ExpressiveLinearProgressIndicator(value: 0.4)),
      );
      expect(
        _paint(tester, ExpressiveLinearProgressIndicator),
        const Size(240, 4),
      );
      expect(ProgressIndicatorBehavior.linearWidth, 240);
      expect(LinearProgressIndicatorTokens.height, 4);

      await tester.pumpWidget(
        _app(const ExpressiveLinearProgressIndicator(value: 0.4, expand: true)),
      );
      expect(_paint(tester, ExpressiveLinearProgressIndicator).width, 360);

      await tester.pumpWidget(
        _app(const ExpressiveLinearProgressIndicator(value: 0.4), width: 120),
      );
      expect(_paint(tester, ExpressiveLinearProgressIndicator).width, 120);
    });

    testWidgets(
      'linear semantics grow 10dp above and below the track, layout does not '
      '(IncreaseVerticalSemanticsBounds)',
      (tester) async {
        final handle = tester.ensureSemantics();
        final pad = ProgressIndicatorBehavior.verticalSemanticsBoundsPadding;
        expect(pad, 10);
        for (final wavy in [false, true]) {
          await tester.pumpWidget(
            _app(
              ExpressiveLinearProgressIndicator(
                value: 0.4,
                wavy: wavy,
                semanticLabel: 'Upload',
              ),
              hero: true,
            ),
          );
          final height = wavy
              ? LinearProgressIndicatorTokens.waveHeight
              : LinearProgressIndicatorTokens.height;
          expect(
            tester
                .getSize(find.byType(ExpressiveLinearProgressIndicator))
                .height,
            height,
          );
          final node = tester.getSemantics(find.bySemanticsLabel('Upload'));
          expect(node.rect, Rect.fromLTRB(0, -pad, 240, height + pad));
          expect(node.value, '40%');
        }
        handle.dispose();
      },
    );

    testWidgets('wavy linear is the wave height, 10dp', (tester) async {
      await tester.pumpWidget(
        _app(
          const ExpressiveLinearProgressIndicator(value: 0.5, wavy: true),
          hero: true,
        ),
      );
      expect(
        _paint(tester, ExpressiveLinearProgressIndicator),
        Size(240, LinearProgressIndicatorTokens.waveHeight),
      );
      expect(LinearProgressIndicatorTokens.waveHeight, 10);
    });

    testWidgets('circular: 40dp, wavy 48dp', (tester) async {
      await tester.pumpWidget(
        _app(const ExpressiveCircularProgressIndicator(value: 0.3)),
      );
      expect(
        _paint(tester, ExpressiveCircularProgressIndicator),
        const Size(40, 40),
      );
      await tester.pumpWidget(
        _app(
          const ExpressiveCircularProgressIndicator(value: 0.3, wavy: true),
          hero: true,
        ),
      );
      expect(
        _paint(tester, ExpressiveCircularProgressIndicator),
        Size.square(CircularProgressIndicatorTokens.waveSize),
      );
      expect(CircularProgressIndicatorTokens.waveSize, 48);
    });
  });

  group('semantics and heroes', () {
    testWidgets('a determinate indicator reads as a percentage', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _app(
          const ExpressiveLinearProgressIndicator(
            value: 0.426,
            semanticLabel: 'Upload',
          ),
        ),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Upload')),
        matchesSemantics(label: 'Upload', value: '43%'),
      );
      handle.dispose();
    });

    testWidgets('a wavy indicator outside an ExpressiveHeroMoment is refused', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(const ExpressiveLinearProgressIndicator(value: 0.5, wavy: true)),
      );
      expect(tester.takeException(), isA<FlutterError>());
      await tester.pumpWidget(
        _app(const ExpressiveCircularProgressIndicator(wavy: true)),
      );
      expect(tester.takeException(), isA<FlutterError>());
      await tester.pumpWidget(
        _app(const ExpressiveCircularProgressIndicator(wavy: true), hero: true),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('motion', () {
    testWidgets('indeterminate indicators run their timelines', (tester) async {
      await tester.pumpWidget(
        _app(
          const Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ExpressiveLinearProgressIndicator(),
              ExpressiveCircularProgressIndicator(),
              ExpressiveLinearProgressIndicator(wavy: true),
              ExpressiveCircularProgressIndicator(wavy: true),
            ],
          ),
          hero: true,
        ),
      );
      // Across a full circular cycle (6 s) and several linear ones.
      for (var i = 0; i < 400; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      expect(tester.takeException(), isNull);
      expect(tester.binding.hasScheduledFrame, isTrue);
      // A determinate flat indicator schedules nothing.
      await tester.pumpWidget(
        _app(const ExpressiveLinearProgressIndicator(value: 1)),
      );
      await tester.pump();
      expect(tester.binding.hasScheduledFrame, isFalse);
    });

    testWidgets('a wavy indicator flattens past 95% on a spring', (
      tester,
    ) async {
      Widget at(double v) => _app(
        ExpressiveLinearProgressIndicator(value: v, wavy: true),
        hero: true,
      );
      await tester.pumpWidget(at(0.5));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpWidget(at(1));
      for (var i = 0; i < 60; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      expect(tester.takeException(), isNull);
    });
  });

  group('step indicator', () {
    testWidgets('done steps show a check; the current one is announced', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _app(
          const ExpressiveStepProgress(
            count: 4,
            currentStep: 2,
            labels: <String>['Basket', 'Delivery', 'Payment', 'Review'],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(ExpressiveSymbols.check), findsNWidgets(2));
      expect(find.text('3'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
      expect(find.bySemanticsLabel('Step 3 of 4: Payment'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('a middle label centres under its marker', (tester) async {
      await tester.pumpWidget(
        _app(
          const ExpressiveStepProgress(
            count: 4,
            currentStep: 1,
            labels: <String>['Basket', 'Delivery', 'Payment', 'Review'],
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (final (label, marker) in const <(String, String)>[
        ('Payment', '3'),
      ]) {
        expect(
          tester.getCenter(find.text(label)).dx,
          moreOrLessEquals(tester.getCenter(find.text(marker)).dx, epsilon: 8),
        );
      }
      // Delivery, the current step, under its number.
      expect(
        tester.getCenter(find.text('Delivery')).dx,
        moreOrLessEquals(tester.getCenter(find.text('2')).dx, epsilon: 8),
      );
    });

    testWidgets('at text 2.0 no name is cut: they print smaller, apart', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          const MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(2)),
            child: ExpressiveStepProgress(
              count: 4,
              currentStep: 1,
              labels: <String>['Basket', 'Delivery', 'Payment', 'Review'],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      const names = <String>['Basket', 'Delivery', 'Payment', 'Review'];
      final rects = [for (final n in names) tester.getRect(find.text(n))];
      for (final n in names) {
        final text = tester.renderObject<RenderParagraph>(find.text(n));
        expect(text.didExceedMaxLines, isFalse, reason: n);
      }
      for (var i = 1; i < rects.length; i++) {
        expect(
          rects[i].left,
          greaterThan(rects[i - 1].right),
          reason: names[i],
        );
      }
      // Inside the indicator's own width (360, centred on the screen).
      final row = tester.getRect(find.byType(ExpressiveStepProgress));
      expect(row.width, 360);
      expect(rects.first.left, greaterThanOrEqualTo(row.left - 0.01));
      expect(rects.last.right, lessThanOrEqualTo(row.right + 0.01));
    });

    testWidgets('segmented: one bar a step, every step done at count', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _app(
          const ExpressiveStepProgress(
            count: 3,
            currentStep: 3,
            kind: ExpressiveStepProgressKind.segmented,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(Expanded), findsNWidgets(3));
      expect(find.bySemanticsLabel('All 3 steps done'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('segmented: each label starts under its own segment', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          const SizedBox(
            width: 360,
            child: ExpressiveStepProgress(
              count: 3,
              currentStep: 1,
              labels: <String>['Rest', 'Reading 1', 'Reading 2'],
              kind: ExpressiveStepProgressKind.segmented,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final segments = find.byType(Expanded);
      expect(segments, findsNWidgets(3));
      for (final (i, name) in <String>[
        'Rest',
        'Reading 1',
        'Reading 2',
      ].indexed) {
        final text = tester.getRect(find.text(name));
        final segment = tester.getRect(segments.at(i));
        expect(text.left, moreOrLessEquals(segment.left, epsilon: 0.5));
        expect(text.top, greaterThan(segment.top));
      }
      expect(tester.takeException(), isNull);
    });
  });
}

/// Cards: the three variants' tokens (colours, shape, stroke, elevation by
/// interaction), clickability and its disabled state, semantics, and the
/// CONTRACT §3 containment asserts.
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';
import 'package:material_expressive_ui/material_expressive_host.dart';

import 'support/brand_shapes.dart';

final ExpressiveThemeData _theme = ExpressiveThemeData.preset(
  'baseline',
  Brightness.light,
);

Widget _app(Widget child) => ExpressiveHost(
  light: _theme,
  brightness: Brightness.light,
  child: Directionality(
    textDirection: TextDirection.ltr,
    child: MediaQuery(
      data: const MediaQueryData(),
      child: Center(child: child),
    ),
  ),
);

const Widget _body = SizedBox(width: 160, height: 96, child: Text('Tide'));

ExpressiveSurface _surface(WidgetTester tester) =>
    tester.widget<ExpressiveSurface>(find.byType(ExpressiveSurface).first);

void main() {
  testWidgets(
    'card role shapes contain content across densities, widths and scales',
    (tester) async {
      for (final shapes in const [
        roundedTestShapes,
        cookieTestShapes,
        scallopedTestShapes,
      ]) {
        for (final density in const [
          ExpressiveDensity.standard,
          ExpressiveDensity.comfortable,
          ExpressiveDensity.compact,
        ]) {
          for (final width in [120.0, 240.0, 390.0]) {
            for (final scale in [1.0, 1.3]) {
              for (final clickable in [false, true]) {
                await tester.pumpWidget(
                  _app(
                    ExpressiveTheme(
                      data: _theme.copyWith(density: density),
                      child: MediaQuery(
                        data: MediaQueryData(
                          textScaler: TextScaler.linear(scale),
                        ),
                        child: SizedBox(
                          width: width,
                          child: ExpressiveCard(
                            style: shapedStyle(shapes.tall),
                            onPressed: clickable ? () {} : null,
                            padding: const EdgeInsets.all(8),
                            child: const Text(
                              'A longer card title and its supporting description',
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
                await tester.pumpAndSettle();
                final face = find.byType(ExpressiveSurface).first;
                final box = tester.getRect(face);
                final content = tester
                    .getRect(
                      find.text(
                        'A longer card title and its supporting description',
                      ),
                    )
                    .shift(-box.topLeft)
                    .deflate(1);
                final path = _surface(tester).shape
                    .getOuterPath(Offset.zero & box.size);
                for (final point in [
                  content.topLeft,
                  content.topCenter,
                  content.topRight,
                  content.centerLeft,
                  content.centerRight,
                  content.bottomLeft,
                  content.bottomCenter,
                  content.bottomRight,
                ]) {
                  expect(
                    path.contains(point),
                    isTrue,
                    reason: '$width $scale $clickable $point',
                  );
                }
                expect(tester.takeException(), isNull);
              }
            }
          }
        }
      }
    },
  );

  final c = _theme.colors;

  group('colours (CardDefaults)', () {
    test('elevated, filled and outlined containers and content', () {
      final elevated = ExpressiveCardColors.of(
        ExpressiveCardVariant.elevated,
        c,
      );
      expect(elevated.container, c.surfaceContainerLow);
      expect(elevated.content, c.onSurface);
      expect(elevated.disabledContainer, c.surface);
      expect(elevated.disabledContent, c.onSurface.withValues(alpha: 0.38));
      expect(elevated.outline, isNull);

      final filled = ExpressiveCardColors.of(ExpressiveCardVariant.filled, c);
      expect(filled.container, c.surfaceContainerHighest);
      expect(filled.content, c.onSurface);
      expect(
        filled.disabledContainer,
        Color.alphaBlend(
          c.surfaceVariant.withValues(alpha: 0.38),
          c.surfaceContainerHighest,
        ),
      );

      final outlined = ExpressiveCardColors.of(
        ExpressiveCardVariant.outlined,
        c,
      );
      expect(outlined.container, c.surface);
      expect(outlined.outline, c.outlineVariant);
      expect(
        outlined.disabledOutline,
        Color.alphaBlend(
          c.outline.withValues(alpha: 0.12),
          c.surfaceContainerLow,
        ),
      );
    });

    test('elevation by interaction', () {
      final elevated = expressiveCardElevation(ExpressiveCardVariant.elevated);
      expect(elevated.resolve(const <WidgetState>{}).dp, 1);
      expect(elevated.resolve(const <WidgetState>{WidgetState.hovered}).dp, 3);
      expect(elevated.resolve(const <WidgetState>{WidgetState.dragged}).dp, 8);
      final filled = expressiveCardElevation(ExpressiveCardVariant.filled);
      expect(filled.resolve(const <WidgetState>{}).dp, 0);
      expect(filled.resolve(const <WidgetState>{WidgetState.hovered}).dp, 1);
      final outlined = expressiveCardElevation(ExpressiveCardVariant.outlined);
      expect(outlined.resolve(const <WidgetState>{WidgetState.hovered}).dp, 0);
      expect(outlined.resolve(const <WidgetState>{WidgetState.dragged}).dp, 6);
    });
  });

  group('ExpressiveCard', () {
    testWidgets('a card is corner.medium, in its container colour', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(const ExpressiveCard.elevated(child: _body)),
      );
      final surface = _surface(tester);
      expect(surface.shape, _theme.shapes.medium);
      expect(surface.color, c.surfaceContainerLow);
      expect(surface.shadowElevation, ExpressiveElevationLevel.level1);
      expect(tester.getSize(find.byType(ExpressiveCard)), const Size(160, 96));
    });

    testWidgets('outlined: a 1dp outlineVariant stroke', (tester) async {
      await tester.pumpWidget(
        _app(const ExpressiveCard.outlined(child: _body)),
      );
      final surface = _surface(tester);
      expect(surface.side.width, 1);
      expect(surface.side.color, c.outlineVariant);
      expect(surface.color, c.surface);
    });

    testWidgets('padding insets the content', (tester) async {
      await tester.pumpWidget(
        _app(
          const ExpressiveCard(
            padding: EdgeInsets.all(ExpressiveSpacing.s16),
            child: _body,
          ),
        ),
      );
      expect(tester.getSize(find.byType(ExpressiveCard)), const Size(192, 128));
    });

    testWidgets('a clickable card is one button; without onPressed it is a '
        'plain surface that takes no tap', (tester) async {
      final handle = tester.ensureSemantics();
      var taps = 0;
      await tester.pumpWidget(
        _app(ExpressiveCard.filled(onPressed: () => taps++, child: _body)),
      );
      await tester.tap(find.byType(ExpressiveCard));
      await tester.pumpAndSettle();
      expect(taps, 1);
      expect(
        tester.getSemantics(find.byType(ExpressivePressable)),
        isSemantics(isButton: true, label: 'Tide'),
      );

      await tester.pumpWidget(
        _app(ExpressiveCard.filled(onPressed: null, child: _body)),
      );
      await tester.tap(find.byType(ExpressiveCard), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(taps, 1);
      // As Flutter's Card: no press target, so no button.
      expect(find.byType(ExpressivePressable), findsNothing);
      expect(find.bySemanticsLabel('Tide'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('a button on a clickable card takes its own taps and keeps '
        'a node of its own (Compose: a child clickable)', (tester) async {
      final handle = tester.ensureSemantics();
      var opens = 0;
      var saves = 0;
      await tester.pumpWidget(
        _app(
          ExpressiveCard.filled(
            onPressed: () => opens++,
            child: SizedBox(
              width: 240,
              height: 120,
              child: Column(
                children: <Widget>[
                  const Expanded(child: Text('Tide')),
                  ExpressiveFilledButton('Save', onPressed: () => saves++),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.bySubtype<ExpressiveButton>());
      await tester.pumpAndSettle();
      expect((opens, saves), (0, 1));
      await tester.tapAt(tester.getCenter(find.text('Tide')));
      await tester.pumpAndSettle();
      expect((opens, saves), (1, 1));

      expect(
        tester.getSemantics(find.text('Tide')),
        isSemantics(label: 'Tide', isButton: true, hasTapAction: true),
      );
      final save = tester.getSemantics(find.text('Save'));
      expect(save.isMergedIntoParent, isFalse);
      expect(
        save,
        isSemantics(label: 'Save', isButton: true, hasTapAction: true),
      );
      handle.dispose();
    });

    testWidgets('a card may hold a card, never three deep (CONTRACT §3)', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          const ExpressiveCard(child: ExpressiveCard.outlined(child: _body)),
        ),
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(
        _app(
          const ExpressiveCard(
            child: ExpressiveCard(child: ExpressiveCard(child: _body)),
          ),
        ),
      );
      expect(
        tester.takeException(),
        isA<FlutterError>().having(
          (e) => e.message,
          'message',
          contains('nested 3 deep'),
        ),
      );
    });

    testWidgets('a card around one field is a defect (CONTRACT §3)', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          const SizedBox(
            width: 320,
            child: ExpressiveCard(child: ExpressiveTextField(label: 'Name')),
          ),
        ),
      );
      expect(
        tester.takeException(),
        isA<FlutterError>().having(
          (e) => e.message,
          'message',
          contains('holds a single ExpressiveTextField'),
        ),
      );
    });
  });
}

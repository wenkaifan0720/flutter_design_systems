import 'dart:async';

import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';
import 'package:material_expressive_ui/material_expressive_host.dart';

final _theme = ExpressiveThemeData.preset('baseline', Brightness.light);

Widget _app(Widget child, {ExpressiveThemeData? theme}) => MaterialApp(
  home: ExpressiveHost(
    light: theme ?? _theme,
    brightness: Brightness.light,
    child: Center(child: child),
  ),
);

void main() {
  testWidgets('dialog actions and FAB menus paint their per-widget ink', (
    tester,
  ) async {
    const ink = Color(0xff123456);
    const style = ExpressiveComponentThemeData(
      foregroundColor: WidgetStatePropertyAll(ink),
    );
    for (final widget in [
      ExpressiveTextButton('Styled action', style: style, onPressed: () {}),
      ExpressiveHeroMoment(
        child: ExpressiveFabMenu(
          icon: ExpressiveSymbols.add,
          expanded: true,
          itemStyle: style,
          items: [
            ExpressiveFabMenuItem(
              icon: ExpressiveSymbols.add,
              label: 'Styled action',
              onPressed: (_) {},
            ),
            ExpressiveFabMenuItem(
              icon: ExpressiveSymbols.edit,
              label: 'Another action',
              onPressed: (_) {},
            ),
          ],
        ),
      ),
    ]) {
      await tester.pumpWidget(_app(widget));
      await tester.pumpAndSettle();
      expect(
        tester
            .renderObject<RenderParagraph>(find.text('Styled action'))
            .text
            .style!
            .color,
        ink,
      );
    }
  });

  testWidgets('coach mark paints the caller tooltip style in its overlay', (
    tester,
  ) async {
    const ink = Color(0xff123456);
    await tester.pumpWidget(
      _app(
        const ExpressiveCoachMark(
          visible: true,
          text: 'A styled coach',
          style: ExpressiveComponentThemeData(
            foregroundColor: WidgetStatePropertyAll(ink),
          ),
          child: Text('Anchor'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .renderObject<RenderParagraph>(find.text('A styled coach'))
          .text
          .style!
          .color,
      ink,
    );
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets('refresh indicator keeps custom fill through its loading phase', (
    tester,
  ) async {
    const fill = Color(0xff123456);
    final done = Completer<void>();
    await tester.pumpWidget(
      _app(
        SizedBox(
          width: 240,
          height: 300,
          child: ExpressiveRefreshIndicator(
            onRefresh: () => done.future,
            style: const ExpressiveComponentThemeData(
              backgroundColor: WidgetStatePropertyAll(fill),
            ),
            child: ListView(children: const [Text('First')]),
          ),
        ),
      ),
    );
    unawaited(
      tester
          .state<ExpressivePullToRefreshState>(
            find.byType(ExpressiveRefreshIndicator),
          )
          .show(),
    );
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    final paints = find.descendant(
      of: find.byType(ExpressiveLoadingIndicator),
      matching: find.byWidgetPredicate(
        (w) => w.runtimeType.toString() == '_SurfacePaint',
      ),
    );
    expect(paints, findsWidgets);
    for (final paint in tester.widgetList(paints)) {
      expect((paint as dynamic).fill, fill);
    }
    done.complete();
    for (var i = 0; i < 90; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(find.byType(ExpressiveLoadingIndicator), findsNothing);
  });

  for (final (interactive, wide) in [
    (false, false),
    (true, false),
    (false, true),
    (true, true),
  ]) {
    testWidgets(
      '${wide ? 'a wide side' : 'an outline-only style'} paints a rim and '
      'reserves it, interactive=$interactive',
      (tester) async {
        const rim = Color(0xff123456);
        final style = wide
            ? const ExpressiveComponentThemeData(
                side: WidgetStatePropertyAll(BorderSide(color: rim, width: 8)),
              )
            : const ExpressiveComponentThemeData(
                outline: WidgetStatePropertyAll(rim),
              );
        await tester.pumpWidget(
          _app(
            interactive
                ? ExpressiveFilledButton('Save', style: style, onPressed: () {})
                : ExpressiveSurface(
                    style: style,
                    shape: const RoundedRectangleBorder(),
                    color: _theme.colors.surface,
                    child: const Text('Save'),
                  ),
          ),
        );
        await tester.pumpAndSettle();
        final finder = find
            .byWidgetPredicate(
              (w) => w.runtimeType.toString() == '_SurfacePaint',
            )
            .first;
        final dynamic paint = tester.widget(finder);
        expect((paint.side as BorderSide).style, BorderStyle.solid);
        expect((paint.side as BorderSide).color, rim);
        if (!wide) return;
        expect((paint.side as BorderSide).width, 8);
        final box = tester.getRect(finder);
        final text = tester.getRect(find.text('Save'));
        expect(text.left - box.left, greaterThanOrEqualTo(8));
        expect(box.right - text.right, greaterThanOrEqualTo(8));
      },
    );
  }

  testWidgets(
    'error state resolves error slots and keeps a null widget override fallback',
    (tester) async {
      const ink = Color(0xff123456);
      await tester.pumpWidget(
        _app(
          ExpressiveErrorState(
            title: 'Unavailable',
            style: ExpressiveComponentThemeData(
              foregroundColor: WidgetStateProperty.resolveWith(
                (states) => null,
              ),
            ),
          ),
          theme: _theme.copyWith(
            statusViewTheme: ExpressiveComponentThemeData(
              foregroundColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.error) ? ink : null,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .renderObject<RenderParagraph>(find.text('Unavailable'))
            .text
            .style!
            .color,
        ink,
      );
      expect(
        tester.widget<ExpressiveIcon>(find.byType(ExpressiveIcon)).color,
        ink,
      );
    },
  );

  testWidgets('skeleton minimum size and widget fill override its theme', (
    tester,
  ) async {
    const fill = Color(0xff123456);
    await tester.pumpWidget(
      _app(
        const ExpressiveSkeleton(
          width: 30,
          height: 20,
          style: ExpressiveComponentThemeData(
            backgroundColor: WidgetStatePropertyAll(fill),
            minimumSize: WidgetStatePropertyAll(Size(80, 50)),
          ),
        ),
        theme: _theme.copyWith(
          skeletonTheme: const ExpressiveComponentThemeData(
            backgroundColor: WidgetStatePropertyAll(Color(0xff654321)),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.getSize(find.byType(ExpressiveSkeleton)), const Size(80, 50));
    final dynamic paint = tester.widget(
      find
          .byWidgetPredicate((w) => w.runtimeType.toString() == '_SurfacePaint')
          .first,
    );
    expect(paint.fill, fill);
  });
  testWidgets(
    'carousel selected ink survives null widget slots and its padded mask hits the right item',
    (tester) async {
      const ink = Color(0xff123456);
      int? tapped;
      await tester.pumpWidget(
        _app(
          SizedBox(
            width: 240,
            child: ExpressiveCarouselView.uncontained(
              itemCount: 3,
              itemWidth: 120,
              height: 100,
              onItemTap: (index) => tapped = index,
              style: ExpressiveComponentThemeData(
                foregroundColor: WidgetStateProperty.resolveWith(
                  (states) => null,
                ),
                padding: const WidgetStatePropertyAll(EdgeInsets.all(4)),
                side: const WidgetStatePropertyAll(BorderSide(width: 3)),
              ),
              itemBuilder: (context, index) => Text('Item $index'),
            ),
          ),
          theme: _theme.copyWith(
            carouselTheme: ExpressiveComponentThemeData(
              foregroundColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.selected) ? ink : null,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .renderObject<RenderParagraph>(find.text('Item 0'))
            .text
            .style!
            .color,
        ink,
      );
      final frame = tester.getRect(find.byType(ExpressiveCarouselView));
      await tester.tapAt(frame.topLeft + const Offset(160, 50));
      expect(tapped, 1);
      expect(tester.takeException(), isNull);
    },
  );

  for (final direction in TextDirection.values) {
    testWidgets('page dots hit the resized and padded marks in $direction', (
      tester,
    ) async {
      int? chosen;
      await tester.pumpWidget(
        _app(
          Directionality(
            textDirection: direction,
            child: ExpressivePageDots(
              count: 4,
              selectedIndex: 1,
              onChanged: (index) => chosen = index,
              style: const ExpressiveComponentThemeData(
                iconSize: WidgetStatePropertyAll(12),
                padding: WidgetStatePropertyAll(EdgeInsets.all(16)),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final marks = find.descendant(
        of: find.byType(ExpressivePageDots),
        matching: find.byType(DecoratedBox),
      );
      await tester.tapAt(tester.getCenter(marks.last));
      expect(chosen, 3);
      expect(
        tester.getSize(find.byType(ExpressivePageDots)).height,
        greaterThanOrEqualTo(48),
      );
    });
  }

  testWidgets(
    'side-only field reserves a thick rim even with zero content padding',
    (tester) async {
      final controller = TextEditingController(text: 'Value');
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _app(
          SizedBox(
            width: 120,
            child: ExpressiveTextField(
              controller: controller,
              kind: ExpressiveTextFieldKind.outlined,
              style: const ExpressiveComponentThemeData(
                side: WidgetStatePropertyAll(BorderSide(width: 12)),
                padding: WidgetStatePropertyAll(EdgeInsets.zero),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final face = tester.getRect(
        find.byWidgetPredicate(
          (w) => w.runtimeType.toString() == '_FieldLayout',
        ),
      );
      final content = tester.getRect(find.byType(EditableText));
      expect(content.left - face.left, greaterThanOrEqualTo(12));
      expect(face.right - content.right, greaterThanOrEqualTo(12));
    },
  );
  testWidgets('avatar and pile reserve a painted rim with no explicit shape', (
    tester,
  ) async {
    const ink = Color(0xff123456);
    for (final sideOnly in [false, true]) {
      final style = ExpressiveComponentThemeData(
        outline: sideOnly ? null : const WidgetStatePropertyAll(ink),
        side: sideOnly
            ? const WidgetStatePropertyAll(BorderSide(color: ink, width: 8))
            : null,
        padding: const WidgetStatePropertyAll(EdgeInsets.zero),
      );
      for (final child in [
        ExpressiveAvatar(name: 'Wide Words', style: style),
        ExpressiveAvatarGroup(
          faces: const [ExpressiveFace('Wide Words')],
          total: 9,
          max: 1,
          style: style,
        ),
      ]) {
        await tester.pumpWidget(_app(child));
        await tester.pumpAndSettle();
        final rims = find.byWidgetPredicate(
          (w) =>
              w is DecoratedBox &&
              w.decoration is ShapeDecoration &&
              ((w.decoration as ShapeDecoration).shape as OutlinedBorder)
                      .side
                      .style ==
                  BorderStyle.solid,
        );
        expect(
          rims,
          child is ExpressiveAvatar ? findsOneWidget : findsNWidgets(2),
        );
        for (final element in rims.evaluate()) {
          final decoration =
              (element.widget as DecoratedBox).decoration as ShapeDecoration;
          final shape = decoration.shape as OutlinedBorder;
          expect(shape.side.color, ink);
          if (sideOnly) expect(shape.side.width, 8);
          final plate = element.findRenderObject()! as RenderBox;
          final path = shape.getInnerPath(Offset.zero & plate.size);
          for (final word
              in find
                  .descendant(
                    of: find.byElementPredicate((e) => e == element),
                    matching: find.byType(Text),
                  )
                  .evaluate()) {
            final box = word.findRenderObject()! as RenderBox;
            final rect = MatrixUtils.transformRect(
              box.getTransformTo(plate),
              box.paintBounds,
            ).deflate(1);
            for (final point in [
              rect.topLeft,
              rect.topRight,
              rect.bottomLeft,
              rect.bottomRight,
            ]) {
              expect(
                path.contains(point),
                isTrue,
                reason: 'Text under the rim: $child, sideOnly=$sideOnly',
              );
            }
          }
        }
      }
    }
  });

  const rimStyle = ExpressiveComponentThemeData(
    side: WidgetStatePropertyAll(
      BorderSide(color: Color(0xff123456), width: 8),
    ),
    padding: WidgetStatePropertyAll(EdgeInsets.zero),
    backgroundColor: WidgetStatePropertyAll(Color(0xff123456)),
    overlayColor: WidgetStatePropertyAll(Color(0x80808080)),
  );
  final rims = <String, Widget Function()>{
    'static card': () =>
        const ExpressiveCard(style: rimStyle, child: Text('Title')),
    'interactive card': () => ExpressiveCard(
      style: rimStyle,
      onPressed: () {},
      child: const Text('Title'),
    ),
    'static list': () =>
        const ExpressiveListTile(style: rimStyle, title: Text('Title')),
    'interactive list': () => ExpressiveListTile(
      style: rimStyle,
      title: const Text('Title'),
      onTap: () {},
    ),
    'toolbar': () => const ExpressiveFloatingToolbar(
      style: rimStyle,
      children: [Text('Title')],
    ),
  };
  for (final entry in rims.entries) {
    testWidgets('${entry.key} paints a style side and reserves its rim', (
      tester,
    ) async {
      await tester.pumpWidget(_app(SizedBox(width: 180, child: entry.value())));
      await tester.pumpAndSettle();
      final surface = find.byWidgetPredicate(
        (w) => w.runtimeType.toString() == '_SurfacePaint',
      );
      late final Rect box;
      late final BorderSide side;
      if (surface.evaluate().isNotEmpty) {
        final dynamic paint = tester.widget(surface.first);
        side = paint.side as BorderSide;
        box = tester.getRect(surface.first);
      } else {
        final finder = find.byWidgetPredicate(
          (w) =>
              w is CustomPaint &&
              w.painter.runtimeType.toString() == '_BodyPainter',
        );
        final dynamic painter = tester.widget<CustomPaint>(finder).painter;
        side = (painter.shape as OutlinedBorder).side;
        box = tester.getRect(finder);
      }
      expect(side.style, BorderStyle.solid);
      expect(side.width, 8);
      final text = tester.getRect(find.text('Title'));
      expect(text.left - box.left, greaterThanOrEqualTo(8));
      expect(box.right - text.right, greaterThanOrEqualTo(8));
    });
  }
}

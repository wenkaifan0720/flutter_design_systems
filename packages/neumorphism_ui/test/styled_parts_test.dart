import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

import 'support.dart';

typedef _Part = Widget Function(NeumorphicStyle?);
typedef _Theme = NeumorphicThemeData Function(
  NeumorphicThemeData,
  NeumorphicStyle,
);

const _content = Text('Content', key: ValueKey('content'));
const _capture = ValueKey('capture');

Future<void> _mount(
  WidgetTester tester,
  Widget child,
  NeumorphicThemeData theme, {
  double width = 320,
  double scale = 1,
  bool flat = true,
}) async {
  tester.view.physicalSize = const Size(600, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
          size: const Size(600, 800),
          textScaler: TextScaler.linear(scale),
        ),
        child: NeumorphicTheme(
          data: theme,
          child: Center(
            child: RepaintBoundary(
              key: _capture,
              child: SizedBox(
                width: width,
                child: flat ? NeumorphicFlatScope(child: child) : child,
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

Future<Color> _facePixel(WidgetTester tester, {Offset? point}) async {
  final face = tester
      .renderObjectList<RenderCustomPaint>(find.byType(CustomPaint))
      .firstWhere((r) => r.painter.runtimeType.toString() == '_CastPainter');
  final capture = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_capture),
  );
  final at = capture.globalToLocal(
    face.localToGlobal(point ?? Offset(9, face.size.height / 2)),
  );
  return (await tester.runAsync(() async {
    final image = await capture.toImage();
    final bytes = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
    final index = (at.dy.floor() * image.width + at.dx.floor()) * 4;
    final color = Color.fromARGB(
      bytes.getUint8(index + 3),
      bytes.getUint8(index),
      bytes.getUint8(index + 1),
      bytes.getUint8(index + 2),
    );
    image.dispose();
    return color;
  }))!;
}

void main() {
  setUpAll(loadNeumorphicFonts);
  for (final kind in ['slab', 'well', 'card']) {
    testWidgets('$kind inherits content slots and keeps child overrides', (
      tester,
    ) async {
      final style = NeumorphicStyle(
        foreground: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? Colors.blue : null,
        ),
        textStyle: const WidgetStatePropertyAll(TextStyle(fontSize: 20)),
        iconSize: const WidgetStatePropertyAll(28),
      );
      const children = <Widget>[
        Text('Inherited'),
        Icon(Icons.star, key: ValueKey('inherited icon')),
        Text('Explicit', style: TextStyle(color: Colors.green, fontSize: 17)),
        Icon(
          Icons.star,
          key: ValueKey('explicit icon'),
          color: Colors.green,
          size: 19,
        ),
      ];
      final theme = NeumorphicThemeData.porcelain().copyWith(
        cardTheme: const NeumorphicStyle(
          foreground: WidgetStatePropertyAll(Colors.red),
          textStyle: WidgetStatePropertyAll(TextStyle(fontSize: 14)),
        ),
      );
      for (final selected in [false, true]) {
        await _mount(
          tester,
          NeumorphicStatesScope(
            states: {if (selected) WidgetState.selected},
            child: switch (kind) {
              'slab' => NeumorphicSlab(
                style: style,
                child: const Column(children: children),
              ),
              'well' => NeumorphicWell(
                style: style,
                child: const Column(children: children),
              ),
              _ => NeumorphicCard(
                title: 'Heading',
                subtitle: 'Meta',
                style: style,
                children: children,
              ),
            },
          ),
          theme,
        );
        final expected = selected ? Colors.blue : Colors.red;
        TextStyle words(String text) => tester
            .renderObject<RenderParagraph>(
              find.descendant(
                of: find.text(text),
                matching: find.byType(RichText),
              ),
            )
            .text
            .style!;
        for (final text in [
          'Inherited',
          if (kind == 'card') ...['Heading', 'Meta'],
        ]) {
          expect(words(text).color, expected);
          expect(words(text).fontSize, 20);
        }
        expect(words('Explicit').color, Colors.green);
        expect(words('Explicit').fontSize, 17);
        final icon = tester.element(
          find.byKey(const ValueKey('inherited icon')),
        );
        expect(IconTheme.of(icon).color, expected);
        expect(IconTheme.of(icon).size, 28);
        final explicit = tester.widget<Icon>(
          find.byKey(const ValueKey('explicit icon')),
        );
        expect(explicit.color, Colors.green);
        expect(explicit.size, 19);
      }
    });
  }
  for (final cast in [
    NeumorphicSurfaceLevel.groove,
    NeumorphicSurfaceLevel.well,
  ]) {
    for (final border in <OutlinedBorder?>[
      null,
      const NeumorphicRoundedBorder(radius: 20),
      const NeumorphicStadiumBorder(),
    ]) {
      testWidgets('${cast.name} $border keeps inset shadow outside content', (
        tester,
      ) async {
        await _mount(
          tester,
          NeumorphicSurface(
            cast: cast,
            shape: border,
            style: const NeumorphicStyle(
              fill: WidgetStatePropertyAll(Color(0xFFFFFFFF)),
            ),
            padding: const EdgeInsets.all(14),
            child: const SizedBox(height: 40),
          ),
          NeumorphicThemeData.porcelain(),
          flat: false,
        );
        final inset =
            border?.dimensions.resolve(TextDirection.ltr) ?? EdgeInsets.zero;
        final point = Offset(15 + inset.left, 15 + inset.top);
        expect((await _facePixel(tester, point: point)).toARGB32(), 0xFFFFFFFF);
      }, tags: ['goldens']);
    }
  }
  final parts = <(String, _Part, _Theme)>[
    (
      'slab',
      (s) => NeumorphicSlab(style: s, child: _content),
      (t, s) => t.copyWith(cardTheme: s),
    ),
    (
      'well',
      (s) => NeumorphicWell(style: s, child: _content),
      (t, s) => t.copyWith(cardTheme: s),
    ),
    (
      'card',
      (s) => NeumorphicCard(style: s, children: const [_content]),
      (t, s) => t.copyWith(cardTheme: s),
    ),
    (
      'dialog',
      (s) =>
          NeumorphicDialog(style: s, title: 'Title', content: const [_content]),
      (t, s) => t.copyWith(dialogTheme: s),
    ),
    (
      'sheet',
      (s) => SizedBox(
        height: 300,
        child: NeumorphicBottomSheet(
          style: s,
          showClose: false,
          child: _content,
        ),
      ),
      (t, s) => t.copyWith(sheetTheme: s),
    ),
    (
      'menu',
      (s) => NeumorphicMenu<int>(
        style: s,
        items: const [NeumorphicMenuItem(1, 'Content')],
      ),
      (t, s) => t.copyWith(menuTheme: s),
    ),
    (
      'tooltip',
      (s) => NeumorphicTooltipFace(style: s, message: 'Content'),
      (t, s) => t.copyWith(tooltipTheme: s),
    ),
    (
      'snack',
      (s) => NeumorphicSnackBar('Content', style: s),
      (t, s) => t.copyWith(snackBarTheme: s),
    ),
  ];
  for (final (name, part, setTheme) in parts) {
    testWidgets(
      '$name reads theme fill and widget override in painted pixels',
      (tester) async {
        const themed = NeumorphicStyle(
          fill: WidgetStatePropertyAll(Colors.red),
        );
        const local = NeumorphicStyle(
          fill: WidgetStatePropertyAll(Colors.blue),
        );
        final theme = setTheme(NeumorphicThemeData.porcelain(), themed);
        await _mount(tester, part(null), theme);
        expect((await _facePixel(tester)).toARGB32(), Colors.red.toARGB32());
        await _mount(tester, part(local), theme);
        expect((await _facePixel(tester)).toARGB32(), Colors.blue.toARGB32());
        await _mount(tester, part(const NeumorphicStyle()), theme);
        expect((await _facePixel(tester)).toARGB32(), Colors.red.toARGB32());
      },
      tags: ['goldens'],
    );
    for (final set in const ['look']) {
      for (final (densityName, density) in [
        ('standard', NeumorphicDensity.standard),
        ('comfortable', NeumorphicDensity.comfortable),
        ('compact', NeumorphicDensity.compact),
      ]) {
        for (final width in [120.0, 240.0, 390.0]) {
          for (final scale in [1.0, 1.3]) {
            testWidgets(
              '$name $set $densityName fits content at $width and $scale',
              (tester) async {
                final theme = NeumorphicThemeData.porcelain().copyWith(
                  density: density,
                );
                await _mount(
                  tester,
                  part(null),
                  theme,
                  width: width,
                  scale: scale,
                );
                final surface = tester
                    .widgetList<NeumorphicSurface>(
                      find.byType(NeumorphicSurface),
                    )
                    .first;
                final border =
                    surface.shape ??
                    NeumorphicRoundedBorder(
                      radius:
                          surface.radius ??
                          (surface.cast == NeumorphicSurfaceLevel.slab
                              ? NeumorphicRadii.slab
                              : surface.cast == NeumorphicSurfaceLevel.well
                              ? NeumorphicRadii.well
                              : NeumorphicRadii.control),
                    );
                final paint = tester
                    .renderObjectList<RenderCustomPaint>(
                      find.byType(CustomPaint),
                    )
                    .firstWhere(
                      (r) => r.painter.runtimeType.toString() == '_CastPainter',
                    );
                final path = border.getOuterPath(Offset.zero & paint.size);
                final content =
                    name == 'menu' || name == 'tooltip' || name == 'snack'
                    ? find.text('Content')
                    : find.byKey(const ValueKey('content'));
                final child = tester.renderObject<RenderBox>(content);
                final bounds = MatrixUtils.transformRect(
                  child.getTransformTo(paint),
                  child.paintBounds,
                ).deflate(1);
                for (final point in [
                  bounds.topLeft,
                  bounds.topCenter,
                  bounds.topRight,
                  bounds.centerRight,
                  bounds.bottomRight,
                  bounds.bottomCenter,
                  bounds.bottomLeft,
                  bounds.centerLeft,
                ]) {
                  expect(
                    path.contains(point),
                    isTrue,
                    reason: '$point outside ${paint.size}',
                  );
                }
              },
            );
          }
        }
      }
    }
  }
}
